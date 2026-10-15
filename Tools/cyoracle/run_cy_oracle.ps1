# CY-Source Tools/cyoracle/run_cy_oracle.ps1 - run a PRIVATE COPY of CY 3.71 Game.exe against cy_oracle_server.py
# (cy-oracle 15/09). Derived from Tools/render/run_cy_capture.ps1 (same capture helpers, one Game.exe on the machine).
# - Starts the oracle (127.0.0.1 only) and Bin64\Game.exe -fl of the copy, both owned by this script, stops both at the end.
# - Every TCP connection of Game.exe is sampled: anything that is not 127.0.0.1:<login|game port> kills the run at once
#   (web 80/443 included: the copy must make 0 outside connections).
# - -Plan "t:action[:arg];..."  t in seconds from start; actions:
#     shot:<name> | key:<vk> | click:<x>,<y> | char:<ascii text> | front | dblclick:<x>,<y>
#     wait:<regex>   (blocks later steps until oracle.log matches; t is the earliest time); a step time '+s' is
#                    relative to the last matched wait
#     cam:<tag>      (read-only memory scan for the Ogre frustum, 16:9 aspect, to cam-<tag>.txt)
#     rclick:<x>,<y> | drag:<x1>,<y1>,<x2>,<y2> (posted right drag) | wheel:<x>,<y>,<delta>
#     mwheel:<x>,<y>,<delta>[,<times>] | camread:<tag>[,<x>,<z>] (read-only camera readback to cam-<tag>.json)
#     mclick:<x>,<y> | mdbl:<x>,<y> | mrdrag:<x1>,<y1>,<x2>,<y2>  REAL mouse (SendInput; CY polls GetCursorPos/GetAsyncKeyState),
#     the game window is kept topmost without activation and the cursor is put back after each action
# - Every -Every seconds a periodic shot t<sec>.png.
# ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$CYRoot,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [ValidateRange(20,150)][int]$Seconds = 150,
    [string]$Plan = '',
    [int]$Every = 0,
    [string]$Scenario = '',
    [int]$LoginPort = 15790,
    [int]$GamePort = 15791,
    [ValidateRange(0,15)][int]$WaitMinutes = 15,
    [hashtable]$View = @{}
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
. (Join-Path $here '..\render\WinCapture.ps1')
if (-not ('CysOracleWin' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class CysOracleWin {
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    public static void Chars(IntPtr h, string s) {
        foreach (char ch in s) { PostMessage(h, 0x102, (IntPtr)ch, (IntPtr)1); System.Threading.Thread.Sleep(40); }
    }
    static IntPtr LP(int x, int y) { return (IntPtr)((y << 16) | (x & 0xFFFF)); }
    public static void DblClick(IntPtr h, int x, int y) {
        PostMessage(h, 0x200, IntPtr.Zero, LP(x, y)); System.Threading.Thread.Sleep(40);
        PostMessage(h, 0x201, (IntPtr)1, LP(x, y)); System.Threading.Thread.Sleep(40); PostMessage(h, 0x202, IntPtr.Zero, LP(x, y));
        System.Threading.Thread.Sleep(40);
        PostMessage(h, 0x203, (IntPtr)1, LP(x, y)); System.Threading.Thread.Sleep(40); PostMessage(h, 0x202, IntPtr.Zero, LP(x, y));
    }
    public static void RClick(IntPtr h, int x, int y) {
        PostMessage(h, 0x200, IntPtr.Zero, LP(x, y)); System.Threading.Thread.Sleep(40);
        PostMessage(h, 0x204, (IntPtr)2, LP(x, y)); System.Threading.Thread.Sleep(80); PostMessage(h, 0x205, IntPtr.Zero, LP(x, y));
    }
    public static void RDrag(IntPtr h, int x1, int y1, int x2, int y2) {
        PostMessage(h, 0x200, IntPtr.Zero, LP(x1, y1)); System.Threading.Thread.Sleep(40);
        PostMessage(h, 0x204, (IntPtr)2, LP(x1, y1)); System.Threading.Thread.Sleep(60);
        for (int i = 1; i <= 20; i++) {
            int x = x1 + (x2 - x1) * i / 20, y = y1 + (y2 - y1) * i / 20;
            PostMessage(h, 0x200, (IntPtr)2, LP(x, y)); System.Threading.Thread.Sleep(25);
        }
        PostMessage(h, 0x205, IntPtr.Zero, LP(x2, y2));
    }
    // CY 3.71 polls the mouse (GetCursorPos + WindowFromPoint + GetAsyncKeyState, Game.exe FUN_140212fd0), so posted
    // mouse messages are ignored: real input is injected with SendInput, the cursor is restored afterwards.
    [StructLayout(LayoutKind.Sequential)] public struct PT { public int X; public int Y; }
    [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx; public int dy; public uint data; public uint flags; public uint time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public MOUSEINPUT mi; }
    [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out PT p);
    [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref PT p);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    public static void TopMost(IntPtr h, bool on) { SetWindowPos(h, (IntPtr)(on ? -1 : -2), 0, 0, 0, 0, 0x0013); }
    static void Btn(uint flag) { var i = new INPUT[1]; i[0].type = 0; i[0].mi.flags = flag; SendInput(1, i, Marshal.SizeOf(typeof(INPUT))); }
    static PT Scr(IntPtr h, int x, int y) { var p = new PT(); p.X = x; p.Y = y; ClientToScreen(h, ref p); return p; }
    public static void MClick(IntPtr h, int x, int y, int times) {
        PT old; GetCursorPos(out old); var p = Scr(h, x, y);
        SetCursorPos(p.X, p.Y); System.Threading.Thread.Sleep(300);
        for (int k = 0; k < times; k++) { Btn(0x0002); System.Threading.Thread.Sleep(120); Btn(0x0004); System.Threading.Thread.Sleep(120); }
        System.Threading.Thread.Sleep(100); SetCursorPos(old.X, old.Y);
    }
    public static void MWheel(IntPtr h, int x, int y, int delta, int times) {
        PT old; GetCursorPos(out old); var p = Scr(h, x, y);
        SetCursorPos(p.X, p.Y); System.Threading.Thread.Sleep(150);
        for (int k = 0; k < times; k++) {
            var i = new INPUT[1]; i[0].type = 0; i[0].mi.flags = 0x0800; i[0].mi.data = (uint)delta;
            SendInput(1, i, Marshal.SizeOf(typeof(INPUT))); System.Threading.Thread.Sleep(120);
        }
        System.Threading.Thread.Sleep(100); SetCursorPos(old.X, old.Y);
    }
    public static void MRDrag(IntPtr h, int x1, int y1, int x2, int y2, int steps) {
        PT old; GetCursorPos(out old); var a = Scr(h, x1, y1); var b = Scr(h, x2, y2);
        SetCursorPos(a.X, a.Y); System.Threading.Thread.Sleep(150); Btn(0x0008); System.Threading.Thread.Sleep(100);
        for (int i = 1; i <= steps; i++) { SetCursorPos(a.X + (b.X - a.X) * i / steps, a.Y + (b.Y - a.Y) * i / steps); System.Threading.Thread.Sleep(30); }
        System.Threading.Thread.Sleep(100); Btn(0x0010); System.Threading.Thread.Sleep(100); SetCursorPos(old.X, old.Y);
    }
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
    // The CY login procedure minimises its window whenever it is not the foreground window (Game.exe FUN_14062fc00 case 3),
    // so the run brings it to the front once; SendInput first makes this process the last-input owner.
    public static bool Front(IntPtr h) {
        var i = new INPUT[1]; i[0].type = 0; i[0].mi.flags = 0x0001; SendInput(1, i, Marshal.SizeOf(typeof(INPUT)));
        if (IsIconic(h)) ShowWindow(h, 9);
        return SetForegroundWindow(h);
    }
    public static void Wheel(IntPtr h, int x, int y, int delta) {
        PostMessage(h, 0x20A, (IntPtr)((delta & 0xFFFF) << 16), LP(x, y));
    }
}
'@
}
$CYRoot = [IO.Path]::GetFullPath($CYRoot).TrimEnd('\')
if ($CYRoot -like '*\Tools\DATA NEW\*') { throw 'Refusing to run the original CY client; use the private copy.' }
$bin = Join-Path $CYRoot 'Bin64'; $game = Join-Path $bin 'Game.exe'
$python = 'C:\Program Files\Python313\python.exe'
if (-not $Scenario) { $Scenario = Join-Path $here 'scenarios\dali.json' }
# Shared game slot (coordinator 15/09): Build\game-slot.lock = "<agent> <time>"; wait while it exists and is younger than
# 5 minutes or any Game.exe runs; take it; remove it as soon as Game.exe has exited.
$slot = 'C:\TLBB\085\CY-Source\Build\game-slot.lock'
$waitEnd = (Get-Date).AddMinutes($WaitMinutes); $free = 0
while ($free -lt 2) {
    $busy = @(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -gt 0
    if (-not $busy -and (Test-Path -LiteralPath $slot)) { $busy = ((Get-Date) - (Get-Item -LiteralPath $slot).LastWriteTime).TotalMinutes -lt 5 }
    if (-not $busy) { $free++ } else { $free = 0 }
    if ($free -lt 2) {
        if ((Get-Date) -gt $waitEnd) { throw 'Game slot still busy after the wait (one Game.exe at a time).' }
        Start-Sleep -Seconds 3
    }
}
[IO.File]::WriteAllText($slot, ('cy-oracle ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$cfgPath = Join-Path $CYRoot 'Bin\System.cfg'
$enc = [Text.Encoding]::GetEncoding(1252)
$cfg = [IO.File]::ReadAllText($cfgPath, $enc)
$set = @{ 'View_FullScreen' = '0'; 'View_MaxWindow' = '0' }
foreach ($k in $View.Keys) { $set[$k] = [string]$View[$k] }
foreach ($k in $set.Keys) {
    $rx = '(?m)^(\s*' + [regex]::Escape($k) + '\s*=\s*)[^\r\n]*'
    if ([regex]::IsMatch($cfg, $rx)) { $cfg = [regex]::Replace($cfg, $rx, ('${1}' + $set[$k])) }
    else { $cfg = $cfg -replace '(?m)^(#-------------------------------\r?\n# Profile)', ($k + ' = ' + $set[$k] + "`r`n`r`n" + '$1') }
}
[IO.File]::WriteAllText($cfgPath, $cfg, $enc)
Copy-Item -LiteralPath $cfgPath -Destination (Join-Path $OutDir 'System.cfg.used')
$steps = @()
foreach ($item in ($Plan -split ';')) {
    if (-not $item.Trim()) { continue }
    $p = $item.Split(':', 3); $rel = $p[0].StartsWith('+')
    $steps += [pscustomobject]@{ t = [double]($p[0].TrimStart('+')); rel = $rel; action = $p[1]; arg = $(if ($p.Count -gt 2) { $p[2] } else { '' }); done = $false }
}
$log = New-Object 'System.Collections.Generic.List[string]'
function Note([string]$s) { $line = ('{0,6:n1}s {1}' -f ((Get-Date) - $script:started).TotalSeconds, $s); $log.Add($line); Write-Host $line }
$script:started = Get-Date
# oracle
$oracleOut = Join-Path $OutDir 'oracle'
$oi = New-Object Diagnostics.ProcessStartInfo
$oi.FileName = $python
$oi.Arguments = ('-B "' + (Join-Path $here 'cy_oracle_server.py') + '" --out "' + $oracleOut + '" --login-port ' + $LoginPort + ' --game-port ' + $GamePort + ' --scenario "' + $Scenario + '" --max-seconds ' + ($Seconds + 30))
$oi.UseShellExecute = $false; $oi.RedirectStandardOutput = $true; $oi.RedirectStandardError = $true; $oi.CreateNoWindow = $true
$oracle = [Diagnostics.Process]::Start($oi)
$oOut = $oracle.StandardOutput.ReadToEndAsync(); $oErr = $oracle.StandardError.ReadToEndAsync()
$oracleLog = Join-Path $oracleOut 'oracle.log'
$t = 0; while (-not (Test-Path $oracleLog) -and $t -lt 50) { Start-Sleep -Milliseconds 100; $t++ }
Start-Sleep -Milliseconds 500
Note ('oracle pid ' + $oracle.Id)
$sockets = New-Object 'System.Collections.Generic.List[object]'; $killedFor = $null
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = $game; $info.Arguments = '-fl'; $info.WorkingDirectory = $bin; $info.UseShellExecute = $false
$info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
$proc = [Diagnostics.Process]::Start($info)
$stdoutTask = $proc.StandardOutput.ReadToEndAsync(); $stderrTask = $proc.StandardError.ReadToEndAsync()
Note ('game pid ' + $proc.Id)
$nextEvery = $Every; $hwnd = [IntPtr]::Zero; $blocked = $false; $script:waitBase = 0
try {
    while (-not $proc.HasExited -and ((Get-Date) - $started).TotalSeconds -lt $Seconds) {
        Start-Sleep -Milliseconds 250
        foreach ($s in @(Get-NetTCPConnection -OwningProcess $proc.Id -ErrorAction SilentlyContinue)) {
            $remote = [string]$s.RemoteAddress
            if ($remote -in @('0.0.0.0', '::')) { continue }
            $key = $remote + ':' + $s.RemotePort
            if (-not ($sockets | Where-Object { $_.endpoint -eq $key })) { $sockets.Add([pscustomobject]@{ endpoint = $key; state = [string]$s.State; t = [math]::Round(((Get-Date) - $started).TotalSeconds, 1) }); Note ('socket ' + $key + ' ' + $s.State) }
            $ok = ($remote -in @('127.0.0.1', '::1')) -and ($s.RemotePort -in @($LoginPort, $GamePort))
            if (-not $ok) { $killedFor = $key; throw ('connection outside the oracle ' + $key) }
        }
        foreach ($c in @(Get-CimInstance Win32_Process -Filter ("ParentProcessId=" + $proc.Id) -ErrorAction SilentlyContinue)) {
            Note ('child process ' + $c.Name + ' pid ' + $c.ProcessId + ' (killed)'); Stop-Process -Id $c.ProcessId -Force -ErrorAction SilentlyContinue
        }
        if ($hwnd -eq [IntPtr]::Zero -or -not [CysWin]::IsWindowVisible($hwnd)) {
            $hwnd = Get-CysMainWindow $proc.Id
            if ($hwnd -ne [IntPtr]::Zero) { $c = [CysWin]::Client($hwnd); [CysOracleWin]::TopMost($hwnd, $true); Note ('window "' + [CysWin]::Title($hwnd) + '" client ' + ($c -join ',') + ' (topmost, no activation)') }
        }
        $now = ((Get-Date) - $started).TotalSeconds
        if ($hwnd -eq [IntPtr]::Zero) { continue }
        foreach ($st in $steps) {
            if ($st.done) { continue }
            $due = $(if ($st.rel) { $script:waitBase + $st.t } else { $st.t })
            if ($now -lt $due) { break }
            if ($st.action -eq 'wait') {
                $txt = ''; try { $fs = New-Object IO.FileStream($oracleLog, 'Open', 'Read', 'ReadWrite'); $sr = New-Object IO.StreamReader($fs); $txt = $sr.ReadToEnd(); $sr.Close() } catch { }
                if ($txt -match $st.arg) { $st.done = $true; $script:waitBase = $now; Note ('wait matched ' + $st.arg); continue } else { break }
            }
            if (((Get-Date) - $started).TotalSeconds -ge $Seconds) { break }
            $st.done = $true
            switch ($st.action) {
                'shot' { $f = Join-Path $OutDir ($st.arg + '.png'); $m = [CysWin]::Capture($hwnd, $f, 'auto'); Note ('shot ' + $st.arg + ' via ' + $m) }
                'key' { [CysWin]::Key($hwnd, [int]$st.arg); Note ('key ' + $st.arg) }
                'click' { $xy = $st.arg.Split(','); [CysWin]::Click($hwnd, [int]$xy[0], [int]$xy[1]); Note ('click ' + $st.arg) }
                'dblclick' { $xy = $st.arg.Split(','); [CysOracleWin]::DblClick($hwnd, [int]$xy[0], [int]$xy[1]); Note ('dblclick ' + $st.arg) }
                'rclick' { $xy = $st.arg.Split(','); [CysOracleWin]::RClick($hwnd, [int]$xy[0], [int]$xy[1]); Note ('rclick ' + $st.arg) }
                'drag' { $xy = $st.arg.Split(','); [CysOracleWin]::RDrag($hwnd, [int]$xy[0], [int]$xy[1], [int]$xy[2], [int]$xy[3]); Note ('rdrag ' + $st.arg) }
                'wheel' { $xy = $st.arg.Split(','); [CysOracleWin]::Wheel($hwnd, [int]$xy[0], [int]$xy[1], [int]$xy[2]); Note ('wheel ' + $st.arg) }
                'mclick' { $xy = $st.arg.Split(','); [CysOracleWin]::MClick($hwnd, [int]$xy[0], [int]$xy[1], 1); Note ('mouse click ' + $st.arg) }
                'mdbl' { $xy = $st.arg.Split(','); [CysOracleWin]::MClick($hwnd, [int]$xy[0], [int]$xy[1], 2); Note ('mouse double ' + $st.arg) }
                'mrdrag' { $xy = $st.arg.Split(','); [CysOracleWin]::MRDrag($hwnd, [int]$xy[0], [int]$xy[1], [int]$xy[2], [int]$xy[3], 25); Note ('mouse right drag ' + $st.arg) }
                'char' { [CysOracleWin]::Chars($hwnd, $st.arg); Note ('chars ' + $st.arg.Length) }
                'cam' {
                    # camera readback like run_cy_capture.ps1 'aspect' (color-calib): Ogre::Frustum aspect 16:9 hits with 64 B
                    # before / 400 B after (fov, near/far, view matrix at +336), read-only ReadProcessMemory
                    $f = Join-Path $OutDir ('cam-' + $st.arg + '.txt'); $n = [CysWin]::ScanFloat($proc.Id, [single](16.0 / 9.0), [single]0.00001, 64, 400, $f, 4000); Note ('camera scan ' + $st.arg + ' hits ' + $n)
                }
                'mwheel' { $xy = $st.arg.Split(','); [CysOracleWin]::MWheel($hwnd, [int]$xy[0], [int]$xy[1], [int]$xy[2], $(if ($xy.Count -gt 3) { [int]$xy[3] } else { 1 })); Note ('mouse wheel ' + $st.arg) }
                'camread' {
                    # read-only camera readback (cy_camera_read.py): arg tag[,x,z] = expected player game position
                    $a = $st.arg.Split(','); $f = Join-Path $OutDir ('cam-' + $a[0] + '.json')
                    $ca = @('-B', (Join-Path $here 'cy_camera_read.py'), '--pid', $proc.Id, '--out', $f)
                    if ($a.Count -ge 3) { $ca += @('--expect', ($a[1] + ',' + $a[2])) }
                    $r = & $python @ca 2>&1 | Select-Object -Last 1; Note ('camread ' + $a[0] + ': ' + $r)
                }
                'front' { $ok = [CysOracleWin]::Front($hwnd); Note ('foreground ' + $ok) }
            }
        }
        if ($Every -gt 0 -and $now -ge $nextEvery) {
            $nextEvery += $Every
            $f = Join-Path $OutDir ('t{0:000}.png' -f [int]$now); $m = [CysWin]::Capture($hwnd, $f, 'auto')
        }
    }
} catch { Note ('STOP: ' + $_.Exception.Message) } finally {
    if ($hwnd -ne [IntPtr]::Zero) { try { [CysOracleWin]::TopMost($hwnd, $false) } catch { } }
    if (-not $proc.HasExited) { $proc.Kill(); $proc.WaitForExit(); Note 'game killed after run' } else { Note ('game exited code ' + $proc.ExitCode) }
    foreach ($c in @(Get-CimInstance Win32_Process -Filter ("ParentProcessId=" + $proc.Id) -ErrorAction SilentlyContinue)) { Stop-Process -Id $c.ProcessId -Force -ErrorAction SilentlyContinue }
    try { if ((Get-Content -LiteralPath $slot -ErrorAction Stop) -like 'cy-oracle *') { Remove-Item -LiteralPath $slot -Force } } catch { }
    foreach ($c in @(Get-CimInstance Win32_Process -Filter ("ParentProcessId=" + $proc.Id) -ErrorAction SilentlyContinue)) { Stop-Process -Id $c.ProcessId -Force -ErrorAction SilentlyContinue }
    [void][IO.Directory]::CreateDirectory($oracleOut); [IO.File]::WriteAllText((Join-Path $oracleOut 'stop'), 'stop')
    if (-not $oracle.WaitForExit(8000)) { $oracle.Kill(); Note 'oracle killed' } else { Note ('oracle exited ' + $oracle.ExitCode) }
    try { [IO.File]::WriteAllText((Join-Path $OutDir 'oracle-stdout.txt'), $oOut.Result + "`r`n--- stderr`r`n" + $oErr.Result) } catch { }
    try { [IO.File]::WriteAllText((Join-Path $OutDir 'stdout.txt'), $stdoutTask.Result + "`r`n--- stderr`r`n" + $stderrTask.Result) } catch { }
    $logDir = Join-Path $bin 'LogDirectory'
    foreach ($f in @(Get-ChildItem -LiteralPath $logDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $started })) { Copy-Item -LiteralPath $f.FullName -Destination $OutDir }
    [IO.File]::WriteAllLines((Join-Path $OutDir 'run.log'), $log)
    ([ordered]@{ game = $game; sha256 = (Get-FileHash -LiteralPath $game).Hash.ToLowerInvariant(); plan = $Plan; scenario = $Scenario; sockets = $sockets.ToArray(); killed_for = $killedFor; started = $started.ToString('o') } | ConvertTo-Json -Depth 4) | Set-Content -Encoding UTF8 (Join-Path $OutDir 'run.json')
}
