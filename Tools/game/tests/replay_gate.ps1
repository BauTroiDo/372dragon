param([string]$RunDir='')
$ErrorActionPreference='Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$source = [IO.File]::ReadAllText((Join-Path $repo 'Tools/game/run_world_gui_live.ps1'))
$start = $source.IndexOf('# CysWorldReplay completes its initial triangle')
$end = $source.IndexOf('# Leaving: the CY system menu', $start)
if ($start -lt 0 -or $end -le $start) { throw 'Cannot locate the production replay checks' }
$block = [scriptblock]::Create($source.Substring($start, $end-$start))
function Grade([string[]]$Lines) {
    $all = $Lines
    $live = @($Lines | Where-Object { $_ -match 'CYS live:' })
    $checks = [ordered]@{}
    . $block
    return [pscustomobject]@{ checks=$checks; path_length=$pathLength; path_points=$movePoints.Count }
}
$baseline = @(
    'CYS live: ground click 1 reachable=1 waypoints=1 limit_move=0',
    'CYS: click-move (0.0,0.0)->(8.0,0.0)',
    'CYS live: ground click 2 reachable=1 waypoints=1 limit_move=0',
    'CYS: click-move (8.0,0.0)->(8.0,8.0)',
    'CYS live: ground click 3 reachable=1 waypoints=1 limit_move=0',
    'CYS: click-move (8.0,8.0)->(0.0,0.0)',
    'CYS live: position before clicks 0.00,0.00 after 0.00,0.00 (delta 0.00,0.00)'
)
$cases = @(
    @{name='baseline'; lines=$baseline; pass=$true},
    @{name='later quest reuses all ids'; lines=($baseline+$baseline); pass=$true},
    @{name='later ui click8'; lines=($baseline+@('CYS live: ground click 8 reachable=1 waypoints=1 limit_move=0')); pass=$true},
    @{name='missing initial click2'; lines=@($baseline | Where-Object {$_ -notmatch 'ground click 2'}); pass=$false},
    @{name='duplicate initial click1'; lines=(@($baseline[0])+$baseline); pass=$false},
    @{name='unreachable initial'; lines=@($baseline -replace 'reachable=1','reachable=0'); pass=$false},
    @{name='movement lock'; lines=@($baseline -replace 'limit_move=0','limit_move=1'); pass=$false},
    @{name='missing completion'; lines=$baseline[0..5]; pass=$false},
    @{name='no click sends'; lines=@($baseline | Where-Object {$_ -notmatch 'CYS: click-move'}); pass=$false}
)
foreach ($case in $cases) {
    $actual=Grade $case.lines
    $passed=-not ($actual.checks.Values -contains $false)
    if ($passed -ne $case.pass) { throw ('Unexpected gate result: '+$case.name) }
    Write-Output ('PASS: '+$case.name)
}
if ($RunDir) {
    $runPath=Join-Path $RunDir 'run.json'
    $logPath=Join-Path $RunDir 'WXClient.log'
    $original=Get-Content -Raw -LiteralPath $runPath | ConvertFrom-Json
    $measured=Grade ([IO.File]::ReadAllLines($logPath))
    $allChecks=[ordered]@{}
    foreach ($property in $original.checks.PSObject.Properties) { $allChecks[$property.Name]=$property.Value }
    foreach ($key in $measured.checks.Keys) { $allChecks[$key]=$measured.checks[$key] }
    $result=[ordered]@{
        reason='Initial world replay is bounded by its own completion record; quest/UI clicks are graded separately.'
        original_run_sha256=(Get-FileHash -LiteralPath $runPath).Hash.ToLowerInvariant()
        original_log_sha256=(Get-FileHash -LiteralPath $logPath).Hash.ToLowerInvariant()
        runner_sha256=(Get-FileHash -LiteralPath (Join-Path $repo 'Tools/game/run_world_gui_live.ps1')).Hash.ToLowerInvariant()
        game_sha256=$original.game_sha256
        stage_manifest_sha256=$original.stage_manifest_sha256
        original_passed=$original.passed
        path_length=$measured.path_length
        path_points=$measured.path_points
        checks=$allChecks
        passed=(-not ($allChecks.Values -contains $false))
    }
    $destination=Join-Path $RunDir 'world-regrade-initial-replay.json'
    if (Test-Path -LiteralPath $destination) { throw 'Refusing to overwrite a prior regrade' }
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $destination -Encoding UTF8
    Write-Output ('Regrade saved; passed='+$result.passed)
}
