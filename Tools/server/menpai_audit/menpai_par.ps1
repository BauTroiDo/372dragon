# menpai-par (17/09/2026): chạy SONG SONG nhiều phiên `menpai_check.ps1` trên nhiều tài khoản test.
#
# Vì sao: đo live là chỗ nghẽn duy nhất của hệ kỹ năng — mỗi chiêu một phiên bot ~90–110 s, mà cả dự án
# chỉ có MỘT nhân vật test nên mọi phiên phải xếp hàng qua một khoá chung (đủ 220 chiêu = 5–6 giờ).
# Server riêng nay có 16 tài khoản test00…test15 ↔ CYTest00…CYTest15 (GUID 200001…200016), nên chia
# theo PHÁI cho nhiều tài khoản chạy cùng lúc là rút được gần đúng N lần.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\menpai_audit\menpai_par.ps1 `
#       -OutRoot Build\Logs\2026-09-17-par -Owner coord-17-09 -Workers 5 `
#       -MenpaiList 0,1,2,3,4,5,6,7,8,10,11,12,13,14,15
#
# Mỗi worker chạy `menpai_check.ps1` với -Account/-Guid riêng (khoá riêng theo tài khoản), ra thư mục
# riêng `<OutRoot>\w<NN>`; cuối lượt gộp mọi `live-results.tsv` thành một bảng bằng `aggregate_check.py`.
#
# ĐIỀU KIỆN: `menpai_check.ps1` phải có -Account/-Guid và khoá theo tài khoản (agent bot-pos-seq thêm 17/09).
# Nếu bản hiện tại chưa có, script này dừng ngay với thông báo rõ chứ không chạy sai.
param(
    [string]$OutRoot = '',
    [string]$Owner = 'coord-par',
    [int]$Workers = 4,
    [string]$MenpaiList = '0,1,2,3,4,5,6,7,8,10,11,12,13,14,15',
    [string]$SkillList = '',
    [string]$ExtraSkills = '',
    [int]$XinfaLevel = 30,
    [int]$Level = 0,
    [int]$MpValue = 0,
    [int]$RestSeconds = 5,
    [string]$Bot = '',
    [string]$Label = '',
    [switch]$TargetSelf,
    [int]$FirstAccount = 0            # worker k dùng test<FirstAccount+k>
)
$ErrorActionPreference = 'Continue'
$repo = 'C:\TLBB\085\CY-Source'
Set-Location $repo
$chk = Join-Path $repo 'Tools\server\menpai_audit\menpai_check.ps1'
$py = 'C:\Program Files\Python313\python.exe'
if (-not $OutRoot) { $OutRoot = 'Build\Logs\{0}-par' -f (Get-Date -Format 'yyyy-MM-dd') }
$OutAbs = if ([IO.Path]::IsPathRooted($OutRoot)) { $OutRoot } else { Join-Path $repo $OutRoot }
New-Item -ItemType Directory -Force $OutAbs | Out-Null

# kiểm điều kiện: menpai_check.ps1 phải nhận -Account/-Guid
$chkText = Get-Content $chk -Raw
foreach ($needed in @('$Account', '$Guid')) {
    if ($chkText -notmatch [regex]::Escape($needed)) {
        Write-Host "menpai_check.ps1 chua co tham so $needed -> chua chay song song duoc. Dung."
        exit 2
    }
}

$menpai = @($MenpaiList -split ',' | Where-Object { $_ -match '^\s*\d+\s*$' } | ForEach-Object { [int]$_ })
if ($Workers -lt 1) { $Workers = 1 }
if ($Workers -gt $menpai.Count) { $Workers = $menpai.Count }
if ($Workers -gt 16) { $Workers = 16 }

# chia phái theo kiểu round-robin để mỗi worker có số phái gần bằng nhau
$buckets = @{}
for ($k = 0; $k -lt $Workers; $k++) { $buckets[$k] = @() }
for ($i = 0; $i -lt $menpai.Count; $i++) { $buckets[$i % $Workers] += $menpai[$i] }

$t0 = Get-Date
Write-Host ("==== menpai_par workers=$Workers menpai=[$MenpaiList] out=$OutRoot")
$jobs = @()
for ($k = 0; $k -lt $Workers; $k++) {
    $acc = 'test{0:d2}' -f ($FirstAccount + $k)
    $guid = 200001 + $FirstAccount + $k
    $list = ($buckets[$k] -join ',')
    if (-not $list) { continue }
    $sub = Join-Path $OutAbs ('w{0:d2}' -f ($FirstAccount + $k))
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $chk,
              '-OutRoot', $sub, '-Owner', ($Owner + '-' + $acc), '-RestSeconds', [string]$RestSeconds,
              '-MenpaiList', $list, '-XinfaLevel', [string]$XinfaLevel,
              '-Account', $acc, '-Guid', [string]$guid,
              '-Label', ($Label + ' [' + $acc + ']'))
    if ($SkillList) { $args += @('-SkillList', $SkillList) }
    if ($ExtraSkills) { $args += @('-ExtraSkills', $ExtraSkills) }
    if ($Level -gt 0) { $args += @('-Level', [string]$Level) }
    if ($MpValue -gt 0) { $args += @('-MpValue', [string]$MpValue) }
    if ($Bot) { $args += @('-Bot', $Bot) }
    if ($TargetSelf) { $args += '-TargetSelf' }
    Write-Host ("  worker {0}: {1} guid={2} menpai=[{3}]" -f $k, $acc, $guid, $list)
    $jobs += Start-Process -FilePath 'powershell' -ArgumentList $args -PassThru -WindowStyle Hidden
}
Write-Host ("  da khoi dong {0} worker, dang cho..." -f $jobs.Count)
foreach ($j in $jobs) { $j.WaitForExit() }
Write-Host ("  moi worker da xong sau {0:n0} giay" -f ((Get-Date) - $t0).TotalSeconds)

# gộp mọi live-results.tsv thành một bảng
$tsvs = @(Get-ChildItem -Path $OutAbs -Recurse -Filter 'live-results.tsv' | ForEach-Object { $_.FullName })
if ($tsvs.Count -gt 0) {
    $aggArgs = @('-X', 'utf8', '-B', (Join-Path $repo 'Tools\server\menpai_audit\aggregate_check.py'), '--results') + $tsvs +
               @('--static', (Join-Path $repo 'Build\Logs\2026-09-15-menpai-audit\static-menpai.json'),
                 '--out', (Join-Path $OutAbs 'aggregate.json'),
                 '--table', (Join-Path $OutAbs 'table.md'),
                 '--label', ($Label + ' (song song ' + $jobs.Count + ' tai khoan)'))
    & $py @aggArgs
    Write-Host ("  bang gop -> " + (Join-Path $OutAbs 'table.md'))
} else {
    Write-Host '  KHONG co live-results.tsv nao -> khong gop duoc'
}
Write-Host '=== XONG menpai_par ==='
