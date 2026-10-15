param([string]$OutDir = '')
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\2026-09-12-gpt-p1-2\tests\packed\run-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
$fullOut = [IO.Path]::GetFullPath($OutDir).TrimEnd('\')
if (-not $fullOut.StartsWith((Join-Path $Root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'OutDir must stay inside repo Build.' }
$cursor = $fullOut
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw ('OutDir must not traverse junction: '+$cursor) }
    $cursor = Split-Path -Parent $cursor
}
[void][IO.Directory]::CreateDirectory($fullOut)
$binary = Join-Path $fullOut ('bin-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($binary)
$env:TEMP = Join-Path $binary 'tmp'
$env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $Root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe = Join-Path $binary 'packed_format_tests.exe'
$lua = Join-Path $Root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$hostSource = Join-Path $Root 'Src\Client\LuaApiGen'
$library = Join-Path $Root 'Build\cmake\ci-x64\lib\LuaPlus.lib'
$dll = Join-Path $Root 'Build\cmake\ci-x64\bin\LuaPlus.dll'
if (-not (Test-Path -LiteralPath $library) -or -not (Test-Path -LiteralPath $dll)) { throw 'Build cys_luaplus with CI first; LuaPlus import library and DLL are required.' }
$args = @('/nologo','/MD','/EHs','/EHc-','/O2','/std:c++14','/DLUAPLUS_HAS_WCHAR_T','/source-charset:utf-8','/execution-charset:.936',('/Fo'+$binary+'\'),('/Fe'+$exe),('/I'+(Join-Path $Root 'Src\Client\CEGUISystem')),('/I'+$lua),('/I'+$hostSource), (Join-Path $PSScriptRoot 'packed_format_tests.cpp'), (Join-Path $hostSource 'CysHostGlobals.cpp'), $library)
$command = 'cl.exe ' + (Join-CmdArgs $args)
$buildLog = Join-Path $fullOut 'build.log'
$testLog = Join-Path $fullOut 'tests.log'
$buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog
$runRc = $null
$dictionary = Join-Path $Root 'Assets\Canonical\Data\ConfigFolder\StrDictionary.txt'
if ($buildRc -eq 0) {
    [IO.File]::Copy($dll,(Join-Path $binary 'LuaPlus.dll'))
    $runRc = Invoke-CmdLogged -CommandLine (Join-CmdArgs @($exe,$dictionary)) -LogFile $testLog
    Get-Content -LiteralPath $testLog
}
$result = [ordered]@{build_rc=$buildRc;run_rc=$runRc;command=$command;build_log=$buildLog;test_log=$testLog;dictionary=$dictionary;executable=$exe;source_count=2;lua_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash}
$resultPath = Join-Path $fullOut 'result.json'
[IO.File]::WriteAllText($resultPath, ($result | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ('Evidence: '+$resultPath)
if ($buildRc -ne 0 -or $runRc -ne 0) { exit 1 }
exit 0
