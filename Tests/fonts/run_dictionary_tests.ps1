param(
    [Parameter(Mandatory=$true)][string]$OutDir,
    [Parameter(Mandatory=$true)][string]$LegacyDictionary
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$OutDir = [IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be inside repo Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output path; preserve old evidence.' }
$cursor = $OutDir
while ($cursor) {
    $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Output must not traverse a junction.' }
    $cursor = Split-Path -Parent $cursor
}
$LegacyDictionary = [IO.Path]::GetFullPath($LegacyDictionary)
if (-not $LegacyDictionary.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture must be inside CY-Source.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$oldTemp=$env:TEMP; $oldTmp=$env:TMP
try {
    $env:TEMP = Join-Path $OutDir 'tmp'; $env:TMP = $env:TEMP
    [void][IO.Directory]::CreateDirectory($env:TEMP)
    . (Join-Path $root 'Tools\build\ci_common.ps1')
    Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
    $exe = Join-Path $OutDir 'dictionary_tests.exe'
    $args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/source-charset:utf-8','/execution-charset:.936',('/I'+(Join-Path $root 'Src\Client\CEGUISystem')),('/Fo'+$OutDir+'\'),('/Fe'+$exe),(Join-Path $PSScriptRoot 'dictionary_tests.cpp'))
    $rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
    if ($rc) { throw 'Dictionary test compile failed.' }
    $canonical = Join-Path $root 'Assets\Canonical\Data\ConfigFolder\StrDictionary.txt'
    & $exe $canonical $LegacyDictionary | Tee-Object -FilePath (Join-Path $OutDir 'tests.log')
    $runRc=$LASTEXITCODE
    $result=[ordered]@{build_rc=$rc;run_rc=$runRc;canonical_sha256=(Get-FileHash -LiteralPath $canonical).Hash;legacy_sha256=(Get-FileHash -LiteralPath $LegacyDictionary).Hash;parser_sha256=(Get-FileHash -LiteralPath (Join-Path $root 'Src\Client\CEGUISystem\CysUiDictionary.h')).Hash}
    [IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
    if ($runRc) { throw 'Dictionary tests failed.' }
} finally { $env:TEMP=$oldTemp; $env:TMP=$oldTmp }
