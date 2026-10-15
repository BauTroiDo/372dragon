param(
    [string]$Root = '',
    [string]$BuildDir = '',
    [string]$OutDir = '',
    [ValidateRange(1,5)][int]$Jobs = 3
)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')) }
$Root = [IO.Path]::GetFullPath($Root).TrimEnd('\')
if (-not $BuildDir) { $BuildDir = Join-Path $Root 'Build\cmake\gpt-luaapi-tests' }
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\2026-09-12-gpt-p1-2\tests\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
$buildRoot = Join-Path $Root 'Build'
foreach ($path in @($BuildDir, $OutDir)) {
    $full = [IO.Path]::GetFullPath($path).TrimEnd('\')
    if (-not $full.StartsWith($buildRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw ('Output must be inside repo Build: ' + $full) }
    $cursor = $full
    while ($cursor) {
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw ('Output must not traverse junction: ' + $cursor) }
        $cursor = Split-Path -Parent $cursor
    }
}
[void][IO.Directory]::CreateDirectory($BuildDir)
[void][IO.Directory]::CreateDirectory($OutDir)
$runBuild = Join-Path $BuildDir ((Get-Date -Format 'yyyyMMdd-HHmmss-fffffff') + '-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runBuild)
$tempDir = Join-Path $runBuild 'tmp'
[void][IO.Directory]::CreateDirectory($tempDir)
$env:TEMP = $tempDir
$env:TMP = $tempDir
$env:PYTHONUTF8 = '1'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:CMAKE_BUILD_PARALLEL_LEVEL = [string]$Jobs
. (Join-Path $Root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$lua = Join-Path $Root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$generated = Join-Path $Root 'Src\Client\LuaApiGen'
$library = Join-Path $Root 'Build\cmake\ci-x64\lib\LuaPlus.lib'
$dll = Join-Path $Root 'Build\cmake\ci-x64\bin\LuaPlus.dll'
if (-not (Test-Path -LiteralPath $library) -or -not (Test-Path -LiteralPath $dll)) { throw 'Build cys_luaplus with CI first; LuaPlus import library and DLL are required.' }
$exe = Join-Path $runBuild 'luaapi_tests.exe'
$sources = @((Join-Path $PSScriptRoot 'luaapi_tests.cpp'), (Join-Path $generated 'CysHostGlobals.cpp')) + @(Get-ChildItem -LiteralPath $generated -Filter 'LuaApiGen_*.cpp' | Sort-Object Name | ForEach-Object { $_.FullName })
$arguments = @('/nologo','/MD','/EHs','/EHc-','/O2','/Zi','/std:c++14','/source-charset:utf-8','/execution-charset:.936',('/MP'+$Jobs),'/DLUAPLUS_HAS_WCHAR_T',('/I'+$lua),('/I'+$generated),('/Fo'+$runBuild+'\'),('/Fd'+(Join-Path $runBuild 'compiler.pdb')),('/Fe'+$exe)) + $sources + @($library)
$rsp = Join-Path $runBuild 'compile.rsp'
[IO.File]::WriteAllLines($rsp, @($arguments | ForEach-Object { ConvertTo-ProcArg $_ }), [Text.Encoding]::ASCII)
$buildLog = Join-Path $OutDir 'build.log'
$runLog = Join-Path $OutDir 'tests.log'
$command = 'cl.exe @' + (ConvertTo-ProcArg $rsp)
$buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog
$runRc = $null
if ($buildRc -eq 0) {
    [IO.File]::Copy($dll, (Join-Path $runBuild 'LuaPlus.dll'))
    $dictionary = Join-Path $Root 'Assets\Canonical\Data\ConfigFolder\StrDictionary.txt'
    $runRc = Invoke-CmdLogged -CommandLine ((ConvertTo-ProcArg $exe) + ' ' + (ConvertTo-ProcArg $dictionary)) -LogFile $runLog
}
$result = [ordered]@{build_rc=$buildRc; run_rc=$runRc; executable=$exe; command=$command; build_log=$buildLog; test_log=$runLog; jobs=$Jobs; source_count=$sources.Count; lua_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash}
$resultPath = Join-Path $OutDir 'result.json'
[IO.File]::WriteAllText($resultPath, ($result | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
if ($buildRc -eq 0) { Get-Content -LiteralPath $runLog }
Write-Host ('Evidence: ' + $resultPath)
if ($buildRc -ne 0 -or $runRc -ne 0) { exit 1 }
exit 0
