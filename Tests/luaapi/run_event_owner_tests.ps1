param([string]$BeforeRoot = '', [string]$OutDir = '')
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\2026-09-12-gpt-p1-2\tests\event-owner\run-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
$fullOut = [IO.Path]::GetFullPath($OutDir).TrimEnd('\')
if (-not $fullOut.StartsWith((Join-Path $Root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'OutDir must stay inside repo Build.' }
$cursor = $fullOut
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw ('OutDir must not traverse junction: '+$cursor) }
    $cursor = Split-Path -Parent $cursor
}
[void][IO.Directory]::CreateDirectory($fullOut)
$env:TEMP = Join-Path $fullOut 'tmp'
$env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $Root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$results = @()
$modes = @('after')
if ($BeforeRoot) { $modes = @('before','after') }
foreach ($mode in $modes) {
    $out = Join-Path $fullOut $mode
    [void][IO.Directory]::CreateDirectory($out)
    $exe = Join-Path $out 'event_owner_tests.exe'
    $inc = @()
    if ($mode -eq 'before') {
        $inc += '/I'+(Join-Path $BeforeRoot 'Src\Engine\Interface')
        $inc += '/I'+(Join-Path $BeforeRoot 'Src\Client\WXClient\Event')
    }
    $inc += '/I'+(Join-Path $Root 'Src\Engine\Interface')
    $inc += '/I'+(Join-Path $Root 'Src\Client\WXClient\Event')
    $args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS','/source-charset:utf-8','/execution-charset:.936',('/Fo'+(Join-Path $out 'event_owner_tests.obj')),('/Fe'+$exe)) + $inc + @((Join-Path $PSScriptRoot 'event_owner_tests.cpp'))
    $command = 'cl.exe ' + (Join-CmdArgs $args)
    $buildLog = Join-Path $out 'build.log'
    $testLog = Join-Path $out 'tests.log'
    $buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog
    $runRc = $null
    if ($buildRc -eq 0) {
        $runRc = Invoke-CmdLogged -CommandLine (ConvertTo-CmdArg $exe) -LogFile $testLog
        Write-Host $mode
        Get-Content -LiteralPath $testLog
    }
    $results += [ordered]@{mode=$mode;build_rc=$buildRc;run_rc=$runRc;command=$command;build_log=$buildLog;test_log=$testLog}
}
$resultPath = Join-Path $fullOut 'results.json'
[IO.File]::WriteAllText($resultPath, (ConvertTo-Json -InputObject $results -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ('Evidence: '+$resultPath)
foreach ($r in $results) {
    if ($r.build_rc -ne 0) { exit 1 }
    if ($r.mode -eq 'after' -and $r.run_rc -ne 0) { exit 1 }
    if ($r.mode -eq 'before' -and $r.run_rc -ne 1) { exit 1 }
}
exit 0
