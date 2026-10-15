<#
.SYNOPSIS
  The whole CI in one command: ci.ps1 -> stage.ps1 -> smoke.ps1 -> checks.ps1 -> tests.ps1 on one commit.
  Writes Build\Logs\ci\<short-sha>\all.json and prints one line per step.
.DESCRIPTION
  Every step keeps its own log and JSON exactly as when it is run by hand; this script only chains them, stops when
  a step cannot be followed by the next one, and prints the result table. It is the command to use after a series
  of commits, instead of remembering the four separate invocations of Timeline\handoff\ci.md.
    ci      build the committed tree (Build\ci\wt -> Build\cmake\ci-x64)         Build\Logs\ci\<sha>\summary.txt
    stage   copy the binaries into Build\Client\Bin64 + Build\Symbols\ci         Bin64\cys_stage.json
    smoke   OgreSmoke + TlbbViewer model and scene runs on Assets\CanonicalCY    <sha>\smoke.json
    checks  protocol / pathlib / scene gates (runs the copy in the worktree)     <sha>\checks.json
    tests   staged unit executables + offline Python suites                      <sha>\tests.json
  A step is skipped when the previous one did not produce what it needs (for example checks needs a green smoke).
  Exit codes: 0 every step OK, 1 a step reported failures, 2 setup error, 3 CI busy (another run holds the lock).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\ci_all.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\ci_all.ps1 -Sha 358ec81 -Jobs 5
.NOTES
  -Jobs defaults to 4 because the machine is shared with the other agents; ci.ps1 called alone still defaults to 5.
  Nothing here starts Game.exe or touches the private server.
#>
param(
    [string]$Sha = 'HEAD',
    [ValidateRange(1, 5)][int]$Jobs = 4,
    [ValidateSet('Release', 'RelWithDebInfo', 'Debug')][string]$Config = 'Release',
    [switch]$NoSmoke,
    [switch]$NoChecks,
    [switch]$NoTests,
    [switch]$BuildOnly,
    [switch]$Fresh,
    [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
if ($Root) { $script:CysRoot = (Resolve-Path -LiteralPath $Root).Path }
$P = Get-CysPaths

# Runs one pipeline script in its own Windows PowerShell (output inherited) and returns the exit code.
function Invoke-Step([string]$Script, [string[]]$Extra = @()) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $PSHOME 'powershell.exe'
    $path = if ([IO.Path]::IsPathRooted($Script)) { $Script } else { Join-Path $PSScriptRoot $Script }
    $all = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $path) + $Extra
    $psi.Arguments = ($all | ForEach-Object { ConvertTo-ProcArg $_ }) -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()
    return $p.ExitCode
}

$r = Invoke-Exe git @('-C', $P.Root, 'rev-parse', '--verify', ($Sha + '^{commit}'))
if ($r.Rc -ne 0 -or -not $r.Out.Count) { Write-Host ('CI ALL ERROR: cannot resolve ' + $Sha); exit 2 }
$full = $r.Out[-1].Trim()
$short = (Invoke-Exe git @('-C', $P.Root, 'rev-parse', '--short', $full)).Out[-1].Trim()
$subject = (Invoke-Exe git @('-C', $P.Root, 'log', '-1', '--format=%s', $full)).Out[-1]
$started = Get-Date
Write-Host ('==== CI ALL ' + $short + ' jobs=' + $Jobs + ' started ' + $started.ToString('s'))

$steps = New-Object System.Collections.Generic.List[object]
function Add-Step([string]$Name, $Rc, [double]$Seconds, [string]$Note = '') {
    # switch ($null) matches no branch in Windows PowerShell, so the skipped case is handled before it.
    $status = 'SKIP'
    if ($null -ne $Rc) {
        $status = switch ([int]$Rc) { 0 { 'OK' } 1 { 'FAIL' } 2 { 'ERROR' } 3 { 'BUSY' } default { 'FAIL' } }
    }
    $steps.Add([ordered]@{ name = $Name; status = $status; rc = $Rc; seconds = [math]::Round($Seconds, 1); note = $Note })
    Write-Host ('STEP ' + $Name.PadRight(7) + $status.PadRight(6) + 'rc=' + $Rc + ' ' + [math]::Round($Seconds, 1) + 's ' + $Note)
}

$w = [Diagnostics.Stopwatch]::StartNew()
$ciArgs = @('-Sha', $full, '-Jobs', [string]$Jobs, '-Config', $Config, '-Root', $P.Root)
if ($Fresh) { $ciArgs += '-Fresh' }
$ci = Invoke-Step 'ci.ps1' $ciArgs
Add-Step 'ci' $ci $w.Elapsed.TotalSeconds

$stage = $null; $smoke = $null; $checks = $null; $tests = $null
if ($ci -eq 3) {
    Write-Host 'CI ALL: another CI run holds the lock; nothing else was started'
} elseif ($ci -eq 2) {
    Write-Host 'CI ALL: the build step could not run; see build.log'
} elseif (-not $BuildOnly) {
    $w.Restart()
    $stage = Invoke-Step 'stage.ps1' @('-Root', $P.Root)
    Add-Step 'stage' $stage $w.Elapsed.TotalSeconds
    if ($stage -eq 0 -or $stage -eq 1) {
        if (-not $NoSmoke) {
            $w.Restart()
            $smoke = Invoke-Step 'smoke.ps1' @('-Root', $P.Root)
            Add-Step 'smoke' $smoke $w.Elapsed.TotalSeconds
        } else { Add-Step 'smoke' $null 0 '-NoSmoke' }
        # checks.ps1 dispatches the committed copy in Build\ci\wt and needs a green smoke at the same commit.
        if (-not $NoChecks) {
            if ($smoke -eq 0) {
                $w.Restart()
                $checks = Invoke-Step 'checks.ps1' @('-Root', $P.Root)
                Add-Step 'checks' $checks $w.Elapsed.TotalSeconds
            } else { Add-Step 'checks' $null 0 'needs smoke OK at the same commit' }
        } else { Add-Step 'checks' $null 0 '-NoChecks' }
        if (-not $NoTests) {
            $w.Restart()
            $tests = Invoke-Step 'tests.ps1' @('-Root', $P.Root)
            Add-Step 'tests' $tests $w.Elapsed.TotalSeconds
        } else { Add-Step 'tests' $null 0 '-NoTests' }
    } else {
        Write-Host 'CI ALL: stage did not produce a usable Bin64; smoke/checks/tests skipped'
    }
}

$logDir = Join-Path $P.LogsCi $short
New-Item -ItemType Directory -Force $logDir | Out-Null
$bad = @($steps | Where-Object { $_.status -eq 'FAIL' -or $_.status -eq 'ERROR' })
$busy = @($steps | Where-Object { $_.status -eq 'BUSY' })
$result = if ($busy.Count) { 'BUSY' } elseif ($bad.Count) { 'FAIL' } else { 'OK' }
$summary = Read-JsonFile (Join-Path $logDir 'summary.json')
$smokeJson = Read-JsonFile (Join-Path $logDir 'smoke.json')
$checksJson = Read-JsonFile (Join-Path $logDir 'checks.json')
$testsJson = Read-JsonFile (Join-Path $logDir 'tests.json')
$all = [ordered]@{
    schema = 1; sha = $full; short = $short; subject = $subject; jobs = $Jobs; config = $Config
    started = $started.ToString('s'); finished = (Get-Date).ToString('s')
    seconds = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
    result = $result; steps = $steps.ToArray()
    targets = $(if ($summary -and $summary.counts) { [string]$summary.counts.OK + '/' + [string]$summary.counts.targets } else { $null })
    # Only report a sub-count for a step that ran in THIS invocation; an older JSON in the same folder is not it.
    checks = $(if ($null -ne $checks -and $checksJson) { [string]@($checksJson.checks | Where-Object { $_.status -eq 'OK' }).Count + '/' + [string]@($checksJson.checks).Count } else { $null })
    tests = $(if ($null -ne $tests -and $testsJson) { [string]$testsJson.suites_ok + '/' + [string]$testsJson.suites_total } else { $null })
    smoke = $(if ($null -ne $smoke -and $smokeJson) { $smokeJson.result } else { $null })
    files = [ordered]@{
        summary = (Join-Path $logDir 'summary.txt'); smoke = (Join-Path $logDir 'smoke.json')
        checks = (Join-Path $logDir 'checks.json'); tests = (Join-Path $logDir 'tests.json')
    }
}
Write-JsonFile $all (Join-Path $logDir 'all.json')
Write-Host ''
Write-Host ('CI ALL ' + $short + ': ' + $result + '  targets ' + $all.targets + '  smoke ' + $all.smoke +
    '  checks ' + $all.checks + '  tests ' + $all.tests + '  (' + $all.seconds + 's)')
Write-Host ('  ' + (Join-Path $logDir 'all.json'))
if ($busy.Count) { exit 3 }
if (@($steps | Where-Object { $_.status -eq 'ERROR' }).Count) { exit 2 }
if ($bad.Count) { exit 1 }
exit 0
