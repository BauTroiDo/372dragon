param([Parameter(Mandatory=$true)][string]$Root)
$ErrorActionPreference = 'Stop'
$releaseRoot = (Resolve-Path -LiteralPath $Root).Path
$dataRoot = Join-Path $releaseRoot 'Assets\CanonicalCY\Data'
$playRoot = Join-Path $releaseRoot 'Play'
if (-not (Test-Path -LiteralPath $dataRoot -PathType Container)) { throw 'Restore runtime-data first.' }
if (-not (Test-Path -LiteralPath (Join-Path $playRoot 'Bin64\Game.exe') -PathType Leaf)) { throw 'Restore client-runtime first.' }
$dataLink = Join-Path $playRoot 'Data'
if (Test-Path -LiteralPath $dataLink) {
    $existing = Get-Item -LiteralPath $dataLink -Force
    if ($existing.LinkType -eq 'Junction' -and [IO.Path]::GetFullPath([string]$existing.Target) -eq [IO.Path]::GetFullPath($dataRoot)) {
        Write-Output 'Data junction already correct.'
        exit 0
    }
    throw 'Play/Data already exists with a different target. No files were replaced.'
}
New-Item -ItemType Junction -Path $dataLink -Target $dataRoot | Out-Null
Write-Output 'Data junction created. Configure your own server and account before launching Play.cmd.'
