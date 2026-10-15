# CY-Source Tools/perf/run_world_perf.ps1 - frame pacing / stutter run of our Game.exe in the offline world replay
# (perf-cy, 15/09/2026). Scenario (Tools\game\run_world_replay.ps1 -Move -Core -Camera): login -> character select ->
# enter Dali (dali_new_320) -> camera script -> one continuous 360 degree camera turn (CYS_PERF_SPIN) -> three ground
# clicks (running) -> core loop (target, three attacks with impacts, loot, chat, bag). 0 sockets, <= 150 s.
# CYS_PERF=1 writes frames.csv with #mark rows per scenario step; -Probe also puts the present probe d3d9.dll into
# Bin64 (same frame clock as the CY runs, Tools\perf\run_cy_probe.ps1); without -Probe a d3d9.dll left there is removed.
# -Set "System_MaxFPS_Front=60;View_Aplomb=0" edits Bin64\WXSystem.cfg of the stage (the first run keeps a copy
# WXSystem.cfg.perfcy-orig). -Env "K=V;K=V" adds process variables (A/B switches). ASCII only.
param(
    [Parameter(Mandatory=$true)][string]$Stage,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [ValidateRange(60,150)][int]$Seconds = 150,
    [string]$Set = 'System_MaxFPS_Front=60;System_MaxFPS_Back=60;View_Aplomb=0;View_Resoution=1280,720',
    [string]$Env = '',
    [int]$SpinMs = 8000,
    [switch]$Probe,
    [switch]$NoPerf,
    [string]$Fixture = 'C:\TLBB\085\CY-Source\Build\Logs\2026-09-14-world-replay\world_session_1.bin',
    [string]$ProbeDll = 'C:\TLBB\085\CY-Source\Build\re\perf-cy\probe\d3d9.dll'
)
$ErrorActionPreference = 'Stop'
$Stage = [IO.Path]::GetFullPath($Stage).TrimEnd('\')
if ($Stage -notlike '*\Build\world-gui\stage-*-perfcy*') { throw 'perf-cy only runs its own stages (Build\world-gui\stage-*-perfcy).' }
$OutDir = [IO.Path]::GetFullPath($OutDir).TrimEnd('\')
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir.' }
$bin = Join-Path $Stage 'Bin64'
$cfgPath = Join-Path $bin 'WXSystem.cfg'
$orig = $cfgPath + '.perfcy-orig'
if (-not (Test-Path -LiteralPath $orig)) { Copy-Item -LiteralPath $cfgPath -Destination $orig }
$lines = New-Object 'System.Collections.Generic.List[string]'
foreach ($l in [IO.File]::ReadAllLines($orig)) { $lines.Add($l) }
foreach ($kv in ($Set -split ';')) {
    if (-not $kv.Trim()) { continue }
    $p = $kv.Split('=', 2); $k = $p[0].Trim(); $v = $p[1].Trim(); $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('^\s*' + [regex]::Escape($k) + '\s*=')) { $lines[$i] = $k + '=' + $v; $found = $true } }
    if (-not $found) { $lines.Add($k + '=' + $v) }
}
[IO.File]::WriteAllLines($cfgPath, $lines.ToArray())
$probeTarget = Join-Path $bin 'd3d9.dll'
if ($Probe) { Copy-Item -LiteralPath $ProbeDll -Destination $probeTarget -Force }
elseif (Test-Path -LiteralPath $probeTarget) { Remove-Item -LiteralPath $probeTarget }
$side = $OutDir + '.perf'
[void][IO.Directory]::CreateDirectory($side)
Copy-Item -LiteralPath $cfgPath -Destination (Join-Path $side 'WXSystem.cfg.used')
$envSet = [ordered]@{ CYS_PERF_SPIN = [string]$SpinMs; CYS_PROBE_DIR = $side }
if (-not $NoPerf) { $envSet['CYS_PERF'] = '1'; $envSet['CYS_PERF_CSV'] = (Join-Path $side 'frames.csv'); $envSet['CYS_PERF_INTERVAL'] = '5' }
foreach ($kv in ($Env -split ';')) { if ($kv.Trim()) { $p = $kv.Split('=', 2); $envSet[$p[0].Trim()] = $p[1] } }
$saved = @{}
foreach ($k in $envSet.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k, 'Process'); [Environment]::SetEnvironmentVariable($k, [string]$envSet[$k], 'Process') }
$stop = Join-Path $side 'stop.flag'
$sampler = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'sample_load.ps1'), '-Out', (Join-Path $side 'load.csv'), '-Seconds', ($Seconds + 960), '-StopFile', $stop)
. (Join-Path $PSScriptRoot 'game_slot.ps1')
$slot = $null
try {
    $slot = Enter-CysGameSlot 'perf-cy'   # shared Game.exe slot (coordinator 15/09)
    & (Join-Path $PSScriptRoot '..\game\run_world_replay.ps1') -Stage $Stage -Fixture $Fixture -OutDir $OutDir -Seconds $Seconds -WaitMinutes 15 -Move -Core -Camera
} finally {
    if ($slot) { Exit-CysGameSlot $slot }
    [IO.File]::WriteAllText($stop, 'stop')
    try { $sampler.WaitForExit(15000) | Out-Null } catch { }
    foreach ($k in $envSet.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
    ([ordered]@{ stage = $Stage; set = $Set; env = $envSet; probe = [bool]$Probe } | ConvertTo-Json -Depth 3) | Set-Content -Encoding UTF8 (Join-Path $side 'perf-run.json')
}
$py = 'C:\Program Files\Python313\python.exe'
if (Test-Path -LiteralPath (Join-Path $side 'frames.csv')) {
    & $py -B (Join-Path $PSScriptRoot 'hitch_report.py') (Join-Path $side 'frames.csv') --json (Join-Path $side 'hitch.json') 2>&1 | Out-File -Encoding utf8 (Join-Path $side 'hitch.txt')
}
foreach ($c in @(Get-ChildItem -LiteralPath $side -Filter 'probe_*.csv' -ErrorAction SilentlyContinue)) {
    & $py -B (Join-Path $PSScriptRoot 'probe_report.py') $c.FullName --steady 0 --json (Join-Path $side 'probe.json') 2>&1 | Out-File -Encoding utf8 (Join-Path $side 'probe.txt')
}
