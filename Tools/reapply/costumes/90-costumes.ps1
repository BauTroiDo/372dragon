# Tools/reapply/costumes/90-costumes.ps1 — ap lai TOAN BO du lieu thoi trang (costumes-all, 18/09/2026)
# len server rieng R = /home/ubuntu/cys-test-20260913 (WSL distro TLBB). Cong thuc that nam o
# Tools/server/costume_data.py (survey | plan | apply | verify), file nay chi goi no dung thu tu.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\reapply\costumes\90-costumes.ps1            # plan + apply + verify
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\reapply\costumes\90-costumes.ps1 -Verify    # chi verify
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\reapply\costumes\90-costumes.ps1 -Survey    # chi do bon con so
#
# Idempotent: chay lai tren R da ap thi `bo_qua_vi_da_co` day du va khong ghi byte nao. Server chi nap bang luc
# khoi dong => sau `apply` PHAI restart server rieng (khi khong co ket noi 15733/15734). ASCII only.
param(
    [switch]$Verify,
    [switch]$Survey,
    [string]$Staging = '/tmp/costumes-plan',
    [string]$OutDir = ''
)
$ErrorActionPreference = 'Stop'
$tool = '/mnt/c/TLBB/085/CY-Source/Tools/server/costume_data.py'
function Run([string]$cmdline) {
    Write-Host ('>> ' + $cmdline)
    & wsl.exe -d TLBB -u root -- bash -c $cmdline
    if ($LASTEXITCODE -ne 0) { throw ('that bai: ' + $cmdline) }
}
if ($Survey) {
    $o = ''
    if ($OutDir) { $o = ' --out ' + $OutDir }
    Run ('cd /mnt/c/TLBB/085/CY-Source && python3 -B ' + $tool + ' survey' + $o)
    exit 0
}
if (-not $Verify) {
    Run ('cd /mnt/c/TLBB/085/CY-Source && python3 -B ' + $tool + ' plan --out ' + $Staging)
    Run ('cd /mnt/c/TLBB/085/CY-Source && python3 -B ' + $tool + ' apply --staging ' + $Staging)
}
Run ('cd /mnt/c/TLBB/085/CY-Source && python3 -B ' + $tool + ' verify')
Write-Host 'OK. Nho restart server rieng (Tools/server/cys_server.ps1) khi khong co ket noi song.'
