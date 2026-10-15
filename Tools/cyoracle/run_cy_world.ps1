# CY-Source Tools/cyoracle/run_cy_world.ps1 - one reproducible CY 3.71 world capture through the oracle (cy-oracle 15/09).
# Login (server preselected by make_loginserver.py), account "oracle" (fake, no password check), character select,
# enter the scenario scene, then the fixed shot list relative to "IN WORLD". <= 150 s, shared Build\game-slot.lock.
#   run_cy_world.ps1 -OutDir Build\Logs\...\run-N [-Scenario dali|wuliang] [-Resolution 1280,720] [-Shots "+4:shot:a;+8:shot:b"]
# Other agents (d3d9-trace, perf-cy) can append their own steps with -Extra (same syntax as run_cy_oracle.ps1 -Plan).
# ASCII only.
param(
    [Parameter(Mandatory=$true)][string]$OutDir,
    [string]$Scenario = 'dali',
    [string]$Resolution = '1280,720',
    [string]$Shots = '',
    [string]$Extra = ''
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$cy = [IO.Path]::GetFullPath((Join-Path $here '..\..\..\re\cy-oracle\CYGame'))
if (-not (Test-Path $cy)) { $cy = 'C:\TLBB\085\CY-Source\Build\re\cy-oracle\CYGame' }
$sc = Join-Path $here ('scenarios\' + $Scenario + '.json')
if (-not $Shots) {
    # timeline of scenarios\dali.json: skill at +10, teleport water +20, teleport south +32 (seconds after GCEnterScene)
    $Shots = '+5:shot:w05-start;+9:shot:w09-idle;+11:shot:w11-skill;+13:shot:w13-skill;+23:shot:w23-tp1;+28:shot:w28-tp1;+35:shot:w35-tp2;+42:shot:w42-tp2'
}
# 1280x720 login: 990,653 = confirm server; 575,278 = account box; 1166,458 = "enter game" on character select
$login = '50:key:27;54:key:27;58:key:27;62:front;63:mclick:990,653;66:front;67:mclick:575,278;68:char:oracle;69:key:9;70:char:x1;71:key:13;72:wait:char list sent;+5:front;+6:mclick:1166,458;+9:key:13;+10:wait:IN WORLD'
$plan = $login + ';' + $Shots
if ($Extra) { $plan = $plan + ';' + $Extra }
& (Join-Path $here 'run_cy_oracle.ps1') -CYRoot $cy -OutDir $OutDir -Seconds 150 -Scenario $sc -View @{ 'View_Resoution' = $Resolution } -Plan $plan
