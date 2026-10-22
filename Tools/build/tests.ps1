<#
.SYNOPSIS
  Fourth CI step: the unit suites the build already produces but nothing ran. Writes Build\Logs\ci\<sha>\tests.json.
  Exit: 0 every suite OK, 1 a suite failed, 2 setup error.
.DESCRIPTION
  native  - the staged test executables of Build\Client\Bin64 (stage.ps1 copies them from <tree>\bin):
            cys_netcore_tests, cys_world_tests, cys_netbot_tests. They are offline: the gate also asserts
            "live_connections=0" for the bot suite, so CI never speaks to the private server. CysActionSetCheck
            reads the staged data folder (ActionSet/CharModelEx consistency; "result: OK").
            cys_protocol_tests has its own gate in checks.ps1 and is not repeated here.
  ps1     - CYS-TESTPATH 19/09: a self-contained Tests\**\run_*_tests.ps1 that compiles its own translation unit
            with cl.exe and runs it (build.log, tests.log, result.json under <OUTDIR>). This is how a C++ suite
            that is NOT a cmake target gets into the standard path at all: nothing builds it, so stage.ps1 has
            nothing to copy and the native kind cannot see it. rolelist links only Build\cmake\ci-x64\lib\
            cys_protocolgen.lib and needs neither NetCore nor Winsock - do not move it into build_netcore_tests.ps1,
            which force-links the NetCore sources (LNK2019 WinsockStreamFactory / GetAdaptersAddresses).
            Same RESULT gate as native.
  python  - the offline Python suites of Tests\ and Tools\ (schema/DBC table list, fx-audit tools, cluster route
            guard, world snapshot collector, perf patchers and report, create-role mesh/scene/selection, stage_game,
            CY GUI image and Lua unpack).
  Unlike checks.ps1 this step runs from the MAIN checkout, not from Build\ci\wt: several suites read
  Assets\CanonicalCY (git-ignored, so it does not exist inside the CI worktree) through a hard-coded repository
  path. A dirty main tree is not refused but is recorded in tests.json (source_dirty, dirty_files) and printed.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\tests.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\tests.ps1 -Only dbc_schema,netbot
#>
param(
    [string]$Bin = '',
    [string]$Out = '',
    [string[]]$Only = @(),
    [switch]$List,
    [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
if ($Root) { $script:CysRoot = (Resolve-Path -LiteralPath $Root).Path }
$P = Get-CysPaths
if (-not $Bin) { $Bin = $P.Bin64 }
# CYS-TESTRED 19/09: -Out MUST end up absolute, and it is cheaper to make it so than to blame the wrong thing later.
# Every suite is launched as  cmd /d /s /c "<command> >> "<log>" 2>&1"  (ci_common.ps1:145) and the native branch
# prefixes  cd /d <Bin64>  (line 159 below), so cmd opens a RELATIVE log path under Bin64 - a directory PowerShell
# never created, because New-Item made <relative>\<suite> under the PowerShell working directory instead. cmd then
# fails to open the redirection before the test even starts: netcore/world/netbot/actionset report FAIL rc=1 in
# ~0.05 s each with an empty or missing run.log, and nothing was actually run. Branch dbc-id-dup lost a run to this
# (25/29 FAIL, then 29/29 OK on the same tree with an absolute -Out). The ps1/python branches cd to the repository
# root instead, so they usually appear to work, which makes the failure look like "my change broke the native
# suites". Resolving against the repository root keeps both spellings working and removes the trap.
if ($Out -and -not [IO.Path]::IsPathRooted($Out)) { $Out = [IO.Path]::GetFullPath((Join-Path $P.Root $Out)) }
$env:TEMP = Join-Path $P.Root 'Build\ci\tmp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force $env:TEMP | Out-Null

# name | kind | file (relative to the repository root) | argument template.
# <OUTDIR> = a fresh folder of this run for that suite, <BIN> = the staged Bin64, <LUADLL> = staged LuaPlus.dll.
# The _REL forms are the same paths written relative to the repository root: Tools\data\prepare_login_profile.py
# (checked) refuses absolute paths and only allows targets under Build, so the create-role suites need those.
$suites = @(
    @{ name = 'netcore';             kind = 'native'; file = 'cys_netcore_tests.exe';                     args = @() },
    @{ name = 'world';               kind = 'native'; file = 'cys_world_tests.exe';                       args = @() },
    @{ name = 'netbot';              kind = 'native'; file = 'cys_netbot_tests.exe';                      args = @() },
    @{ name = 'actionset';           kind = 'native'; file = 'CysActionSetCheck.exe';                     args = @('--data', '<DATA>', '--report', '<OUTDIR>.tsv') },
    @{ name = 'rolelist';            kind = 'ps1';    file = 'Tests\net\run_login_role_list_tests.ps1';   args = @('-OutDir', '<OUTDIR>') },
    # CYS-TESTPATH 19/09 (dot 2): eleven suites that had a working runner and no caller. Every one of them was RUN
    # before it was added here - see Timeline\handoff\tests-path.md dot 3b for the per-suite rc and count.
    # CYS-TESTRED 19/09: four of the five suites tests-path left out are here now (camp, luaapi, packed_format,
    # widget). None of them was made green by lowering an expectation: each was a stale expectation the product had
    # deliberately moved past, and each rewritten case was re-proved against a deliberately broken build - see
    # Timeline\handoff\tests-red5.md dot 3. `hotkey` is STILL not here on purpose: it does not compile at HEAD and
    # it cannot be fixed without deciding what it should test (dot 4 of the same handoff). Do not add a red suite.
    @{ name = 'dialog_vars';         kind = 'ps1';    file = 'Tests\luaapi\run_dialog_vars_tests.ps1';    args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'event_owner';         kind = 'ps1';    file = 'Tests\luaapi\run_event_owner_tests.ps1';    args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'event_text_join';     kind = 'ps1';    file = 'Tests\luaapi\run_event_text_join_tests.ps1'; args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'province';            kind = 'ps1';    file = 'Tests\luaapi\run_province_tests.ps1';       args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'role_selection';      kind = 'ps1';    file = 'Tests\luaapi\run_role_selection_tests.ps1'; args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'timer';               kind = 'ps1';    file = 'Tests\luaapi\run_timer_tests.ps1';          args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'flash';               kind = 'ps1';    file = 'Tests\ui\run_flash_tests.ps1';              args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'gl_input';            kind = 'ps1';    file = 'Tests\ui\run_gl_input_tests.ps1';           args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'window_size';         kind = 'ps1';    file = 'Tests\ui\run_window_size_tests.ps1';        args = @('-OutDir', '<OUTDIR>') },
    # These two print "RESULT <passed>/<total>" instead of "passed=N": the gate still judges them (their exit code
    # does), but tests.json records no `checks` for them. Fix the printf in the suite, never widen the regex.
    @{ name = 'font';                kind = 'ps1';    file = 'Tests\fonts\run_font_tests.ps1';            args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'create_role_appear';  kind = 'ps1';    file = 'Tests\ui\run_create_role_appearance_tests.ps1'; args = @('-OutDir', '<OUTDIR>') },
    # CYS-TESTRED 19/09: four suites that were red or unbuilt this morning and are green now. Measured before being
    # added, one runner call each: camp 12/12, luaapi 73/73, packed_format 34/34, widget 139/139, all rc=0.
    @{ name = 'camp';                kind = 'ps1';    file = 'Tests\combat\run_camp_tests.ps1';             args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'luaapi';              kind = 'ps1';    file = 'Tests\luaapi\run_tests.ps1';                  args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'packed_format';       kind = 'ps1';    file = 'Tests\luaapi\run_packed_format_tests.ps1';    args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'widget';              kind = 'ps1';    file = 'Tests\ui\run_widget_tests.ps1';               args = @('-OutDir', '<OUTDIR>') },
    @{ name = 'dbc_schema';          kind = 'python'; file = 'Tests\abi\test_dbc_schema.py';              args = @('--out-dir', '<OUTDIR>') },
    @{ name = 'fx_tools';            kind = 'python'; file = 'Tests\fx\audit\test_fx_tools.py';           args = @() },
    @{ name = 'cluster_route';       kind = 'python'; file = 'Tests\net\cluster_route_guard_tests.py';    args = @() },
    @{ name = 'world_snapshot';      kind = 'python'; file = 'Tests\net\collect_world_snapshot_tests.py'; args = @('--out', '<OUTDIR>') },
    @{ name = 'perf_patchers';       kind = 'python'; file = 'Tests\perf\test_patchers.py';               args = @() },
    @{ name = 'perf_report';         kind = 'python'; file = 'Tests\perf\test_perf_report.py';            args = @() },
    @{ name = 'create_role_mesh';    kind = 'python'; file = 'Tests\ui\create_role_mesh_upgrade_tests.py'; args = @() },
    @{ name = 'create_role_scene';   kind = 'python'; file = 'Tests\ui\create_role_scene_resources_tests.py'; args = @() },
    @{ name = 'create_role_select';  kind = 'python'; file = 'Tests\ui\create_role_selection_tests.py';   args = @('--out', '<OUTDIR_REL>', '--lua-dll', '<LUADLL_REL>') },
    @{ name = 'stage_game';          kind = 'python'; file = 'Tools\game\test_stage_game.py';             args = @() },
    @{ name = 'cy_gui_image';        kind = 'python'; file = 'Tools\pipeline\test_cy_gui_image_vi.py';    args = @() },
    @{ name = 'cy_lua_unpack';       kind = 'python'; file = 'Tools\pipeline\test_cy_lua_unpack.py';      args = @() }
)
if ($List) {
    foreach ($s in $suites) { Write-Host ($s.kind.PadRight(6) + '  ' + $s.name.PadRight(20) + $s.file) }
    exit 0
}
if ($Only.Count) {
    $wanted = @($Only | ForEach-Object { $_.Split(',') } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $suites = @($suites | Where-Object { $wanted -contains $_.name })
    if (-not $suites.Count) { Write-Host 'TESTS ERROR: -Only matched no suite (use -List)'; exit 2 }
}

$exitCode = 2
try {
    if (-not (Test-Path -LiteralPath $Bin)) { throw ('staged Bin64 not found: ' + $Bin) }
    $stage = Read-JsonFile (Join-Path $Bin 'cys_stage.json')
    $sha = $null
    $short = $null
    if ($stage) { $sha = $stage.sha; $short = $stage.short }
    if (-not $short) {
        $g = Invoke-Exe git @('-C', $P.Root, 'rev-parse', '--short', 'HEAD')
        if ($g.Rc -ne 0) { throw 'no cys_stage.json and no git HEAD; run ci.ps1 and stage.ps1 first' }
        $short = $g.Out[-1].Trim()
        $sha = (Invoke-Exe git @('-C', $P.Root, 'rev-parse', 'HEAD')).Out[-1].Trim()
    }
    # The suites read the MAIN checkout, so record exactly what was on disk.
    $st = Invoke-Exe git @('-C', $P.Root, 'status', '--porcelain', '--untracked-files=no')
    $dirtyFiles = @()
    if ($st.Rc -eq 0) { $dirtyFiles = @($st.Out | Where-Object { $_ }) }
    if ($dirtyFiles.Count) {
        Write-Host ('WARNING main tree has ' + $dirtyFiles.Count + ' modified file(s); suites run on the working copy, not on ' + $short)
    }
    $logRoot = Join-Path $P.LogsCi $short
    New-Item -ItemType Directory -Force $logRoot | Out-Null
    if (-not $Out) { $Out = Join-Path $logRoot 'tests' }
    if (Test-Path -LiteralPath $Out) { Move-CysToQuarantine $Out 'ci-tests' }
    New-Item -ItemType Directory -Force $Out | Out-Null
    $luaDll = Join-Path $Bin 'LuaPlus.dll'
    if (-not (Test-Path -LiteralPath $P.Python)) { throw ('missing python: ' + $P.Python) }
    # Same data folder the stage recorded, so a suite never judges the binaries on another data set.
    $dataDir = $null
    if ($stage -and $stage.data_dir -and (Test-Path -LiteralPath $stage.data_dir)) { $dataDir = (Resolve-Path -LiteralPath $stage.data_dir).Path }
    else { $dataDir = (Get-CysDataDir).Dir }
    # Path relative to the repository root, or the absolute path when it is outside (the suite then reports it).
    $rootPrefix = [IO.Path]::GetFullPath($P.Root).TrimEnd('\') + '\'
    function ConvertTo-RootRelative([string]$Path) {
        $full = [IO.Path]::GetFullPath($Path)
        if ($full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { return $full.Substring($rootPrefix.Length) }
        return $full
    }

    $rows = New-Object System.Collections.Generic.List[object]
    $started = (Get-Date).ToString('s')
    foreach ($s in $suites) {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $row = [ordered]@{ name = $s.name; kind = $s.kind; status = 'FAIL'; rc = $null }
        $suiteOut = Join-Path $Out $s.name
        New-Item -ItemType Directory -Force $suiteOut | Out-Null
        $log = Join-Path $suiteOut 'run.log'
        $row.log = $log
        try {
            if ($s.kind -eq 'native') {
                $exe = Join-Path $Bin $s.file
                if (-not (Test-Path -LiteralPath $exe)) { throw ('not staged: ' + $exe + ' (run ci.ps1 then stage.ps1)') }
                if ($stage) {
                    $entry = @($stage.files | Where-Object { $_.name -eq $s.file -and $_.kind -eq 'ours' })
                    if ($entry.Count -eq 1 -and (Get-FileHash -LiteralPath $exe).Hash -ne $entry[0].sha256) {
                        throw ('staged binary differs from the manifest: ' + $s.file)
                    }
                }
                $nativeArgs = @($s.args | ForEach-Object {
                        $_.Replace('<DATA>', $dataDir).Replace('<OUTDIR>', (Join-Path $suiteOut 'report')).Replace('<BIN>', $Bin)
                    })
                $row.command = Join-CmdArgs (@($exe) + $nativeArgs)
                # cwd = Bin64: the test executables load the staged DLLs next to them.
                $row.rc = Invoke-CmdLogged ('cd /d "' + $Bin + '" && ' + $row.command) $log
            } elseif ($s.kind -eq 'ps1') {
                # CYS-TESTPATH 19/09: no cmake target, so nothing is staged - the runner compiles the suite from the
                # MAIN checkout and runs it. <OUTDIR> must NOT exist yet: these runners refuse to overwrite evidence.
                $script = Join-Path $P.Root $s.file
                if (-not (Test-Path -LiteralPath $script)) { throw ('missing suite script: ' + $script) }
                $argv = @($s.args | ForEach-Object { $_.Replace('<OUTDIR>', (Join-Path $suiteOut 'out')).Replace('<BIN>', $Bin) })
                $row.command = Join-CmdArgs (@((Join-Path $PSHOME 'powershell.exe'), '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script) + $argv)
                $row.rc = Invoke-CmdLogged ('cd /d "' + $P.Root + '" && ' + $row.command) $log
            } else {
                $script = Join-Path $P.Root $s.file
                if (-not (Test-Path -LiteralPath $script)) { throw ('missing suite script: ' + $script) }
                $needLua = (($s.args -join ' ') -match '<LUADLL')
                if ($needLua -and -not (Test-Path -LiteralPath $luaDll)) { throw ('not staged: ' + $luaDll + ' (run ci.ps1 then stage.ps1)') }
                $suiteOutDir = Join-Path $suiteOut 'out'
                $argv = @($s.args | ForEach-Object {
                        $_.Replace('<OUTDIR_REL>', (ConvertTo-RootRelative $suiteOutDir)).
                        Replace('<LUADLL_REL>', (ConvertTo-RootRelative $luaDll)).
                        Replace('<OUTDIR>', $suiteOutDir).Replace('<BIN>', $Bin).Replace('<LUADLL>', $luaDll)
                    })
                $row.command = Join-CmdArgs (@($P.Python, '-B', $script) + $argv)
                $row.rc = Invoke-CmdLogged ('cd /d "' + $P.Root + '" && set PYTHONUTF8=1&& set PYTHONDONTWRITEBYTECODE=1&& set PYTHONIOENCODING=utf-8&& ' + $row.command) $log
            }
            $text = ''
            if (Test-Path -LiteralPath $log) { $text = [IO.File]::ReadAllText($log) }
            # CYS-TESTPATH 19/09 (dot 2): every Tests\**\run_*_tests.ps1 writes its own tests.log into <OUTDIR>, but
            # only SOME of them echo it to stdout. Reading both means a suite does not have to be edited just to be
            # gated (run_create_role_appearance_tests.ps1 prints nothing: "RESULT 123/123" exists only in tests.log).
            # The regex below takes the FIRST ^RESULT, so appending never overrides what the runner already printed.
            if ($s.kind -eq 'ps1') {
                $suiteLog = Join-Path (Join-Path $suiteOut 'out') 'tests.log'
                if (Test-Path -LiteralPath $suiteLog) { $text += "`r`n" + [IO.File]::ReadAllText($suiteLog) }
            }
            if ($row.rc -ne 0) { throw ('exit code ' + $row.rc) }
            if ($s.kind -ne 'python') {
                # Two shapes: the unit suites end with "RESULT ... status=PASS", CysActionSetCheck with "result: OK".
                # CYS-TESTPATH 19/09: "passed=" is the third count word (rolelist prints "RESULT passed=26 failed=0");
                # the alternation is scanned left to right over the line, so checks=/tests= suites keep their number.
                $m = [regex]::Match($text, '(?m)^RESULT[^\r\n]*')
                if ($m.Success) {
                    $row.result_line = $m.Value.Trim()
                    if ($row.result_line -match 'status=FAIL' -or $row.result_line -match 'failed=[1-9]') { throw ('RESULT reports failures: ' + $row.result_line) }
                    $c = [regex]::Match($row.result_line, '(?:checks|tests|passed)=(\d+)')
                    if ($c.Success) { $row.checks = [int]$c.Groups[1].Value }
                } else {
                    $m2 = [regex]::Match($text, '(?m)^result: *(\S+)')
                    if (-not $m2.Success) { throw 'no RESULT / result: line' }
                    $row.result_line = $m2.Value.Trim()
                    if ($m2.Groups[1].Value -ne 'OK') { throw ('reported ' + $row.result_line) }
                }
                # Offline contract: the bot suite must not have opened a socket to the private server.
                if ($row.result_line -match 'live_connections=(\d+)') {
                    $row.live_connections = [int]$Matches[1]
                    if ($row.live_connections -ne 0) { throw ('suite opened ' + $row.live_connections + ' live connection(s); CI must stay offline') }
                }
            } else {
                if ($text -match '(?m)^FAILED\b' -or $text -match '(?m)^\s*FAIL\s') { throw 'the suite printed a FAIL line' }
                $m = [regex]::Match($text, 'Ran (\d+) tests?')
                if ($m.Success) { $row.checks = [int]$m.Groups[1].Value }
                elseif ($text -match '(?m)^(?:PASS|ok)\b') { $row.checks = @([regex]::Matches($text, '(?m)^PASS\b')).Count }
            }
            $row.status = 'OK'
        } catch {
            $row.error = $_.Exception.Message
        }
        $row.seconds = [math]::Round($watch.Elapsed.TotalSeconds, 2)
        $rows.Add($row)
        Write-Host ('TEST ' + $s.name.PadRight(20) + $row.status + ' rc=' + $row.rc + ' ' + $row.seconds + 's ' +
            $(if ($row.checks) { 'checks=' + $row.checks + ' ' } else { '' }) + $row.error)
    }
    $bad = @($rows | Where-Object { $_.status -ne 'OK' })
    $result = if ($bad.Count) { 'FAIL' } else { 'OK' }
    $json = [ordered]@{
        schema = 1; sha = $sha; short = $short; root = $P.Root; bin64 = $Bin
        source_dirty = [bool]$dirtyFiles.Count; dirty_files = $dirtyFiles
        started = $started; finished = (Get-Date).ToString('s'); result = $result
        suites_ok = ($rows.Count - $bad.Count); suites_total = $rows.Count; out_dir = $Out
        suites = $rows.ToArray()
    }
    Write-JsonFile $json (Join-Path $logRoot 'tests.json')
    Write-Host ('TESTS ' + $short + ': ' + $result + ' (' + ($rows.Count - $bad.Count) + '/' + $rows.Count + ') -> ' + (Join-Path $logRoot 'tests.json'))
    $exitCode = if ($bad.Count) { 1 } else { 0 }
} catch {
    Write-Host ('TESTS ERROR: ' + $_.Exception.Message)
    $exitCode = 2
}
exit $exitCode
