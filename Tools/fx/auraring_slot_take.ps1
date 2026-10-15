# CYS-AURARING: cong khe + dong NHAN trong CUNG MOT script (luat cua fx-cy-2 bay 12).
# Khe rong <=> 0 Game.exe VA khong nhanh nao co su kien cuoi la "NHAN khe". Chi ghi NHAN sau khi cong QUA.
# ASCII only.
$ErrorActionPreference = 'Stop'
$root = 'C:\TLBB\085\CY-Source'
$env:PYTHONIOENCODING = 'utf-8'
$gate = & python (Join-Path $root 'Tools\fx\fxcy2_slot_free.py') 2>&1
$rc = $LASTEXITCODE
Write-Host ("cong khe: " + ($gate -join ' '))
if ($rc -ne 0) { throw 'Cong khe TU CHOI; khong ghi NHAN.' }
$now = (Get-Date).ToString('HH:mm')
$line = @"

auraring | NHAN khe ($now) | HAI luot live tren stage-auraring (moi: Game.exe 79f2a9a3629c09dd, Render.dll f7f4a241aac9b332), tai khoan test02/CYTest02, moi luot toi da 300 s. Cong khe fxcy2_slot_free.py DA QUA ngay truoc dong nay trong CUNG script. KHONG restart server, KHONG ghi Mongo, KHONG danh nhau (probe chi LAI CON TRO vao MCT_SKILL_AREA, khong gui goi thi trien). A/B mot bien so CYS_AURARING: e0=0 (nguyen van duong ma cu), e1=1 (ban va ghep chi so nhu CY). DU DOAN VIET TRUOC, 8 o, da dang ky trong Tools\fx\auraring_ab.py (selftest 9/9 co ca ca am): (1) e0 effect=aura_rune_projector khong chu so; (2) e0 co dong "can't find the required effect template"; (3) e0 diem anh doi <= 1500; (4) e1 effect=aura_rune_projector0; (5) e1 KHONG co dong "can't find"; (6) e1 diem anh doi >= 5000, hop bao >= 60x60; (7) ca hai canh ring_made=1 va lenh=MCT_SKILL_AREA; (8) 0 dong ERROR. Bat ky o nao truot => BAO SAI, khong noi nguong. SE ghi dong TRA khe.
"@
Add-Content -LiteralPath (Join-Path $root 'Build\game-slot-queue.txt') -Value $line -Encoding UTF8
Write-Host 'DA GHI NHAN khe.'
