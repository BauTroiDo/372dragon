# CY-Source Tools/render/run_viewer_shots.ps1 - TlbbViewer scene shots, one process per case, synchronous
# (CYS-COLOR, color-calib 15/09). Cases file: one case per line "name<TAB>env (K=V;K=V or -)<TAB>viewer arguments".
# Every case gets --data <Data> --shader-cache <Cache> --shot <Out>\<name>.png and CWD = the viewer folder
# (TerrainTypeInfo.cfg must be there). Existing shots are kept unless -Force. ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$Viewer,
    [Parameter(Mandatory=$true)][string]$Cases,
    [Parameter(Mandatory=$true)][string]$Out,
    [string]$Data = 'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data',
    [string]$Cache = 'C:\TLBB\085\CY-Source\Build\diagnostics\color-calib\ShaderCache',
    [string]$Only = '',
    [int]$TimeoutSec = 300,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
[void][IO.Directory]::CreateDirectory($Out); [void][IO.Directory]::CreateDirectory($Cache)
$dir = Split-Path -Parent $Viewer
foreach ($line in [IO.File]::ReadAllLines($Cases)) {
    if (-not $line.Trim() -or $line.StartsWith('#')) { continue }
    $f = $line.Split("`t")
    $name = $f[0].Trim(); $envs = $f[1].Trim(); $args0 = $f[2].Trim()
    if ($Only -and $name -notmatch $Only) { continue }
    $shot = Join-Path $Out ($name + '.png')
    if ((Test-Path $shot) -and -not $Force) { Write-Host ('skip ' + $name); continue }
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $Viewer; $info.WorkingDirectory = $dir; $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $info.Arguments = ('--data "' + $Data + '" ' + $args0 + ' --shader-cache "' + $Cache + '" --shot "' + $shot + '"')
    foreach ($k in @('CYS_SHADOW_LUT', 'CYS_COLORLUT', 'CYS_COLOR', 'CYS_SHADOW_PROMOTE')) { $info.EnvironmentVariables.Remove($k) }
    if ($envs -and $envs -ne '-') { foreach ($kv in $envs.Split(';')) { $p = $kv.Split('=', 2); $info.EnvironmentVariables[$p[0]] = $p[1] } }
    $t = Get-Date
    $proc = [Diagnostics.Process]::Start($info)
    $so = $proc.StandardOutput.ReadToEndAsync(); $se = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) { $proc.Kill(); $proc.WaitForExit(); Write-Host ('TIMEOUT ' + $name) }
    [IO.File]::WriteAllText((Join-Path $Out ($name + '.stdout.txt')), ('args: ' + $info.Arguments + "`r`nenv: " + $envs + "`r`n" + $so.Result + "`r`n--- stderr`r`n" + $se.Result))
    Write-Host ('{0} rc={1} {2:n0}s shot={3}' -f $name, $proc.ExitCode, ((Get-Date) - $t).TotalSeconds, (Test-Path $shot))
}
