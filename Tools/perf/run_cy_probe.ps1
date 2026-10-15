# CY-Source Tools/perf/run_cy_probe.ps1 - frame times of the CY 3.71 client copy with the present probe (perf-cy, 15/09).
# Puts the probe d3d9.dll into Bin64 of a PRIVATE copy under Build\re\perf-cy (never the color-calib copy, never the
# original), samples the machine load, then runs Tools\render\run_cy_capture.ps1 (0 game-server connections, one Game.exe
# on the machine, <= 150 s). Output: OutDir\probe_<pid>.csv|txt, load.csv, the capture files.
# -View "System_MaxFPS_Front=60;View_Aplomb=0" overrides System.cfg keys of the copy. ASCII only.
param(
    [string]$CYRoot = 'C:\TLBB\085\CY-Source\Build\re\perf-cy\CYGame',
    [Parameter(Mandatory=$true)][string]$OutDir,
    [ValidateRange(20,150)][int]$Seconds = 90,
    [string]$Resolution = '1280,720',
    [string]$View = '',
    [string]$Plan = '',
    [string]$Probe = 'C:\TLBB\085\CY-Source\Build\re\perf-cy\probe\d3d9.dll'
)
$ErrorActionPreference = 'Stop'
$CYRoot = [IO.Path]::GetFullPath($CYRoot).TrimEnd('\')
if ($CYRoot -notlike 'C:\TLBB\085\CY-Source\Build\re\perf-cy\*') { throw 'CYRoot must be the private copy under Build\re\perf-cy.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir.' }
Copy-Item -LiteralPath $Probe -Destination (Join-Path $CYRoot 'Bin64\d3d9.dll') -Force
$probeDir = $OutDir.TrimEnd('\') + '.probe'
[void][IO.Directory]::CreateDirectory($probeDir)
$env:CYS_PROBE_DIR = $probeDir
$stop = Join-Path $probeDir 'stop.flag'
$loadCsv = Join-Path $probeDir 'load.csv'
$sampler = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'sample_load.ps1'), '-Out', $loadCsv, '-Seconds', ($Seconds + 60), '-StopFile', $stop)
# The capture script writes its overrides into System.cfg of the copy and they persist: start every run from the CY
# defaults of Tools\DATA NEW\CY Game\Bin\System.cfg (45/25 fps, VSync on), then apply -View.
$viewHash = @{ 'System_MaxFPS_Front' = '45'; 'System_MaxFPS_Back' = '25'; 'View_Aplomb' = '1' }
foreach ($kv in ($View -split ';')) { if ($kv -match '^\s*([^=]+?)\s*=\s*(.*)$') { $viewHash[$Matches[1]] = $Matches[2] } }
. (Join-Path $PSScriptRoot 'game_slot.ps1')
$slot = $null
try {
    $slot = Enter-CysGameSlot 'perf-cy'   # shared Game.exe slot (coordinator 15/09)
    & (Join-Path $PSScriptRoot '..\render\run_cy_capture.ps1') -CYRoot $CYRoot -OutDir $OutDir -Seconds $Seconds -Resolution $Resolution -Plan $Plan -View $viewHash
} finally {
    if ($slot) { Exit-CysGameSlot $slot }
    [IO.File]::WriteAllText($stop, 'stop')
    try { $sampler.WaitForExit(15000) | Out-Null } catch { }
    Remove-Item Env:\CYS_PROBE_DIR -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $OutDir) {
        foreach ($f in Get-ChildItem -LiteralPath $probeDir -File) { if ($f.Name -ne 'stop.flag') { Move-Item -LiteralPath $f.FullName -Destination $OutDir -Force } }
    }
}
