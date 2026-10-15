# CY-Source Tools/game/run_world_gui_live.ps1 - live GUI turn of a stage_game.py stage against the PRIVATE server
# (/home/ubuntu/cys-test-20260913 on WSL TLBB, profile cys-server in Patch\CysServerProfile.txt). Never the live server.
# Starts Bin64\Game.exe -fl -cys-gl-login-smoke with CYS_CREATE_ROLE_SMOKE=World: the owned smoke pointer types test00
# and the password (read from .local\test-accounts.txt into the CHILD environment only), selects CYTest00, clicks the
# enter-game button, and CysWorldReplay drives the world (camera script + three navmesh ground clicks) before the run
# leaves through the system menu (QuitApplication -> CGAskQuit). Evidence (logs, PNGs, run.json) goes to -OutDir.
# The password is never written to the log, run.json or the console; every captured log is scanned for it afterwards.
# At most ONE login attempt per run: a rejected login ends the run, never retried here (wrong passwords count per host).
# Single-instance rule: Game.exe runs only once per machine; a foreign Game.exe is waited for and never stopped.
# ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$Stage,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [ValidateRange(60,900)][int]$Seconds = 150,
    [ValidateRange(1,30)][int]$WaitMinutes = 10,
    [string]$AccountFile = 'C:\TLBB\085\CY-Source\.local\test-accounts.txt',
    [string]$Account = 'test00',
    # maps-instance 17/09: -Account da co tu truoc nhung ten tai khoan/nhan vat KHONG duoc truyen
    # vao tien trinh con, nen moi lan chay deu dang nhap bang test00/CYTest00 du -Account la gi
    # (CysGlLoginSmoke.h:50 doc CYS_BOT_ACCOUNT, khong co thi mac dinh "test00"). Nay truyen
    # dung hai bien do. De trong -Role = suy ra "CYTest" + hai chu so cuoi cua -Account.
    # Hanh vi mac dinh khong doi: -Account test00 => CYS_BOT_ACCOUNT=test00, CYS_BOT_ROLE=CYTest00.
    [string]$Role = '',
    [switch]$EquipCraftProbe,
    [switch]$MountFlightProbe,
    [switch]$WuhunPreviewProbe,
    [switch]$WuhunAppearanceProbe,
    [switch]$WuhunReloginProbe,
    [ValidateRange(0,2)][int]$DualSoulsProbe = 0,
    [ValidateRange(0,2)][int]$SmartEquipProbe = 0,
    [ValidateRange(0,2)][int]$CurrencyProbe = 0,
    [ValidateRange(0,4)][int]$RuntimePolishProbe = 0,
    [ValidateRange(0,4)][int]$GameplayAuditProbe = 0,
    [ValidateRange(0,6)][int]$PowerSystemsProbe = 0,
    [ValidateRange(0,3)][int]$PlayerShopProbe = 0,
    [ValidateRange(0,2)][int]$SoulReforgeProbe = 0,
    [ValidateRange(0,3)][int]$CommunityProbe = 0,
    [ValidateRange(0,7)][int]$PartyGuildProbe = 0
)
$ErrorActionPreference = 'Stop'
function Hash([string]$path) { return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Full([string]$path) { return [IO.Path]::GetFullPath($path).TrimEnd('\') }
function ReadLiveLog([string]$path) {
    # The client reopens its log for every line. Do not deny concurrent writes.
    $stream = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    $reader = $null
    try {
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true)
        return $reader.ReadToEnd()
    } finally {
        if ($reader) { $reader.Dispose() } else { $stream.Dispose() }
    }
}
$Stage = Full $Stage
$OutDir = Full $OutDir
if ($Stage -notmatch '\\Build\\') { throw 'Stage must lie below a Build folder.' }
if ($OutDir -notmatch '\\Build\\Logs\\') { throw 'OutDir must lie below Build\Logs.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir; prior evidence is preserved.' }
$bin = Join-Path $Stage 'Bin64'
$game = Join-Path $bin 'Game.exe'
if (-not (Test-Path -LiteralPath $game)) { throw ('Game.exe not found in ' + $bin) }
$data = Get-Item -LiteralPath (Join-Path $Stage 'Data') -Force
if (-not ($data.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Stage Data must be a junction (never delete it recursively).' }
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $bin 'game_data_stage.json') | ConvertFrom-Json
foreach ($file in $manifest.binaries) {
    if ([IO.Path]::GetFileName($file.name) -ne $file.name) { throw 'Invalid binary manifest filename.' }
    if ((Hash (Join-Path $bin $file.name)) -ne $file.sha256) { throw ('Staged binary differs from its manifest: ' + $file.name) }
}
if (-not $manifest.wsl_test -or $manifest.wsl_test.profile -ne 'cys-server') { throw 'Stage is not in the cys-server profile state (stage_wsl_test.py apply).' }
$profileFile = Join-Path $Stage 'Patch\CysServerProfile.txt'
if (-not (Test-Path -LiteralPath $profileFile)) { throw 'Patch\CysServerProfile.txt is missing.' }
$profileText = [IO.File]::ReadAllText($profileFile)
if ($profileText -notmatch '(?m)^login=(\d+\.\d+\.\d+\.\d+):(\d+)\s*$') { throw 'Server profile has no login endpoint.' }
$loginHost = $Matches[1]; $loginPort = [int]$Matches[2]
if ($profileText -notmatch '(?m)^game_port=(\d+)\s*$') { throw 'Server profile has no game port.' }
$gamePort = [int]$Matches[1]
if ($loginHost -ne '127.0.0.1') { throw 'This runner only drives the loopback private server.' }
# ---- password: child environment only
if (-not (Test-Path -LiteralPath $AccountFile)) { throw ('Account file not found: ' + $AccountFile) }
$line = @(Get-Content -LiteralPath $AccountFile | Where-Object { $_ -like ($Account + '=*') })
if ($line.Count -ne 1) { throw 'Exactly one account line is required in the account file.' }
$secret = $line[0].Substring($Account.Length + 1)
if (-not $secret -or $secret.Length -gt 32) { throw 'Unsupported password length in the account file.' }
# ---- single instance: wait until no Game.exe is alive (never kill a foreign one)
$waitStarted = Get-Date; $waited = 0
while (@(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -gt 0) {
    if (((Get-Date) - $waitStarted).TotalMinutes -ge $WaitMinutes) { throw ('Another Game.exe stayed alive for ' + $WaitMinutes + ' minutes; not starting (single-instance rule).') }
    Write-Host ('Another Game.exe is alive; waiting 30 s (' + [int](((Get-Date) - $waitStarted).TotalSeconds) + ' s so far)')
    Start-Sleep -Seconds 30
    $waited++
}
[void][IO.Directory]::CreateDirectory($OutDir)
$tmp = Join-Path $OutDir 'tmp'; [void][IO.Directory]::CreateDirectory($tmp)
$prior = Join-Path $OutDir 'prior-logs'; [void][IO.Directory]::CreateDirectory($prior)
foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT')) {
    $source = Join-Path $bin $name
    if (Test-Path -LiteralPath $source) { Move-Item -LiteralPath $source -Destination (Join-Path $prior $name) }
}
$shotDir = Join-Path $Stage 'ScreenShots'
[void][IO.Directory]::CreateDirectory($shotDir)
$beforeShots = @(Get-ChildItem -LiteralPath $shotDir -Filter '*.png' -ErrorAction SilentlyContinue | ForEach-Object Name)
$beforeDumps = @(Get-ChildItem -LiteralPath $bin -Filter '*.dmp' -ErrorAction SilentlyContinue | ForEach-Object Name)
$arguments = '-fl -cys-gl-login-smoke'
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = $game; $info.Arguments = $arguments; $info.WorkingDirectory = $bin
$info.UseShellExecute = $false; $info.CreateNoWindow = $true
$info.EnvironmentVariables['CYS_GL_LOGIN_SMOKE'] = '1'
$info.EnvironmentVariables['CYS_WSL_LOGIN_TEST'] = '1'
$info.EnvironmentVariables['CYS_CREATE_ROLE_SMOKE'] = 'World'
if ($EquipCraftProbe) { $info.EnvironmentVariables['CYS_EQUIPCRAFT_LIVE'] = '1' }
if ($MountFlightProbe) { $info.EnvironmentVariables['CYS_MOUNT_FLIGHT_LIVE'] = '1' }
if ($WuhunPreviewProbe) { $info.EnvironmentVariables['CYS_WUHUN_PREVIEW_LIVE'] = '1' }
if ($WuhunAppearanceProbe) { $info.EnvironmentVariables['CYS_WUHUN_APPEARANCE_LIVE'] = '1' }
if ($WuhunReloginProbe) { $info.EnvironmentVariables['CYS_WUHUN_APPEARANCE_LIVE'] = '2' }
if ($WuhunAppearanceProbe -or $WuhunReloginProbe) { $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '260000' }
if ($SmartEquipProbe) { $info.EnvironmentVariables['CYS_SMART_EQUIP_LIVE'] = [string]$SmartEquipProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($CurrencyProbe) { $info.EnvironmentVariables['CYS_CURRENCY_LIVE'] = [string]$CurrencyProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($RuntimePolishProbe) { $info.EnvironmentVariables['CYS_RUNTIME_POLISH_LIVE'] = [string]$RuntimePolishProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000'; $info.EnvironmentVariables['CYS_PREVIEW_FX_METRICS'] = '1' }
if ($PartyGuildProbe) { $info.EnvironmentVariables['CYS_PARTY_GUILD_LIVE'] = [string]$PartyGuildProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($CommunityProbe) { $info.EnvironmentVariables['CYS_COMMUNITY_LIVE'] = [string]$CommunityProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($GameplayAuditProbe) { $info.EnvironmentVariables['CYS_GAMEPLAY_AUDIT_LIVE'] = [string]$GameplayAuditProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($PowerSystemsProbe) { $info.EnvironmentVariables['CYS_POWER_SYSTEMS_LIVE'] = [string]$PowerSystemsProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($PlayerShopProbe) { $info.EnvironmentVariables['CYS_PLAYER_SHOP_PROBE'] = [string]$PlayerShopProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($SoulReforgeProbe) { $info.EnvironmentVariables['CYS_SOUL_REFORGE_PROBE'] = [string]$SoulReforgeProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '300000' }
if ($DualSoulsProbe) { $info.EnvironmentVariables['CYS_DUAL_SOULS_LIVE'] = [string]$DualSoulsProbe; $info.EnvironmentVariables['CYS_WORLD_SMOKE_TIMEOUT_MS'] = '420000' }
$info.EnvironmentVariables['CYS_BOT_PWD'] = $secret
# maps-instance 17/09: CysGlLoginSmoke.h:47-58 doc hai bien nay; khong dat thi luon la test00/CYTest00.
if (-not $Role) { $Role = 'CYTest' + $Account.Substring($Account.Length - 2) }
$info.EnvironmentVariables['CYS_BOT_ACCOUNT'] = $Account
$info.EnvironmentVariables['CYS_BOT_ROLE'] = $Role
foreach ($name in @('CYS_WORLD_REPLAY', 'CYS_WORLD_REPLAY_AUTO')) { $info.EnvironmentVariables.Remove($name) }
$info.EnvironmentVariables['TEMP'] = $tmp; $info.EnvironmentVariables['TMP'] = $tmp
$started = Get-Date; $connections = New-Object 'System.Collections.Generic.List[object]'
$responding = New-Object 'System.Collections.Generic.List[object]'
$terminated = $false; $process = $null; $launchError = $null; $exitCode = $null; $processId = $null; $loginFailed = $false
try {
    $process = New-Object Diagnostics.Process; $process.StartInfo = $info
    if (-not $process.Start()) { throw 'Could not start Game.exe.' }
    $info.EnvironmentVariables.Remove('CYS_BOT_PWD')
    $processId = $process.Id
    $clientLogLive = Join-Path $bin 'WXClient.log'
    while (-not $process.HasExited -and (Get-Date) -lt $started.AddSeconds($Seconds)) {
        Start-Sleep -Seconds 1; $process.Refresh()
        if ($process.HasExited) { break }
        $responding.Add([ordered]@{t = [int]((Get-Date) - $started).TotalSeconds; cpu = [math]::Round($process.TotalProcessorTime.TotalSeconds, 2); responding = $process.Responding})
        foreach ($socket in @(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue)) {
            $remote = [string]$socket.RemoteAddress
            $connections.Add([ordered]@{t = [int]((Get-Date) - $started).TotalSeconds; remote = $remote; port = $socket.RemotePort; state = [string]$socket.State})
            if ($remote -notin @('0.0.0.0', '::') -and ($remote -ne '127.0.0.1' -or $socket.RemotePort -notin @($loginPort, $gamePort))) {
                throw 'Unexpected connection from the isolated Game.'
            }
        }
        # One login attempt only: a rejected login ends the run at once (wrong passwords count per host).
        if (Test-Path -LiteralPath $clientLogLive) {
            $tail = ''
            try { $tail = ReadLiveLog $clientLogLive } catch { $tail = '' }
            if ($tail -match 'CYS WSL login: (failed|profile rejected|start rejected)') { $loginFailed = $true; break }
        }
    }
    if (-not $process.HasExited -and $loginFailed) { Start-Sleep -Seconds 2; $process.Refresh() }
    if ($process.HasExited) { $exitCode = $process.ExitCode }
} catch { $launchError = $_.Exception.Message } finally {
    $info.EnvironmentVariables.Remove('CYS_BOT_PWD')
    if ($process -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit(); $terminated = $true }
    $elapsed = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
    if ($process) { try { if ($null -eq $exitCode -and $process.HasExited) { $exitCode = $process.ExitCode } } catch {} ; $process.Dispose() }
    foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT')) {
        $path = Join-Path $bin $name
        if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $OutDir }
    }
    $shots = @(Get-ChildItem -LiteralPath $shotDir -Filter '*.png' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $beforeShots })
    $records = @(foreach ($shot in $shots) {
        Copy-Item -LiteralPath $shot.FullName -Destination $OutDir
        [ordered]@{name = $shot.Name; sha256 = (Hash $shot.FullName); bytes = $shot.Length}
    })
    $dumps = @(Get-ChildItem -LiteralPath $bin -Filter '*.dmp' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $beforeDumps } | ForEach-Object Name)
}
# ---- evidence
$checks = [ordered]@{}
$world = @(); $live = @(); $all = @()
$clientLog = Join-Path $OutDir 'WXClient.log'
if (Test-Path -LiteralPath $clientLog) {
    $all = [IO.File]::ReadAllLines($clientLog)
    $world = @($all | Where-Object { $_ -match 'CYS world:' })
    $live = @($all | Where-Object { $_ -match 'CYS live:' })
}
# The password must not appear in any captured log.
$leak = $false
foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT', 'run.json')) {
    $path = Join-Path $OutDir $name
    if (Test-Path -LiteralPath $path) { if (([IO.File]::ReadAllText($path)).Contains($secret)) { $leak = $true } }
}
$secret = $null
$foreign = @($connections | Where-Object { $_.remote -notin @('0.0.0.0', '::') })
$checks.login_not_rejected = (-not $loginFailed) -and (@($all | Where-Object { $_ -match 'CYS WSL login: (failed|profile rejected|start rejected)' }).Count -eq 0)
$checks.one_login_submit = (@($all | Where-Object { $_ -match 'CYS GL smoke: submitted once (through GL TextAccepted|natively)' }).Count -eq 1)
$checks.authenticated = (@($all | Where-Object { $_ -match 'CYS WSL login: authenticated' }).Count -eq 1)
# CYS-XINFA 17/09: the character name follows the run's role (-Role / CYS_BOT_ROLE, CysGlLoginSmoke.h smokeRole()),
# not the hardcoded CYTest00 - otherwise every run on another test account fails this gate for the wrong reason.
$roleName = if ($Role) { $Role } elseif ($env:CYS_BOT_ROLE) { $env:CYS_BOT_ROLE } else { 'CYTest00' }
$checks.character_selected = (@($all | Where-Object { $_ -match ('CYS create smoke: typed server list count=1 name=' + [regex]::Escape($roleName)) }).Count -eq 1)
$checks.enter_clicked = (@($all | Where-Object { $_ -match 'CYS world smoke: clicked the enter-game button once' }).Count -eq 1)
# The server decides the scene (the saved position of CYTest00: scene 2 Dai Ly until cs3a, scene 73 Vo Luong Son since
# cs3a2-maps on 14/09 22:xx); the check only requires GCConnect and GCEnterScene to agree on one scene id.
$connectLine = @($world | Where-Object { $_ -match 'GCConnect generation=\d+ scene=(\d+)' } | Select-Object -First 1)
$liveScene = ''
if ($connectLine.Count -eq 1 -and $connectLine[0] -match 'scene=(\d+)') { $liveScene = $Matches[1] }
$checks.gcconnect = ($liveScene -ne '')
$checks.gcenterscene_same_scene = ($liveScene -ne '') -and (@($world | Where-Object { $_ -match ('GCEnterScene scene=' + $liveScene + ' ') }).Count -ge 1)
$checks.stats_in_world_with_objects = (@($world | Where-Object { $_ -match 'stats phase=in_world .*objects=(\d+)' -and [int]$Matches[1] -gt 0 }).Count -ge 1)
# The navmesh of the entered scene (SceneDefineEx of the server's scene id: dali_new_320.path for 2, wuliang.path for 73)
$checks.navmesh_loaded = (@($all | Where-Object { $_ -match 'CYS: navmesh \S+\.path points=\d+ .*invariant_violations=0' }).Count -ge 1)
# CysWorldReplay completes its initial triangle with this measurement before
# handing control to optional probes. Quest travel reuses click IDs 1/2/3.
# Scope navigation checks to that complete initial replay, never to later probes.
$initialReplay = New-Object System.Collections.ArrayList
$initialReplayComplete = $false
foreach ($line in $all) {
    [void]$initialReplay.Add($line)
    if ($line -match 'CYS live: position before clicks ') {
        $initialReplayComplete = $true
        break
    }
}
$checks.three_ground_clicks = $initialReplayComplete
foreach ($clickIndex in 1..3) {
    $clickRows = @($initialReplay | Where-Object { $_ -match ('CYS live: ground click ' + $clickIndex + ' ') })
    if ($clickRows.Count -ne 1 -or $clickRows[0] -notmatch 'reachable=1 .*limit_move=0') {
        $checks.three_ground_clicks = $false
    }
}
$checks.click_move_lines = (@($initialReplay | Where-Object { $_ -match 'CYS: click-move ' }).Count -ge 3)
# CYS-PATHLEN 17/09: do QUANG DUONG DI DUOC, khong phai do doi cho rong. Ba cu bam di mot vong tam
# giac roi ve gan cho cu, nen "delta" co the < 2.0 du nhan vat da di that - hai luot do duoc 1,25 va
# 1,88 nen bi bao truot oan, va cac luot cu chi PASS nho may man cua duong di. Toa do dau moi dong
# "click-move" la cho nhan vat DANG DUNG luc bam, nen cong do dai tung chang moi la thuoc do dung.
$movePoints = New-Object System.Collections.ArrayList
foreach ($line in $initialReplay) {
    if ($line -match 'CYS: click-move \((-?[\d.]+),(-?[\d.]+)\)->\(') {
        [void]$movePoints.Add(@([double]$Matches[1], [double]$Matches[2]))
    }
}
$delta = @($initialReplay | Where-Object { $_ -match 'position before clicks .*\(delta (-?[\d.]+),(-?[\d.]+)\)' } | Select-Object -Last 1)
if ($delta.Count -eq 1 -and $delta[0] -match 'after (-?[\d.]+),(-?[\d.]+) \(delta') {
    [void]$movePoints.Add(@([double]$Matches[1], [double]$Matches[2]))
}
$pathLength = 0.0
for ($i = 1; $i -lt $movePoints.Count; $i++) {
    $dx = $movePoints[$i][0] - $movePoints[$i - 1][0]
    $dz = $movePoints[$i][1] - $movePoints[$i - 1][1]
    $pathLength += [math]::Sqrt(($dx * $dx) + ($dz * $dz))
}
$checks.position_changed = (($movePoints.Count -ge 2) -and ($pathLength -ge 2.0))
# Leaving: the CY system menu (Operation_QuitGame) when Alt+F4 opens it, else the direct quit request; both end in CGAskQuit
$checks.quit_requested = (@($all | Where-Object { $_ -match 'CYS world smoke: (clicked the quit item|the system menu did not open; posting the quit request directly)' }).Count -eq 1)
$checks.quit_complete_flag0_decode0 = (@($world | Where-Object { $_ -match 'terminal=quit_complete .*quit_flag=0 .*decode_failures=0' }).Count -eq 1)
$checks.no_handler_errors = (@($world | Where-Object { $_ -match 'handler exception|send refused|game session rejected|scene load failed|quit wait expired|terminal=error' }).Count -eq 0)
$checks.no_dump = (@($dumps).Count -eq 0)
$checks.world_shots = (@($records | Where-Object { $_.name -match 'cys-live-.*(move-before|move-after|cam-)' }).Count -ge 3)
$checks.only_private_server_sockets = (@($foreign | Where-Object { $_.remote -ne '127.0.0.1' -or $_.port -notin @($loginPort, $gamePort) }).Count -eq 0)
$checks.password_absent_from_logs = (-not $leak)
$checks.finished_in_time = (-not $terminated)
if ($WuhunAppearanceProbe -or $WuhunReloginProbe) {
    $marker = if ($WuhunReloginProbe) { 'RELOGIN' } else { 'RESULT' }
    $checks.wuhun_appearance_complete = (@($all | Where-Object { $_ -match ('CYS-WUHUN-APPEARANCE: ' + $marker + ' errors=0') }).Count -eq 1)
    $checks.wuhun_no_errors = (@($all | Where-Object { $_ -match 'CYS-WUHUN-APPEARANCE: FAIL|CYS Lua failure env=Wuhun_Env' }).Count -eq 0)
}
$passed = -not ($checks.Values -contains $false)
if ($DualSoulsProbe) {
    $marker = if ($DualSoulsProbe -eq 2) { 'RELOGIN' } else { 'RESULT' }
    $checks.dual_souls_complete = (@($all | Where-Object { $_ -match ('CYS-DUAL-SOULS: ' + $marker + ' errors=0') }).Count -eq 1)
    $checks.dual_souls_no_errors = (@($all | Where-Object { $_ -match 'CYS-DUAL-SOULS: FAIL|CYS Lua failure env=CysDualSouls_Env' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($SmartEquipProbe) {
    $marker = if ($SmartEquipProbe -eq 2) { 'RELOGIN' } else { 'RESULT' }
    $checks.smart_equip_complete = (@($all | Where-Object { $_ -match ('CYS-SMART-EQUIP: ' + $marker + ' errors=0') }).Count -eq 1)
    $checks.smart_equip_no_errors = (@($all | Where-Object { $_ -match 'CYS-SMART-EQUIP: FAIL' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($CurrencyProbe) {
    $checks.currency_complete = (@($all | Where-Object { $_ -match 'CYS-CURRENCY: RESULT errors=0' }).Count -eq 1)
    $checks.currency_no_errors = (@($all | Where-Object { $_ -match 'CYS-CURRENCY: FAIL' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($RuntimePolishProbe) {
    $checks.runtime_polish_complete = (@($all | Where-Object { $_ -match 'CYS-RUNTIME-POLISH: RESULT mode=\d+ errors=0' }).Count -eq 1)
    $checks.runtime_polish_no_errors = (@($all | Where-Object { $_ -match 'CYS-RUNTIME-POLISH: FAIL' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($PartyGuildProbe) {
    $checks.party_guild_complete = (@($all | Where-Object { $_ -match 'CYS-PARTY-GUILD: RESULT mode=\d+ errors=0' }).Count -eq 1)
    $checks.party_guild_no_errors = (@($all | Where-Object { $_ -match 'CYS-PARTY-GUILD: FAIL|CYS Lua failure' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($CommunityProbe) {
    $checks.community_complete = (@($all | Where-Object { $_ -match 'CYS-COMMUNITY: RESULT mode=\d+ errors=0' }).Count -eq 1)
    $checks.community_no_errors = (@($all | Where-Object { $_ -match 'CYS-COMMUNITY: FAIL|CYS Lua failure' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($GameplayAuditProbe) {
    $checks.gameplay_audit_complete = (@($all | Where-Object { $_ -match 'CYS-GAMEPLAY-AUDIT: RESULT mode=\d+ errors=0' }).Count -eq 1)
    $checks.gameplay_audit_no_errors = (@($all | Where-Object { $_ -match 'CYS-GAMEPLAY-AUDIT: FAIL' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($PlayerShopProbe) {
    $checks.player_shop_complete = (@($all | Where-Object { $_ -match ('CYS-SHOP-PROBE: RESULT mode=' + $PlayerShopProbe + ' errors=0') }).Count -eq 1)
    $checks.player_shop_no_errors = (@($all | Where-Object { $_ -match 'CYS-SHOP-PROBE: FAIL|CYS Lua failure' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($SoulReforgeProbe) {
    $checks.soul_reforge_complete = (@($all | Where-Object { $_ -match ('CYS-SOUL-REFORGE: RESULT mode=' + $SoulReforgeProbe + ' errors=0') }).Count -eq 1)
    $checks.soul_reforge_no_errors = (@($all | Where-Object { $_ -match 'CYS-SOUL-REFORGE: FAIL|CYS Lua failure' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($PowerSystemsProbe) {
    $checks.power_systems_complete = (@($all | Where-Object { $_ -match ('CYS-POWER-SYSTEMS: RESULT mode=' + $PowerSystemsProbe + ' errors=0') }).Count -eq 1)
    $checks.power_systems_no_errors = (@($all | Where-Object { $_ -match 'CYS-POWER-SYSTEMS: FAIL|CYS Lua failure' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
if ($env:CYS_QUEST_LIVE -eq '1') {
    $checks.quest_complete = (@($all | Where-Object { $_ -match 'CYS quest-live: PASS quest live script passed=[1-9][0-9]* failed=0' }).Count -eq 1)
    $checks.quest_no_errors = (@($all | Where-Object { $_ -match 'CYS quest-live: (FAIL|PARTIAL)|CYS Lua failure' }).Count -eq 0)
    $passed = -not ($checks.Values -contains $false)
}
$run = [ordered]@{stage = $Stage; command = $game + ' ' + $arguments; cwd = $bin; account = $Account
    env = [ordered]@{CYS_GL_LOGIN_SMOKE = '1'; CYS_WSL_LOGIN_TEST = '1'; CYS_CREATE_ROLE_SMOKE = 'World'; CYS_BOT_PWD = '<from ' + $AccountFile + ', child process only>'; CYS_WARDROBE_LIVE = $env:CYS_WARDROBE_LIVE; CYS_HJ_START = $env:CYS_HJ_START; CYS_HJ_COUNT = $env:CYS_HJ_COUNT; CYS_HJ_AFTER_MODE = $env:CYS_HJ_AFTER_MODE}
    server = [ordered]@{login = ($loginHost + ':' + $loginPort); game_port = $gamePort; profile = $manifest.wsl_test.profile}
    waited_for_other_game_polls = $waited; started = $started.ToString('o'); finished = (Get-Date).ToString('o'); elapsed_s = $elapsed; seconds_limit = $Seconds
    path_length = [math]::Round($pathLength, 2); path_points = $movePoints.Count   # CYS-PATHLEN: so do that cua position_changed
    pid = $processId; exit_code = $exitCode; terminated_after_timeout = $terminated; launch_error = $launchError; login_failed = $loginFailed
    game_sha256 = (Hash $game); stage_manifest_sha256 = (Hash (Join-Path $bin 'game_data_stage.json'))
    sockets = $connections.ToArray(); foreign_sockets = $foreign.Count; dumps = $dumps; shots = $records; samples = $responding.ToArray()
    world_lines = $world; live_lines = $live; checks = $checks; passed = $passed}
[IO.File]::WriteAllText((Join-Path $OutDir 'run.json'), ($run | ConvertTo-Json -Depth 7), (New-Object Text.UTF8Encoding($false)))
Write-Host ('exit=' + $exitCode + ' elapsed=' + $elapsed + 's killed=' + $terminated + ' world_lines=' + $world.Count + ' live_lines=' + $live.Count + ' shots=' + $records.Count)
foreach ($key in $checks.Keys) { Write-Host (('{0,-32} {1}' -f $key, $(if ($checks[$key]) { 'PASS' } else { 'FAIL' }))) }
if ($loginFailed) { Write-Host 'LOGIN REJECTED - do NOT retry this run.' }
if ($launchError) { throw $launchError }
if (-not $passed) { throw ('World GUI live run FAILED; see ' + $OutDir) }
Write-Host ('PASS world GUI live; evidence in ' + $OutDir)
