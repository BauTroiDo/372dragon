<#
.SYNOPSIS
  Three offline gates on the committed CI worktree, after stage and smoke.
  Writes Build\Logs\ci\<sha>\checks.json. Exit: 0 OK, 1 gate failed, 2 setup error, 3 busy.
.DESCRIPTION
  protocol: cys_protocol_tests.exe G1 gate, every captured frame byte-identical (data independent).
  pathlib:  Tests\pathlib harness "load" on the staged PathLib.dll over EVERY *.path of the CI data folder
            (Assets\CanonicalCY\Data: SceneFolder + Scene2Folder, 418 files on 14/09/2026). The expected count is
            counted from the folder at run time and must be parsed 100% with 0 crashes - never a hard-coded number.
  scene:    CYSSceneTest (Tests\scene) over EVERY *.Scene of the same folders (512 on 14/09/2026, unique names as
            the test's resource lookup sees them): all loaded, 0 unknown keys, unit checks OK.
  Data: Get-CysDataDir (ci_common.ps1) - CanonicalCY only, since ci-cy 14/09/2026 (GL gates were 488 / 548).
#>
param([string]$Root = '')
$ErrorActionPreference = 'Stop'
$sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ci_common.ps1')
if ($Root) { $script:CysRoot = (Resolve-Path -LiteralPath $Root).Path }
$P = Get-CysPaths
$env:TEMP = Join-Path $P.Root 'Build\ci\tmp'
$env:TMP = $env:TEMP
$env:PYTHONUTF8 = '1'
$env:PYTHONDONTWRITEBYTECODE = '1'
New-Item -ItemType Directory -Force $env:TEMP | Out-Null

# CYS: an invocation from main dispatches the committed copy; no tests use main's edits.
if ($sourceRoot -ne $P.Wt) {
    $committed = Join-Path $P.Wt 'Tools\build\checks.ps1'
    if (-not (Test-Path -LiteralPath $committed)) { throw 'Commit checks.ps1 and run CI/stage/smoke first' }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $committed -Root $P.Root
    exit $LASTEXITCODE
}

$exitCode = 2
Enter-CysLock 'checks' @('tree', 'bin64', 'checks')
try {
    $g = Invoke-Exe git @('-C', $P.Wt, 'rev-parse', 'HEAD')
    if ($g.Rc -ne 0) { throw 'cannot read worktree commit' }
    $sha = $g.Out[-1].Trim()
    $short = (Invoke-Exe git @('-C', $P.Wt, 'rev-parse', '--short', 'HEAD')).Out[-1].Trim()
    $dirty = Invoke-Exe git @('-C', $P.Wt, 'status', '--porcelain', '--untracked-files=all')
    if ($dirty.Rc -ne 0 -or @($dirty.Out | Where-Object { $_ }).Count) { throw 'CI worktree must be clean' }
    $stage = Read-JsonFile (Join-Path $P.Bin64 'cys_stage.json')
    if (-not $stage -or $stage.sha -ne $sha -or $stage.source_dirty -or $stage.ci_result -ne 'OK') {
        throw 'stage must be clean and built OK at the worktree commit'
    }
    foreach ($name in @('PathLib.dll', 'cys_protocol_tests.exe')) {
        $entry = @($stage.files | Where-Object { $_.name -eq $name -and $_.kind -eq 'ours' })
        if ($entry.Count -ne 1 -or (Get-FileHash -LiteralPath (Join-Path $P.Bin64 $name)).Hash -ne $entry[0].sha256) {
            throw ('staged binary differs from the manifest: ' + $name)
        }
    }
    $logRoot = Join-Path $P.LogsCi $short
    $priorSmoke = Read-JsonFile (Join-Path $logRoot 'smoke.json')
    if (-not $priorSmoke -or $priorSmoke.sha -ne $sha -or $priorSmoke.result -ne 'OK') { throw 'successful smoke required at the same commit' }
    $out = Join-Path $logRoot 'checks'
    if (Test-Path -LiteralPath $out) { Move-CysToQuarantine $out 'ci-checks' }
    New-Item -ItemType Directory -Force $out | Out-Null
    $checks = New-Object System.Collections.Generic.List[object]
    $started = (Get-Date).ToString('s')
    $vs = Find-VsBuildTools
    Import-VcVars $vs 'x64'
    $cmake = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
    $ninja = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe'
    [Environment]::CurrentDirectory = $P.Wt
    # CYS ci-cy: the gates run on the staged data folder (CanonicalCY); the stage must have used the same one.
    $dataDir = (Get-CysDataDir).Dir
    if ($stage.data_dir -and ((Resolve-Path -LiteralPath $stage.data_dir).Path -ne $dataDir)) {
        throw ('stage data_dir ' + $stage.data_dir + ' differs from the CI data folder ' + $dataDir)
    }
    $sceneDirs = @(@('SceneFolder', 'Scene2Folder') | ForEach-Object { Join-Path $dataDir $_ } | Where-Object { Test-Path -LiteralPath $_ })
    if (-not $sceneDirs.Count) { throw ('no SceneFolder in ' + $dataDir) }
    # Counted from the folders each run; the gates demand 100% of what is there.
    $pathFiles = @(foreach ($d in $sceneDirs) { Get-ChildItem -LiteralPath $d -File | Where-Object { $_.Extension -ieq '.path' } })
    $sceneNames = @{}
    foreach ($d in $sceneDirs) {
        foreach ($f in @(Get-ChildItem -LiteralPath $d -File | Where-Object { $_.Extension -ieq '.scene' })) { $sceneNames[$f.Name.ToLowerInvariant()] = 1 }
    }
    $pathExpected = $pathFiles.Count
    $sceneExpected = $sceneNames.Count
    Write-Host ('data: ' + $dataDir + ' (' + $pathExpected + ' .path, ' + $sceneExpected + ' .Scene in ' + ($sceneDirs.Count) + ' folder(s))')

    function Run-Gate([string]$Name, [scriptblock]$Body) {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $row = [ordered]@{ name = $Name; status = 'FAIL'; rc = $null; log_dir = (Join-Path $out $Name) }
        New-Item -ItemType Directory -Force $row.log_dir | Out-Null
        try {
            & $Body $row
            $row.status = 'OK'
        } catch { $row.error = $_.Exception.Message }
        $row.seconds = [math]::Round($watch.Elapsed.TotalSeconds, 2)
        $checks.Add($row)
        Write-Host ('CHECK ' + $Name + ': ' + $row.status + ' rc=' + $row.rc + ' ' + $row.seconds + 's ' + $row.error)
        Write-JsonFile ([ordered]@{ schema = 1; sha = $sha; short = $short; worktree = $P.Wt; started = $started; result = 'RUNNING'; checks = $checks.ToArray() }) (Join-Path $logRoot 'checks.json')
    }

    Run-Gate 'protocol' {
        param($row)
        $log = Join-Path $row.log_dir 'run.log'
        $row.command = Join-CmdArgs @($P.Python, (Join-Path $P.Wt 'Tests\protocol\run_protocol_tests.py'), '--exe', (Join-Path $P.Bin64 'cys_protocol_tests.exe'), '--logs', $row.log_dir)
        $row.rc = Invoke-CmdLogged $row.command $log
        $text = [IO.File]::ReadAllText($log)
        $count = [regex]::Match($text, 'GATE capture round trip: (\d+)/(\d+) frames byte-identical')
        if ($row.rc -ne 0 -or $text -notmatch 'G1 GATE: PASSED' -or -not $count.Success -or [int]$count.Groups[2].Value -le 0 -or $count.Groups[1].Value -ne $count.Groups[2].Value) { throw 'protocol G1 did not pass with a nonempty, byte-identical capture' }
        $row.frames_ok = [int]$count.Groups[1].Value
        $row.frames_total = [int]$count.Groups[2].Value
        $row.report = Join-Path $row.log_dir 'gate_summary.txt'
    }

    Run-Gate 'pathlib' {
        param($row)
        $tests = Join-Path $P.Tree 'tests'
        New-Item -ItemType Directory -Force $tests | Out-Null
        $exe = Join-Path $tests 'pathlib_test.exe'
        $buildLog = Join-Path $row.log_dir 'build.log'
        $build = Join-CmdArgs @('cl.exe', '/nologo', '/EHa', '/O2', '/Zi', '/std:c++14', ('/Fe:' + $exe), ('/Fo:' + (Join-Path $tests 'pathlib_test.obj')), ('/Fd:' + (Join-Path $tests 'pathlib_test.pdb')), (Join-Path $P.Wt 'Tests\pathlib\pathlib_test.cpp'), '/link', '/INCREMENTAL:NO')
        $row.build_rc = Invoke-CmdLogged $build $buildLog
        if ($row.build_rc -ne 0) { throw 'pathlib harness build failed' }
        $log = Join-Path $row.log_dir 'run.log'
        if ($pathExpected -le 0) { throw ('no .path files in ' + $dataDir) }
        $row.data_dir = $dataDir
        $row.folders = @($sceneDirs)
        $row.command = Join-CmdArgs (@($exe, 'load', (Join-Path $P.Bin64 'PathLib.dll')) + $sceneDirs)
        $row.rc = Invoke-CmdLogged $row.command $log
        $text = [IO.File]::ReadAllText($log)
        $want = 'LOAD TEST: ' + $pathExpected + ' files, ' + $pathExpected + ' parsed ok, 0 parse-fail, 0 CRASH'
        if ($row.rc -ne 0 -or $text -notmatch [regex]::Escape($want)) { throw ('pathlib must parse all ' + $pathExpected + ' .path files of ' + $dataDir + ' with zero failures or crashes') }
        $row.files_ok = $pathExpected
        $row.files_total = $pathExpected
        $row.report = $log
    }

    Run-Gate 'scene' {
        param($row)
        $tree = Join-Path $P.Root 'Build\cmake\ci-scene-x64'
        $cfgLog = Join-Path $row.log_dir 'configure.log'
        $config = Join-CmdArgs @($cmake, '-S', (Join-Path $P.Wt 'Src'), '-B', $tree, '-G', 'Ninja', ('-DCMAKE_MAKE_PROGRAM=' + $ninja.Replace('\','/')), '-DCMAKE_BUILD_TYPE=Release', '-UCYS_COMPONENTS', ('-DCMAKE_PROJECT_CYSource_INCLUDE=' + (Join-Path $P.Wt 'Tests\scene\scene_test.cmake').Replace('\','/')), '-DCYS_CG_DLL=C:/TLBB/085/client_GL/Bin64/cg.dll')
        $row.configure_rc = Invoke-CmdLogged $config $cfgLog
        if ($row.configure_rc -ne 0) { throw 'scene configure failed' }
        $env:CMAKE_BUILD_PARALLEL_LEVEL = '5'
        $row.build_rc = Invoke-CmdLogged (Join-CmdArgs @($cmake, '--build', $tree, '--target', 'CYSSceneTest', '--parallel', '5', '--', '-k', '0')) (Join-Path $row.log_dir 'build.log')
        if ($row.build_rc -ne 0) { throw 'scene test build failed' }
        $report = Join-Path $row.log_dir 'report.txt'
        if ($sceneExpected -le 0) { throw ('no .Scene files in ' + $dataDir) }
        $row.data_dir = $dataDir
        $row.folders = @($sceneDirs)
        $row.command = Join-CmdArgs @((Join-Path $tree 'bin\CYSSceneTest.exe'), '--data', $dataDir, '--report', $report, '--log', (Join-Path $row.log_dir 'Ogre.log'))
        $row.rc = Invoke-CmdLogged $row.command (Join-Path $row.log_dir 'run.log')
        if (-not (Test-Path -LiteralPath $report)) { throw 'scene test wrote no report' }
        $text = [IO.File]::ReadAllText($report)
        $foundRe = 'Scene files found = ' + $sceneExpected + '\b'
        $loadedRe = 'Scenes loaded = ' + $sceneExpected + '\b'
        if ($row.rc -ne 0 -or $text -notmatch $foundRe -or $text -notmatch $loadedRe -or $text -notmatch 'RESULT: PASS \(failures 0, unknown keys 0, unit checks ok\)') { throw ('scene must load all ' + $sceneExpected + ' scenes of ' + $dataDir + ' and pass every unit check') }
        $row.scenes_ok = $sceneExpected
        $row.scenes_total = $sceneExpected
        $row.report = $report
    }
    $bad = @($checks | Where-Object { $_.status -ne 'OK' })
    $result = if ($bad.Count) { 'FAIL' } else { 'OK' }
    Write-JsonFile ([ordered]@{ schema = 1; sha = $sha; short = $short; worktree = $P.Wt; started = $started; finished = (Get-Date).ToString('s'); result = $result; checks = $checks.ToArray() }) (Join-Path $logRoot 'checks.json')
    Write-Host ('CHECKS ' + $short + ': ' + $result + ' (' + ($checks.Count - $bad.Count) + '/3) -> ' + (Join-Path $logRoot 'checks.json'))
    $exitCode = if ($bad.Count) { 1 } else { 0 }
} catch {
    Write-Host ('CHECKS ERROR: ' + $_.Exception.Message)
} finally { Exit-CysLock }
exit $exitCode
