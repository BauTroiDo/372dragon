param([Parameter(Mandatory=$true)][string]$OutDir, [switch]$CY)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$OutDir = [IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be inside repo Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output path; preserve evidence.' }
$cursor = $OutDir
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Output cannot traverse a junction.' }
    $cursor = Split-Path -Parent $cursor
}
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP = Join-Path $OutDir 'tmp'; $env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$source = Join-Path $root 'Src\Client\WXClient\Procedure'
$exe = Join-Path $OutDir 'appearance_tests.exe'
$args = @('/nologo','/MD','/EHsc','/O2','/W4','/std:c++14','/source-charset:utf-8','/execution-charset:.936',('/I'+$source),('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'create_role_appearance_tests.cpp'),(Join-Path $source 'CysCreateRoleAppearance.cpp'))
$rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw 'Appearance test compilation failed.' }
$data = Join-Path $root "Assets\Canonical\Data\ConfigFolder"
$extra = @()
if ($CY) { $data = [IO.Path]::GetFullPath((Join-Path $root "..\Tools\DATA NEW\DataCY31-08-26\Config")); $extra = @("cy") }
$run = Invoke-CmdLogged -CommandLine ((Join-CmdArgs (@($exe,$data)+$extra))) -LogFile (Join-Path $OutDir 'tests.log')
$result = [ordered]@{build_rc=$rc;run_rc=$run;data=$data;source=(Get-FileHash -LiteralPath (Join-Path $source 'CysCreateRoleAppearance.cpp')).Hash;camera=(Get-FileHash -LiteralPath (Join-Path $source 'CysCreateRoleCamera.h')).Hash;test=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'create_role_appearance_tests.cpp')).Hash;out=$OutDir}
[IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
if ($run) { throw 'Appearance tests failed.' }
