param(
    [string]$OutDir = '',
    [string]$ReferenceList = '',
    [ValidateRange(1,3)][int]$Jobs = 3
)
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\2026-09-13-gpt-login-areas\tests\login-areas\run-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
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
$exe = Join-Path $binary 'login_area_tests.exe'
$lua = Join-Path $Root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$hostSource = Join-Path $Root 'Src\Client\LuaApiGen'
$library = Join-Path $Root 'Build\cmake\ci-x64\lib\LuaPlus.lib'
$dll = Join-Path $Root 'Build\cmake\ci-x64\bin\LuaPlus.dll'
if (-not (Test-Path -LiteralPath $library) -or -not (Test-Path -LiteralPath $dll)) { throw 'Existing CI LuaPlus library and DLL are required.' }
$sources = @(
    (Join-Path $PSScriptRoot 'login_area_tests.cpp'),
    (Join-Path $hostSource 'CysHostQueries.cpp'),
    (Join-Path $hostSource 'LuaApiGen_Common.cpp'),
    (Join-Path $hostSource 'LuaApiGen_GameProduceLogin.cpp'),
    (Join-Path $Root 'Src\Client\WXClient\Procedure\CysLoginList.cpp')
)
$glLogon = Join-Path $Root 'Assets\Canonical\Data\InterfaceFolder\Logon\LogOn.lua'
$trackedInputs = $sources + @($glLogon,(Join-Path $Root 'Src\Client\WXClient\Procedure\CysLoginList.h'),(Join-Path $hostSource 'CysHostQueries.h'),(Join-Path $hostSource 'LuaApiGen.h'))
$before = @($trackedInputs | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} })
$args = @('/nologo','/MD','/EHs','/EHc-','/O2','/std:c++14',('/MP'+$Jobs),'/DLUAPLUS_HAS_WCHAR_T','/source-charset:utf-8','/execution-charset:.936',('/Fo'+$binary+'\'),('/Fe'+$exe),('/I'+$lua),('/I'+$hostSource),('/I'+(Join-Path $Root 'Src\Client\WXClient\Procedure'))) + $sources + @($library)
$command = 'cl.exe ' + (Join-CmdArgs $args)
$buildLog = Join-Path $fullOut 'build.log'
$testLog = Join-Path $fullOut 'tests.log'
$buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog
$runRc = $null
if ($buildRc -eq 0) {
    [IO.File]::Copy($dll,(Join-Path $binary 'LuaPlus.dll'))
    $processInfo = New-Object Diagnostics.ProcessStartInfo
    $processInfo.FileName = $exe
    $referenceFull = ''
    if ($ReferenceList) {
        $referenceFull = [IO.Path]::GetFullPath($ReferenceList)
        if (-not $referenceFull.StartsWith((Join-Path $Root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'ReferenceList must be inside repo Build.' }
    }
    $processInfo.Arguments = '"'+$referenceFull+'" "'+$glLogon+'"'
    $processInfo.WorkingDirectory = $binary
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $processInfo
    try {
        if (-not $process.Start()) { throw 'Could not start isolated login area test.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit(5000)
        if ($timedOut) { $process.Kill(); $process.WaitForExit() }
        $output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
        if ($timedOut) { $output += "`nFAIL runner: five-second process timeout`n" }
        [IO.File]::WriteAllText($testLog,$output,(New-Object Text.UTF8Encoding($false)))
        Write-Host $output
        $runRc = if ($timedOut) { 124 } else { $process.ExitCode }
    }
    finally { $process.Dispose() }
}
$unchanged = $true
foreach ($entry in $before) { if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.sha256) { $unchanged = $false } }
$result = [ordered]@{
    build_rc=$buildRc;run_rc=$runRc;source_unchanged=$unchanged;command=$command;
    build_log=$buildLog;test_log=$testLog;executable=$exe;source_count=$sources.Count;jobs=$Jobs;
    timeout_seconds=5;reference_list=$ReferenceList;gl_logon_script=$glLogon;synthetic_regions=$true;game_runtime=$false;
    lua_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash;source_hashes=$before
}
$resultPath = Join-Path $fullOut 'result.json'
[IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
Write-Host ('Evidence: '+$resultPath)
if ($buildRc -ne 0 -or $runRc -ne 0 -or -not $unchanged) { exit 1 }
exit 0
