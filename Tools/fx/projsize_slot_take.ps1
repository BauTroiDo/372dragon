# CYS-PROJSIZE: cong khe + dong NHAN trong CUNG MOT script (luat cua fx-cy-2 bay 12).
# Cong dung o day la `projsize_slot_free.py`: no goi cong chung RUI CONG THEM luat
# "RESTART SERVER ... DA NHAN chua co DA TRA = khe BAN" (lo hong `auraring` bay so 7).
# ASCII only (bay 1 cua crt-guard: mot ky tu khong-ASCII => script KHONG CHAY MOT DONG NAO).
$ErrorActionPreference = 'Stop'
$root = 'C:\TLBB\085\CY-Source'
$wt = 'C:\TLBB\085\CY-Source\Build\wt-projsize'
$env:PYTHONIOENCODING = 'utf-8'
$gate = & python -B (Join-Path $wt 'Tools\fx\projsize_slot_free.py') 2>&1
$rc = $LASTEXITCODE
Write-Host ("cong khe: " + ($gate -join ' | '))
if ($rc -ne 0) { throw 'Cong khe TU CHOI; khong ghi NHAN.' }
$now = (Get-Date).ToString('HH:mm')
$line = @"

projsize | NHAN khe ($now) | HAI luot live tren stage-projsize (moi: Game.exe f8d1ced9f45dcb76, Render.dll d8a1f2d043202467), tai khoan test02/CYTest02 (tai khoan `auraring` da tra khe luc 10:08), moi luot toi da 300 s. Cong khe projsize_slot_free.py (cong chung + luat RESTART SERVER) DA QUA ngay truoc dong nay trong CUNG script. KHONG restart server, KHONG ghi Mongo, KHONG danh nhau (bo do chi LAI CON TRO vao MCT_SKILL_AREA, khong gui goi thi trien). A/B mot bien so CYS_RINGSIZE: e0=0 (nguyen van duong ma 0.85, setProjectionSize ap len m_pEffect NULL), e1=1 (ap len effect cua chinh CWXObj_ProjTex, nhu CY 3.71 0x18001d280 va client_GL 0x180007eb0). Moi luot quet BA ban kinh tren CUNG camera: CYS_AURARING_SWEEP=300,1000,800. NGUONG 11 O DA DANG KY TRUOC tai Build\Logs\2026-09-20-projsize\nguong-dang-ky-truoc.txt va cung so trong Tools\fx\projsize_ab.py (--selftest 10/10, 8 ca am gom ca "luot chua he chay"): (1) e0 co dong dummy fix=0 va 0 dong projtex; (2) e1 co projtex type=4 du ba co 300/1000/800; (3) e1 projtex type=2 size=100 (decal con tro khong hoi quy); (4) ca hai sweep=3 ring_made=1 lenh=MCT_SKILL_AREA; (5) 0 dong ERROR; (6) sau anh deu co cum vong >=800 px trong vung san choi; (7) e0 max(W)/min(W) <= 1.15 (ba vong CUNG co - loi hien tai phai tai hien duoc); (8) e1 W(1000)/W(300) trong [2.80,3.90]; (9) e1 W(800)/W(300) trong [2.25,3.10]; (10) e1 W(800) lech <=15% so trung binh W cua e0; (11) e1 W(300)<W(800)<W(1000) moi khoang >=20 px. Bat ky o nao truot => BAO SAI, khong noi nguong, KHONG commit. SE ghi dong TRA khe.
"@
Add-Content -LiteralPath (Join-Path $root 'Build\game-slot-queue.txt') -Value $line -Encoding UTF8
Write-Host 'DA GHI NHAN khe.'
