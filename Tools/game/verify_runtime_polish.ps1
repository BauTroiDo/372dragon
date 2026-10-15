param([string]$Batch = 'final', [ValidateSet('none','ui')][string]$StartAfter='none')
$ErrorActionPreference = 'Stop'
$base = 'Build/Logs/2026-09-26-runtime-polish'
$stage = 'Build/world-gui/stage-runtime-polish-26'
if ($Batch -notmatch '^[a-z0-9-]+$') { throw 'Invalid evidence prefix' }
function Fixture([string]$mode) {
    & wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/runtime_polish_fixture.py $mode
    if ($LASTEXITCODE -ne 0) { throw ('Fixture failed: ' + $mode) }
}
function Run([string]$name,[int]$mode) {
    & "$PSScriptRoot/run_world_gui_live.ps1" -Stage $stage -OutDir "$base/$Batch-$name" -Account test15 -Seconds 330 -RuntimePolishProbe $mode
}
# Read kernel socket state without connecting to the login protocol.
$ready = $false
for ($i=0; $i -lt 180; $i++) {
    $listeners = @(& wsl -d TLBB -u root -- ss -Hltn '( sport = :15733 or sport = :15734 )')
    if ($listeners.Count -eq 2) { $ready=$true; break }
    Start-Sleep -Seconds 5
}
if (-not $ready) { throw 'Private login/game listeners not ready after 900 seconds' }
if ($StartAfter -eq 'none') {
    Fixture 'gift'
    Run 'gift' 3
    Run 'gift-relogin' 4
    Fixture 'reset'
    Run 'ui' 1
}
Fixture 'battle'
try {
    $env:CYS_ROUND2_LIVE='11'
    Run 'battle' 0
} finally { Remove-Item Env:CYS_ROUND2_LIVE -ErrorAction SilentlyContinue }
& wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/runtime_polish_fixture.py verify | Set-Content -Encoding utf8 "$base/$Batch-battle-persisted.txt"
$flightLog='/mnt/c/TLBB/085/CY-Source/'+$base+'/'+$Batch+'-flight-fixture'
$first=$true
foreach ($case in @(@('dragon',96),@('ground',1),@('kite',206))) {
    $operation=if($first){'seed'}else{'refresh'}
    & wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/mount_flight_fixture.py $operation --ride $case[1] --scene 12 --log $flightLog
    if ($LASTEXITCODE -ne 0) { throw 'Flight fixture failed' }
    $first=$false
    & "$PSScriptRoot/run_world_gui_live.ps1" -Stage $stage -OutDir "$base/$Batch-flight-$($case[0])" -Account test15 -Seconds 260 -MountFlightProbe
}
Fixture 'restore'
