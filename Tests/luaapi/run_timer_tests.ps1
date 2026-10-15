param(
    [string]$OutDir = '',
    [ValidateRange(1,3)][int]$Jobs = 3
)
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\2026-09-12-gpt-p1-2\tests\timers\run-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
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
$env:PYTHONUTF8 = '1'
$env:PYTHONDONTWRITEBYTECODE = '1'
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $Root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe = Join-Path $binary 'timer_tests.exe'
$lua = Join-Path $Root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$hostSource = Join-Path $Root 'Src\Client\LuaApiGen'
$library = Join-Path $Root 'Build\cmake\ci-x64\lib\LuaPlus.lib'
$dll = Join-Path $Root 'Build\cmake\ci-x64\bin\LuaPlus.dll'
if (-not (Test-Path -LiteralPath $library) -or -not (Test-Path -LiteralPath $dll)) { throw 'Build cys_luaplus with CI first; existing LuaPlus import library and DLL are required.' }
$sources = @(
    (Join-Path $PSScriptRoot 'timer_tests.cpp'),
    (Join-Path $hostSource 'CysHostTimers.cpp'),
    (Join-Path $hostSource 'CysHostTimerLua.cpp'),
    (Join-Path $hostSource 'LuaApiGen_Common.cpp'),
    (Join-Path $hostSource 'LuaApiGen_Globals.cpp')
)
$trackedInputs = $sources + @((Join-Path $hostSource 'CysHostTimers.h'),(Join-Path $hostSource 'CysHostTimerLua.h'),(Join-Path $hostSource 'LuaApiGen.h'))
$before = @($trackedInputs | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} })
$args = @('/nologo','/MD','/EHs','/EHc-','/O2','/std:c++14',('/MP'+$Jobs),'/DLUAPLUS_HAS_WCHAR_T','/source-charset:utf-8','/execution-charset:.936',('/Fo'+$binary+'\'),('/Fe'+$exe),('/I'+$lua),('/I'+$hostSource)) + $sources + @($library,'user32.lib')
$command = 'cl.exe ' + (Join-CmdArgs $args)
$buildLog = Join-Path $fullOut 'build.log'
$testLog = Join-Path $fullOut 'tests.log'
$nativeLog = Join-Path $fullOut 'native-exception.log'
$buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog

function Invoke-BoundedTest([string[]]$Arguments, [string]$LogFile) {
    $processInfo = New-Object Diagnostics.ProcessStartInfo
    $processInfo.FileName = $exe
    $processInfo.Arguments = Join-CmdArgs $Arguments
    $processInfo.WorkingDirectory = $binary
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $processInfo
    try {
        if (-not $process.Start()) { throw 'Could not start isolated timer test.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit(5000)
        if ($timedOut) { $process.Kill(); $process.WaitForExit() }
        $output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
        if ($timedOut) { $output += "`nFAIL runner: five-second process timeout`n" }
        [IO.File]::WriteAllText($LogFile,$output,(New-Object Text.UTF8Encoding($false)))
        Write-Host $output
        if ($timedOut) { return 124 }
        return $process.ExitCode
    }
    finally { $process.Dispose() }
}

$runRc = $null
$nativeRc = $null
$unchanged = $true
if ($buildRc -eq 0) {
    [IO.File]::Copy($dll,(Join-Path $binary 'LuaPlus.dll'))
    $runRc = Invoke-BoundedTest -Arguments @() -LogFile $testLog
    $nativeRc = Invoke-BoundedTest -Arguments @('--native-exception-child') -LogFile $nativeLog
}
foreach ($entry in $before) {
    if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.sha256) { $unchanged = $false }
}
$result = [ordered]@{
    build_rc=$buildRc;run_rc=$runRc;native_exception_rc=$nativeRc;source_unchanged=$unchanged;
    command=$command;build_log=$buildLog;test_log=$testLog;native_exception_log=$nativeLog;
    executable=$exe;source_count=$sources.Count;jobs=$Jobs;timeout_seconds=5;
    lua_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash;source_hashes=$before
}
$resultPath = Join-Path $fullOut 'result.json'
[IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
Write-Host ('Evidence: '+$resultPath)
if ($buildRc -ne 0 -or $runRc -ne 0 -or $nativeRc -ne 0 -or -not $unchanged) { exit 1 }
exit 0
