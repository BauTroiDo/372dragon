param([Parameter(Mandatory=$true)][string]$OutDir, [string]$NativeTree='Build\cmake\ci-x64')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
function BuildPath([string]$value) {
    if (-not [IO.Path]::IsPathRooted($value)) { $value=Join-Path $root $value }
    $path=[IO.Path]::GetFullPath($value)
    if (-not $path.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Path must stay inside CY-Source Build.' }
    $cursor=$path
    while ($cursor) {
        $item=Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'No junction paths.' }
        $cursor=Split-Path -Parent $cursor
    }
    return $path
}
$OutDir=BuildPath $OutDir
$tree=BuildPath $NativeTree
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new evidence output.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP=Join-Path $OutDir 'tmp';$env:TMP=$env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$header=Join-Path $root 'Src\Client\WXClient\Procedure\CysLoginRoleList.h'
$source=Join-Path $PSScriptRoot 'login_role_list_tests.cpp'
# CYS-TESTPATH 19/09: the ONLY link input. No NetCore, no ws2_32/iphlpapi - that is why this suite has its own
# runner instead of a -TestSource of build_netcore_tests.ps1 (which force-links NetCore => LNK2019
# WinsockStreamFactory / GetAdaptersAddresses). Name the missing library instead of letting Get-FileHash below
# fail with a bare "path does not exist".
$protocolLib=Join-Path $tree 'lib\cys_protocolgen.lib'
if (-not (Test-Path -LiteralPath $protocolLib)) {
    throw ('missing ' + $protocolLib + ' - build it first: Tools\build\ci.ps1, or Tools\build\build.cmd x64 <name> Release "protocolgen" cys_protocolgen then pass -NativeTree Build\cmake\<name>')
}
$inputs=@($header,$source,$protocolLib)
$hashes=@($inputs | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} })
$exe=Join-Path $OutDir 'login_role_list_tests.exe'
$arguments=@('/nologo','/MD','/EHsc','/O2','/W4','/std:c++14','/utf-8',
    ('/I'+(Join-Path $root 'Src\Shared\ProtocolGen')),('/I'+(Join-Path $root 'Src\Client\WXClient\Procedure')),
    ('/Fo'+$OutDir+'\'),('/Fe'+$exe),$source,$protocolLib)
$buildRc=Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $arguments)) -LogFile (Join-Path $OutDir 'build.log')
$runRc=$null
if ($buildRc -eq 0) {
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=$exe;$info.WorkingDirectory=$OutDir;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.EnvironmentVariables.Remove('CYS_BOT_PWD')
    $process=New-Object Diagnostics.Process;$process.StartInfo=$info
    try {
        if (-not $process.Start()) { throw 'Could not start isolated list test.' }
        $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        $timedOut=-not $process.WaitForExit(5000)
        if ($timedOut) { $process.Kill();$process.WaitForExit() }
        $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
        [IO.File]::WriteAllText((Join-Path $OutDir 'tests.log'),$output,(New-Object Text.UTF8Encoding($false)))
        Write-Host $output
        $runRc=if ($timedOut) { 124 } else { $process.ExitCode }
    } finally { $process.Dispose() }
}
$unchanged=$true
foreach ($entry in $hashes) { if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.sha256) { $unchanged=$false } }
$result=[ordered]@{build_rc=$buildRc;run_rc=$runRc;source_unchanged=$unchanged;hashes=$hashes;compiler_jobs=1;timeout_seconds=5;network=$false;game_runtime=$false}
[IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
if ($buildRc -ne 0 -or $runRc -ne 0 -or -not $unchanged) { exit 1 }
exit 0
