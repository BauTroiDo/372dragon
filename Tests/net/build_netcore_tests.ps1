param([Parameter(Mandatory=$true)][string]$OutDir, [string]$NativeTree='Build\cmake\ci-x64',
    [ValidateSet('netcore_tests.cpp','creation_session_tests.cpp','world_session_tests.cpp')][string]$TestSource='netcore_tests.cpp')
# CYS-TESTPATH 19/09: do NOT add login_role_list_tests.cpp to the ValidateSet above. This script force-links every
# NetCore source (NetCommon/GameClient/WorldModel/LoginClient/LoginProbe + ws2_32), which that suite does not use and
# cannot satisfy => LNK2019 WinsockStreamFactory / GetAdaptersAddresses. It has its own runner,
# Tests\net\run_login_role_list_tests.ps1 (links only cys_protocolgen.lib), wired into Tools\build\tests.ps1 as
# suite "rolelist" (kind ps1).
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
function BuildPath([string]$value) {
    if (-not [IO.Path]::IsPathRooted($value)) { $value=Join-Path $root $value }
    $path=[IO.Path]::GetFullPath($value)
    if (-not $path.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Path must stay in CY-Source Build.' }
    $cursor=$path
    while ($cursor) {
        $item=Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Path must not traverse a junction.' }
        $cursor=Split-Path -Parent $cursor
    }
    return $path
}
$OutDir=BuildPath $OutDir
$tree=BuildPath $NativeTree
if (Test-Path -LiteralPath $OutDir) { throw 'Choose new output; preserve evidence.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP=Join-Path $OutDir 'tmp'; $env:TMP=$env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$exe=Join-Path $OutDir 'cys_netcore_tests.exe'
$arguments=@('/nologo','/MD','/EHsc','/O2','/W4','/std:c++14','/utf-8','/DWIN32_LEAN_AND_MEAN','/DNOMINMAX',
    ('/I'+(Join-Path $root 'Src\Shared\ProtocolGen')),('/I'+(Join-Path $root 'Src\Client\NetCore')),
    ('/I'+(Join-Path $root 'Src\Tools\CysNetBot')),('/Fo'+$OutDir+'\'),('/Fe'+$exe),
    (Join-Path $root 'Src\Client\NetCore\NetCommon.cpp'),(Join-Path $root 'Src\Client\NetCore\GameClient.cpp'),
    (Join-Path $root 'Src\Client\NetCore\WorldModel.cpp'),
    # CYS-TESTPATH 19/09: NetStream.cpp + iphlpapi.lib were missing, so this script did not link AT ALL - not even
    # with its own default -TestSource netcore_tests.cpp (measured: Build\Logs\2026-09-19-tests-path\
    # netcore-script-control\build.log, rc=1, LNK2019 WinsockStreamFactory + __imp_GetAdaptersAddresses, LNK1120).
    # Those are the same two errors the 18/09 handoff blamed on login_role_list_tests.cpp; the cause is here, not
    # there. GameClient.cpp:166 / LoginClient.cpp:204 call WinsockStreamFactory, DEFINED in NetStream.cpp:133;
    # NetCommon.cpp:65 calls GetAdaptersAddresses. Keep this list next to netcore.cmake's cys_netcore sources.
    # world_session_tests.cpp also needs the replay/record/profile seam (LNK2019 replay::Session, ParseServerProfiles).
    (Join-Path $root 'Src\Client\NetCore\NetStream.cpp'),(Join-Path $root 'Src\Client\NetCore\ReplayStream.cpp'),
    (Join-Path $root 'Src\Client\NetCore\RecordStream.cpp'),(Join-Path $root 'Src\Client\NetCore\ServerProfile.cpp'),
    (Join-Path $root 'Src\Client\NetCore\LoginClient.cpp'),(Join-Path $root 'Src\Tools\CysNetBot\LoginProbe.cpp'),
    (Join-Path $PSScriptRoot $TestSource),(Join-Path $tree 'lib\cys_protocolgen.lib'),'ws2_32.lib','iphlpapi.lib')
$rc=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $arguments)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw ('NetCore test build failed; see '+$OutDir) }
Write-Host ('Built '+$exe)
