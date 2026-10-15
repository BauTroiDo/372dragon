param([string]$OutDir = '', [string]$NativeTree = '')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (-not $OutDir) { $OutDir = Join-Path $root ('Build\Logs\2026-09-12-gpt-font\tests-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')) }
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
$tree = Join-Path $root 'Build\cmake\ci-x64'
if ($NativeTree) {
    $tree = [IO.Path]::GetFullPath($NativeTree)
    if (-not $tree.StartsWith((Join-Path $root 'Build\cmake')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Native tree must be inside repo Build/cmake.' }
}
$cegui = Join-Path $root 'Src\ThirdParty\CEGUI-0.4.1\CEGUI\include'
$ft = Join-Path $root 'Src\ThirdParty\FreeType\include'
$exe = Join-Path $OutDir 'font_tests.exe'
$args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/source-charset:utf-8','/execution-charset:.936',('/I'+$cegui),('/I'+$ft),('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'font_tests.cpp'),(Join-Path $tree 'lib\CEGUIBase.lib'),(Join-Path $tree 'lib\cys_freetype.lib'),'normaliz.lib')
$rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw ('Test compile failed; see '+$OutDir) }
[IO.File]::Copy((Join-Path $tree 'bin\CEGUIBase.dll'),(Join-Path $OutDir 'CEGUIBase.dll'))
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe; $start.WorkingDirectory=$OutDir; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
$start.Arguments=Join-CmdArgs @((Join-Path $root 'Assets\Canonical\Data\InterfaceFolder'))
$start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
$process=New-Object Diagnostics.Process; $process.StartInfo=$start
try {
    if (-not $process.Start()) { throw 'Could not start font tests.' }
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) { $process.Kill(); $process.WaitForExit(); throw 'Font test timeout.' }
    $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $OutDir 'tests.log'),$output,(New-Object Text.UTF8Encoding($false)))
    Write-Host $output
    $result=[ordered]@{build_rc=$rc;run_rc=$process.ExitCode;native_tree=$tree;source=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'font_tests.cpp')).Hash;dll=(Get-FileHash -LiteralPath (Join-Path $OutDir 'CEGUIBase.dll')).Hash;out=$OutDir}
    [IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
    if ($process.ExitCode) { throw ('Font tests failed: '+$OutDir) }
} finally { $process.Dispose() }
