# CYS-FXBASE (fx-cy-baseline 19/09): CY-Source side of one batch = offline world replay of stage Build\world-gui\stage-fxbase
# with CYS_WORLD_SCENARIO (same packets as the CY oracle sent), CYS_SFX_SHOT_MS dense captures after every tag,
# CYS_SFX_CAM = the camera read back from the CY run of the same batch (zoom from orbit distance, yaw), post-fx knobs
# pinned to what CY 3.71 actually runs (no FXAA, OGRE default texture filtering).
# usage: fxbase_replay_run.ps1 -Batch b00-calib [-Rep 1] [-CamZoom 0.4 -CamDir -24.0] [-Seconds 130] [-Env 'K=V;K=V']
# ASCII only (Windows PowerShell 5.1).
param([Parameter(Mandatory=$true)][string]$Batch, [int]$Rep = 1, [double]$CamZoom = -1, [double]$CamDir = -999,
      [string]$Table = 'C:\TLBB\085\CY-Source\Build\re\fx-cy-baseline\tables\ours\ImpactSEData_V1.txt',
      [int]$Seconds = 175, [string]$Env = '', [string]$Stage = 'C:\TLBB\085\CY-Source\Build\world-gui\stage-fxbase-3')
$ErrorActionPreference = 'Stop'
$R = 'C:\TLBB\085\CY-Source'
$logs = "$R\Build\Logs\2026-09-19-fx-cy-baseline"
$fixture = "$R\Build\Logs\2026-09-14-world-replay\world_session_1.bin"
$scenario = "$logs\batches\$Batch.replay.txt"
$meta = Get-Content -Raw -Encoding UTF8 "$logs\batches\$Batch.batch.json" | ConvertFrom-Json
$outDir = "$logs\ours\$Batch-r$Rep"
if (Test-Path -LiteralPath $outDir) { throw "choose a new -Rep: $outDir exists" }
if (-not (Test-Path -LiteralPath $scenario)) { throw "no scenario $scenario" }
# camera: from the CY run of this batch unless given
if ($CamZoom -lt 0 -or $CamDir -lt -998) {
    # the CY run of the SAME rep (its yaw is this run's yaw; every CY run drags a different yaw): never another rep
    $camFile = "$logs\cy\$Batch-r$Rep\cam-c0.json"
    if (-not (Test-Path -LiteralPath $camFile)) { throw "no CY camera read-back for this batch and rep ($camFile); run the CY side first or pass -CamZoom/-CamDir" }
    $cands = @((Get-Content -Raw -Encoding UTF8 $camFile | ConvertFrom-Json).candidates)   # sorted by ray miss: [0] = best
    if ($cands.Count -lt 1) { throw "no camera candidate in $camFile" }
    $cam = $cands[0]
    if ([double]$cam.ray_miss_xz -gt 150) { throw ("camera candidate misses the player by " + $cam.ray_miss_xz + " render units") }
    # CCamera_Scene distance in game metres = render units / 100, MIN/MAX_DISTANCE 6 / 27.5 (CysWorldReplay.cpp wlp)
    $orbit = [double]$cam.orbit_distance
    if (-not $orbit) { $e = $cam.eye; $t = $cam.orbit_target; $orbit = [math]::Sqrt(($e[0]-$t[0])*($e[0]-$t[0]) + ($e[1]-$t[1])*($e[1]-$t[1]) + ($e[2]-$t[2])*($e[2]-$t[2])) }
    $CamZoom = ($orbit / 100.0 - 6.0) / (27.5 - 6.0)
    if ($CamZoom -lt 0) { $CamZoom = 0 }; if ($CamZoom -gt 1) { $CamZoom = 1 }
    $CamDir = [double]$cam.yaw_deg
    Write-Host ("camera from $camFile : orbit $orbit -> zoom {0:n3}, yaw {1:n2}" -f $CamZoom, $CamDir)
}
# the override table of this run (continuous = tables\ours, one-shot = tables-enable\ours); sha256 in the manifest
if (-not (Test-Path -LiteralPath $Table)) { throw "table not found: $Table" }
Copy-Item -LiteralPath $Table -Destination "$Stage\Overlay\Post\ConfigFolder\ImpactSEData_V1.txt" -Force
$vars = @{ 'CYS_WORLD_SCENARIO' = $scenario; 'CYS_SFX_LOG' = '1'; 'CYS_SFX_SHOT_MS' = [string]$meta.our_shot_env }
# invariant culture: "0.400,-24.00" (sscanf in CysWorldReplay.cpp)
$vars['CYS_SFX_CAM'] = [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:0.000},{1:0.00}', $CamZoom, $CamDir)
# post-fx parity with CY 3.71 as installed (Src/Engine/WXCore/CYS/PostFX/CysPostFx.cpp: CYS_AA / CYS_TEXFILTER win over cfg;
# the shipped defaults PostFX.AAMode=fxaa and View_TextureFiltering=2 deviate from CY's run-time state on purpose)
$vars['CYS_AA'] = 'cy'            # View_Fanhunjiao decides (0 in both cfgs) -> no FXAA, like CY in the world
$vars['CYS_TEXFILTER'] = 'ogre'   # CY never applies View_TextureFiltering at start-up (aa-cy spec): OGRE default
# camera look-at height: CY orbits (50,1350,-450); this engine's default add height 0.7 m gives (50,1270,-450) and 1.8 m
# gave (50,1380,-450) (b00-calib-r2 / b00b-calib-r1) -> the character origin is at y 1200, CY's add height is 1.5 m
# (CysWorldReplay.cpp CYS_SFX_CAM_ADDH, // CYS-FXBASE)
$vars['CYS_SFX_CAM_ADDH'] = '1.5'
foreach ($kv in ($Env -split ';')) { if ($kv.Trim()) { $p = $kv.Split('=', 2); $vars[$p[0]] = $p[1] } }
$lock = "$R\Build\game-slot.lock"; $waited = 0
while ($true) {
    $busy = @(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -gt 0
    if (-not $busy -and (Test-Path -LiteralPath $lock)) {
        $own = (Get-Content -LiteralPath $lock -ErrorAction SilentlyContinue) -match '^fx-cy-baseline'
        $busy = -not $own -and ((Get-Date) - (Get-Item -LiteralPath $lock).LastWriteTime).TotalMinutes -lt 5
    }
    if (-not $busy) { break }
    if ($waited -ge 1500) { throw 'Game.exe slot stayed busy for 25 minutes' }
    Start-Sleep -Seconds 2; $waited += 2
}
[IO.File]::WriteAllText($lock, 'fx-cy-baseline ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + " $Batch-r$Rep")
Write-Host "slot after $waited s; env: " + (($vars.Keys | Sort-Object | ForEach-Object { $_ + '=' + $vars[$_] }) -join ' ')
try {
    foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
    # run_world_replay.ps1 reports its own checks as "FAILED" on stderr (deadline / quit checks that this scenario does not
    # satisfy by design); that must not abort this script before the manifest is written
    $ErrorActionPreference = 'Continue'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$R\Tools\game\run_world_replay.ps1" -Stage $Stage -Fixture $fixture -OutDir $outDir -Seconds $Seconds -WaitMinutes 2 2>&1 | Out-String -Stream | Select-Object -Last 4
    $ErrorActionPreference = 'Stop'
} finally {
    foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
    if ((Test-Path -LiteralPath $lock) -and ((Get-Content -LiteralPath $lock) -match '^fx-cy-baseline')) { [IO.File]::Delete($lock) }
}
$env_used = [ordered]@{}; foreach ($k in ($vars.Keys | Sort-Object)) { $env_used[$k] = $vars[$k] }
$m = [ordered]@{ batch = $Batch; rep = $Rep; stage = $Stage; env = $env_used; camera_from = "$logs\cy\$Batch-r$Rep\cam-c0.json"; cam_zoom = $CamZoom; cam_dir_deg = $CamDir
                 game_sha256 = (Get-FileHash "$Stage\Bin64\Game.exe").Hash.ToLower(); render_sha256 = (Get-FileHash "$Stage\Bin64\Render.dll").Hash.ToLower()
                 override_table_sha256 = (Get-FileHash "$Stage\Overlay\Post\ConfigFolder\ImpactSEData_V1.txt").Hash.ToLower()
                 scenario_sha256 = (Get-FileHash $scenario).Hash.ToLower(); shots = @() }
foreach ($f in Get-ChildItem -LiteralPath $outDir -Filter 'cys-replay-*.png' -ErrorAction SilentlyContinue | Sort-Object Name) {
    $m.shots += [ordered]@{ name = $f.Name; sha256 = (Get-FileHash $f.FullName).Hash.ToLower(); bytes = $f.Length }
}
$m | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $outDir 'manifest.json')
Select-String -LiteralPath "$outDir\WXClient.log" -Pattern 'CYS scenario|replay scenario: tag|terminal=|CYS-AA|CYS-PARITY|AAMode|TexFilter' -ErrorAction SilentlyContinue | Select-Object -First 12 | ForEach-Object { $_.Line }
Write-Host ("shots: " + $m.shots.Count)
