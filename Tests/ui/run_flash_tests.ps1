param([string]$OutDir = '', [string]$NativeTree = '')
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
$tree = Join-Path $root 'Build\cmake\ci-x64'
if ($NativeTree) {
    $tree = [IO.Path]::GetFullPath($NativeTree)
    if (-not $tree.StartsWith((Join-Path $root 'Build\cmake')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Native tree must be inside repo Build/cmake.' }
}
$cegui = Join-Path $root 'Src\ThirdParty\CEGUI-0.4.1\CEGUI\include'
$ft = Join-Path $root 'Src\ThirdParty\FreeType\include'
$exe = Join-Path $OutDir 'flash_tests.exe'
$lua = Join-Path $root 'Src\ThirdParty\LuaPlus\Src\LuaPlus'
$hostSources = Join-Path $root 'Src\Client\LuaApiGen'
$ui = Join-Path $root 'Src\Client\CEGUISystem'

$args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/source-charset:utf-8','/execution-charset:.936',('/I'+$cegui),('/I'+$lua),('/I'+$hostSources),('/I'+$ui),('/I'+$ft),('/I'+(Join-Path $root 'Src\Client\CEGUIFalagardEx')),('/I'+(Join-Path $root 'Src\ThirdParty\CEGUI-0.4.1\CEGUI\WidgetSets\Falagard\include')),('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'flash_tests.cpp'),(Join-Path $tree 'lib\LuaPlus.lib'),(Join-Path $tree 'lib\CEGUIBase.lib'),(Join-Path $tree 'lib\CEGUIFalagard.lib'),'normaliz.lib','user32.lib')
$rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw ('Test compile failed; see '+$OutDir) }
Get-ChildItem -LiteralPath (Join-Path $root 'Build\Client\Bin64') -Filter '*.dll' | ForEach-Object { [IO.File]::Copy($_.FullName,(Join-Path $OutDir $_.Name)) }
if ($NativeTree) {
    foreach ($name in @('CEGUIBase.dll','CEGUIFalagard.dll','CEGUIOgreRenderer.dll','LuaPlus.dll','UI_CEGUI.dll')) {
        [IO.File]::Copy((Join-Path $tree ('bin\'+$name)),(Join-Path $OutDir $name),$true)
    }
}
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe; $start.WorkingDirectory=$OutDir; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
$start.Arguments=Join-CmdArgs @((Join-Path $root 'Assets\Canonical\Data\InterfaceFolder'))
$start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
$process=New-Object Diagnostics.Process; $process.StartInfo=$start
try {
    if (-not $process.Start()) { throw 'Could not start Flash tests.' }
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) { $process.Kill(); $process.WaitForExit(); throw 'Flash test timeout.' }
    $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $OutDir 'tests.log'),$output,(New-Object Text.UTF8Encoding($false)))
    Write-Host $output
    $result=[ordered]@{build_rc=$rc;run_rc=$process.ExitCode;source=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'flash_tests.cpp')).Hash;dll=(Get-FileHash -LiteralPath (Join-Path $OutDir 'CEGUIBase.dll')).Hash;widgets=(Get-FileHash -LiteralPath (Join-Path $OutDir 'CEGUIFalagard.dll')).Hash;out=$OutDir;native_tree=$tree;binding=(Get-FileHash -LiteralPath (Join-Path $ui 'CysFlashBinding.h')).Hash;canonical=(Get-FileHash -LiteralPath (Join-Path $root 'Assets\Canonical\Data\InterfaceFolder\SelectServer\SelectServer.lua')).Hash;ui_dll=(Get-FileHash -LiteralPath (Join-Path $OutDir 'UI_CEGUI.dll')).Hash}
    [IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
    if ($process.ExitCode) { throw ('Flash tests failed: '+$OutDir) }
} finally { $process.Dispose() }
