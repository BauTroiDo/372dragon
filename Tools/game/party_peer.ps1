param([Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=[IO.Path]::GetFullPath((Join-Path $root $OutDir))
if (-not $out.StartsWith((Join-Path $root 'Build\Logs\'))) {throw 'Output must be an owned test log folder'}
if (Test-Path -LiteralPath $out) {throw 'Preserve previous evidence'}
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=Join-Path $root 'Build\cmake\coord-x64\bin\CysNetBot.exe'
$info.WorkingDirectory=$root
$info.UseShellExecute=$false
$info.CreateNoWindow=$true
$info.Arguments='--host 127.0.0.1 --port 15733 --game-port 15734 --account test14 --guid 200015 --mode world --timeout-ms 30000 --dwell-ms 180000 --hold-ms 180000 --walk 0 --team-accept 1 --team-wait-ms 120000 --out "'+$OutDir+'"'
$line=@(Get-Content -LiteralPath (Join-Path $root '.local\test-accounts.txt') | Where-Object {$_ -like 'test14=*'})
if($line.Count -ne 1){throw 'Owned account not found'}
$info.EnvironmentVariables['CYS_BOT_PWD']=$line[0].Substring(7)
$peer=New-Object Diagnostics.Process
$peer.StartInfo=$info
try {if(-not $peer.Start()){throw 'Peer launch failed'};$info.EnvironmentVariables.Remove('CYS_BOT_PWD');while(-not $peer.WaitForExit(1000)){};Write-Output ('Peer exit '+$peer.ExitCode)}
finally {$info.EnvironmentVariables.Remove('CYS_BOT_PWD');$peer.Dispose()}
