param([Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$out=[IO.Path]::GetFullPath($OutDir)
if(Test-Path -LiteralPath $out){throw 'Use a new output directory.'}
[void][IO.Directory]::CreateDirectory($out)
. (Join-Path $repo 'Tools/build/ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe=Join-Path $out 'ui_command_tests.exe'
$compilerArgs=@('/nologo','/MD','/EHsc','/O2','/std:c++14','/W4','/utf-8',('/Fo'+$out+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'ui_command_tests.cpp'))
$build=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $compilerArgs)) -LogFile (Join-Path $out 'build.log')
if($build){Get-Content (Join-Path $out 'build.log');throw 'Compile failed.'}
$run=Invoke-CmdLogged -CommandLine (Join-CmdArgs @($exe,(Join-Path $repo 'Assets/CanonicalCY/Data/ConfigFolder/UICommandIndex.txt'))) -LogFile (Join-Path $out 'tests.log')
Get-Content (Join-Path $out 'tests.log')
@{build_rc=$build;run_rc=$run;source=(Get-FileHash (Join-Path $PSScriptRoot 'ui_command_tests.cpp')).Hash}|ConvertTo-Json|Set-Content (Join-Path $out 'result.json')
if($run){throw 'Tests failed.'}
