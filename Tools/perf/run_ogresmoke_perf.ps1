<#
.SYNOPSIS
  CYS-PERF: OgreSmoke render timing on the private perf stage (Build\perf\stage).
.DESCRIPTION
  Runs OgreSmoke --data <Data> --out <dir> --batch <B> --frames <N> --width W --height H for every size and
  extracts "rendered N frames in X s" (the grid of the batch models; the time includes first-use shader
  compiles, the shader cache of the stage is warm after the first run) and "resources:" timings.
#>
param(
    [Parameter(Mandatory=$true)][string]$Tag,
    [string[]]$Sizes = @('1920x1080','1024x768'),
    [string]$Stage = 'Build\perf\stage',
    [string]$Data = 'Assets\Canonical\Data',
    [int]$Frames = 600,
    [int]$Batch = 200,
    [ValidateSet('NoActivate','Hidden')][string]$Window = 'NoActivate',
    [int]$TimeoutSeconds = 600,
    [string]$OutRoot = 'Build\Logs\2026-09-13-perf\ogresmoke'
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
function Resolve-InRoot([string]$path) {
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $root $path }
    return [IO.Path]::GetFullPath($path).TrimEnd('\')
}
$Stage = Resolve-InRoot $Stage
if (-not $Stage.StartsWith((Join-Path $root 'Build\perf') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Only stages under Build\perf.' }
$bin = Join-Path $Stage 'Bin64'
$exe = Join-Path $bin 'OgreSmoke.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw ('No OgreSmoke.exe in ' + $bin) }
$Data = Resolve-InRoot $Data
$Sizes = @($Sizes | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$out = Join-Path (Resolve-InRoot $OutRoot) $Tag
if (Test-Path -LiteralPath $out) { throw ('Output exists, choose a new tag: ' + $out) }
[void][IO.Directory]::CreateDirectory($out)
. (Join-Path $PSScriptRoot 'perf_launch.ps1')
$results = @()
foreach ($size in $Sizes) {
    $wh = $size.Split('x')
    $dir = Join-Path $out $size
    [void][IO.Directory]::CreateDirectory($dir)
    $stdout = Join-Path $dir 'ogresmoke.log'
    $args = ('--data "{0}" --out "{1}" --batch {2} --frames {3} --width {4} --height {5}' -f $Data, $dir, $Batch, $Frames, $wh[0], $wh[1])
    $r = Invoke-CysPerfProcess -Exe $exe -Arguments $args -WorkingDirectory $bin -Env ([ordered]@{}) `
                               -TimeoutSeconds $TimeoutSeconds -Hidden:($Window -eq 'Hidden')
    $r['size'] = $size
    $logs = @(Get-ChildItem -LiteralPath $dir -Filter '*.log' -File | Sort-Object LastWriteTime)
    foreach ($l in $logs) {
        foreach ($m in @(Select-String -LiteralPath $l.FullName -Pattern 'rendered (\d+) frames in ([0-9.]+) s' -AllMatches)) {
            $n = [int]$m.Matches[0].Groups[1].Value; $s = [double]$m.Matches[0].Groups[2].Value
            $r['frames'] = $n; $r['render_seconds'] = $s; $r['avg_fps'] = [math]::Round($n / $s, 2); $r['avg_ms'] = [math]::Round(1000.0 * $s / $n, 3)
            $r['line'] = $m.Line.Trim()
        }
    }
    $results += $r
    Write-Host ('{0}: exit={1} {2}' -f $size, $r.exit_code, $r['line'])
}
[IO.File]::WriteAllText((Join-Path $out 'runs.json'), ($results | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
