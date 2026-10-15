# CY-Source Tools/game/run_world_replay.ps1 - offline world replay of a Tools/game/stage_game.py stage.
# Starts Bin64\Game.exe -fl with CYS_WORLD_REPLAY=<PGWORLD1 fixture>: no server, no socket; the client logs in
# with any account on the replay stream, enters with CYTest00 (GUID 200001), receives the recorded 741 GC frames,
# captures PNGs and closes itself once the replay has finished (CGAskQuit on shutdown). The run is bounded by
# -Seconds (default 90); a longer run is killed and reported as a failure. Evidence (logs, PNGs, run.json) goes
# to -OutDir. Single-instance rule: Game.exe runs only once per machine, so the script waits (up to -WaitMinutes,
# polling every 30 s) until no Game.exe is alive and never touches a foreign Game process.
# Only the Game process started here is ever stopped. ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$Stage,
    [Parameter(Mandatory=$true)][string]$Fixture,
    [Parameter(Mandatory=$true)][string]$OutDir,
    [ValidateRange(30,300)][int]$Seconds = 90,
    [ValidateRange(0,5000)][int]$GapMs = 20,
    [ValidateRange(0,120000)][int]$DwellMs = 12000,
    [ValidateRange(1,30)][int]$WaitMinutes = 10,
    [switch]$Move,
    [switch]$Camera,
    [switch]$Core
)
$ErrorActionPreference = 'Stop'
function Hash([string]$path) { return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Full([string]$path) { return [IO.Path]::GetFullPath($path).TrimEnd('\') }
$Stage = Full $Stage
$Fixture = Full $Fixture
$OutDir = Full $OutDir
if ($Stage -notmatch '\\Build\\') { throw 'Stage must lie below a Build folder.' }
if ($OutDir -notmatch '\\Build\\Logs\\') { throw 'OutDir must lie below Build\Logs.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new -OutDir; prior evidence is preserved.' }
if (-not (Test-Path -LiteralPath $Fixture)) { throw ('Fixture not found: ' + $Fixture) }
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
$fixtureBytes = [IO.File]::ReadAllBytes($Fixture)
if ($fixtureBytes.Length -lt 8 -or [Text.Encoding]::ASCII.GetString($fixtureBytes, 0, 8) -ne 'PGWORLD1') { throw 'Fixture is not PGWORLD1.' }

# ---- single instance: wait until no Game.exe is alive (never kill a foreign one)
$waitStarted = Get-Date
$waited = 0
while (@(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -gt 0) {
    if (((Get-Date) - $waitStarted).TotalMinutes -ge $WaitMinutes) { throw ('Another Game.exe stayed alive for ' + $WaitMinutes + ' minutes; not starting (single-instance rule).') }
    Write-Host ('Another Game.exe is alive; waiting 30 s (' + [int](((Get-Date) - $waitStarted).TotalSeconds) + ' s so far)')
    Start-Sleep -Seconds 30
    $waited++
}

[void][IO.Directory]::CreateDirectory($OutDir)
$tmp = Join-Path $OutDir 'tmp'; [void][IO.Directory]::CreateDirectory($tmp)
# WXClient.log is opened in append mode: move every prior log away before the launch.
$prior = Join-Path $OutDir 'prior-logs'; [void][IO.Directory]::CreateDirectory($prior)
foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT')) {
    $source = Join-Path $bin $name
    if (Test-Path -LiteralPath $source) { Move-Item -LiteralPath $source -Destination (Join-Path $prior $name) }
}
$shotDir = Join-Path $Stage 'ScreenShots'
[void][IO.Directory]::CreateDirectory($shotDir)
$beforeShots = @(Get-ChildItem -LiteralPath $shotDir -Filter 'cys-replay-*.png' -ErrorAction SilentlyContinue | ForEach-Object Name)
$beforeDumps = @(Get-ChildItem -LiteralPath $bin -Filter '*.dmp' -ErrorAction SilentlyContinue | ForEach-Object Name)

$arguments = '-fl'
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = $game; $info.Arguments = $arguments; $info.WorkingDirectory = $bin
$info.UseShellExecute = $false; $info.CreateNoWindow = $true
$info.EnvironmentVariables['CYS_WORLD_REPLAY'] = $Fixture
$info.EnvironmentVariables['CYS_WORLD_REPLAY_GAP_MS'] = [string]$GapMs
$info.EnvironmentVariables['CYS_WORLD_REPLAY_DWELL_MS'] = [string]$DwellMs
$info.EnvironmentVariables['CYS_WORLD_REPLAY_DEADLINE_MS'] = [string]([Math]::Max(10000, ($Seconds - 15) * 1000))
$info.EnvironmentVariables['CYS_WORLD_REPLAY_AUTO'] = '1'
if ($Core) { $info.EnvironmentVariables['CYS_WORLD_REPLAY_CORE'] = '1' } # CYS-CORE: synthetic responder + core-loop driver
foreach ($name in @('CYS_BOT_PWD', 'CYS_WSL_LOGIN_TEST', 'CYS_GL_LOGIN_SMOKE', 'CYS_CREATE_ROLE_SMOKE')) { $info.EnvironmentVariables.Remove($name) }
$info.EnvironmentVariables['TEMP'] = $tmp; $info.EnvironmentVariables['TMP'] = $tmp
$started = Get-Date; $connections = New-Object 'System.Collections.Generic.List[object]'
$terminated = $false; $process = $null; $launchError = $null; $exitCode = $null; $processId = $null
$responding = New-Object 'System.Collections.Generic.List[object]'
try {
    $process = New-Object Diagnostics.Process; $process.StartInfo = $info
    if (-not $process.Start()) { throw 'Could not start Game.exe.' }
    $processId = $process.Id
    while (-not $process.HasExited -and (Get-Date) -lt $started.AddSeconds($Seconds)) {
        Start-Sleep -Seconds 1; $process.Refresh()
        if ($process.HasExited) { break }
        $responding.Add([ordered]@{t = [int]((Get-Date) - $started).TotalSeconds; cpu = [math]::Round($process.TotalProcessorTime.TotalSeconds, 2); responding = $process.Responding})
        foreach ($socket in @(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue)) {
            $connections.Add([ordered]@{t = [int]((Get-Date) - $started).TotalSeconds; remote = [string]$socket.RemoteAddress; port = $socket.RemotePort; state = [string]$socket.State})
        }
    }
    if (-not $process.HasExited) { $process.Refresh() }
    if ($process.HasExited) { $exitCode = $process.ExitCode }
} catch { $launchError = $_.Exception.Message } finally {
    if ($process -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit(); $terminated = $true }
    $elapsed = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
    if ($process) { try { if ($null -eq $exitCode -and $process.HasExited) { $exitCode = $process.ExitCode } } catch {} ; $process.Dispose() }
    foreach ($name in @('WXClient.log', 'WXRender.log', 'UISystem.log', 'Ogre.log', 'WXC_SML.TXT')) {
        $path = Join-Path $bin $name
        if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $OutDir }
    }
    $shots = @(Get-ChildItem -LiteralPath $shotDir -Filter 'cys-replay-*.png' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $beforeShots })
    $records = @(foreach ($shot in $shots) {
        Copy-Item -LiteralPath $shot.FullName -Destination $OutDir
        [ordered]@{name = $shot.Name; sha256 = (Hash $shot.FullName); bytes = $shot.Length}
    })
    $dumps = @(Get-ChildItem -LiteralPath $bin -Filter '*.dmp' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $beforeDumps } | ForEach-Object Name)
}

# ---- evidence: the CYS world / CYS replay lines of WXClient.log
$checks = [ordered]@{}
$world = @(); $replay = @()
$clientLog = Join-Path $OutDir 'WXClient.log'
if (Test-Path -LiteralPath $clientLog) {
    $lines = [IO.File]::ReadAllLines($clientLog)
    $world = @($lines | Where-Object { $_ -match 'CYS world:' })
    $replay = @($lines | Where-Object { $_ -match 'CYS replay:' })
}
$foreign = @($connections | Where-Object { $_.remote -notin @('0.0.0.0', '::') })
$checks.exit_code_zero = ($exitCode -eq 0)
$checks.finished_in_time = (-not $terminated) -and ($elapsed -le $Seconds)
$checks.no_socket = ($foreign.Count -eq 0)
$checks.no_dump = (@($dumps).Count -eq 0)
$checks.replay_enabled = (@($replay | Where-Object { $_ -match 'CYS replay: enabled fixture=' }).Count -eq 1)
$checks.gcconnect_scene2 = (@($world | Where-Object { $_ -match 'GCConnect generation=1 scene=2' }).Count -eq 1)
$checks.gcenterscene_scene2 = (@($world | Where-Object { $_ -match 'GCEnterScene scene=2 ' }).Count -eq 1)
$statsLines = @($world | Where-Object { $_ -match 'stats phase=in_world .*objects=(\d+)' -and [int]$Matches[1] -gt 0 })
$checks.stats_in_world_with_objects = ($statsLines.Count -ge 1)
$terminalLines = @($world | Where-Object { $_ -match 'terminal=quit_complete .*quit_flag=0 .*decode_failures=0' })
$checks.quit_complete_flag0_decode0 = ($terminalLines.Count -eq 1)
$checks.no_handler_errors = (@($world | Where-Object { $_ -match 'handler exception|send refused|game session rejected|scene load failed|quit wait expired|terminal=error' }).Count -eq 0)
$checks.world_shots = (@($records | Where-Object { $_.name -match 'world' }).Count -ge 1)
if ($Move) {
    $all = @()
    if (Test-Path -LiteralPath $clientLog) { $all = [IO.File]::ReadAllLines($clientLog) }
    # CYS-CY (cs2-world): the navmesh file name comes from SceneDefineEx (DBC line "SceneDefineEx scene 2 resolved ...
    # path=<file>"), not a fixed dali.path: CanonicalCY maps scene 2 to dali_new_320.path, Canonical GL to dali.path.
    $pathLine = @($all | Where-Object { $_ -match 'DBC: SceneDefineEx scene 2 resolved .*path=(\S+) ' } | Select-Object -First 1)
    $navFile = 'dali.path'
    if ($pathLine.Count -eq 1 -and $pathLine[0] -match 'path=(\S+) ') { $navFile = $Matches[1] }
    $checks.scene_path_from_scenedefineex = ($pathLine.Count -eq 1)
    $checks.navmesh_loaded = (@($all | Where-Object { $_ -match ('CYS: navmesh ' + [regex]::Escape($navFile) + ' points=') }).Count -ge 1)
    $checks.actionset_b_tables = (@($all | Where-Object { $_ -match 'CYS action-set: B tables loaded' }).Count -ge 1)
    $checks.detail_attrib_limit_move = (@($world | Where-Object { $_ -match 'GCDetailAttrib obj=\d+ self=1 .*limit_move=0' }).Count -ge 1)
    $checks.three_ground_clicks = (@($replay | Where-Object { $_ -match 'ground click \d .*reachable=1 .*limit_move=0' }).Count -eq 3)
    $checks.click_move_lines = (@($all | Where-Object { $_ -match 'CYS: click-move ' }).Count -ge 3)
    $counter = @($replay | Where-Object { $_ -match 'CYS replay: counters .*moves=(\d+) move_echoes=(\d+)' } | Select-Object -Last 1)
    $checks.cgcharmove_sent_and_echoed = $false
    if ($counter.Count -eq 1 -and $counter[0] -match 'moves=(\d+) move_echoes=(\d+)') { $checks.cgcharmove_sent_and_echoed = ([int]$Matches[1] -ge 3 -and [int]$Matches[2] -ge 3) }
    # CYS-PATHLEN 17/09: do QUANG DUONG DI DUOC, khong phai do doi cho rong - xem chu thich cung ten
    # trong run_world_gui_live.ps1. Ba cu bam di mot vong tam giac roi ve gan cho cu nen "delta" nho
    # hon nguong du nhan vat da di that; toa do dau moi dong "click-move" la cho dang dung luc bam.
    $movePoints = New-Object System.Collections.ArrayList
    foreach ($line in $all) {
        if ($line -match 'CYS: click-move \((-?[\d.]+),(-?[\d.]+)\)->\(') {
            [void]$movePoints.Add(@([double]$Matches[1], [double]$Matches[2]))
        }
    }
    $delta = @($replay | Where-Object { $_ -match 'position before clicks .*\(delta (-?[\d.]+),(-?[\d.]+)\)' } | Select-Object -Last 1)
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
    $checks.move_shots = (@($records | Where-Object { $_.name -match 'move-before|move-after' }).Count -eq 2)
}
if ($Camera) {
    # camera3d: CY 3.71 free 3D camera script of CysWorldReplay (classic -> free low -> yaw 90 -> zoom far -> clicks at a 3D angle)
    $cam = @()
    if (Test-Path -LiteralPath $clientLog) { $cam = @([IO.File]::ReadAllLines($clientLog) | Where-Object { $_ -match 'CYS camera:' }) }
    $checks.camera_classic_shot = (@($cam | Where-Object { $_ -match 'shot=cam-classic mode=classic ' }).Count -eq 1)
    $low = @($cam | Where-Object { $_ -match 'shot=cam-sky-low mode=free3d pitch_deg=(-?[\d.]+) ' } | Select-Object -First 1)
    $checks.camera_free_low_pitch = $false
    if ($low.Count -eq 1 -and $low[0] -match 'pitch_deg=(-?[\d.]+) ') { $checks.camera_free_low_pitch = ([double]$Matches[1] -le 10.0) }
    $checks.camera_yaw90_shot = (@($cam | Where-Object { $_ -match 'shot=cam-yaw90 mode=free3d ' }).Count -eq 1)
    $checks.camera_zoom_far_shot = (@($cam | Where-Object { $_ -match 'shot=cam-zoom-far mode=free3d ' }).Count -eq 1)
    $checks.camera_click_pick = (@($cam | Where-Object { $_ -match 'click-pick \d screen=\(\d+,\d+\) .*error_m=0\.\d+ free3d=1 ' }).Count -ge 1)
    $checks.camera_move_running_free3d = (@($cam | Where-Object { $_ -match 'shot=move-running mode=free3d ' }).Count -eq 1)
    $checks.camera_shots = (@($records | Where-Object { $_.name -match 'cam-sky-low|cam-yaw90|cam-zoom-far' }).Count -eq 3)
}
if ($Core) {
    # CYS-CORE: core loop on the synthetic responder (CYS_WORLD_REPLAY_CORE=1): target, 3 skills, death + drop box,
    # loot window, pick, chat echo, bag list; lines "CYS core:" come from the ported handlers, "CYS replay: core" from the driver.
    $coreLines = @()
    if (Test-Path -LiteralPath $clientLog) { $coreLines = @([IO.File]::ReadAllLines($clientLog) | Where-Object { $_ -match 'CYS core:' }) }
    $checks.core_target_locked = (@($replay | Where-Object { $_ -match 'core target=\d+ ' }).Count -eq 1)
    $checks.core_three_skills = (@($replay | Where-Object { $_ -match 'core CGCharUseSkill \d skill=0 target=' }).Count -eq 3)
    $checks.core_skill_list = (@($coreLines | Where-Object { $_ -match 'GCDetailSkillList skills=1' }).Count -ge 1)
    $checks.core_damage_lines = (@($coreLines | Where-Object { $_ -match 'GCDetailHealsAndDamages receiver=\d+ sender=\d+ hp=-\d+' }).Count -eq 3)
    $checks.core_drop_box = (@($coreLines | Where-Object { $_ -match 'GCNewItemBox obj=\d+ owner=200001 monster=\d+ type=-1' }).Count -eq 1)
    $checks.core_loot_list = (@($coreLines | Where-Object { $_ -match 'GCBoxItemList box=\d+ items=1 shown=1' }).Count -eq 1)
    $checks.core_pick_ok = (@($coreLines | Where-Object { $_ -match 'GCPickResult box=\d+ result=0 ' }).Count -eq 1)
    $checks.core_item_info = (@($coreLines | Where-Object { $_ -match 'GCItemInfo bag_index=\d+ item=30001011' }).Count -eq 1)
    $checks.core_chat_echo = (@($coreLines | Where-Object { $_ -match 'GCChat type=0 from=CYTest00 ' }).Count -eq 1)
    $checks.core_bag_list = (@($coreLines | Where-Object { $_ -match 'GCMyBagList items=1 shown=1' }).Count -eq 1)
    # CYS-CYGUI2: with the CY 3.71 GUI the chat frame and the bag/skill windows add their own GCChat/ask round trips
    # (replay-10: chats=14 bag_lists=2 skill_lists=2); the core loop needs AT LEAST the scripted counts.
    $checks.core_done = $false
    $doneLine = @($replay | Where-Object { $_ -match 'core done ' } | Select-Object -Last 1)
    if ($doneLine.Count -eq 1) {
        $need = [ordered]@{ chats = 1; skill_sends = 3; damages = 3; target_lists = 3; item_boxes = 1; box_lists = 1; picks_ok = 1; item_infos = 1; bag_lists = 1; skill_lists = 1; bag_items = 1 }
        $ok = $true
        foreach ($k in $need.Keys) { if (-not ($doneLine[0] -match (' ' + $k + '=(\d+)')) -or [int]$Matches[1] -lt $need[$k]) { $ok = $false } }
        $checks.core_done = $ok
    }
    $checks.core_shots = (@($records | Where-Object { $_.name -match 'core-target|core-hit|core-dead|core-loot|core-chat|core-bag' }).Count -eq 6)
    $checks.core_no_handler_errors = (@($world | Where-Object { $_ -match 'handler exception' }).Count -eq 0)
}
$passed = -not ($checks.Values -contains $false)
$run = [ordered]@{stage = $Stage; fixture = $Fixture; fixture_sha256 = (Hash $Fixture); command = $game + ' ' + $arguments; cwd = $bin
    env = [ordered]@{CYS_WORLD_REPLAY = $Fixture; CYS_WORLD_REPLAY_GAP_MS = $GapMs; CYS_WORLD_REPLAY_DWELL_MS = $DwellMs; CYS_WORLD_REPLAY_DEADLINE_MS = $info.EnvironmentVariables['CYS_WORLD_REPLAY_DEADLINE_MS']; CYS_WORLD_REPLAY_AUTO = '1'}
    waited_for_other_game_polls = $waited; started = $started.ToString('o'); finished = (Get-Date).ToString('o'); elapsed_s = $elapsed; seconds_limit = $Seconds
    pid = $processId; exit_code = $exitCode; terminated_after_timeout = $terminated; launch_error = $launchError
    game_sha256 = (Hash $game); stage_manifest_sha256 = (Hash (Join-Path $bin 'game_data_stage.json'))
    sockets = $connections.ToArray(); foreign_sockets = $foreign.Count; dumps = $dumps; shots = $records; samples = $responding.ToArray()
    world_lines = $world; replay_lines = $replay; checks = $checks; passed = $passed}
[IO.File]::WriteAllText((Join-Path $OutDir 'run.json'), ($run | ConvertTo-Json -Depth 7), (New-Object Text.UTF8Encoding($false)))
Write-Host ('exit=' + $exitCode + ' elapsed=' + $elapsed + 's killed=' + $terminated + ' world_lines=' + $world.Count + ' replay_lines=' + $replay.Count + ' shots=' + $records.Count + ' sockets=' + $foreign.Count)
foreach ($key in $checks.Keys) { Write-Host (('{0,-32} {1}' -f $key, $(if ($checks[$key]) { 'PASS' } else { 'FAIL' }))) }
if ($launchError) { throw $launchError }
if (-not $passed) { throw ('World replay run FAILED; see ' + $OutDir) }
Write-Host ('PASS world replay; evidence in ' + $OutDir)
