param([string]$OutDir = '')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (-not $OutDir) { $OutDir = Join-Path $root ('Build\Logs\2026-09-13-gpt-p1-1\tests-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
$OutDir = [IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be inside repo Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output path; preserve old evidence.' }
$cursor = $OutDir
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Output must not traverse a junction.' }
    $cursor = Split-Path -Parent $cursor
}
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP = Join-Path $OutDir 'tmp'; $env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe = Join-Path $OutDir 'behit_tests.exe'
$args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/source-charset:utf-8','/execution-charset:.936',('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'behit_tests.cpp'))
$rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw ('Test compile failed; see '+$OutDir) }
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe; $start.WorkingDirectory=$OutDir; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
$start.Arguments=Join-CmdArgs @((Join-Path $root 'Assets\Canonical\Data\ConfigFolder\BeHit.txt'))
$start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
$process=New-Object Diagnostics.Process; $process.StartInfo=$start
try {
    if (-not $process.Start()) { throw 'Could not start BeHit tests.' }
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) { $process.Kill(); $process.WaitForExit(); throw 'BeHit test timeout.' }
    $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $OutDir 'tests.log'),$output,(New-Object Text.UTF8Encoding($false)))
    Write-Host $output
    $result=[ordered]@{build_rc=$rc;run_rc=$process.ExitCode;source=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'behit_tests.cpp')).Hash;config_source=(Get-FileHash -LiteralPath (Join-Path $root 'Src\Client\CEGUISystem\CysBeHitConfig.h')).Hash;out=$OutDir}
    [IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
    if ($process.ExitCode) { throw ('BeHit tests failed: '+$OutDir) }
} finally { $process.Dispose() }
