<#
.SYNOPSIS
  CYS-PERF: offline Game.exe measurement on the private perf stage (Build\perf\stage). Never a server, never the
  user's stage.
.DESCRIPTION
  Drives the existing GL/CY UI smoke (-cys-gl-login-smoke, CYS_CREATE_ROLE_SMOKE=Preview: offline fixtures, no
  authentication, no socket) through login -> character selection -> character creation, and records:
  frames.csv (CYS_PERF_CSV, one row per frame), logsize.csv (log growth and process CPU each second), the three
  game logs, screenshots, run.json and report.json/.md (Tools\perf\perf_report.py).
  -Hold is passed as CYS_PERF_HOLD: the scripted smoke pauses that many seconds after each named procedure
  becomes active, so idle states can be sampled (CYS-PERF builds only).
  Any TCP connection of the game other than a listening socket stops the run.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_game_perf.ps1 -Tag A-1080 -Width 1920 -Height 1080
#>
param(
    [Parameter(Mandatory=$true)][string]$Tag,
    [string]$Stage = 'Build\perf\stage',
    [ValidateSet('Preview','None')][string]$CreateMode = 'Preview',
    [ValidateRange(20,600)][int]$Seconds = 150,
    [int]$Width = 1024,
    [int]$Height = 768,
    [string]$Hold = 'Login:15,CharSel:20',
    [ValidateSet('NoActivate','Hidden')][string]$Window = 'NoActivate',
    [switch]$NoPerf,
    [int]$Overlay = 0,
    [string[]]$Set = @(),
    [string[]]$Env = @(),
    [string]$OutRoot = 'Build\Logs\2026-09-13-perf\game'
)
$ErrorActionPreference = 'Stop'
if ($Hold -eq 'none') { $Hold = '' }   # powershell -File cannot pass an empty string
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
function Resolve-InRoot([string]$path) {
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $root $path }
    return [IO.Path]::GetFullPath($path).TrimEnd('\')
}
$Stage = Resolve-InRoot $Stage
$perfRoot = Join-Path $root 'Build\perf'
if (-not $Stage.StartsWith($perfRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Only stages under Build\perf are run by this script.' }
$bin = Join-Path $Stage 'Bin64'
$game = Join-Path $bin 'Game.exe'
if (-not (Test-Path -LiteralPath $game)) { throw ('No Game.exe in ' + $bin) }
$out = Join-Path (Resolve-InRoot $OutRoot) $Tag
if (Test-Path -LiteralPath $out) { throw ('Output exists, choose a new tag: ' + $out) }

$others = @()
foreach ($p in @(Get-Process -Name Game,TlbbViewer,OgreSmoke,CysUiViewer,CysPostFxTest,CysShadowTest -ErrorAction SilentlyContinue)) {
    $path = $null
    try { $path = $p.Path } catch { }
    if ($path -and $path.StartsWith($bin, [StringComparison]::OrdinalIgnoreCase)) { throw ('A tool of this stage is running: pid ' + $p.Id) }
    $others += [ordered]@{ pid = $p.Id; name = $p.ProcessName; path = $path }
}
if ($others.Count) { Write-Warning ('Other GPU tools are running (results may be affected): ' + (($others | ForEach-Object { $_.name + ':' + $_.pid }) -join ', ')) }
[void][IO.Directory]::CreateDirectory($out)
$tmp = Join-Path $out 'tmp'
[void][IO.Directory]::CreateDirectory($tmp)

# WXSystem.cfg: the user's settings (template) + offline endpoint + requested size + -Set overrides.
$template = Join-Path $Stage 'WXSystem.template.cfg'
if (-not (Test-Path -LiteralPath $template)) { throw 'Run stage_perf.ps1 first (no WXSystem.template.cfg).' }
$settings = [ordered]@{ GameServer_Address = '127.0.0.1'; GameServer_Port = '14400'; GameServer_ConnectDirect = '0';
                        View_Resoution = ('{0},{1}' -f $Width, $Height); View_FullScreen = '0' }
foreach ($kv in $Set) {
    $pair = $kv.Split('=', 2)
    if ($pair.Count -ne 2) { throw ('Bad -Set value: ' + $kv) }
    $settings[$pair[0].Trim()] = $pair[1].Trim()
}
$done = @{}
$lines = New-Object System.Collections.Generic.List[string]
foreach ($line in [IO.File]::ReadAllLines($template)) {
    if ($line -match '^\s*([A-Za-z0-9_]+)\s*=' -and $settings.Contains($Matches[1])) {
        $key = $Matches[1]
        $lines.Add($key + '=' + $settings[$key])
        $done[$key] = $true
    } else {
        $lines.Add($line)
    }
}
foreach ($key in $settings.Keys) { if (-not $done.ContainsKey($key)) { $lines.Add($key + '=' + $settings[$key]) } }
[IO.File]::WriteAllLines((Join-Path $bin 'WXSystem.cfg'), $lines.ToArray())
Copy-Item -LiteralPath (Join-Path $bin 'WXSystem.cfg') -Destination (Join-Path $out 'WXSystem.cfg')

# Logs of the previous run go with this run's evidence (WXClient.log is opened in append mode by the game).
$prior = Join-Path $out 'prior-logs'
foreach ($name in @('WXClient.log','WXRender.log','UISystem.log')) {
    $f = Join-Path $bin $name
    if (Test-Path -LiteralPath $f) {
        [void][IO.Directory]::CreateDirectory($prior)
        Move-Item -LiteralPath $f -Destination (Join-Path $prior $name)
    }
}
$shotsDir = Join-Path $Stage 'ScreenShots'
[void][IO.Directory]::CreateDirectory($shotsDir)
$shotsBefore = @(Get-ChildItem -LiteralPath $shotsDir -File -ErrorAction SilentlyContinue | ForEach-Object Name)

if (-not ('CysPerfLaunch' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class CysPerfLaunch {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow, cbReserved2; public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess, hThread; public int dwProcessId, dwThreadId; }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool CreateProcessW(string app, StringBuilder cmd, IntPtr pa, IntPtr ta, bool inherit, uint flags,
                                      IntPtr env, string cwd, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    // show: 4 = SW_SHOWNOACTIVATE (visible, keeps the user's focus), 0 = SW_HIDE
    public static int Start(string exe, string args, string cwd, short show) {
        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
        si.dwFlags = 1; // STARTF_USESHOWWINDOW
        si.wShowWindow = show;
        PROCESS_INFORMATION pi;
        StringBuilder cmd = new StringBuilder("\"" + exe + "\" " + args);
        if (!CreateProcessW(exe, cmd, IntPtr.Zero, IntPtr.Zero, false, 0, IntPtr.Zero, cwd, ref si, out pi))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return pi.dwProcessId;
    }
}
'@
}

# Child environment (inherited from this PowerShell process, restored afterwards). Never a credential.
$envSet = [ordered]@{ CYS_GL_LOGIN_SMOKE = '1'; TEMP = $tmp; TMP = $tmp }
if ($CreateMode -ne 'None') { $envSet['CYS_CREATE_ROLE_SMOKE'] = $CreateMode }
if ($Hold) { $envSet['CYS_PERF_HOLD'] = $Hold }
if (-not $NoPerf) {
    $envSet['CYS_PERF'] = '1'
    $envSet['CYS_PERF_CSV'] = (Join-Path $out 'frames.csv')
    if ($Overlay) { $envSet['CYS_PERF_OVERLAY'] = [string]$Overlay }
}
foreach ($kv in $Env) {
    $pair = $kv.Split('=', 2)
    if ($pair.Count -ne 2 -or -not $pair[0].StartsWith('CYS_')) { throw ('Bad -Env value (CYS_* only): ' + $kv) }
    $envSet[$pair[0]] = $pair[1]
}
$cleared = @('CYS_WSL_LOGIN_TEST','CYS_BOT_PWD','CYS_CREATE_ROLE_SMOKE','CYS_GL_LOGIN_SMOKE','CYS_PERF','CYS_PERF_CSV',
             'CYS_PERF_HOLD','CYS_PERF_OVERLAY','CYS_PERF_GPU','CYS_PERF_ALLOC','CYS_PERF_INTERVAL','CYS_PERF_LISTENERS',
             'CYS_PERF_PACER','CYS_PERF_SCENE_BUILD_MS')
$saved = @{}
foreach ($k in ($cleared + @($envSet.Keys))) { $saved[$k] = [Environment]::GetEnvironmentVariable($k, 'Process') }

$started = Get-Date
$gamePid = $null
$terminated = $false
$violation = $null
$launchError = $null
$sockets = New-Object System.Collections.Generic.List[object]
$samples = New-Object System.Collections.Generic.List[string]
$samples.Add('t_s,wxrender_bytes,uisystem_bytes,wxclient_bytes,cpu_s,working_set_mb,compilers,gpu_tools')
try {
    foreach ($k in $cleared) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
    foreach ($k in $envSet.Keys) { [Environment]::SetEnvironmentVariable($k, [string]$envSet[$k], 'Process') }
    $show = if ($Window -eq 'Hidden') { [int16]0 } else { [int16]4 }
    $gamePid = [CysPerfLaunch]::Start($game, '-fl -cys-gl-login-smoke', $bin, $show)
    $clock = [Diagnostics.Stopwatch]::StartNew()
    while ($clock.Elapsed.TotalSeconds -lt $Seconds) {
        Start-Sleep -Milliseconds 1000
        $proc = Get-Process -Id $gamePid -ErrorAction SilentlyContinue
        if (-not $proc) { break }
        $sizes = foreach ($name in @('WXRender.log','UISystem.log','WXClient.log')) {
            $f = Join-Path $bin $name
            if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
        }
        # Contention proxy on this shared machine: compilers/linkers of any agent and other GPU tools.
        $compilers = @(Get-Process -Name cl,link,ninja,lld-link -ErrorAction SilentlyContinue).Count
        $gpuTools = @(Get-Process -Name TlbbViewer,OgreSmoke,CysUiViewer,CysPostFxTest,CysShadowTest -ErrorAction SilentlyContinue).Count +
                    @(Get-Process -Name Game -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $gamePid }).Count
        $samples.Add(('{0:F1},{1},{2},{3},{4:F2},{5:F0},{6},{7}' -f $clock.Elapsed.TotalSeconds, $sizes[0], $sizes[1], $sizes[2],
                      $proc.TotalProcessorTime.TotalSeconds, ($proc.WorkingSet64 / 1MB), $compilers, $gpuTools))
        foreach ($c in @(Get-NetTCPConnection -OwningProcess $gamePid -ErrorAction SilentlyContinue)) {
            $sockets.Add([ordered]@{ t = [math]::Round($clock.Elapsed.TotalSeconds, 1); local = ('{0}:{1}' -f $c.LocalAddress, $c.LocalPort);
                                     remote = ('{0}:{1}' -f $c.RemoteAddress, $c.RemotePort); state = [string]$c.State })
            if ($c.RemoteAddress -notin @('0.0.0.0', '::')) { $violation = ('unexpected connection to {0}:{1}' -f $c.RemoteAddress, $c.RemotePort) }
        }
        if ($violation) { break }
    }
} catch {
    $launchError = $_.Exception.Message
} finally {
    foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
    if ($gamePid) {
        $proc = Get-Process -Id $gamePid -ErrorAction SilentlyContinue
        if ($proc) { Stop-Process -Id $gamePid -Force; $terminated = $true; Start-Sleep -Milliseconds 1500 }
    }
}

foreach ($name in @('WXClient.log','WXRender.log','UISystem.log')) {
    $f = Join-Path $bin $name
    if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination $out }
}
$shots = @(Get-ChildItem -LiteralPath $shotsDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $shotsBefore })
foreach ($s in $shots) { Move-Item -LiteralPath $s.FullName -Destination $out }
[IO.File]::WriteAllLines((Join-Path $out 'logsize.csv'), $samples.ToArray())
$variant = $null
$stageManifest = Join-Path $bin 'perf_stage.json'
if (Test-Path -LiteralPath $stageManifest) { $variant = (Get-Content -Raw -LiteralPath $stageManifest | ConvertFrom-Json).variant }
$run = [ordered]@{
    tag = $Tag; variant = $variant; stage = $Stage; started = $started.ToString('o'); finished = (Get-Date).ToString('o');
    seconds = $Seconds; width = $Width; height = $Height; create_mode = $CreateMode; hold = $Hold; window = $Window;
    perf = (-not $NoPerf); overlay = $Overlay; cfg_overrides = $Set; env_overrides = $Env; pid = $gamePid;
    terminated_after_timeout = $terminated; violation = $violation; launch_error = $launchError;
    other_gpu_tools = $others; sockets = $sockets.ToArray(); screenshots = @($shots | ForEach-Object Name)
}
[IO.File]::WriteAllText((Join-Path $out 'run.json'), ($run | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))

$csv = Join-Path $out 'frames.csv'
if (Test-Path -LiteralPath $csv) {
    $env:PYTHONUTF8 = '1'
    & 'C:\Program Files\Python313\python.exe' -B (Join-Path $PSScriptRoot 'perf_report.py') $csv --settle 2 --title $Tag `
        --json (Join-Path $out 'report.json') --md (Join-Path $out 'report.md') | Out-Null
}
$avg = Select-String -LiteralPath (Join-Path $out 'WXRender.log') -Pattern 'Average FPS' -ErrorAction SilentlyContinue | Select-Object -Last 1
Write-Host ('run ' + $Tag + ': pid ' + $gamePid + ', terminated=' + $terminated + ', violation=' + $violation + ', error=' + $launchError)
if ($avg) { Write-Host $avg.Line }
if ($violation -or $launchError) { exit 1 }
exit 0
