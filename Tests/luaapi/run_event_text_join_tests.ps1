param([string]$OutDir = '')
# CYS-QUEST: unit tests of the event-list text join (header Src\Client\WXClient\Network\CysEventTextJoin.h).
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\event-text-join\run-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
$fullOut = [IO.Path]::GetFullPath($OutDir).TrimEnd('\')
[void][IO.Directory]::CreateDirectory($fullOut)
$binary = Join-Path $fullOut ('bin-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($binary)
$env:TEMP = Join-Path $binary 'tmp'
$env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
$ciRoot = $Root
if (-not (Test-Path -LiteralPath (Join-Path $ciRoot 'Tools\build\ci_common.ps1'))) { throw 'Tools\build\ci_common.ps1 missing' }
. (Join-Path $ciRoot 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe = Join-Path $binary 'event_text_join_tests.exe'
$args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/W4','/utf-8',('/Fo'+$binary+'\'),('/Fe'+$exe),('/I'+(Join-Path $Root 'Src\Client\WXClient\Network')),(Join-Path $PSScriptRoot 'event_text_join_tests.cpp'))
$command = 'cl.exe ' + (Join-CmdArgs $args)
$buildLog = Join-Path $fullOut 'build.log'
$testLog = Join-Path $fullOut 'tests.log'
$buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog
$runRc = $null
$dictionary = Join-Path (Split-Path -Parent (Split-Path -Parent $Root)) 'Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt'
if (-not (Test-Path -LiteralPath $dictionary)) { $dictionary = Join-Path $Root 'Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt' }
if ($buildRc -eq 0) {
    $runRc = Invoke-CmdLogged -CommandLine (Join-CmdArgs @($exe,$dictionary)) -LogFile $testLog
    Get-Content -LiteralPath $testLog -Encoding UTF8
} else { Get-Content -LiteralPath $buildLog }
$result = [ordered]@{build_rc=$buildRc;run_rc=$runRc;command=$command;build_log=$buildLog;test_log=$testLog;dictionary=$dictionary;executable=$exe}
[IO.File]::WriteAllText((Join-Path $fullOut 'result.json'), ($result | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ('Evidence: '+(Join-Path $fullOut 'result.json'))
if ($buildRc -ne 0 -or $runRc -ne 0) { exit 1 }
exit 0
