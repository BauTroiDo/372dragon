# CY-Source Tools/game/run_game_smoke.ps1 - offline GL login smoke of a Tools/game/stage_game.py stage.
# Starts Bin64\Game.exe -fl -cys-gl-login-smoke (CYS_GL_LOGIN_SMOKE=1, CWD Bin64), never authenticates or connects,
# stops it after -Seconds, keeps logs and captures in -OutDir, runs Tests\ui\validate_gl_login_result.ps1 on them and
# gates on the client_GL DBC schema check of CDataBaseSystem::OpenAllDataBase (no "DBC ERROR" in WXClient.log).
# Only the Game process started here is ever stopped. ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$Stage,
    [string]$OutDir = '',
    [ValidateRange(30,300)][int]$Seconds = 75,
    [ValidateSet('Canonical', 'CanonicalCY')][string]$DataProfile = 'Canonical',
    [string]$TreeRoot = '',
    [switch]$NoValidate,
    # CYS-AVATAR: -CreateMode Preview = the offline creation-screen smoke of CysGlLoginSmoke (CYS_CREATE_ROLE_SMOKE=Preview:
    # 30 sect previews, portraits, rotate/zoom; needs the CY creation profile of the stage and >= 180 s).
    [ValidateSet('None', 'Preview')][string]$CreateMode = 'None'
)
if ($CreateMode -eq 'Preview' -and $Seconds -lt 180) { throw 'CreateMode Preview needs -Seconds 180 or more.' }
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
# CYS-CY: -TreeRoot C:\TLBB\085\CY-Source when the script runs from a worktree but the stage lives in the main Build tree.
if ($TreeRoot) { $root = [IO.Path]::GetFullPath($TreeRoot).TrimEnd('\') }
# CYS-CY (cs1-tables): -DataProfile CanonicalCY for Game.exe builds with the CY 3.71 structs. In a worktree Assets\<profile>
# may itself be a junction to the main tree: compare against its target.
$canonicalRoot = Join-Path $root ('Assets\' + $DataProfile)
$canonicalItem = Get-Item -LiteralPath $canonicalRoot -Force -ErrorAction SilentlyContinue
if ($canonicalItem -and ($canonicalItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    $canonicalRoot = [string]@($canonicalItem.Target)[0]
    if ($canonicalRoot.StartsWith('\??\')) { $canonicalRoot = $canonicalRoot.Substring(4) }
}
$canonical = [IO.Path]::GetFullPath((Join-Path $canonicalRoot 'Data')).TrimEnd('\')
function Hash([string]$path) { return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function InBuild([string]$path) {
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $root $path }
    $full = [IO.Path]::GetFullPath($path).TrimEnd('\')
    if (-not $full.StartsWith((Join-Path $root 'Build') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Path must stay inside CY-Source\Build.' }
    return $full
}
function ExactSetting([string]$text, [string]$name, [string]$expected) {
    $values = [regex]::Matches($text, '(?m)^\s*' + [regex]::Escape($name) + '\s*=\s*([^\r\n]*)')
    if ($values.Count -ne 1 -or $values[0].Groups[1].Value.Trim() -ne $expected) { throw ('Unexpected or duplicate setting: ' + $name) }
}
$Stage = InBuild $Stage
$bin = Join-Path $Stage 'Bin64'
foreach ($path in @($Stage, $bin, (Join-Path $Stage 'Patch'))) {
    $item = Get-Item -LiteralPath $path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw ('Unexpected reparse point: ' + $path) }
}
$data = Get-Item -LiteralPath (Join-Path $Stage 'Data') -Force
if (-not ($data.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw ('Stage Data must be the junction to Assets\' + $DataProfile + '\Data.') }
$target = [string]@($data.Target)[0]
if ($target.StartsWith('\??\')) { $target = $target.Substring(4) }
if ([IO.Path]::GetFullPath($target).TrimEnd('\') -ne $canonical) { throw ('Data junction points elsewhere: ' + $target) }
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $bin 'game_data_stage.json') | ConvertFrom-Json
foreach ($file in $manifest.binaries) {
    if ([IO.Path]::GetFileName($file.name) -ne $file.name) { throw 'Invalid binary manifest filename.' }
    if ((Hash (Join-Path $bin $file.name)) -ne $file.sha256) { throw ('Staged binary differs from its manifest: ' + $file.name) }
}
$cfg = [IO.File]::ReadAllText((Join-Path $bin 'WXSystem.cfg'))
ExactSetting $cfg 'GameServer_Address' '127.0.0.1'
ExactSetting $cfg 'GameServer_Port' '14400'
ExactSetting $cfg 'GameServer_ConnectDirect' '0'
ExactSetting $cfg 'System_CodePage' '65001'
if ((Hash (Join-Path $Stage 'Patch\LoginServer.txt')) -ne (Hash (Join-Path $root 'Tests\ui\fixtures\login-server-utf8.txt'))) { throw 'Patch\LoginServer.txt is not the offline fixture.' }
$legacy = [IO.File]::ReadAllText((Join-Path $Stage 'Patch\WXLoginServer.txt'))
$servers = [regex]::Matches($legacy, '(?ms)^\[LOGIN\d+\]\s*(.*?)(?=^\[|\z)')
if ($servers.Count -ne 1) { throw 'Exactly one dummy fallback server is required.' }
ExactSetting $servers[0].Groups[1].Value 'IP' '127.0.0.1'
ExactSetting $servers[0].Groups[1].Value 'PORT' '14400'
$game = Join-Path $bin 'Game.exe'
foreach ($p in @(Get-Process -Name Game -ErrorAction SilentlyContinue)) {
    $path = $null
    try { $path = $p.Path } catch { $path = $null }
    if ($path -and ([IO.Path]::GetFullPath($path) -eq $game)) { throw 'A Game.exe of this stage is already running; not starting another.' }
}
if (-not $OutDir) { $OutDir = 'Build\Logs\2026-09-13-game-data\smoke-' + (Split-Path -Leaf $Stage) + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss') }
$OutDir = InBuild $OutDir
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir; prior evidence is preserved.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$tmp = Join-Path $OutDir 'tmp'; [void][IO.Directory]::CreateDirectory($tmp)
# WXClient.log is opened in append mode: move every prior log away before the launch.
$prior = Join-Path $OutDir 'prior-logs'; [void][IO.Directory]::CreateDirectory($prior)
foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT')) {
    $source = Join-Path $bin $name
    if (Test-Path -LiteralPath $source) { Move-Item -LiteralPath $source -Destination (Join-Path $prior $name) }
}
$shotDir = Join-Path $Stage 'ScreenShots'
$beforeShots = @(Get-ChildItem -LiteralPath $shotDir -Filter 'cys-gl-*.png' -ErrorAction SilentlyContinue | ForEach-Object Name)
$beforeDumps = @(Get-ChildItem -LiteralPath $bin -Filter '*.dmp' -ErrorAction SilentlyContinue | ForEach-Object Name)
$arguments = '-fl -cys-gl-login-smoke'
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = $game; $info.Arguments = $arguments; $info.WorkingDirectory = $bin
$info.UseShellExecute = $false; $info.CreateNoWindow = $true
$info.EnvironmentVariables['CYS_GL_LOGIN_SMOKE'] = '1'
foreach ($name in @('CYS_BOT_PWD', 'CYS_WSL_LOGIN_TEST', 'CYS_CREATE_ROLE_SMOKE')) { $info.EnvironmentVariables.Remove($name) }
if ($CreateMode -ne 'None') { $info.EnvironmentVariables['CYS_CREATE_ROLE_SMOKE'] = $CreateMode }  # CYS-AVATAR
$info.EnvironmentVariables['TEMP'] = $tmp; $info.EnvironmentVariables['TMP'] = $tmp
$started = Get-Date; $connections = New-Object 'System.Collections.Generic.List[object]'
$terminated = $false; $process = $null; $launchError = $null
$cpu = New-Object 'System.Collections.Generic.List[object]'; $responding = $null
try {
    $process = New-Object Diagnostics.Process; $process.StartInfo = $info
    if (-not $process.Start()) { throw 'Could not start Game.exe.' }
    while (-not $process.HasExited -and (Get-Date) -lt $started.AddSeconds($Seconds)) {
        Start-Sleep -Seconds 2; $process.Refresh()
        if ($process.HasExited) { break }
        # CPU time per sample: a stalled run that keeps burning CPU is a spin (loop), a flat line is a wait/deadlock.
        $cpu.Add([ordered]@{t = [int]((Get-Date) - $started).TotalSeconds; cpu = [math]::Round($process.TotalProcessorTime.TotalSeconds, 2); responding = $process.Responding})
        foreach ($socket in @(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue)) {
            $connections.Add([ordered]@{remote = [string]$socket.RemoteAddress; port = $socket.RemotePort; state = [string]$socket.State})
            if ([string]$socket.RemoteAddress -notin @('0.0.0.0', '::')) { throw 'Unexpected connection from the offline Game.' }
        }
    }
} catch { $launchError = $_.Exception.Message } finally {
    if ($process -and -not $process.HasExited) { $responding = $process.Responding; $process.Kill(); $process.WaitForExit(); $terminated = $true }
    [IO.File]::WriteAllText((Join-Path $OutDir 'cpu.json'), (([ordered]@{samples = $cpu.ToArray(); responding_before_kill = $responding}) | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
    foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT')) {
        $path = Join-Path $bin $name
        if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $OutDir }
    }
    $shots = @(Get-ChildItem -LiteralPath $shotDir -Filter 'cys-gl-*.png' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $beforeShots })
    $records = @(foreach ($shot in $shots) {
        Copy-Item -LiteralPath $shot.FullName -Destination $OutDir
        [ordered]@{name = $shot.Name; sha256 = (Hash $shot.FullName); bytes = $shot.Length}
    })
    $dumps = @(Get-ChildItem -LiteralPath $bin -Filter '*.dmp' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $beforeDumps } | ForEach-Object Name)
    $dbc = [ordered]@{ok = 0; errors = @(); summary = $null}
    $clientLog = Join-Path $OutDir 'WXClient.log'
    if (Test-Path -LiteralPath $clientLog) {
        $text = [IO.File]::ReadAllText($clientLog)
        $dbc.ok = [regex]::Matches($text, 'DBC: \S+ OK columns=').Count
        $dbc.errors = @([regex]::Matches($text, '(?m)^.*DBC ERROR.*$') | ForEach-Object { $_.Value.Trim() })
        $m = [regex]::Match($text, 'DBC: (\d+) table\(s\) checked against the (client_GL|CY 3\.71) schema, (\d+) error\(s\), (\d+) absent')
        if ($m.Success) { $dbc.summary = $m.Value }
    }
    $run = [ordered]@{stage = $Stage; mode = 'Offline'; create_mode = 'None'; started = $started.ToString('o'); finished = (Get-Date).ToString('o');
        command = $game + ' ' + $arguments; cwd = $bin; terminated_after_timeout = $terminated; pid = $null; exit_code = $null;
        shots = $records; sockets = $connections.ToArray(); dumps = $dumps; dbc = $dbc; launch_error = $launchError;
        stage_manifest_sha256 = (Hash (Join-Path $bin 'game_data_stage.json'))}
    if ($process) {
        $run.pid = $process.Id
        if ($process.HasExited) { $run.exit_code = $process.ExitCode }
        $process.Dispose()
    }
    [IO.File]::WriteAllText((Join-Path $OutDir 'run.json'), ($run | ConvertTo-Json -Depth 7), (New-Object Text.UTF8Encoding($false)))
}
if ($launchError) { throw $launchError }
Write-Host ('DBC: ' + $dbc.ok + ' tables OK, ' + @($dbc.errors).Count + ' DBC ERROR line(s); ' + $dbc.summary)
if (-not $NoValidate) { & (Join-Path $root 'Tests\ui\validate_gl_login_result.ps1') -OutDir $OutDir }
if (@($dbc.errors).Count -ne 0 -or -not $dbc.summary) { throw ('DBC gate failed; see ' + $OutDir) }
if (@($dumps).Count -ne 0) { throw ('Crash dump(s) written: ' + ($dumps -join ', ')) }
Write-Host ('PASS offline Game smoke on ' + $DataProfile + ' data; evidence in ' + $OutDir)
