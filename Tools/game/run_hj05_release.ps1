# Exact-build GUI verification. Stop immediately on failure; a crashed actor
# must be cleared through the private server before touching its saved record.
param([ValidatePattern('^[a-z0-9-]+$')][string]$Prefix='release')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $root
$stage = 'Build/world-gui/stage-hj05-28'
$log = 'Build/Logs/2026-09-28-hj05-fixes'
function Fixture([string]$script,[string]$mode) {
    & wsl -d TLBB -u root -- python3 ('/mnt/c/TLBB/085/CY-Source/Tools/server/'+$script+'.py') $mode
    if ($LASTEXITCODE -ne 0) { throw ('Fixture failed: '+$script+' '+$mode) }
}
function Probe([int]$mode,[string]$folder) {
    $boundary = "$log/$folder-server-start.json"
    & 'C:/Program Files/Python313/python.exe' -X utf8 "$PSScriptRoot/hj05_server_watch.py" start $boundary
    if ($LASTEXITCODE -ne 0) { throw 'Server log boundary failed' }
    & "$PSScriptRoot/run_world_gui_live.ps1" -Stage $stage -OutDir "$log/$folder" -Seconds 220 -Account test15 -PowerSystemsProbe $mode
    & 'C:/Program Files/Python313/python.exe' -X utf8 "$PSScriptRoot/hj05_server_watch.py" check $boundary --out "$log/$folder/server-check.json"
    if ($LASTEXITCODE -ne 0) { throw 'GUI interval has a server error' }
}
& 'C:/Program Files/Python313/python.exe' -X utf8 "$PSScriptRoot/stage_hj05.py"
if ($LASTEXITCODE -ne 0) { throw 'Stage failed' }
Fixture hj05_fixture restore
Fixture hj05_bank_fixture seed
Probe 5 "$Prefix-bank"
Fixture hj05_bank_fixture inspect
Copy-Item -LiteralPath "$log/bank-after.json" -Destination "$log/bank-after-transfer.json"
Probe 6 "$Prefix-bank-relogin"
Fixture hj05_bank_fixture inspect
Copy-Item -LiteralPath "$log/bank-after.json" -Destination "$log/bank-after-relogin.json"
Fixture hj05_fixture restore
Fixture hj05_fixture seed
Probe 3 "$Prefix-soul"
Fixture hj05_fixture inspect
Copy-Item -LiteralPath "$log/fixture-after.json" -Destination "$log/soul-after-action.json"
Probe 4 "$Prefix-soul-relogin"
Fixture hj05_fixture inspect
Copy-Item -LiteralPath "$log/fixture-after.json" -Destination "$log/soul-after-relogin.json"
Fixture hj05_fixture restore
Fixture hj05_fixture verify
Write-Host 'PASS all four exact-build GUI runs; full test15 BSON restored'
