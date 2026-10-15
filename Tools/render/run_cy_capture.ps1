# CY-Source Tools/render/run_cy_capture.ps1 - reference frames from the CY 3.71 client (CYS-COLOR, color-calib 15/09).
# Runs Bin64\Game.exe -fl of a PRIVATE COPY of `Tools\DATA NEW\CY Game` (never the original: Game.exe clears
# Bin64\ShaderCache and rewrites Bin\System.cfg), no admin, no account typed, and never lets it reach a game server:
# every TCP connection of the process is sampled; any non-loopback connection to a port other than 80/443 kills it
# at once (web announcement fetches on 80/443 are only recorded). Stops after -Seconds (<= 150).
# -Plan "t:action[:arg];..." with actions shot:<name> | key:<vk> | click:<x>,<y> (client pixels) | shots:<every s>.
# ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$CYRoot,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [ValidateRange(20,150)][int]$Seconds = 120,
    [string]$Resolution = '1024,768',
    [string]$Plan = '',
    [int]$Every = 0,
    [ValidateRange(0,15)][int]$WaitMinutes = 15,
    [hashtable]$View = @{}
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'WinCapture.ps1')
$CYRoot = [IO.Path]::GetFullPath($CYRoot).TrimEnd('\')
if ($CYRoot -like '*\Tools\DATA NEW\*') { throw 'Refusing to run the original CY client; use the private copy.' }
$bin = Join-Path $CYRoot 'Bin64'; $game = Join-Path $bin 'Game.exe'
# One Game.exe on the machine: wait (synchronously, up to -WaitMinutes) until no Game.exe for two samples in a row.
$waitEnd = (Get-Date).AddMinutes($WaitMinutes); $free = 0
while ($free -lt 2) {
    if (@(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -eq 0) { $free++ } else { $free = 0 }
    if ($free -lt 2) {
        if ((Get-Date) -gt $waitEnd) { throw 'Another Game.exe is still running after the wait (one Game.exe at a time).' }
        Start-Sleep -Seconds 3
    }
}
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir.' }
[void][IO.Directory]::CreateDirectory($OutDir)
# System.cfg of the copy: resolution, windowed, not maximised; optional View_* overrides.
$cfgPath = Join-Path $CYRoot 'Bin\System.cfg'
$enc = [Text.Encoding]::GetEncoding(1252)
$cfg = [IO.File]::ReadAllText($cfgPath, $enc)
$set = @{ 'View_Resoution' = $Resolution; 'View_FullScreen' = '0'; 'View_MaxWindow' = '0' }
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
    $p = $item.Split(':', 3); $steps += [pscustomobject]@{ t = [double]$p[0]; action = $p[1]; arg = $(if ($p.Count -gt 2) { $p[2] } else { '' }); done = $false }
}
$log = New-Object 'System.Collections.Generic.List[string]'
function Note([string]$s) { $line = ('{0,6:n1}s {1}' -f ((Get-Date) - $script:started).TotalSeconds, $s); $log.Add($line); Write-Host $line }
$sockets = New-Object 'System.Collections.Generic.List[object]'; $killedFor = $null
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = $game; $info.Arguments = '-fl'; $info.WorkingDirectory = $bin; $info.UseShellExecute = $false
$info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
$script:started = Get-Date
$proc = [Diagnostics.Process]::Start($info)
$stdoutTask = $proc.StandardOutput.ReadToEndAsync(); $stderrTask = $proc.StandardError.ReadToEndAsync()
Note ('started pid ' + $proc.Id)
$nextEvery = $Every; $shotIndex = 0; $hwnd = [IntPtr]::Zero
try {
    while (-not $proc.HasExited -and ((Get-Date) - $started).TotalSeconds -lt $Seconds) {
        Start-Sleep -Milliseconds 400
        foreach ($s in @(Get-NetTCPConnection -OwningProcess $proc.Id -ErrorAction SilentlyContinue)) {
            $remote = [string]$s.RemoteAddress
            if ($remote -in @('0.0.0.0', '::', '127.0.0.1', '::1')) { continue }
            $key = $remote + ':' + $s.RemotePort
            if (-not ($sockets | Where-Object { $_.endpoint -eq $key })) { $sockets.Add([pscustomobject]@{ endpoint = $key; state = [string]$s.State; t = [math]::Round(((Get-Date) - $started).TotalSeconds, 1) }); Note ('socket ' + $key + ' ' + $s.State) }
            if ($s.RemotePort -notin @(80, 443)) { $killedFor = $key; throw ('non-web connection ' + $key) }
        }
        if ($hwnd -eq [IntPtr]::Zero -or -not [CysWin]::IsWindowVisible($hwnd)) {
            $hwnd = Get-CysMainWindow $proc.Id
            if ($hwnd -ne [IntPtr]::Zero) { $c = [CysWin]::Client($hwnd); Note ('window "' + [CysWin]::Title($hwnd) + '" class ' + [CysWin]::Klass($hwnd) + ' client ' + ($c -join ',')) }
        }
        $now = ((Get-Date) - $started).TotalSeconds
        if ($hwnd -eq [IntPtr]::Zero) { continue }
        foreach ($st in $steps) {
            if ($st.done -or $now -lt $st.t) { continue }
            $st.done = $true
            switch ($st.action) {
                'shot' { $f = Join-Path $OutDir ($st.arg + '.png'); $m = [CysWin]::Capture($hwnd, $f, 'auto'); Note ('shot ' + $st.arg + ' via ' + $m) }
                'key' { [CysWin]::Key($hwnd, [int]$st.arg); Note ('key ' + $st.arg) }
                'click' { $xy = $st.arg.Split(','); [CysWin]::Click($hwnd, [int]$xy[0], [int]$xy[1]); Note ('click ' + $st.arg) }
                'aspect' { $f = Join-Path $OutDir ('mem-aspect-' + $st.arg + '.txt'); $n = [CysWin]::ScanFloat($proc.Id, [single](16.0 / 9.0), [single]0.00001, 64, 400, $f, 4000); Note ('memory scan aspect 16:9 hits ' + $n) }
                'mem' {
                    # CYS-AA: t:mem:<module>,<rva hex>,<offset hex>,<count> e.g. OgreMain.dll,418a08,b0,4 (MaterialManager
                    # default min/mag/mip filter + anisotropy of CY OgreMain 3.71); read-only.
                    $a = $st.arg.Split(','); $mod = @($proc.Modules | Where-Object { $_.ModuleName -ieq $a[0] })
                    if ($mod.Count -eq 0) { Note ('mem ' + $st.arg + ': module not loaded') }
                    else {
                        # more than 4 fields: module,rva,ptrOff1[,ptrOff2...],off,count (e.g. OgreMain.dll,424638,18,4398,4 =
                        # Root -> mActiveRenderer -> D3D9RenderSystem FSAA/FSAAQuality/RTFSAA/RTFSAAQuality)
                        $chain = @(); for ($i = 2; $i -lt $a.Count - 2; $i++) { $chain += [Convert]::ToInt64($a[$i], 16) }
                        $r = [CysWin]::ReadChain($proc.Id, [long]$mod[0].BaseAddress, [Convert]::ToInt64($a[1], 16), [long[]]$chain, [Convert]::ToInt64($a[$a.Count - 2], 16), [int]$a[$a.Count - 1]); Note ('mem ' + $st.arg + ' -> ' + $r)
                    }
                }
                'front' {[void][CysWin]::SetForegroundWindow($hwnd); Note 'foreground' }
            }
        }
        if ($Every -gt 0 -and $now -ge $nextEvery) {
            $nextEvery += $Every; $shotIndex++
            $f = Join-Path $OutDir ('t{0:000}.png' -f [int]$now); $m = [CysWin]::Capture($hwnd, $f, 'auto'); Note ('periodic shot via ' + $m)
        }
    }
} catch { Note ('STOP: ' + $_.Exception.Message) } finally {
    if (-not $proc.HasExited) { $proc.Kill(); $proc.WaitForExit(); Note 'killed after run' } else { Note ('exited code ' + $proc.ExitCode) }
    try { [IO.File]::WriteAllText((Join-Path $OutDir 'stdout.txt'), $stdoutTask.Result + "`r`n--- stderr`r`n" + $stderrTask.Result) } catch { }
    $logDir = Join-Path $bin 'LogDirectory'
    foreach ($f in @(Get-ChildItem -LiteralPath $logDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $started })) { Copy-Item -LiteralPath $f.FullName -Destination $OutDir }
    [IO.File]::WriteAllLines((Join-Path $OutDir 'run.log'), $log)
    ([ordered]@{ game = $game; sha256 = (Get-FileHash -LiteralPath $game).Hash.ToLowerInvariant(); resolution = $Resolution; plan = $Plan; sockets = $sockets.ToArray(); killed_for = $killedFor; started = $started.ToString('o') } | ConvertTo-Json -Depth 4) | Set-Content -Encoding UTF8 (Join-Path $OutDir 'run.json')
}
