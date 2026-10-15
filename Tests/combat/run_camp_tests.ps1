# CYS-TESTRED 19/09: -StageTable used to default to Build/gpt-p1-1-20260913/stage-15523fa/..., a staged game of
# 13/09. /Build is git-ignored (.gitignore:15), so that default could never survive a clean checkout and it was
# deleted with the stage; the suite then failed its very first case ("current data did not load") and every later
# case that reuses $staged. The second operand is now a committed copy of the legacy TEXT form of the same table
# (Tests/combat/fixtures/CampAndStand.stage-text.txt, 704 bytes, sha256 107c90f6...), taken from a staged game
# tree (Build/gpt-font/stage-baseline/Data/Config/CampAndStand.txt - a loose Data/Config of a game build: 156
# files, every one stamped 2025-04-07). Verified: it decodes to the same 16x17 matrix as the binary we ship.
# This keeps what the case is for: DBCFile decodes the BINARY table we ship (00CCBBDD, Assets/Canonical, 1173
# bytes) and the TEXT table of the original game through two different parsers - OpenFromMemoryImpl_Binary vs
# OpenFromMemoryImpl_Text (TLBB_DBC.cpp:133-144) - and both must yield the same 16x17 matrix.
# NEVER pass the same file for both arguments: the comparison would then be a file against itself, i.e. green
# without meaning. A caller with a real staged game is still welcome to point -StageTable at it.
param([Parameter(Mandatory=$true)][string]$OutDir, [string]$StageTable = 'Tests/combat/fixtures/CampAndStand.stage-text.txt')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$OutDir=[IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must stay inside Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output directory; preserve evidence.' }
$cursor=$OutDir
while($cursor){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue;if($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Output must not traverse a junction.'};$cursor=Split-Path -Parent $cursor}
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP=Join-Path $OutDir 'tmp';$env:TMP=$env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $root 'Tools/build/ci_common.ps1')
$canonical=Join-Path $root 'Assets/Canonical/Data/ConfigFolder/CampAndStand.txt'
if(-not [IO.Path]::IsPathRooted($StageTable)){$StageTable=Join-Path $root $StageTable}
if(-not (Test-Path -LiteralPath $StageTable)){throw ('-StageTable does not exist: '+$StageTable)}
# CYS-TESTRED 19/09: refuse the one input that makes this suite green while proving nothing - the same bytes on
# both sides. The first case would then compare a file with itself and pass no matter what the data says.
# Checked BEFORE the compile so a bad argument costs a second, not a full cl.exe run.
if((Get-FileHash -LiteralPath $canonical).Hash -eq (Get-FileHash -LiteralPath $StageTable).Hash){throw ('-StageTable is byte-identical to the canonical table, so the matrix comparison would compare a file with itself: '+$StageTable)}
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$common=Join-Path $root 'Src/Shared/Common'
$exe=Join-Path $OutDir 'camp_tests.exe'
$args=@('/nologo','/MD','/EHsc','/O2','/std:c++14','/source-charset:utf-8','/execution-charset:.936','/D__WINDOWS__','/DGAME_CLIENT','/DNDEBUG',('/I'+$PSScriptRoot),('/I'+$common),('/I'+(Join-Path $common 'DataBase')),('/I'+(Join-Path $common 'Combat')),('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'camp_tests.cpp'),(Join-Path $common 'Combat/CampAndStand.cpp'),(Join-Path $common 'DataBase/TLBB_DBC.cpp'))
$build=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
if($build){throw ('Camp tests compile failed: '+$OutDir)}
$run=Invoke-CmdLogged -CommandLine ((Join-CmdArgs @($exe,$canonical,$StageTable))) -LogFile (Join-Path $OutDir 'tests.log')
Get-Content -LiteralPath (Join-Path $OutDir 'tests.log')
$result=[ordered]@{build_rc=$build;run_rc=$run;canonical_sha256=(Get-FileHash -LiteralPath $canonical).Hash;stage_sha256=(Get-FileHash -LiteralPath $StageTable).Hash;source_sha256=(Get-FileHash -LiteralPath (Join-Path $common 'Combat/CampAndStand.cpp')).Hash;header_sha256=(Get-FileHash -LiteralPath (Join-Path $common 'Combat/CampAndStand.h')).Hash;template_sha256=(Get-FileHash -LiteralPath (Join-Path $common 'Combat/TemplateManager.h')).Hash}
[IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
if($run){throw ('Camp tests failed: '+$OutDir)}
