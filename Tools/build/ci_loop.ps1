<#
.SYNOPSIS
  CI loop: polls HEAD of C:\TLBB\085\CY-Source every -IntervalMinutes and runs ci.ps1 -> stage.ps1 -> smoke.ps1 -> checks.ps1
  for every new commit. Stops after -MaxHours, or when HEAD has not changed for -IdleMinutes.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\ci_loop.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\ci_loop.ps1 -IntervalMinutes 10 -MaxHours 1
.NOTES
  Events: Build\Logs\ci\loop.log. The commit in Build\Logs\ci\latest.json is treated as already built.
  After a run the loop re-checks HEAD at once (commits often land while a build runs). No new build starts after
  -MaxHours. A busy CI lock (another ci/stage/smoke running) is retried at the next poll.
#>
param(
    [int]$IntervalMinutes = 20,
    [double]$MaxHours = 3,
    [int]$IdleMinutes = 60,
    [switch]$NoSmoke
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
$P = Get-CysPaths
New-Item -ItemType Directory -Force $P.LogsCi | Out-Null
$loopLog = Join-Path $P.LogsCi 'loop.log'

function Write-LoopEvent([string]$Message) {
    $line = (Get-Date -Format s) + ' ' + $Message
    [System.IO.File]::AppendAllText($loopLog, $line + "`r`n", $script:Utf8NoBom)
    Write-Host $line
}

# Runs one pipeline script in a child Windows PowerShell (output inherited), returns its exit code.
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

$start = Get-Date
$lastChange = $start
$built = $null
$latest = Read-JsonFile (Join-Path $P.LogsCi 'latest.json')
if ($latest -and $latest.sha -and $latest.result -ne 'INFRA_FAIL') { $built = $latest.sha }
Write-LoopEvent ('LOOP start interval=' + $IntervalMinutes + 'm maxHours=' + $MaxHours + ' idle=' + $IdleMinutes + 'm already built=' + $built)
while ($true) {
    $h = Invoke-Exe git @('-C', $P.Root, 'rev-parse', 'HEAD')
    $head = $null
    if ($h.Rc -eq 0 -and $h.Out.Count) { $head = $h.Out[-1].Trim() }
    $now = Get-Date
    if ($head -and $head -ne $built) {
        if (($now - $start).TotalHours -ge $MaxHours) { Write-LoopEvent ('LOOP stop: ' + $MaxHours + ' h reached, new HEAD ' + $head + ' not built'); break }
        $lastChange = $now
        Write-LoopEvent ('NEW HEAD ' + $head)
        $ci = Invoke-Step 'ci.ps1' @('-Sha', $head)
        if ($ci -eq 3) { Write-LoopEvent 'BUSY: another CI step holds the lock; retry at the next poll'; Start-Sleep -Seconds ($IntervalMinutes * 60); continue }
        $st = 'skipped'
        $sm = 'skipped'
        $ck = 'skipped'
        if ($ci -eq 0 -or $ci -eq 1) {
            $st = Invoke-Step 'stage.ps1'
            if (-not $NoSmoke -and ($st -eq 0 -or $st -eq 1)) { $sm = Invoke-Step 'smoke.ps1' }
            # CYS: gates execute the committed script and test sources from the CI worktree.
            if ($sm -eq 0) { $ck = Invoke-Step (Join-Path $P.Wt 'Tools\build\checks.ps1') @('-Root', $P.Root) }
        }
        $built = $head
        $res = Read-JsonFile (Join-Path $P.LogsCi 'latest.json')
        $txt = ''
        if ($res) { $txt = ' result=' + $res.result + ' targets=' + $res.targets_ok + '/' + $res.targets_total }
        Write-LoopEvent ('DONE ' + $head + ' ci=' + $ci + ' stage=' + $st + ' smoke=' + $sm + ' checks=' + $ck + $txt)
        continue
    }
    if (($now - $lastChange).TotalMinutes -ge $IdleMinutes) { Write-LoopEvent ('LOOP stop: HEAD unchanged for ' + $IdleMinutes + ' min'); break }
    if (($now - $start).TotalHours -ge $MaxHours) { Write-LoopEvent ('LOOP stop: ' + $MaxHours + ' h reached'); break }
    $sleep = $IntervalMinutes * 60
    $toIdle = ($lastChange.AddMinutes($IdleMinutes) - $now).TotalSeconds + 5
    $toEnd = ($start.AddHours($MaxHours) - $now).TotalSeconds + 5
    $sleep = [math]::Max(5, [math]::Min($sleep, [math]::Min($toIdle, $toEnd)))
    Write-LoopEvent ('poll: HEAD ' + $head + ' unchanged, next check in ' + [int]$sleep + ' s')
    Start-Sleep -Seconds ([int]$sleep)
}
