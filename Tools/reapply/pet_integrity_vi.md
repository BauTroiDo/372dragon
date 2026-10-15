# Áp lại bản sửa Pet — CY 3.71, 22/09/2026

Chỉ áp vào server riêng `/home/ubuntu/cys-test-20260913`. Không sửa server gốc,
snapshot WSL, `client`, `client_GL` hoặc nguồn CY sống. Kết quả và giới hạn:
[bàn giao Pet](../../Timeline/handoff/pet-integrity-22-09_vi.md).

## Nguồn và sinh dữ liệu

`Tools/server/pet_integrity_data.py` sinh `CysPetUpgradeData.inl` từ
`Tools/DATA NEW/DataCY31-08-26/{Config,tlbb15/Public/Config}/PetSkillLevelup.txt`.
Công cụ kiểm hai bảng trùng 267 dòng ở các cột chung. Chỉ 84 dòng có mức nâng
nhanh/giá được chứng minh cùng hai nhánh và tới được qua chuỗi nâng mới được bật.

```powershell
python -B -X utf8 Tools/server/pet_integrity_data.py --check
python -B -X utf8 Tools/server/pet_integrity.py --out Build/Logs/pet-reapply/staging
```

Bản kế hoạch có 19 file: 18 Lua và bảng `configs/PetSkillLevelup.txt` giữ GBK
nguyên byte của CY Public. Các nguồn Lua nằm trong `pet_integrity_lua/`; module
`cy_pet_rules_data.lua` được sinh từ bảng CY, không lấy dữ liệu người chơi.
Các phép biến đổi phải idempotent. Xem manifest trước khi áp; không ghi kế hoạch
vào snapshot. Nguồn sống phải có trên máy để sinh lại.

## Kiểm và áp server

```powershell
wsl -d TLBB -u root -- lua5.4 /mnt/c/TLBB/085/CY-Source/Tools/server/pet_integrity_tests.lua /mnt/c/TLBB/085/CY-Source/Build/Logs/pet-reapply/staging /mnt/c/TLBB/085/CY-Source/Build/Logs/pet-reapply/staging/GameServer/lualib
python -B -X utf8 Tools/server/pet_integrity.py --out Build/Logs/pet-reapply/staging --apply
wsl -d TLBB -u root -- bash /mnt/c/TLBB/085/CY-Source/Tools/server/cys_server.sh restart --confirm-root /home/ubuntu/cys-test-20260913
```

Chạy `luac5.4 -p` riêng từng Lua. Công cụ sao lưu file thay đổi trước khi ghi vào
`<private>/backups/pet-integrity-<UTC>/`, kèm SHA trước/sau. Kiểm 6 dịch vụ,
16 cổng và log sau thời gian nạp scene; không coi 14/16 ngay sau start là lỗi.
Rollback dùng đúng manifest và backup tương ứng, khi không có client; file
`before=null` là module mới, không ghi đè các bản vá mới hơn bằng backup cũ.

Kiểm hồi quy túi: `inventory_integrity_tests.lua` với GameServer riêng và
`GameServer/lualib/cys_inventory_guard.lua`; kiểm túi thú đầy bằng
`pet_bagfull_tests.lua` với `services/scene/obj/human.lua` riêng.

## Kiểm client và dữ liệu thử

Dựng target `cys_wxclient` bằng `Tools/build/build.cmd x64 coord-x64 Release ...`
theo danh sách component đang dùng. Giữ mutex `Tools/perf/game_slot.ps1`, ghi
NHAN/TRA vào `Build/game-slot-queue.txt`; không build khi Game đang chạy.
Stage riêng `stage-equipment-skills-23` phải dùng CanonicalCY, cùng cụm DLL.

`CYS_PET_MECHANICS_LIVE=1` kiểm sách, trùng skill, nâng skill, cộng năm thuộc
tính, dung hồn/tách hồn, ngộ tính/linh tính và xuất/thu hồi thú. Cờ
`CYS_PET_ITEM_LEGACY=1` là đối chứng âm duy nhất: bỏ GUID đích, sách không được
tiêu và skill không được học. Mode 2 kiểm giữ dữ liệu qua đăng nhập lại. Mode 3
kiểm huyễn hóa, lặp yêu cầu, linh tính thường, nâng skill nhanh và sáu giá trị UI.
Tất cả cờ mặc định tắt; probe chỉ cho phép tài khoản thử `test15` cùng login smoke.

`pet_integrity_fixture.py` chạy trong WSL, chỉ sửa GUID 200016/test15. `seed`
tạo backup **toàn bộ** document, không ghi đè backup đã có; `reset` dùng backup
đó; thêm `--awakening` cho mode 3. Sau khi đổi lượt thử phải restart private để
xóa phiên RAM trước khi reset. Mode 1 âm rồi dương có thể nối tiếp vì lượt âm
không đổi sách/skill. Sau lượt dương chạy mode 2 không reset.

Sau kiểm phải restart private, chạy `restore --backup ...`, rồi `verify` để so
khớp **toàn bộ document**. Không commit fixture, mật khẩu, dump hoặc binary.
Không dùng test09/test13. Skill mẫu phải học bằng luồng sách thật; BSON key
chuỗi `"1"` không đại diện cho chỉ mục skill số 1 trong Lua.

## Phát hành Play21

Trong mutex và khi mọi Game đã thoát, gọi `Tools/game/publish_pet_client.py`
với `--negative`, `--normal`, `--relogin`, `--awakening` trỏ tới bốn thư mục
bằng chứng mới. Công cụ yêu cầu world PASS, marker tính năng đúng, không lỗi
Lua/crash và cùng hash Game/manifest; không nhận bài thử của binary cũ.
Nó sao lưu Play21 rồi cập nhật Game/PDB, bản kê và xóa hai cờ thử trong launcher.

Kiểm cuối:

```powershell
python -B -X utf8 Tools/game/stage_wsl_test.py check --stage Build/world-gui/stage-play-21
python -B -X utf8 Tools/build/dll_cluster_check.py Build/world-gui/stage-play-21/Bin64
python -B -X utf8 Tools/pipeline/cys_stage_datatree_check.py Build/world-gui/stage-play-21
```

Không coi các lệnh này là chứng nhận mọi cơ chế Pet. Dung hợp độ, Thú hồn CY
mở rộng, sinh sản/kho thú và các nhánh nâng cao còn thiếu phải theo bảng tồn
đọng của bàn giao, có phép thử riêng trước khi đóng.
