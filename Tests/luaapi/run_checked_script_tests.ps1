param([string]$OutDir = '')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
if (-not $OutDir) { $OutDir = 'Build\Logs\checked-script\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff') }
if (-not [IO.Path]::IsPathRooted($OutDir)) { $OutDir = Join-Path $root $OutDir }
$out = [IO.Path]::GetFullPath($OutDir).TrimEnd('\')
if (-not $out.StartsWith((Join-Path $root 'Build\Logs')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Use a new directory under CY-Source Build/Logs.' }
$cursor = $out
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Do not traverse junctions.' }
    $cursor = Split-Path -Parent $cursor
}
if (Test-Path -LiteralPath $out) { throw 'Preserve prior test evidence; choose a new directory.' }
[void][IO.Directory]::CreateDirectory($out)
$bin = Join-Path $out 'bin'; [void][IO.Directory]::CreateDirectory($bin)
$env:TEMP = Join-Path $out 'tmp'; $env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$lua = Join-Path $root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$script = Join-Path $root 'Src\Client\WXClient\Script'
$source = Join-Path $PSScriptRoot 'checked_script_tests.cpp'
$header = Join-Path $script 'CysCheckedScriptLua.h'
$hostSource = Join-Path $root 'Src\Client\LuaApiGen'
$globalsSource = Join-Path $hostSource 'CysHostGlobals.cpp'
$library = Join-Path $root 'Build\cmake\ci-x64\lib\LuaPlus.lib'
$dll = Join-Path $root 'Build\cmake\ci-x64\bin\LuaPlus.dll'
$inputs = @($source,$header,$globalsSource,(Join-Path $hostSource 'CysHostGlobals.h'),$library,$dll)
$hashes = @($inputs | ForEach-Object { [ordered]@{path=$_.Substring($root.Length+1);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} })
$exe = Join-Path $bin 'checked_script_tests.exe'
$arguments = @('/nologo','/MD','/EHs','/EHc-','/O2','/W4','/std:c++14','/DLUAPLUS_HAS_WCHAR_T','/source-charset:utf-8','/execution-charset:.936',('/Fo'+$bin+'\'),('/Fe'+$exe),('/I'+$lua),('/I'+$script),('/I'+$hostSource),$source,$globalsSource,$library,'user32.lib')
$buildRc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $arguments)) -LogFile (Join-Path $out 'build.log')
function Run-Test([string]$Arguments,[string]$LogName) {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName=$exe; $info.Arguments=$Arguments; $info.WorkingDirectory=$bin
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true; $info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $info.EnvironmentVariables.Remove('CYS_BOT_PWD')
    $process = New-Object Diagnostics.Process; $process.StartInfo=$info
    try {
        if (-not $process.Start()) { throw 'Could not start the isolated test.' }
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        $timedOut=-not $process.WaitForExit(10000)
        if ($timedOut) { $process.Kill(); $process.WaitForExit() }
        $text=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
        if ($text.Contains('DIAGNOSTIC_CANARY_7X')) { throw 'Synthetic error text escaped the metadata boundary; output withheld.' }
        [IO.File]::WriteAllText((Join-Path $out $LogName),$text,(New-Object Text.UTF8Encoding($false)))
        Write-Host $text
        if ($timedOut) { return 124 }
        return $process.ExitCode
    } finally { $process.Dispose() }
}
$runRc=$null; $nativeRc=$null; $nestedRc=$null
if ($buildRc -eq 0) {
    [IO.File]::Copy($dll,(Join-Path $bin 'LuaPlus.dll'))
    $runRc=Run-Test '' 'tests.log'
    $nativeRc=Run-Test '--native-child' 'native.log'
    $nestedRc=Run-Test '--native-nested-child' 'native-nested.log'
}
$unchanged=$true
foreach ($entry in $hashes) {
    if ((Get-FileHash -LiteralPath (Join-Path $root $entry.path) -Algorithm SHA256).Hash -ne $entry.sha256) { $unchanged=$false }
}
$result=[ordered]@{build_rc=$buildRc;run_rc=$runRc;native_rc=$nativeRc;nested_native_rc=$nestedRc;inputs_unchanged=$unchanged;compiler_jobs=1;timeout_seconds=10;inputs=$hashes}
[IO.File]::WriteAllText((Join-Path $out 'result.json'),($result|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
if ($buildRc -ne 0 -or $runRc -ne 0 -or $nativeRc -ne 0 -or $nestedRc -ne 0 -or -not $unchanged) { exit 1 }
exit 0
