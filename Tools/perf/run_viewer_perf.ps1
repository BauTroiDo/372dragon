<#
.SYNOPSIS
  CYS-PERF: TlbbViewer frame timing for oracle scenes and effects on the private perf stage.
.DESCRIPTION
  For every case and size: TlbbViewer --scene/--effect ... --frames N --dt D --no-vsync --size WxH --shot --log
  with CYS_PERF=1 and CYS_PERF_CSV, then Tools\perf\perf_report.py (frames of the first -Settle seconds are
  excluded from the settled numbers). Cases are ids of Tests\oracle\cases.json (S01, E012, ...) or raw
  effect names prefixed with "fx:". The window is shown without activation unless -Window Hidden.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_viewer_perf.ps1 -Tag A -Cases S01,S07
#>
param(
    [Parameter(Mandatory=$true)][string]$Tag,
    [string[]]$Cases = @('S01','S07','S09','S10'),
    [string[]]$Sizes = @('1920x1080','1024x768'),
    [string]$Stage = 'Build\perf\stage',
    [string]$Data = 'Assets\Canonical\Data',
    [int]$Frames = 900,
    [double]$Dt = 0.0166667,
    [double]$Settle = 0.0,
    [int]$SkipFrames = 60,
    [ValidateSet('NoActivate','Hidden')][string]$Window = 'NoActivate',
    [int]$TimeoutSeconds = 300,
    [switch]$NoPerf,
    [string[]]$Env = @(),
    [string[]]$ExtraArgs = @(),
    [string]$OutRoot = 'Build\Logs\2026-09-13-perf\viewer'
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
$viewer = Join-Path $bin 'TlbbViewer.exe'
if (-not (Test-Path -LiteralPath $viewer)) { throw ('No TlbbViewer.exe in ' + $bin) }
$Data = Resolve-InRoot $Data
$Cases = @($Cases | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Sizes = @($Sizes | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$out = Join-Path (Resolve-InRoot $OutRoot) $Tag
if (Test-Path -LiteralPath $out) { throw ('Output exists, choose a new tag: ' + $out) }
[void][IO.Directory]::CreateDirectory($out)
$oracle = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'Tests\oracle\cases.json') | ConvertFrom-Json
. (Join-Path $PSScriptRoot 'perf_launch.ps1')

$results = @()
$caseIndex = 0
foreach ($case in $Cases) {
    $content = $null
    $caseIndex++
    if ($case.StartsWith('fx:')) {
        # Effect names are often Chinese: the file id keeps the list position so two names never collide.
        $content = @('--effect', ('"' + $case.Substring(3) + '"'))
        $id = ('fx{0:D2}-' -f $caseIndex) + ($case.Substring(3) -replace '[^A-Za-z0-9_-]', '')
    } else {
        $scene = @($oracle.scenes | Where-Object { $_.id -eq $case })
        $effect = @($oracle.effects | Where-Object { $_.id -eq $case })
        $model = @($oracle.models | Where-Object { $_.id -eq $case })
        if ($scene.Count) { $content = @('--scene', ('"' + $scene[0].scene + '"')) }
        elseif ($effect.Count) { $content = @('--effect', ('"' + $effect[0].effect + '"')) }
        elseif ($model.Count) { $content = @('--model', ('"' + $model[0].obj + '"')) }
        else { throw ('Unknown case ' + $case) }
        $id = $case
    }
    foreach ($size in $Sizes) {
        $name = $id + '-' + $size
        $csv = Join-Path $out ($name + '.csv')
        $png = Join-Path $out ($name + '.png')
        $log = Join-Path $out ($name + '.log')
        $arguments = @('--data', ('"' + $Data + '"')) + $content + @('--frames', [string]$Frames, '--dt', ([string]$Dt),
                     '--no-vsync', '--size', $size, '--shot', ('"' + $png + '"'), '--log', ('"' + $log + '"'))
        if ($Window -ne 'Hidden') { $arguments += '--show' }
        $arguments += $ExtraArgs
        $envSet = [ordered]@{}
        if (-not $NoPerf) { $envSet['CYS_PERF'] = '1'; $envSet['CYS_PERF_CSV'] = $csv; $envSet['CYS_PERF_LOG'] = (Join-Path $out ($name + '.perf.log')) }
        foreach ($kv in $Env) { $pair = $kv.Split('=', 2); $envSet[$pair[0]] = $pair[1] }
        $r = Invoke-CysPerfProcess -Exe $viewer -Arguments ($arguments -join ' ') -WorkingDirectory $bin -Env $envSet `
                                   -TimeoutSeconds $TimeoutSeconds -Hidden:($Window -eq 'Hidden')
        $r['case'] = $case; $r['size'] = $size; $r['arguments'] = ($arguments -join ' ')
        if (Test-Path -LiteralPath $csv) {
            $env:PYTHONUTF8 = '1'
            & 'C:\Program Files\Python313\python.exe' -B (Join-Path $PSScriptRoot 'perf_report.py') $csv --settle $Settle `
                --drop-last 1 --skip-frames $SkipFrames --title $name --json (Join-Path $out ($name + '.json')) `
                --md (Join-Path $out ($name + '.md')) | Out-Null
        }
        $results += $r
        Write-Host ('{0}: exit={1} seconds={2:F1} timeout={3}' -f $name, $r.exit_code, $r.seconds, $r.timed_out)
    }
}
[IO.File]::WriteAllText((Join-Path $out 'runs.json'), ($results | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
