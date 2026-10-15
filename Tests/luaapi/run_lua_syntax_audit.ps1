param([Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$out=[IO.Path]::GetFullPath($OutDir)
if(Test-Path -LiteralPath $out){throw 'Choose a new output directory.'}
[void][IO.Directory]::CreateDirectory($out)
. (Join-Path $repo 'Tools/build/ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$tree=Join-Path $repo 'Build/cmake/coord-x64'
$exe=Join-Path $out 'lua_syntax_audit.exe'
$args=@('/nologo','/MD','/EHsc','/O2','/std:c++14','/DLUAPLUS_HAS_WCHAR_T','/utf-8',('/I'+(Join-Path $repo 'Src/ThirdParty/LuaPlus/Src/LuaPlus')),('/Fo'+$out+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'lua_syntax_audit.cpp'),(Join-Path $tree 'lib/LuaPlus.lib'))
$build=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $out 'build.log')
if($build){Get-Content (Join-Path $out 'build.log');throw 'Compile failed.'}
Copy-Item -LiteralPath (Join-Path $tree 'bin/LuaPlus.dll') -Destination $out
$manifest=Join-Path $out 'files.txt'
$files=@(Get-ChildItem -LiteralPath (Join-Path $repo 'Assets/CanonicalCY/Data/InterfaceFolder') -Recurse -Filter '*.lua' -File | Sort-Object FullName | ForEach-Object {$_.FullName})
[IO.File]::WriteAllLines($manifest,$files,(New-Object Text.UTF8Encoding($false)))
$run=Invoke-CmdLogged -CommandLine (Join-CmdArgs @($exe,$manifest)) -LogFile (Join-Path $out 'syntax.log')
Get-Content (Join-Path $out 'syntax.log')
@{build_rc=$build;run_rc=$run;files=$files.Count;lua_dll=(Get-FileHash (Join-Path $out 'LuaPlus.dll')).Hash}|ConvertTo-Json|Set-Content (Join-Path $out 'result.json')
if($run){throw 'Lua source compilation failed; inspect syntax.log.'}
