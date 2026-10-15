param([string]$Out = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
$P = Get-CysPaths
if (-not $Out) {
    $Out = Join-Path $P.Root ('Build\Logs\' + (Get-Date -Format 'yyyy-MM-dd') + '-gpt-p0-5\test-' + (Get-Date -Format 'HHmmss-fffffff'))
}
$Out = [IO.Path]::GetFullPath($Out)
$buildPrefix = [IO.Path]::GetFullPath((Join-Path $P.Root 'Build')).TrimEnd('\') + '\'
if (-not $Out.StartsWith($buildPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Test output must be inside CY-Source Build' }
$cursor = $Out
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw ('Test output crosses a reparse point: ' + $cursor) }
    $cursor = Split-Path -Parent $cursor
}
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$rows = New-Object System.Collections.Generic.List[object]
$summary = New-Object System.Collections.Generic.List[string]
function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ($null -eq $Expected) {
        if ($null -ne $Actual) { throw ($Label + ': expected null, actual=' + $Actual) }
    } elseif ($Actual -cne $Expected) { throw ($Label + ': expected=' + $Expected + ', actual=' + $Actual) }
}
function Assert-Near([double]$Actual, [double]$Expected, [string]$Label) {
    if ([Math]::Abs($Actual - $Expected) -gt 0.000001) { throw ($Label + ': expected=' + $Expected + ', actual=' + $Actual) }
}
function Test-Case([string]$Name, [scriptblock]$Body) {
    $detail = $null
    $errorText = $null
    try { $detail = & $Body; $ok = $true } catch { $ok = $false; $errorText = $_.Exception.Message }
    $rows.Add([ordered]@{ name = $Name; ok = $ok; detail = $detail; error = $errorText })
    $label = if ($ok) { 'OK ' } else { 'FAIL ' }
    $line = $label + $Name
    if ($errorText) { $line += ': ' + $errorText }
    $summary.Add($line)
    Write-Host $line
}
function Assert-Script($Result, [string]$Name, [string]$Group, [int]$Milliseconds) {
    $matches = @($Result.scripts | Where-Object { $_.name -ceq $Name -and $_.group -ceq $Group })
    Assert-Equal $matches.Count 1 ('script count: ' + $Group + '/' + $Name)
    Assert-Equal $matches[0].milliseconds $Milliseconds ('script time: ' + $Group + '/' + $Name)
}

Test-Case 'load-helper' {
    . (Join-Path $PSScriptRoot 'ci_timings.ps1')
    Assert-Equal ([bool](Get-Command Get-CysViewerTimings -ErrorAction SilentlyContinue)) $true 'viewer helper exists'
    Assert-Equal ([bool](Get-Command Get-CysOgreTimings -ErrorAction SilentlyContinue)) $true 'ogre helper exists'
}
# Load into script scope as well; subsequent cases report errors if the helper failed to load.
if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ci_timings.ps1')) { . (Join-Path $PSScriptRoot 'ci_timings.ps1') }

# Fixed expectations were transcribed from historical logs, independently of the parser.
$fixtures = @(
    @{ hash = 'dae48f3'; ready = 40906; script_count = 19; character = 5625; material = 23188; particle = 1703; bootstrap = 738.55; general = 1486.46; cache = $false },
    @{ hash = '80fc02c'; ready = 21109; script_count = 10; character = 266; material = 13453; particle = 1750; bootstrap = 653.382; general = 1361.85; cache = $true }
)
foreach ($fixture in $fixtures) {
    Test-Case ($fixture.hash + '-viewer-M25') {
        $dir = Join-Path $P.LogsCi ($fixture.hash + '\smoke\viewer')
        $log = Join-Path $dir 'M25.png.log'
        $stdout = [IO.File]::ReadAllText((Join-Path $dir 'M25.stdout.txt'))
        $actual = Get-CysViewerTimings $log $stdout
        Assert-Equal $actual.engine_ready_ms $fixture.ready 'engine_ready_ms'
        Assert-Equal @($actual.scripts).Count $fixture.script_count 'reported script count'
        Assert-Script $actual 'Character.program' 'Bootstrap' $fixture.character
        Assert-Script $actual 'all.material' 'General' $fixture.material
        Assert-Script $actual 'all.particle' 'General' $fixture.particle
        Assert-Equal @($actual.scripts | Where-Object { $_.name -eq 'all.skill' }).Count 0 'unmeasured all.skill must be absent'
        if ($fixture.cache) {
            Assert-Equal $actual.shader_cache.hits 399 'shader cache hits'
            Assert-Equal $actual.shader_cache.misses 0 'shader cache misses'
        } else { Assert-Equal $actual.shader_cache $null 'historical cache is unknown' }
        return [ordered]@{ log = $log; timings = $actual }
    }
    Test-Case ($fixture.hash + '-ogresmoke') {
        $path = Join-Path $P.LogsCi ($fixture.hash + '\smoke\ogresmoke\stdout.txt')
        $actual = Get-CysOgreTimings ([IO.File]::ReadAllText($path))
        Assert-Near $actual.bootstrap_ms $fixture.bootstrap 'bootstrap_ms'
        Assert-Near $actual.general_ms $fixture.general 'general_ms'
        Assert-Equal $actual.shader_cache.hits 209 'after-scripts cache hits'
        Assert-Equal $actual.shader_cache.misses 0 'after-scripts cache misses, before runtime variants'
        return [ordered]@{ stdout = $path; timings = $actual }
    }
}

# Generate a GBK log without embedding non-ASCII bytes in this PowerShell source.
$gbkName = ([string][char]0x89D2) + ([string][char]0x8272) + ' body.material'
$syntheticPath = Join-Path $Out 'synthetic-gbk.log'
$syntheticText = @(
    ('20:00:00: [TlbbViewer] parsing script ' + $gbkName + ' (group Bootstrap)'),
    ('20:00:00: [TlbbViewer] ' + $gbkName + ' parsed in 150 ms'),
    '20:00:00: [TlbbViewer] parsing script quick.material (group Bootstrap)',
    ('20:00:00: [TlbbViewer] parsing script ' + $gbkName + ' (group General)'),
    ('20:00:01: [TlbbViewer] ' + $gbkName + ' parsed in 210 ms'),
    '20:00:01: [TlbbViewer] orphan.material parsed in 333 ms',
    '20:00:02: TlbbViewer: engine ready in 54321 ms'
) -join "`n"
[IO.File]::WriteAllBytes($syntheticPath, [Text.Encoding]::GetEncoding(936).GetBytes($syntheticText))
Test-Case 'gbk-name-and-repeated-groups' {
    $actual = Get-CysViewerTimings $syntheticPath ''
    Assert-Script $actual $gbkName 'Bootstrap' 150
    Assert-Script $actual $gbkName 'General' 210
    Assert-Equal @($actual.scripts).Count 3 'two measured occurrences plus orphan'
    Assert-Equal @($actual.scripts | Where-Object { $_.name -eq 'quick.material' }).Count 0 'no invented timing'
    return $actual
}
Test-Case 'orphan-script-group-unknown' {
    $actual = Get-CysViewerTimings $syntheticPath ''
    $orphan = @($actual.scripts | Where-Object { $_.name -eq 'orphan.material' })
    Assert-Equal $orphan.Count 1 'orphan count'
    Assert-Equal $orphan[0].group $null 'orphan group'
    Assert-Equal $orphan[0].milliseconds 333 'orphan duration'
    return $orphan[0]
}
Test-Case 'engine-log-fallback' {
    $actual = Get-CysViewerTimings $syntheticPath ''
    Assert-Equal $actual.engine_ready_ms 54321 'engine from log only'
    Assert-Equal $actual.shader_cache $null 'cache not reported'
    return $actual
}
$emptyPath = Join-Path $Out 'empty.log'
[IO.File]::WriteAllBytes($emptyPath, [byte[]]@())
Test-Case 'missing-viewer-measurements-stay-null' {
    $actual = Get-CysViewerTimings $emptyPath 'unrelated status output'
    Assert-Equal $actual.engine_ready_ms $null 'engine'
    Assert-Equal $actual.shader_cache $null 'cache'
    Assert-Equal @($actual.scripts).Count 0 'scripts'
    return $actual
}
Test-Case 'missing-ogre-measurements-stay-null' {
    $actual = Get-CysOgreTimings 'unrelated status output'
    Assert-Equal $actual.bootstrap_ms $null 'bootstrap'
    Assert-Equal $actual.general_ms $null 'general'
    Assert-Equal $actual.shader_cache $null 'cache'
    return $actual
}
Test-Case 'explicit-zero-cache-is-not-unknown' {
    $actual = Get-CysViewerTimings $emptyPath 'TlbbViewer: engine ready in 0 ms; shader cache hits 0 / misses 0'
    Assert-Equal $actual.engine_ready_ms 0 'measured zero engine'
    Assert-Equal $actual.shader_cache.hits 0 'measured zero hits'
    Assert-Equal $actual.shader_cache.misses 0 'measured zero misses'
    return $actual
}
foreach ($cultureName in @('vi-VN', 'fr-FR')) {
    Test-Case ('decimal-seconds-under-' + $cultureName) {
        $thread = [Threading.Thread]::CurrentThread
        $savedCulture = $thread.CurrentCulture
        try {
            $thread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo($cultureName)
            $actual = Get-CysOgreTimings "shader cache after scripts: hits 2, misses (compiled) 3`nresources: Bootstrap 0.123456 s, General 1.25 s, materials defined: 1"
            Assert-Near $actual.bootstrap_ms 123.456 'bootstrap milliseconds'
            Assert-Near $actual.general_ms 1250 'general milliseconds'
            Assert-Equal $actual.shader_cache.hits 2 'cache hits'
            Assert-Equal $actual.shader_cache.misses 3 'cache misses'
            return $actual
        } finally { $thread.CurrentCulture = $savedCulture }
    }
}
$bad = @($rows | Where-Object { -not $_.ok })
$result = [ordered]@{ passed = $rows.Count - $bad.Count; failed = $bad.Count; checks = $rows.ToArray() }
Write-JsonFile $result (Join-Path $Out 'results.json')
$last = 'CI TIMINGS: ' + $result.passed + '/' + $rows.Count + ' checks passed; failures=' + $result.failed
$summary.Add($last)
[IO.File]::WriteAllText((Join-Path $Out 'summary.txt'), ($summary -join "`n") + "`n", $script:Utf8NoBom)
Write-Host ($last + '; ' + $Out)
if ($bad.Count) { exit 1 }
exit 0
