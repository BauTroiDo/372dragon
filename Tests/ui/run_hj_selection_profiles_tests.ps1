param([Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$OutDir=[IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\')) { throw 'Evidence must stay under Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Preserve prior evidence; use a new output directory.' }
[void][IO.Directory]::CreateDirectory($OutDir)
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$source=Join-Path $root 'Src\Client\WXClient\Procedure'
$exe=Join-Path $OutDir 'hj_selection_profiles_tests.exe'
$argv=@('/nologo','/MD','/EHsc','/O2','/W4','/std:c++14','/utf-8',('/I'+$source),('/I'+(Join-Path $root 'Src\Client\WXClient\DataPool')),('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'hj_selection_profiles_tests.cpp'),(Join-Path $source 'CysCreateRoleAppearance.cpp'))
$rc=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $argv)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw 'Compilation failed.' }
$rc=Invoke-CmdLogged -CommandLine (Join-CmdArgs @($exe,(Join-Path $root 'Build\world-gui\stage-play-21'),(Join-Path $root 'Build\world-gui\stage-hj-appearance-25'))) -LogFile (Join-Path $OutDir 'tests.log')
if ($rc) { throw 'HJ selection profile test failed.' }
