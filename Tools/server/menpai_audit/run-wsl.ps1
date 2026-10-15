param([Parameter(Mandatory=$true)][string]$Script, [string]$Out = '')
$full = (Resolve-Path $Script).Path
if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "bad path" }
$w = '/mnt/' + $Matches[1].ToLower() + '/' + ($Matches[2] -replace '\\', '/')
if ($Out) { & wsl.exe -d TLBB -u root -- bash $w @args 2>&1 | Tee-Object -FilePath $Out } else { & wsl.exe -d TLBB -u root -- bash $w @args 2>&1 }
