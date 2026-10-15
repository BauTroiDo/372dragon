<#
.SYNOPSIS
  Smoke test of a staged layout (Build\Client\Bin64, see stage.ps1). Results: Build\Logs\ci\<short-sha>\smoke.json.
.DESCRIPTION
  Data = the staged data folder (cys_stage.json data_dir: Assets\CanonicalCY\Data, CY 3.71, since ci-cy 14/09/2026)
  or -Data.
  1. OgreSmoke.exe --data <data> --out <logs>\smoke\ogresmoke --batch 200
     (Root + D3D9 + inner plugins, resource groups, default mesh render + screenshots, 200 skeletons + 200 meshes).
  2. TlbbViewer.exe on -CaseCount (5) model cases of Tests\oracle\cases.json (generated on CanonicalCY by
     Tests\oracle\make_cases.py --profile cy; cases_gl.json is the old GL set, not used here): the first case of
     each bucket, or -CaseIds.
       --data <data> --model <obj> [--anim <anim>] --ff --shot <png> --frames 30 --dt 0.033 --size 1280x720
     (--ff = fixed-function diagnostic while the real material path is still being fixed).
  2b. TlbbViewer on -SceneCases (fix-projector 15/09/2026): --data <data> --scene <scene> --shot <png> --frames 30
     --size 1280x720. Default luoyang_new (3 Projector objects, CY BaseWhite = no projector; crashed with
     boost::bad_any_cast before fix-projector) and Scene2Folder\chengzhanPVP1 (23 textured decals, ':1' = at least one
     live projector, from the viewer line "TlbbViewer: projectors: objects=N live=M").
  3. Game.exe is never started here: that needs a confirmed offline mode from the game-layer agent.
  Per run: exit code and meaning, seconds, stdout/stderr files, crash dumps (.dmp), screenshot size, log census.
  Tools whose CMake target is not OK in the CI summary of the staged commit are skipped (the staged binary would be
  stale), unless -Force. _NT_SYMBOL_PATH = Build\Symbols\ci for symbolised crash stacks.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\smoke.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\smoke.ps1 -CaseIds M07,M38
.NOTES
  Exit codes: 0 all runs OK, 1 a run failed/crashed/timed out or was skipped, 2 setup error, 3 CI busy.
#>
param(
    [string]$Bin = '',
    [string]$Data = '',
    [int]$CaseCount = 5,
    [string[]]$CaseIds = @(),
    [int]$Batch = 200,
    # CYS-FIX fix-projector: scene cases ('<folder>\<file>.Scene[:<min live projectors>]'); [] = none.
    [string[]]$SceneCases = @('SceneFolder\luoyang_new.Scene', 'Scene2Folder\chengzhanPVP1.Scene:1'),
    [int]$ViewerTimeoutSec = 300,
    [int]$SmokeTimeoutSec = 1200,
    [string]$Tag = '',
    [switch]$Force,
    [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
. (Join-Path $PSScriptRoot 'ci_blank_detector.ps1')
. (Join-Path $PSScriptRoot 'ci_timings.ps1')
# CYS: -Root = main tree when this copy runs from a branch worktree (Build\Client\Bin64, Build\Logs\ci of main).
if ($Root) { $script:CysRoot = (Resolve-Path -LiteralPath $Root).Path }
$P = Get-CysPaths
if (-not $Bin) { $Bin = $P.Bin64 }

# Runs a tool without a console window; stdout/stderr (UTF-8) saved to files; kills it after the timeout.
function Invoke-Tool {
    param([string]$Exe, [string[]]$ArgList, [string]$WorkDir, [string]$StdoutFile, [string]$StderrFile,
          [int]$TimeoutSec, [hashtable]$Environment)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = ($ArgList | ForEach-Object { ConvertTo-ProcArg $_ }) -join ' '
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    foreach ($k in $Environment.Keys) { $psi.EnvironmentVariables[$k] = [string]$Environment[$k] }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $p = [System.Diagnostics.Process]::Start($psi)
    $so = $p.StandardOutput.ReadToEndAsync()
    $se = $p.StandardError.ReadToEndAsync()
    $timedOut = $false
    if ($p.WaitForExit($TimeoutSec * 1000)) {
        $p.WaitForExit()
    } else {
        $timedOut = $true
        try { $p.Kill() } catch { }
        [void]$p.WaitForExit(20000)
    }
    $sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    $stdout = ''
    $stderr = ''
    if ($so.Wait(10000)) { $stdout = $so.Result }
    if ($se.Wait(10000)) { $stderr = $se.Result }
    [System.IO.File]::WriteAllText($StdoutFile, $stdout, $script:Utf8NoBom)
    [System.IO.File]::WriteAllText($StderrFile, $stderr, $script:Utf8NoBom)
    $rc = $null
    if (-not $timedOut) { $rc = $p.ExitCode }
    [pscustomobject]@{
        Rc = $rc; TimedOut = $timedOut; Seconds = $sec; Stdout = $stdout; Stderr = $stderr
        CommandLine = ('"' + $psi.FileName + '" ' + $psi.Arguments)
    }
}

function Get-RunStatus($Run, [object[]]$Dumps, [int]$CrashCode) {
    if ($Run.TimedOut) { return 'TIMEOUT' }
    if (@($Dumps).Count -gt 0) { return 'CRASH' }
    if ($CrashCode -and $Run.Rc -eq $CrashCode) { return 'CRASH' }
    if ($Run.Rc -lt 0) { return 'CRASH' }
    if ($Run.Rc -eq 0) { return 'OK' }
    return 'FAIL'
}

function Format-ExitCode($Rc) {
    if ($null -eq $Rc) { return 'none (killed)' }
    if ($Rc -lt 0) { return ('0x{0:X8}' -f ([int64]$Rc + 4294967296)) }
    return [string]$Rc
}

# Lines of an engine log (GBK bytes) that mention error / not found / unknown / exception.
function Get-LogCensus([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $lines = [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::GetEncoding(936))
    $err = @($lines | Where-Object { $_ -match '(?i)error' })
    [ordered]@{
        path          = $Path
        lines         = $lines.Count
        error         = $err.Count
        not_found     = @($lines | Where-Object { $_ -match '(?i)not found|cannot find|can''t find' }).Count
        unknown       = @($lines | Where-Object { $_ -match '(?i)unknown|unrecognised|unrecognized' }).Count
        exception     = @($lines | Where-Object { $_ -match '(?i)exception' }).Count
        error_samples = @($err | Select-Object -First 5 | ForEach-Object { $_.Substring(0, [math]::Min(300, $_.Length)) })
    }
}

# CYS: snapshots bracket each run; unavailable counters stay null with evidence.
function Get-CysRunSnapshot([string]$CachePath) {
    $sample = [ordered]@{
        at = (Get-Date).ToString('o'); cache_files = $null; cpu_percent = $null
        cache_error = $null; cpu_error = $null
    }
    try {
        if (Test-Path -LiteralPath $CachePath) {
            $sample.cache_files = @(Get-ChildItem -LiteralPath $CachePath -File -Recurse -Force -ErrorAction Stop).Count
        } else { $sample.cache_files = 0 }
    } catch { $sample.cache_error = $_.Exception.Message }
    try {
        $cpu = @(Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -OperationTimeoutSec 3 -ErrorAction Stop)
        if ($cpu.Count -ne 1 -or $null -eq $cpu[0].PercentProcessorTime) { throw 'CPU counter unavailable' }
        $sample.cpu_percent = [double]$cpu[0].PercentProcessorTime
    } catch { $sample.cpu_error = $_.Exception.Message }
    return $sample
}

Enter-CysLock 'smoke' @('bin64')
$exitCode = 2
try {
    $started = Get-Date
    $stage = Read-JsonFile (Join-Path $Bin 'cys_stage.json')
    if (-not $stage) { throw ('no cys_stage.json in ' + $Bin + ' (run stage.ps1 first)') }
    $dataDir = $stage.data_dir
    if ($Data) { $dataDir = $Data }
    if (-not $dataDir -or -not (Test-Path -LiteralPath $dataDir)) { throw ('staged data folder not found: ' + $dataDir + ' (stage.ps1 on Assets\CanonicalCY\Data first)') }
    $label = $stage.short
    if (-not $label) { $label = 'stage-' + (Get-Date -Format 'yyyyMMdd-HHmm') }
    elseif ($stage.source_dirty) { $label = $label + '-dirty-' + (Get-Date -Format 'yyyyMMdd-HHmm') }
    $logRoot = Join-Path $P.LogsCi $label
    $base = 'smoke'
    if ($Tag) { $base = 'smoke-' + ($Tag -replace '[^A-Za-z0-9_.-]', '_') }
    $out = Join-Path $logRoot $base
    if (Test-Path -LiteralPath $out) {
        Move-CysToQuarantine $out 'ci-smoke'
    }
    New-Item -ItemType Directory -Force $out | Out-Null

    $ci = $null
    if ($stage.ci_summary) { $ci = Read-JsonFile $stage.ci_summary }
    function Get-TargetStatus([string]$Name) {
        if (-not $ci) { return $null }
        foreach ($t in @($ci.targets)) { if ($t.name -eq $Name) { return $t.status } }
        return 'ABSENT'
    }
    $envs = @{ '_NT_SYMBOL_PATH' = $P.Symbols }
    $cachePath = Join-Path $Bin 'ShaderCache'
    $gpu = $null
    try { $gpu = (@(Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join '; ') } catch { }
    Write-Host ('smoke ' + $label + ': bin ' + $Bin + ', data ' + $dataDir + ', out ' + $out)

    # ---------------------------------------------------------------- 1. OgreSmoke
    $smokeExe = Join-Path $Bin 'OgreSmoke.exe'
    $og = [ordered]@{ tool = 'OgreSmoke'; status = 'SKIPPED'; timings = $null }
    $ts = Get-TargetStatus 'OgreSmoke'
    if (-not (Test-Path -LiteralPath $smokeExe)) {
        $og.reason = 'OgreSmoke.exe not staged'
    } elseif ($ts -and $ts -ne 'OK' -and -not $Force) {
        $og.reason = 'CI target status ' + $ts + ' at this commit (staged binary would be stale); use -Force'
    } else {
        $od = Join-Path $out 'ogresmoke'
        New-Item -ItemType Directory -Force $od | Out-Null
        $before = Get-CysRunSnapshot $cachePath
        $r = Invoke-Tool $smokeExe @('--data', $dataDir, '--out', $od, '--batch', [string]$Batch) $Bin `
            (Join-Path $od 'stdout.txt') (Join-Path $od 'stderr.txt') $SmokeTimeoutSec $envs
        $after = Get-CysRunSnapshot $cachePath
        $og.timings = Get-CysOgreTimings $r.Stdout
        $og.timings.before = $before
        $og.timings.after = $after
        $lines = @($r.Stdout -split "`r?`n")
        $ogreLog = Join-Path $Bin 'Ogre.log'
        if ((Test-Path -LiteralPath $ogreLog) -and -not (Test-Path -LiteralPath (Join-Path $od 'Ogre.log'))) {
            Copy-Item -LiteralPath $ogreLog -Destination (Join-Path $od 'Ogre.log') -Force
        }
        $dumps = @(Get-ChildItem -LiteralPath $od -Filter '*.dmp' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        $og.status = Get-RunStatus $r $dumps 0
        $og.exit_code = Format-ExitCode $r.Rc
        $og.seconds = $r.Seconds
        $og.command = $r.CommandLine
        $bm = [regex]::Match($r.Stdout, 'batch: skeletons ok (\d+) / fail (\d+); meshes ok (\d+) / fail (\d+)')
        if ($bm.Success) {
            $og.batch = [ordered]@{
                skeletons_ok = [int]$bm.Groups[1].Value; skeletons_fail = [int]$bm.Groups[2].Value
                meshes_ok = [int]$bm.Groups[3].Value; meshes_fail = [int]$bm.Groups[4].Value
            }
        }
        $og.highlights = @($lines | Where-Object { $_ -match '^(render system:|resources:|batch:|census:|rendered |total |CRASH|capture FAILED|  fail x|screenshot)' } | Select-Object -First 40)
        $og.stderr_tail = @(($r.Stderr -split "`r?`n") | Where-Object { $_ } | Select-Object -Last 5)
        $og.crash_dumps = $dumps
        $og.ogre_log = Get-LogCensus (Join-Path $od 'Ogre.log')
        $og.out_dir = $od
    }
    Write-Host ('OgreSmoke: ' + $og.status + ' rc=' + $og.exit_code + ' ' + $og.seconds + ' s ' + $og.reason)

    # ---------------------------------------------------------------- 2. TlbbViewer model cases
    $casesFile = $null
    if ($stage.source_dir) {
        $c1 = Join-Path (Split-Path -Parent $stage.source_dir) 'Tests\oracle\cases.json'
        if (Test-Path -LiteralPath $c1) { $casesFile = $c1 }
    }
    if (-not $casesFile) { $casesFile = Join-Path $P.Root 'Tests\oracle\cases.json' }
    $cj = Get-Content -Raw -Encoding UTF8 -LiteralPath $casesFile | ConvertFrom-Json
    $ids = @($CaseIds | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $selected = @()
    if ($ids.Count) {
        foreach ($id in $ids) {
            $m = @($cj.models | Where-Object { $_.id -eq $id })
            if ($m.Count) { $selected += $m[0] } else { Write-Host ('unknown case id ' + $id) }
        }
    } else {
        $seen = @{}
        foreach ($m in $cj.models) {
            if ($selected.Count -ge $CaseCount) { break }
            if (-not $seen.ContainsKey($m.bucket)) { $seen[$m.bucket] = $true; $selected += $m }
        }
    }

    $viewerExe = Join-Path $Bin 'TlbbViewer.exe'
    $vts = Get-TargetStatus 'TlbbViewer'
    $vdir = Join-Path $out 'viewer'
    New-Item -ItemType Directory -Force $vdir | Out-Null
    $meaning = @{ 0 = 'ok'; 1 = 'usage'; 2 = 'content not found'; 3 = 'engine init failed'; 4 = 'capture failed'; 5 = 'crash (.dmp written)' }
    $viewerRuns = New-Object System.Collections.Generic.List[object]
    foreach ($c in $selected) {
        $vr = [ordered]@{ tool = 'TlbbViewer'; case = $c.id; bucket = $c.bucket; model = $c.obj; anim = $c.anim; status = 'SKIPPED'; blank = $null; timings = $null }
        if (-not (Test-Path -LiteralPath $viewerExe)) {
            $vr.reason = 'TlbbViewer.exe not staged'
        } elseif ($vts -and $vts -ne 'OK' -and -not $Force) {
            $vr.reason = 'CI target status ' + $vts + ' at this commit (staged binary would be stale); use -Force'
        } else {
            $png = Join-Path $vdir ($c.id + '.png')
            $a = @('--data', $dataDir, '--model', $c.obj)
            if ($c.anim) { $a += @('--anim', $c.anim) }
            $a += @('--ff', '--shot', $png, '--frames', '30', '--dt', '0.033', '--size', '1280x720')
            $before = Get-CysRunSnapshot $cachePath
            $r = Invoke-Tool $viewerExe $a $Bin (Join-Path $vdir ($c.id + '.stdout.txt')) `
                (Join-Path $vdir ($c.id + '.stderr.txt')) $ViewerTimeoutSec $envs
            $after = Get-CysRunSnapshot $cachePath
            $vr.timings = Get-CysViewerTimings ($png + '.log') $r.Stdout
            $vr.timings.before = $before
            $vr.timings.after = $after
            $dumps = @(Get-ChildItem -LiteralPath $vdir -Filter ($c.id + '*.dmp') -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
            $vr.status = Get-RunStatus $r $dumps 5
            $vr.exit_code = Format-ExitCode $r.Rc
            if ($null -ne $r.Rc -and $meaning.ContainsKey([int]$r.Rc)) { $vr.exit_meaning = $meaning[[int]$r.Rc] }
            $vr.seconds = $r.Seconds
            $em = [regex]::Match($r.Stdout, 'engine ready in (\d+) ms')
            if ($em.Success) { $vr.engine_ready_ms = [int]$em.Groups[1].Value }
            if (Test-Path -LiteralPath $png) { $vr.png = [ordered]@{ path = $png; bytes = (Get-Item -LiteralPath $png).Length } }
            else { $vr.png = $null }
            $vr.log = Get-LogCensus ($png + '.log')
            # CYS: fail even rc=0 when the image or model-creation log is blank.
            $blankLog = $r.Stdout + "`n" + $r.Stderr
            if (Test-Path -LiteralPath ($png + '.log')) {
                $blankLog += "`n" + [IO.File]::ReadAllText(($png + '.log'), [Text.Encoding]::GetEncoding(936))
            }
            $vr.blank_details = Get-CysBlankFrame $png $blankLog
            $vr.blank = $vr.blank_details.detected
            if ($vr.blank) {
                if ($vr.status -eq 'OK') { $vr.status = 'FAIL' }
                $vr.reason = 'BLANK FRAME: ' + ($vr.blank_details.reasons -join ', ')
                Write-Host ('FAIL TlbbViewer ' + $c.id + ': ' + $vr.reason)
            }
            $vr.stdout_tail = @(($r.Stdout -split "`r?`n") | Where-Object { $_ } | Select-Object -Last 4)
            $vr.stderr_tail = @(($r.Stderr -split "`r?`n") | Where-Object { $_ } | Select-Object -Last 5)
            $vr.crash_dumps = $dumps
            $vr.command = $r.CommandLine
        }
        $viewerRuns.Add($vr)
        Write-Host ('TlbbViewer ' + $c.id + ' [' + $c.bucket + ']: ' + $vr.status + ' rc=' + $vr.exit_code + ' ' + $vr.seconds + ' s ' + $vr.reason)
    }

    # ---------------------------------------------------------------- 2b. TlbbViewer scene cases (CYS-FIX fix-projector)
    $sdir = Join-Path $out 'scenes'
    New-Item -ItemType Directory -Force $sdir | Out-Null
    foreach ($spec in @($SceneCases | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $scene = $spec
        $minLive = 0
        $sm = [regex]::Match($spec, '^(.*\.Scene):(\d+)$')
        if ($sm.Success) { $scene = $sm.Groups[1].Value; $minLive = [int]$sm.Groups[2].Value }
        $sid = 'scene_' + ([IO.Path]::GetFileNameWithoutExtension($scene) -replace '[^A-Za-z0-9_.-]', '_')
        $vr = [ordered]@{ tool = 'TlbbViewer'; case = $sid; bucket = 'scene'; scene = $scene; status = 'SKIPPED'; timings = $null }
        if (-not (Test-Path -LiteralPath $viewerExe)) {
            $vr.reason = 'TlbbViewer.exe not staged'
        } elseif ($vts -and $vts -ne 'OK' -and -not $Force) {
            $vr.reason = 'CI target status ' + $vts + ' at this commit (staged binary would be stale); use -Force'
        } elseif (-not (Test-Path -LiteralPath (Join-Path $dataDir $scene))) {
            $vr.reason = 'scene not in the staged data folder'
        } else {
            $png = Join-Path $sdir ($sid + '.png')
            $a = @('--data', $dataDir, '--scene', $scene, '--shot', $png, '--frames', '30', '--size', '1280x720')
            $r = Invoke-Tool $viewerExe $a $Bin (Join-Path $sdir ($sid + '.stdout.txt')) `
                (Join-Path $sdir ($sid + '.stderr.txt')) $ViewerTimeoutSec $envs
            $dumps = @(Get-ChildItem -LiteralPath $sdir -Filter ($sid + '*.dmp') -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
            $vr.status = Get-RunStatus $r $dumps 5
            $vr.exit_code = Format-ExitCode $r.Rc
            if ($null -ne $r.Rc -and $meaning.ContainsKey([int]$r.Rc)) { $vr.exit_meaning = $meaning[[int]$r.Rc] }
            $vr.seconds = $r.Seconds
            if (Test-Path -LiteralPath $png) { $vr.png = [ordered]@{ path = $png; bytes = (Get-Item -LiteralPath $png).Length } }
            else { $vr.png = $null; if ($vr.status -eq 'OK') { $vr.status = 'FAIL'; $vr.reason = 'no PNG' } }
            $pm = [regex]::Match($r.Stdout + "`n" + $r.Stderr, 'projectors: objects=(\d+) live=(\d+)')
            if ($pm.Success) {
                $vr.projectors = [ordered]@{ objects = [int]$pm.Groups[1].Value; live = [int]$pm.Groups[2].Value; min_live = $minLive }
                if ($vr.status -eq 'OK' -and $vr.projectors.live -lt $minLive) { $vr.status = 'FAIL'; $vr.reason = 'live projectors ' + $vr.projectors.live + ' < ' + $minLive }
            } elseif ($vr.status -eq 'OK' -and $minLive -gt 0) {
                $vr.status = 'FAIL'; $vr.reason = 'no "projectors:" line in the viewer output'
            }
            $vr.log = Get-LogCensus ($png + '.log')
            $vr.stdout_tail = @(($r.Stdout -split "`r?`n") | Where-Object { $_ } | Select-Object -Last 4)
            $vr.stderr_tail = @(($r.Stderr -split "`r?`n") | Where-Object { $_ } | Select-Object -Last 5)
            $vr.crash_dumps = $dumps
            $vr.command = $r.CommandLine
        }
        $viewerRuns.Add($vr)
        Write-Host ('TlbbViewer ' + $sid + ' [scene]: ' + $vr.status + ' rc=' + $vr.exit_code + ' ' + $vr.seconds + ' s ' + $vr.reason)
    }

    # ---------------------------------------------------------------- 3. Game.exe (never started here)
    $game = [ordered]@{ tool = 'Game.exe'; status = 'SKIPPED' }
    if (Test-Path -LiteralPath (Join-Path $Bin 'Game.exe')) {
        $game.reason = 'not started: no confirmed offline mode from the game-layer agent (never launch a client that can log in)'
    } else {
        $game.reason = 'not built at this commit'
    }

    $all = @($og) + @($viewerRuns.ToArray())
    $executed = @($all | Where-Object { $_.status -ne 'SKIPPED' })
    $bad = @($all | Where-Object { @('FAIL', 'CRASH', 'TIMEOUT') -contains $_.status })
    $skipped = @($all | Where-Object { $_.status -eq 'SKIPPED' })
    if ($bad.Count) { $result = 'FAIL' }
    elseif (-not $executed.Count) { $result = 'SKIPPED' }
    elseif ($skipped.Count) { $result = 'PARTIAL' }
    else { $result = 'OK' }
    $smoke = [ordered]@{
        schema      = 1
        sha         = $stage.sha
        short       = $stage.short
        label       = $label
        result      = $result
        started     = $started.ToString('s')
        finished    = (Get-Date).ToString('s')
        bin64       = $Bin
        data_dir    = $dataDir
        data_reason = $stage.data_reason
        ci_result   = $stage.ci_result
        cases_file  = $casesFile
        gpu         = $gpu
        timings     = [ordered]@{
            unit = 'ms'
            cache_path = $cachePath
            measurement_note = 'CPU snapshots are not run averages; RTX 2060 is shared with background upscale. Script timings include only emitted log entries.'
            cache_note = 'Hit/miss totals: OgreSmoke after scripts; TlbbViewer at exit. File snapshots bracket the entire process.'
            ogresmoke = $og.timings
            viewer = @($viewerRuns.ToArray() | ForEach-Object { [ordered]@{ case = $_.case; phases = $_.timings } })
        }
        counts      = [ordered]@{ runs = $all.Count; executed = $executed.Count; ok = @($all | Where-Object { $_.status -eq 'OK' }).Count; bad = $bad.Count; skipped = $skipped.Count }
        ogresmoke   = $og
        viewer      = $viewerRuns.ToArray()
        game        = $game
        out_dir     = $out
    }
    $smokePath = Join-Path $logRoot ($base + '.json')
    Write-JsonFile $smoke $smokePath
    Write-Host ('SMOKE ' + $label + ': ' + $result + ' (' + $smoke.counts.ok + ' ok / ' + $bad.Count + ' bad / ' + $skipped.Count + ' skipped) -> ' + $smokePath)
    if ($result -eq 'OK') { $exitCode = 0 } else { $exitCode = 1 }
} catch {
    Write-Host ('SMOKE ERROR: ' + $_.Exception.Message + ' @ ' + $_.InvocationInfo.PositionMessage)
    $exitCode = 2
} finally {
    Exit-CysLock
}
exit $exitCode
