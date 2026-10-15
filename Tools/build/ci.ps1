<#
.SYNOPSIS
  CY-Source CI: builds the COMMITTED state of the repository (never the half-edited main working tree).
.DESCRIPTION
  1. Detached git worktree of -Sha (default HEAD) at Build\ci\wt. Created on first use with
     "git worktree add --detach", afterwards checked clean and moved with "git checkout --detach <sha>".
     Git-ignored inputs: Build\ci\wt\Src\ThirdParty\_sdk is a directory junction to the main tree's
     Src\ThirdParty\_sdk (FMOD 2.02.35 SDK). The path is in .gitignore, so nothing is ever committed.
     The x64 cg.dll (import library for Plugin_CgProgramManager) is passed as -DCYS_CG_DLL (read-only).
  2. Configures ONE tree Build\cmake\ci-x64 from the worktree's Src with ALL components: the default list of
     Src\CMakeLists.txt (-UCYS_COMPONENTS drops a stale cached list), Ninja, MSVC x64 (vcvarsall), -Config.
  3. Builds with CMAKE_BUILD_PARALLEL_LEVEL = -Jobs (default 5: ten agents share the machine), ninja -k 0.
  4. Writes Build\Logs\ci\<short-sha>\build.log, meta.json, summary.json and summary.txt through
     Tools\build\ci_summary.py (per target OK/FAIL/BLOCKED, first error lines, warnings, durations, owners),
     and updates Build\Logs\ci\latest.json + history.tsv.
  5. CYS-WARNSWEEP: gates on the "group A" warning count (-WarnAMax, exit code 1 when exceeded). The raw
     warning total is useless as a signal - 85% of it is the deliberate D9025 from /EHc- - so only the
     group A count (bad printf format, pointer truncation, uninitialised variable, missing return) is
     gated. summary.txt prints OUR code's count first; see Timeline\handoff\warn-sweep.md.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\ci.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\ci.ps1 -Sha 21ba253 -Jobs 5
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Build\wt-ci-cy\Tools\build\ci.ps1 -Sha ci-cy -Root C:\TLBB\085\CY-Source
.NOTES
  Exit codes: 0 every target OK, 1 build/target failures, 2 infrastructure or configure error, 3 CI busy.
  Never run "git clean" in Build\ci\wt and never delete it with Remove-Item (Windows PowerShell may follow the
  junction). This script never removes the worktree.
#>
param(
    [string]$Sha = 'HEAD',
    [ValidateRange(1, 5)][int]$Jobs = 5,
    [ValidateSet('Release', 'RelWithDebInfo', 'Debug')][string]$Config = 'Release',
    [string]$Components = '',
    [string]$CgDll = 'C:\TLBB\085\client_GL\Bin64\cg.dll',
    [switch]$Fresh,
    [string]$Root = '',
    # CYS-WARNSWEEP 19/09: cong kiem dem canh bao "nhom A" (sai chuoi dinh dang, cat cut con tro,
    # bien chua khoi tao, khong tra ve gia tri...). Vuot nguong => ci.ps1 tra exit code 1.
    # Nguong dat o muc DO DUOC hom nay, KHONG noi rong "cho an toan": mot cong dat long la mot cong
    # khong bao gio do. 69 = so khoan DO DUOC o luot CI dau tien sau commit c305ab35 (lan dau cong
    # nay chay that): 3 ma cua ta + 43 OGRE + 23 ThirdParty. Du bao truoc commit la 70/4; chenh 1 vi
    # TDException.cpp:162 da duoc crash-report sua. Bang chung: Build\Logs\ci\c305ab35\summary.json.
    # Con so dang theo doi la warnings_group_a_ours = 3. Muon tat: -WarnAMax -1.
    # Chi tiet: Timeline\handoff\warn-sweep.md.
    [int]$WarnAMax = 69
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
# CYS: -Root runs this script copy (e.g. from a branch worktree) against the main tree's Build\ci, Build\cmake\ci-x64
# and Build\Logs\ci; the commit is still resolved in that repository (worktrees share the object store).
if ($Root) { $script:CysRoot = (Resolve-Path -LiteralPath $Root).Path }
$P = Get-CysPaths
Enter-CysLock 'ci' @('tree')
$exitCode = 2
$log = $null
$logDir = $null
$full = $null
$short = $null
try {
    # ---------------------------------------------------------------- 1. commit + worktree
    $r = Invoke-Exe git @('-C', $P.Root, 'rev-parse', '--verify', ($Sha + '^{commit}'))
    if ($r.Rc -ne 0 -or -not $r.Out.Count) { throw ("cannot resolve '" + $Sha + "': " + ($r.Out -join ' ')) }
    $full = $r.Out[-1].Trim()
    $short = (Invoke-Exe git @('-C', $P.Root, 'rev-parse', '--short', $full)).Out[-1].Trim()
    $logDir = Join-Path $P.LogsCi $short
    New-Item -ItemType Directory -Force $logDir | Out-Null
    $log = Join-Path $logDir 'build.log'
    if (Test-Path -LiteralPath $log) { Move-CysToQuarantine $log 'ci-logs' }
    $started = Get-Date
    Write-CiLog $log ('==== CI ' + $full + ' (' + $short + ') started ' + $started.ToString('s') + ' jobs=' + $Jobs + ' config=' + $Config)

    $wtGit = Join-Path $P.Wt '.git'
    if (-not (Test-Path -LiteralPath $wtGit)) {
        if ((Test-Path -LiteralPath $P.Wt) -and (Get-ChildItem -Force -LiteralPath $P.Wt | Select-Object -First 1)) {
            throw ($P.Wt + ' exists but is not a git worktree; unlink its Src\ThirdParty\_sdk junction (cmd /c rmdir) and remove it first')
        }
        New-Item -ItemType Directory -Force (Split-Path $P.Wt) | Out-Null
        [void](Invoke-Exe git @('-C', $P.Root, 'worktree', 'prune'))
        Write-CiLog $log ('git worktree add --detach ' + $P.Wt + ' ' + $full)
        $r = Invoke-Exe git @('-C', $P.Root, 'worktree', 'add', '--detach', $P.Wt, $full)
    } else {
        # CYS: never discard another worker's edits, including untracked files.
        $check = Invoke-Exe git @('-C', $P.Wt, 'status', '--porcelain', '--untracked-files=all')
        if ($check.Rc -ne 0) { throw 'cannot inspect CI worktree' }
        if (@($check.Out | Where-Object { $_ }).Count) { throw 'CI worktree is dirty; preserve edits and ask the user' }
        Write-CiLog $log ('git -C ' + $P.Wt + ' checkout --detach ' + $full)
        $r = Invoke-Exe git @('-C', $P.Wt, 'checkout', '--detach', $full)
    }
    Write-CiLog $log (($r.Out | Where-Object { $_ -notmatch '^Updating files:' }) -join "`r`n")
    if ($r.Rc -ne 0) { throw ('git worktree/checkout failed, rc ' + $r.Rc) }
    $wtHead = (Invoke-Exe git @('-C', $P.Wt, 'rev-parse', 'HEAD')).Out[-1].Trim()
    if ($wtHead -ne $full) { throw ('worktree is at ' + $wtHead + ', expected ' + $full) }
    $dirty = @((Invoke-Exe git @('-C', $P.Wt, 'status', '--porcelain', '--untracked-files=no')).Out | Where-Object { $_ })
    if ($dirty.Count) { throw 'CI worktree is dirty after checkout' }

    # Git-ignored SDKs (FMOD): junction Build\ci\wt\Src\ThirdParty\_sdk -> main tree (ignored path, never committed).
    $sdkMain = Join-Path $P.Root 'Src\ThirdParty\_sdk'
    $sdkWt = Join-Path $P.Wt 'Src\ThirdParty\_sdk'
    $sdkState = 'no Src\ThirdParty\_sdk in the main tree'
    if (Test-Path -LiteralPath $sdkMain) {
        $item = Get-Item -LiteralPath $sdkWt -Force -ErrorAction SilentlyContinue
        if ($item -and -not ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            throw ($sdkWt + ' is a real directory, expected a junction to ' + $sdkMain)
        }
        if (-not $item) {
            New-Item -ItemType Directory -Force (Split-Path $sdkWt) | Out-Null
            New-Item -ItemType Junction -Path $sdkWt -Value $sdkMain | Out-Null
            $sdkState = 'junction created -> ' + $sdkMain
        } else {
            $sdkState = 'junction present -> ' + $sdkMain
        }
    }
    $fmodH = Join-Path $sdkWt 'fmod\api\core\inc\fmod.h'
    $fmodVisible = [bool](Test-Path -LiteralPath $fmodH)
    Write-CiLog $log ('_sdk: ' + $sdkState + '; fmod.h visible in worktree: ' + $fmodVisible)

    # ---------------------------------------------------------------- 2. configure
    $vs = Find-VsBuildTools
    Import-VcVars $vs 'x64'
    $cmake = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
    $ninja = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe'
    foreach ($t in @($cmake, $ninja, $P.Python)) {
        if (-not (Test-Path -LiteralPath $t)) { throw ('missing tool ' + $t) }
    }
    if ($Fresh -and (Test-Path -LiteralPath $P.Tree)) {
        Write-CiLog $log ('-Fresh: preserving ' + $P.Tree)
        Move-CysToQuarantine $P.Tree 'ci-fresh'
    }
    New-Item -ItemType Directory -Force $P.Tree | Out-Null
    # CMake File API: codemodel reply gives targets, artifacts, dependencies and defining files for the summary.
    $apiQuery = Join-Path $P.Tree '.cmake\api\v1\query'
    New-Item -ItemType Directory -Force $apiQuery | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $apiQuery 'codemodel-v2'), '')
    $apiReply = Join-Path $P.Tree '.cmake\api\v1\reply'
    if (Test-Path -LiteralPath $apiReply) { Move-CysToQuarantine $apiReply 'ci-cmake-reply' }

    $cfgArgs = @()
    if ($Components) { $cfgArgs += ('-DCYS_COMPONENTS=' + $Components) } else { $cfgArgs += '-UCYS_COMPONENTS' }
    $cfgArgs += @('-S', (Join-Path $P.Wt 'Src'), '-B', $P.Tree, '-G', 'Ninja',
        ('-DCMAKE_MAKE_PROGRAM=' + $ninja.Replace('\', '/')), ('-DCMAKE_BUILD_TYPE=' + $Config))
    if (Test-Path -LiteralPath $CgDll) {
        $cfgArgs += ('-DCYS_CG_DLL=' + $CgDll.Replace('\', '/'))
    } else {
        Write-CiLog $log ('WARNING x64 cg.dll not found: ' + $CgDll + ' (Plugin_CgProgramManager will be skipped)')
    }
    Write-CiLog $log ('==== CONFIGURE ' + (Get-Date -Format s))
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $cfgRc = Invoke-CmdLogged (Join-CmdArgs (@($cmake) + $cfgArgs)) $log
    $cfgSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    Write-CiLog $log ('==== CONFIGURE END rc=' + $cfgRc + ' seconds=' + $cfgSec)

    # ---------------------------------------------------------------- 3. build
    $bRc = $null
    $bSec = 0
    if ($cfgRc -eq 0) {
        $nl = Join-Path $P.Tree '.ninja_log'
        $before = Join-Path $logDir 'ninja_log.before'
        if (Test-Path -LiteralPath $nl) { Copy-Item -LiteralPath $nl $before -Force }
        elseif (Test-Path -LiteralPath $before) { Move-CysToQuarantine $before 'ci-logs' }
        $env:CMAKE_BUILD_PARALLEL_LEVEL = [string]$Jobs
        Write-CiLog $log ('==== BUILD ' + (Get-Date -Format s) + ' CMAKE_BUILD_PARALLEL_LEVEL=' + $Jobs)
        $sw.Restart()
        $bRc = Invoke-CmdLogged (Join-CmdArgs @($cmake, '--build', $P.Tree, '--parallel', [string]$Jobs, '--', '-k', '0')) $log
        $bSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        Write-CiLog $log ('==== BUILD END rc=' + $bRc + ' seconds=' + $bSec)
    }

    # ---------------------------------------------------------------- 4. summary
    $meta = [ordered]@{
        sha                 = $full
        short               = $short
        started             = $started.ToString('s')
        root                = $P.Root
        worktree            = $P.Wt
        tree                = $P.Tree
        config              = $Config
        jobs                = $Jobs
        components_override = $Components
        cg_dll              = $CgDll
        sdk                 = $sdkState
        fmod_visible        = $fmodVisible
        worktree_dirty      = $dirty
        vs                  = $vs
        cmake               = $cmake
        ninja               = $ninja
        configure           = [ordered]@{ rc = $cfgRc; seconds = $cfgSec }
        build               = [ordered]@{ rc = $bRc; seconds = $bSec }
        log                 = $log
    }
    $metaPath = Join-Path $logDir 'meta.json'
    Write-JsonFile $meta $metaPath
    $env:PYTHONIOENCODING = 'utf-8'
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
    # CYS-WARNSWEEP 19/09: chi truyen --warn-a-max khi cong duoc bat (-WarnAMax -1 = tat han).
    $sumArgs = @((Join-Path $PSScriptRoot 'ci_summary.py'), '--meta', $metaPath)
    if ($WarnAMax -ge 0) { $sumArgs += @('--warn-a-max', [string]$WarnAMax) }
    $s = Invoke-Exe $P.Python $sumArgs
    $s.Out | ForEach-Object { Write-Host $_ }
    if ($s.Rc -eq 0 -or $s.Rc -eq 1 -or $s.Rc -eq 2) { $exitCode = $s.Rc } else { throw ('ci_summary.py failed, rc ' + $s.Rc) }
} catch {
    $msg = 'CI ERROR: ' + $_.Exception.Message
    Write-CiLog $log $msg
    $exitCode = 2
    if ($logDir) {
        $fail = [ordered]@{
            schema = 1; sha = $full; short = $short; result = 'INFRA_FAIL'; error = $_.Exception.Message
            finished = (Get-Date).ToString('s'); files = [ordered]@{ build_log = $log }
        }
        Write-JsonFile $fail (Join-Path $logDir 'summary.json')
        Write-JsonFile $fail (Join-Path $P.LogsCi 'latest.json')
    }
} finally {
    Exit-CysLock
}
exit $exitCode
