Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------
# Settings (edit here)
# -----------------------------
$Version = "1.2.0"
$Repo = "vramwiz/Syncroh2-site"
$SetupRoot = "D:\DelphiProg\Syncroh2\Setup"
$OutputRoot = "D:\DelphiProg\Syncroh2\ReleaseArtifacts"
$NotesFile = "D:\DelphiProg\Syncroh2-site\releases\TEMPLATE.md"
$InstallerExe = "D:\DelphiProg\Syncroh2\Setup\Syncroh2_Setup.exe"
$CreateAsDraft = $false
$RequireExistingTag = $false

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Normalize-Tag {
    param([string]$InputVersion)
    if ($InputVersion.StartsWith("v")) { return $InputVersion }
    return "v$InputVersion"
}

function Normalize-VersionForFileName {
    param([string]$InputVersion)
    if ($InputVersion.StartsWith("v")) { return $InputVersion.Substring(1) }
    return $InputVersion
}

function Is-PreReleaseVersion {
    param([string]$InputVersion)
    $v = $InputVersion.ToLowerInvariant()
    return $v.Contains("-beta") -or $v.Contains("-rc") -or $v.Contains("-alpha")
}

if (-not (Test-Path -LiteralPath $SetupRoot)) {
    throw "SetupRoot not found: $SetupRoot"
}

$requiredItems = @(
    "Syncroh2_Desktop.exe",
    "README.txt",
    "Plugin",
    "Script"
)

foreach ($item in $requiredItems) {
    $path = Join-Path $SetupRoot $item
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required item not found in SetupRoot: $item"
    }
}

if (-not (Test-CommandExists -Name "gh")) {
    throw "GitHub CLI (gh) is not installed or not in PATH."
}

& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    throw "gh is not authenticated. Run: gh auth login"
}

$tag = Normalize-Tag -InputVersion $Version
$versionForName = Normalize-VersionForFileName -InputVersion $Version
$zipName = "Syncroh2_Desktop_v{0}.zip" -f $versionForName
$title = "Syncroh2 {0}" -f $tag

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
$zipPath = Join-Path $OutputRoot $zipName

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Push-Location $SetupRoot
try {
    # Keep folder structure inside the zip:
    # Syncroh2_Desktop.exe, README.txt, Plugin/, Script/
    Compress-Archive `
        -Path @("Syncroh2_Desktop.exe", "README.txt", "Plugin", "Script") `
        -DestinationPath $zipPath `
        -CompressionLevel Optimal
}
finally {
    Pop-Location
}

$assets = @($zipPath)
if (Test-Path -LiteralPath $InstallerExe) {
    $assets += $InstallerExe
} else {
    Write-Warning "Installer exe not found. Releasing zip only: $InstallerExe"
}

$args = @("release", "create", $tag)
$args += $assets
$args += @("--repo", $Repo, "--title", $title)

if (Test-Path -LiteralPath $NotesFile) {
    $args += @("--notes-file", $NotesFile)
} else {
    $args += @("--notes", $title)
}

if (Is-PreReleaseVersion -InputVersion $Version) {
    $args += "--prerelease"
}

if ($CreateAsDraft) {
    $args += "--draft"
}

if ($RequireExistingTag) {
    $args += "--verify-tag"
}

Write-Output "Repo      : $Repo"
Write-Output "Tag       : $tag"
Write-Output "Title     : $title"
Write-Output "Zip       : $zipPath"
Write-Output "Assets    : $($assets -join ', ')"
Write-Output "NotesFile : $NotesFile"

& gh @args
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create release."
}

Write-Output "Release created successfully: $tag"
