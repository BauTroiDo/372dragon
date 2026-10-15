# CYS-FXFINISH: cong khe + dong NHAN trong CUNG MOT script (luat cua fx-cy-2 bay 12).
# Cong dung o day la `projsize_slot_free.py`: cong chung + luat "RESTART SERVER ... DA NHAN chua
# co DA TRA = khe BAN" (lo hong `auraring` bay so 7). No doc SO O CAY CHINH, khong theo worktree
# (bay 1 cua projsize).
# ASCII only (bay 1 cua crt-guard: mot ky tu khong-ASCII => script KHONG CHAY MOT DONG NAO).
#
# KHONG chay script nay khi dieu phoi chua ghi "TRA khe". Chay xong thi chay ngay
# fxfinish_run_ab.ps1, roi fxfinish_slot_return.ps1 - KE CA KHI LUOT HONG.
$ErrorActionPreference = 'Stop'
$root = 'C:\TLBB\085\CY-Source'
$wt = "$root\Build\wt-fxfinish"
$env:PYTHONIOENCODING = 'utf-8'

# 1. tien kiem cua chinh luot (duong dan, sha binary, do phan giai, thu muc dich, selftest bo cham)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$wt\Tools\fx\fxfinish_run_ab.ps1" -Check
if ($LASTEXITCODE -ne 0) { throw 'Tien kiem KHONG sach; khong ghi NHAN.' }

# 2. cong khe
$gate = & python -B "$root\Tools\fx\projsize_slot_free.py" 2>&1
$rc = $LASTEXITCODE
Write-Host ("cong khe: " + ($gate -join ' | '))
if ($rc -ne 0) { throw 'Cong khe TU CHOI; khong ghi NHAN.' }

# 3. ghi NHAN - chi khi hai buoc tren da qua, trong CUNG script nay
$now = (Get-Date).ToString('HH:mm')
$line = @"

fx-finish | NHAN khe ($now) | HAI luot replay NGOAI TUYEN tren stage-fxfinish, moi luot toi da 175 s
  (~6 phut ca hai). KHONG server, KHONG dang nhap, KHONG danh nhau, KHONG ghi Mongo, KHONG restart.
  Binary (mot ban duy nhat cho ca hai canh, da do): Game.exe 23aa289a4804aaba,
  Render.dll 8ead92197ab219e3. Tien kiem + cong khe DA QUA ngay truoc dong nay trong CUNG script.
  A/B mot bien so CYS_FXPROJ: e0=0 (nguyen van duong ma 0.85: dat tu the may chieu MOT LAN luc tao),
  e1=1 (dat lai tu the sau moi lan EffectElement::setTransformInfo ghi de - dung hanh vi CY 3.71
  0x180090720 trong cay da DAN PHANG node). Luot ghi vao ours\b09-r6 va r7 (r4/r5 la cua fx-cy-2).
  NGUONG DA DANG KY TRUOC va DA KHOA tai Build\Logs\2026-09-20-fx-finish\nguong-dang-ky-truoc.txt
  (cung so trong Tools\fx\fxfinish_flat_ab.py, --selftest 14/14 voi 9 ca am):
  A1-A5 phep do co that su chay (cung binary, env dung canh, 0 dong ERROR, dong log fix=0/fix=1
  dung canh, >=3 khung co ve); B1 near_frustum == near_elem tren moi may chieu; C1-C2 canh doi
  chung phai tai hien duoc loi (share <= 0,65 va >= 4 cum); D1 share >= 0,75; D2 aspect trong
  [1,20; 1,90]; D3b |x(tam hop bao) - x(moc)| <= 60 px; D5 dien tich e1/e0 >= 2,0; D4 hieu ung
  doi chung fx-REAL13 khong xe dich (<= 40 px) va dien tich khong lech (<= 25 %).
  Bat ky o nao truot => BAO SAI, khong noi nguong, KHONG commit. SE ghi dong TRA khe ke ca khi hong.
"@
Add-Content -LiteralPath (Join-Path $root 'Build\game-slot-queue.txt') -Value $line -Encoding UTF8
Write-Host 'DA GHI NHAN khe.'
