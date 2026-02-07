param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [ValidateSet('short', 'thread')]
    [string]$Mode = 'short',

    [int]$MaxLength = 280,

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

function Get-SubsectionBullets {
    param(
        [string[]]$Lines,
        [string]$Subheading
    )

    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^###\s+' -and $Lines[$i].Contains($Subheading)) {
            $start = $i + 1
            break
        }
    }

    if ($start -lt 0) { return @() }

    $end = $Lines.Count
    for ($j = $start; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j] -match '^###\s+') {
            $end = $j
            break
        }
    }

    if ($end -le $start) { return @() }
    return Get-Bullets -Lines $Lines[$start..($end - 1)]
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

$text = Read-Utf8Text -Path $InputFile
$lines = $text -split "`r?`n"

$title = ($lines | Where-Object { $_ -match '^#\s+(.+)$' } | Select-Object -First 1)
if (-not $title) {
    throw 'Release title is missing. Add a first-level heading: # 新旧朗2 ...'
}
$titleText = $title -replace '^#\s+', ''

$summaryLines = Get-SectionLines -Lines $lines -HeadingPrefix '要約'
$summary = Get-Bullets -Lines $summaryLines
if ($summary.Count -eq 0) {
    $summary = @('更新内容はサイトの履歴をご確認ください。')
}

$detailLines = Get-SectionLines -Lines $lines -HeadingPrefix '変更詳細'
$added = Get-SubsectionBullets -Lines $detailLines -Subheading '追加'
$fixed = Get-SubsectionBullets -Lines $detailLines -Subheading '修正'
$known = Get-SubsectionBullets -Lines $detailLines -Subheading '既知'

$downloadLines = Get-SectionLines -Lines $lines -HeadingPrefix 'ダウンロード'
$setup = ''
$desktop = ''
foreach ($line in $downloadLines) {
    if ($line -match '^\s*-\s*Setup\s*:\s*(.+)$') { $setup = $Matches[1].Trim() }
    if ($line -match '^\s*-\s*Desktop\s*:\s*(.+)$') { $desktop = $Matches[1].Trim() }
}

$mainUrl = if ($desktop) { $desktop } elseif ($setup) { $setup } else { '' }

function Build-ShortPost {
    param(
        [string]$ReleaseTitle,
        [string[]]$Summary,
        [string]$Url,
        [int]$Limit
    )

    $header = "$ReleaseTitle 公開"
    $tail = if ($Url) { "`n`nDL: $Url" } else { '' }
    $tags = "`n#新旧朗2 #AviUtl2"

    $body = @()
    foreach ($item in $Summary) {
        $candidate = @($body + "・$item")
        $tmp = $header + "`n`n" + ($candidate -join "`n") + $tail + $tags
        if ($tmp.Length -le $Limit) {
            $body = $candidate
        } else {
            break
        }
    }

    if ($body.Count -eq 0) {
        $body = @('・更新しました')
    }

    return $header + "`n`n" + ($body -join "`n") + $tail + $tags
}

function Build-ThreadPost {
    param(
        [string]$ReleaseTitle,
        [string[]]$Summary,
        [string[]]$Added,
        [string[]]$Fixed,
        [string[]]$Known,
        [string]$SetupUrl,
        [string]$DesktopUrl
    )

    $p1 = @(
        "$ReleaseTitle 公開",
        '',
        '要点:'
    )
    $p1 += ($Summary | Select-Object -First 4 | ForEach-Object { "・$_" })
    $p1 += '#新旧朗2 #AviUtl2'

    $p2 = @('変更詳細')
    if ($Added.Count -gt 0) {
        $p2 += ''
        $p2 += '追加:'
        $p2 += ($Added | Select-Object -First 6 | ForEach-Object { "・$_" })
    }
    if ($Fixed.Count -gt 0) {
        $p2 += ''
        $p2 += '修正:'
        $p2 += ($Fixed | Select-Object -First 6 | ForEach-Object { "・$_" })
    }
    if ($p2.Count -eq 1) {
        $p2 += ''
        $p2 += '・詳細は更新履歴をご確認ください。'
    }

    $p3 = @('ダウンロード')
    if ($SetupUrl) { $p3 += "・Setup: $SetupUrl" }
    if ($DesktopUrl) { $p3 += "・Desktop: $DesktopUrl" }
    if ($Known.Count -gt 0) {
        $p3 += ''
        $p3 += '既知の問題:'
        $p3 += ($Known | Select-Object -First 4 | ForEach-Object { "・$_" })
    }

    return @(
        ($p1 -join "`n"),
        ($p2 -join "`n"),
        ($p3 -join "`n")
    ) -join "`n`n---`n`n"
}

$output = if ($Mode -eq 'short') {
    Build-ShortPost -ReleaseTitle $titleText -Summary $summary -Url $mainUrl -Limit $MaxLength
} else {
    Build-ThreadPost -ReleaseTitle $titleText -Summary $summary -Added $added -Fixed $fixed -Known $known -SetupUrl $setup -DesktopUrl $desktop
}

if ($OutputPath) {
    Write-Utf8Text -Path $OutputPath -Content $output
    Write-Output "Written: $OutputPath"
} else {
    Write-Output $output
}
