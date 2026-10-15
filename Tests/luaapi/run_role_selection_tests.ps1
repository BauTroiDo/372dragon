param(
    [string]$OutDir = '',
    [ValidateRange(1,2)][int]$Jobs = 1
)
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = Join-Path $Root ('Build\Logs\2026-09-13-gpt-gl-login\role-selection-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
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
$exe = Join-Path $binary 'role_selection_tests.exe'
$lua = Join-Path $Root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$hostSource = Join-Path $Root 'Src\Client\LuaApiGen'
$library = Join-Path $Root 'Build\cmake\ci-x64\lib\LuaPlus.lib'
$dll = Join-Path $Root 'Build\cmake\ci-x64\bin\LuaPlus.dll'
if (-not (Test-Path -LiteralPath $library) -or -not (Test-Path -LiteralPath $dll)) { throw 'Existing CI LuaPlus library and DLL are required.' }
$sources = @((Join-Path $PSScriptRoot 'role_selection_tests.cpp'))
$inputSource = Join-Path $Root 'Src\Client\WXClient\Procedure'
$env:PYTHONUTF8 = '1'
$env:PYTHONDONTWRITEBYTECODE = '1'
& 'C:\Program Files\Python313\python.exe' -B (Join-Path $PSScriptRoot 'extract_role_selection.py') --root $Root --out $binary
if ($LASTEXITCODE -ne 0) { throw 'Dispatcher extraction failed.' }
$extracted = Get-Content -LiteralPath (Join-Path $binary 'extracted.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$glScript = Join-Path $Root 'Assets\Canonical\Data\InterfaceFolder\SelectRole\SelectRole.lua'
$trackedInputs = @($extracted | ForEach-Object { Join-Path $Root $_.source }) + @((Join-Path $PSScriptRoot 'extract_role_selection.py'),$glScript) + $sources
$before = @($trackedInputs | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} })
$args = @('/nologo','/MD','/EHs','/EHc-','/O2','/std:c++14',('/MP'+$Jobs),'/DLUAPLUS_HAS_WCHAR_T','/source-charset:utf-8','/execution-charset:.936',('/Fo'+$binary+'\'),('/Fe'+$exe),('/I'+$lua),('/I'+$hostSource),('/I'+$inputSource),('/I'+$binary),'/D_FINAL') + $sources + @($library)
$command = 'cl.exe ' + (Join-CmdArgs $args)
$buildLog = Join-Path $fullOut 'build.log'
$testLog = Join-Path $fullOut 'tests.log'
$buildRc = Invoke-CmdLogged -CommandLine $command -LogFile $buildLog
$runRc = $null
if ($buildRc -eq 0) {
    [IO.File]::Copy($dll,(Join-Path $binary 'LuaPlus.dll'))
    $processInfo = New-Object Diagnostics.ProcessStartInfo
    $processInfo.FileName = $exe
    $processInfo.WorkingDirectory = $binary
    $processInfo.Arguments = (Join-CmdArgs @($glScript))
    $processInfo.EnvironmentVariables.Remove('CYS_BOT_PWD')
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $processInfo
    try {
        if (-not $process.Start()) { throw 'Could not start isolated role selection test.' }
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
    timeout_seconds=5;service_doubles=$true;game_runtime=$false;extracted_methods=$extracted;
    lua_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash;source_hashes=$before
}
$resultPath = Join-Path $fullOut 'result.json'
[IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
Write-Host ('Evidence: '+$resultPath)
if ($buildRc -ne 0 -or $runRc -ne 0 -or -not $unchanged) { exit 1 }
exit 0
