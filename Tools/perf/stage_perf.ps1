<#
.SYNOPSIS
  CYS-PERF: installs a binary variant into the private perf stage Build\perf\stage.
.DESCRIPTION
  The perf stage is a one-time copy of the user's stage (Data, Patch, Bin64 runtime files). This script never
  writes outside Build\perf. It copies the engine binaries of a build tree (or, with -FromUserStage, the exact
  binaries of the user's stage, read-only) into Bin64, writes Bin64\perf_stage.json, keeps a template of the
  user's WXSystem.cfg, and points the stage's login lists at the offline dummy endpoint 127.0.0.1:14400.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\stage_perf.ps1 -Variant A-instrumented
  powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\stage_perf.ps1 -Variant user-91148e1 -FromUserStage
#>
param(
    [Parameter(Mandatory=$true)][string]$Variant,
    [string]$From = 'Build\perf\src\Build\cmake\perf-x64\bin',
    [switch]$FromUserStage,
    [string]$UserStage = 'Build\gpt-p1-1-20260913\stage-91148e1',
    [string]$Stage = 'Build\perf\stage'
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
function Resolve-InRoot([string]$path) {
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $root $path }
    return [IO.Path]::GetFullPath($path).TrimEnd('\')
}
$Stage = Resolve-InRoot $Stage
$perfRoot = Join-Path $root 'Build\perf'
if (-not $Stage.StartsWith($perfRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'The perf stage must be under Build\perf.' }
$bin = Join-Path $Stage 'Bin64'
if (-not (Test-Path -LiteralPath (Join-Path $Stage 'Data'))) { throw 'The perf stage has no Data folder (copy the user stage once first).' }
if ($FromUserStage) { $From = Join-Path (Resolve-InRoot $UserStage) 'Bin64' }
$src = Resolve-InRoot $From
if (-not (Test-Path -LiteralPath $src)) { throw ('No binaries at ' + $src) }
foreach ($p in @(Get-Process -Name Game,TlbbViewer,OgreSmoke -ErrorAction SilentlyContinue)) {
    $path = $null
    try { $path = $p.Path } catch { }
    if ($path -and $path.StartsWith($bin, [StringComparison]::OrdinalIgnoreCase)) { throw ('A tool of the perf stage is running: pid ' + $p.Id) }
}

$names = @('Game.exe','TlbbViewer.exe','OgreSmoke.exe','OgreMain.dll','Render.dll','RenderSystem_Direct3D9.dll',
           'Plugin_ParticleFX2.dll','Plugin_Scorpio.dll','Plugin_CgProgramManager.dll','CEGUIBase.dll','CEGUIFalagard.dll',
           'CEGUIOgreRenderer.dll','UI_CEGUI.dll','LuaPlus.dll','PathLib.dll')
$symbols = Join-Path $perfRoot ('symbols\' + $Variant)
[void][IO.Directory]::CreateDirectory($symbols)
$files = @()
foreach ($name in $names) {
    $from = Join-Path $src $name
    $to = Join-Path $bin $name
    if (Test-Path -LiteralPath $from) {
        Copy-Item -LiteralPath $from -Destination $to -Force
        $pdb = [IO.Path]::ChangeExtension($from, '.pdb')
        if (Test-Path -LiteralPath $pdb) { Copy-Item -LiteralPath $pdb -Destination $symbols -Force }
        $files += [ordered]@{ name = $name; bytes = (Get-Item -LiteralPath $to).Length; sha256 = (Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash.ToLowerInvariant() }
    } elseif (Test-Path -LiteralPath $to) {
        Remove-Item -LiteralPath $to -Force   # keep every variant pure: no binary left over from another build
    }
}

# Template of the user's settings (taken once from the copied stage) and offline login endpoints.
$template = Join-Path $Stage 'WXSystem.template.cfg'
if (-not (Test-Path -LiteralPath $template)) {
    $userCfg = Join-Path (Resolve-InRoot $UserStage) 'Bin64\WXSystem.cfg'
    Copy-Item -LiteralPath $userCfg -Destination $template
}
$legacy = Join-Path $Stage 'Patch\WXLoginServer.txt'
$modern = Join-Path $Stage 'Patch\LoginServer.txt'
$utf8 = New-Object Text.UTF8Encoding($false)
if (Test-Path -LiteralPath $legacy) {
    $text = [IO.File]::ReadAllText($legacy)
    [IO.File]::WriteAllText($legacy, ($text -replace 'PORT=\d+', 'PORT=14400'), $utf8)
}
if (Test-Path -LiteralPath $modern) {
    $text = [IO.File]::ReadAllText($modern, $utf8)
    [IO.File]::WriteAllText($modern, ($text -replace '127\.0\.0\.1:\d+', '127.0.0.1:14400'), $utf8)
}

$manifest = [ordered]@{ variant = $Variant; from = $src; staged = (Get-Date).ToString('o'); files = $files }
[IO.File]::WriteAllText((Join-Path $bin 'perf_stage.json'), ($manifest | ConvertTo-Json -Depth 4), $utf8)
Write-Host ('staged variant ' + $Variant + ': ' + $files.Count + ' binaries from ' + $src)
