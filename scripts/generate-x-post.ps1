param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [int]$MaxItems = 5,

    [int]$MaxLength = 280,

    [string]$ScopeText = '以下はすべて AviUtl2 に対する変更',

    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Utf8Text {
    param([string]$Path)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    return [System.IO.File]::ReadAllText($Path, $utf8NoBom)
}

function Write-Utf8Text {
    param(
        [string]$Path,
        [string]$Content
    )
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-SectionLines {
    param(
        [string[]]$Lines,
        [string]$HeadingPrefix
    )

    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^##\s+' -and $Lines[$i].Contains($HeadingPrefix)) {
            $start = $i + 1
            break
        }
    }
    if ($start -lt 0) { return @() }

    $end = $Lines.Count
    for ($j = $start; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j] -match '^##\s+') {
            $end = $j
            break
        }
    }

    if ($end -le $start) { return @() }
    return $Lines[$start..($end - 1)]
}

function Get-Bullets {
    param([string[]]$Lines)

    $items = @()
    foreach ($line in $Lines) {
        if ($line -match '^\s*-\s+(.+)$') {
            $items += $Matches[1].Trim()
        }
    }
    return $items
}

function Get-DownloadUrl {
    param([string[]]$Lines)

    $setup = ''
    $desktop = ''
    foreach ($line in $Lines) {
        if ($line -match '^\s*-\s*Setup\s*:\s*(.+)$') { $setup = $Matches[1].Trim() }
        if ($line -match '^\s*-\s*Desktop\s*:\s*(.+)$') { $desktop = $Matches[1].Trim() }
    }
    if ($desktop) { return $desktop }
    if ($setup) { return $setup }
    return ''
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

$text = Read-Utf8Text -Path $InputFile
$lines = $text -split "`r?`n"

$titleLine = ($lines | Where-Object { $_ -match '^#\s+(.+)$' } | Select-Object -First 1)
if (-not $titleLine) {
    throw 'Release title is missing. Add a first-level heading: # 新旧朗2 ...'
}
$title = $titleLine -replace '^#\s+', ''

$releaseUrl = ''
foreach ($line in $lines) {
    if ($line -match '^\s*release_url\s*:\s*(.+)$') {
        $releaseUrl = $Matches[1].Trim()
        break
    }
}

$bulletLines = Get-SectionLines -Lines $lines -HeadingPrefix 'X用変更点'
$bullets = Get-Bullets -Lines $bulletLines
if ($bullets.Count -eq 0) {
    $summaryLines = Get-SectionLines -Lines $lines -HeadingPrefix '要約'
    $bullets = Get-Bullets -Lines $summaryLines
}
if ($bullets.Count -eq 0) {
    $bullets = @('更新内容はリリースページをご確認ください')
}

if (-not $releaseUrl) {
    $downloadLines = Get-SectionLines -Lines $lines -HeadingPrefix 'ダウンロード'
    $releaseUrl = Get-DownloadUrl -Lines $downloadLines
}

$limitCount = [Math]::Min([Math]::Max($MaxItems, 1), $bullets.Count)

function Build-Post {
    param(
        [string]$Title,
        [string]$Scope,
        [string[]]$Items,
        [string]$Url
    )

    $parts = @($Title, $Scope, '')
    $parts += ($Items | ForEach-Object { "・$_" })
    if ($Url) {
        $parts += ''
        $parts += $Url
    }
    return ($parts -join "`n")
}

$output = ''
for ($count = $limitCount; $count -ge 1; $count--) {
    $candidate = Build-Post -Title $title -Scope $ScopeText -Items ($bullets | Select-Object -First $count) -Url $releaseUrl
    if ($candidate.Length -le $MaxLength) {
        $output = $candidate
        break
    }
}

if (-not $output) {
    $fallback = Build-Post -Title $title -Scope '' -Items @('更新しました') -Url $releaseUrl
    if ($fallback.Length -gt $MaxLength -and $releaseUrl) {
        $fallback = "$title`n$releaseUrl"
    }
    $output = $fallback
}

if ($OutputPath) {
    Write-Utf8Text -Path $OutputPath -Content $output
    Write-Output "Written: $OutputPath"
} else {
    Write-Output $output
}
