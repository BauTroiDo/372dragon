param([Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$OutDir=[IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\')) { throw 'Evidence must stay under Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Preserve prior evidence; use a new output directory.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$cpp=Join-Path $OutDir 'rider_test.cpp'
python (Join-Path $PSScriptRoot 'hj_rider_selection_fixture.py') $cpp
if ($LASTEXITCODE) { throw 'Fixture generation failed.' }
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe=Join-Path $OutDir 'rider_test.exe'
$argv=@('/nologo','/MD','/EHsc','/O2','/std:c++14','/utf-8',('/Fo'+$OutDir+'\'),('/Fe'+$exe),$cpp)
$rc=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $argv)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw 'Compilation failed.' }
$rc=Invoke-CmdLogged -CommandLine (Join-CmdArgs @($exe)) -LogFile (Join-Path $OutDir 'tests.log')
if ($rc) { throw 'HJ rider selection failed.' }
