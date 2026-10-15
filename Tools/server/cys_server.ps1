# CY-Source Tools/server/cys_server.ps1 - Windows wrapper for Tools/server/cys_server.sh (private CY-Source server only).
#   powershell -NoProfile -File Tools\server\cys_server.ps1 status
#   powershell -NoProfile -File Tools\server\cys_server.ps1 backup before-edit
#   powershell -NoProfile -File Tools\server\cys_server.ps1 restart --confirm-root /home/ubuntu/cys-test-20260913
# Runs the script from this checkout inside WSL TLBB as root. Docs: Docs/specs/net/cys-server_vi.md
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'cys_server.sh'
$full = (Resolve-Path $script).Path
if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "cys_server.sh must be on a Windows drive: $full" }
$wslPath = '/mnt/' + $Matches[1].ToLower() + '/' + ($Matches[2] -replace '\\', '/')
& wsl.exe -d TLBB -u root -- bash $wslPath @args
exit $LASTEXITCODE
