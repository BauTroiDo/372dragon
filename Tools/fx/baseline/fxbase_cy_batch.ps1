# CYS-FXBASE (fx-cy-baseline 19/09): one CY 3.71 batch through the oracle on the PRIVATE copy
# Build\re\fx-cy-baseline\CYGame (hard links of the cy-oracle copy + own Bin cfg + FxBase override table).
# Login plan (1280x720, proven by cy-oracle run-13..27), then the classic camera (6 wheel ticks in, one right drag),
# then the batch tail (wait for every timeline tag in oracle.log, shots at fixed offsets, camera read-back).
# usage: fxbase_cy_batch.ps1 -Batch b00-calib [-Rep 1]   (files from Tools/fx/baseline/fxbase_scenario.py)
# ASCII only (Windows PowerShell 5.1).
param([Parameter(Mandatory=$true)][string]$Batch, [int]$Rep = 1, [string]$Camera = 'mrdrag:560,360,660,360',
      [string]$Table = 'C:\TLBB\085\CY-Source\Build\re\fx-cy-baseline\tables\cy\ImpactSEData_V1.txt')
$ErrorActionPreference = 'Stop'
$R = 'C:\TLBB\085\CY-Source'
$logs = "$R\Build\Logs\2026-09-19-fx-cy-baseline"
$cy = "$R\Build\re\fx-cy-baseline\CYGame"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sc = "$logs\batches\$Batch.cy.json"
$tail = (Get-Content -LiteralPath "$logs\batches\$Batch.tail.txt" -Raw).Trim()
if (-not (Test-Path -LiteralPath $sc)) { throw "no scenario $sc" }
$outDir = "$logs\cy\$Batch-r$Rep"
if (Test-Path -LiteralPath $outDir) { throw "choose a new -Rep: $outDir exists" }
if (Test-Path -LiteralPath "$cy\Bin64\d3d9.dll") { throw 'stale d3d9 proxy in the CY copy' }
# the override table of this run (continuous = tables\cy, one-shot = tables-enable\cy); its sha256 goes into the manifest
if (-not (Test-Path -LiteralPath $Table)) { throw "table not found: $Table" }
Copy-Item -LiteralPath $Table -Destination "$cy\FxBase\ImpactSEData_V1.txt" -Force
$login = '50:key:27;54:key:27;58:key:27;62:front;63:mclick:990,653;66:front;67:mclick:575,278;68:char:oracle;69:key:9;70:char:x1;71:key:13;72:wait:char list sent;+5:front;+6:mclick:1166,458;+9:key:13;+10:wait:IN WORLD'
$cam = '+2:front;+4:mwheel:640,360,120,6;+6:front;+7:' + $Camera
$plan = $login + ';' + $cam + ';' + $tail
Write-Host ("batch $Batch rep $Rep -> $outDir")
& "$here\fxbase_cy_run.ps1" -CYRoot $cy -OutDir $outDir -Seconds 150 -Scenario $sc -View @{ 'View_Resoution' = '1280,720' } -Plan $plan -WaitMinutes 15
# manifest: sha256 of every PNG + the binaries + the override table (determinism evidence)
$m = [ordered]@{ batch = $Batch; rep = $Rep; game_sha256 = (Get-FileHash "$cy\Bin64\Game.exe").Hash.ToLower()
                 render_sha256 = (Get-FileHash "$cy\Bin64\Render.dll").Hash.ToLower()
                 override_table_sha256 = (Get-FileHash "$cy\FxBase\ImpactSEData_V1.txt").Hash.ToLower()
                 fairy_resources_sha256 = (Get-FileHash "$cy\Bin\FairyResources.cfg").Hash.ToLower()
                 scenario_sha256 = (Get-FileHash $sc).Hash.ToLower(); shots = @() }
foreach ($f in Get-ChildItem -LiteralPath $outDir -Filter '*.png' | Sort-Object Name) {
    $m.shots += [ordered]@{ name = $f.Name; sha256 = (Get-FileHash $f.FullName).Hash.ToLower(); bytes = $f.Length }
}
$m | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $outDir 'manifest.json')
Write-Host ("shots: " + $m.shots.Count)
