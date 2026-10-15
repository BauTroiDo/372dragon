# Dựng lại kỹ năng trang bị và các sửa tiếp ngày 22/09/2026

Chuẩn dữ liệu CY 3.71; chỉ ghi CY-Source/CanonicalCY và server riêng `/home/ubuntu/cys-test-20260913`. Không ghi client/client_GL/CY Game hoặc server gốc.

## Client

Sau khi sinh lại CanonicalCY, chạy theo thứ tự:

```powershell
python -B -X utf8 Tools/reapply/equipment_skill_ui.py --apply
python -B -X utf8 Tools/reapply/equipment_skill_text.py --apply
python -B -X utf8 Tools/reapply/equipment_skill_layout.py --apply
python -B -X utf8 Tools/reapply/residual_ui.py --apply
```

Bỏ `--apply` để kiểm trước. Có backup dưới `Build/backups`; chạy lại không nhân đôi bản vá. Ba layout chỉ đổi vùng chữ/nút và vị trí, giữ tên control, cha/con, event. Chữ Ám khí có tooltip, khi bỏ item thì tooltip cũng được xóa. Không bật GLResponsive.

Build cả `cys_wxclient` và `cys_uisystem` trong cây `coord-x64` Release. Chạy syntax client bằng `Tests/luaapi/run_lua_syntax_audit.ps1` (LuaPlus của game); Lua5.4 không phải parser tương thích cho toàn bộ UI.

`CYS_EQUIPMENT_SKILLS_LIVE=1/2/3/4` lần lượt kiểm nghiệp vụ, lưu lại, UI/Ám khí, hợp đồng Pet/metadata. Chỉ test15. `CYS_PET_LIST_LEGACY=1` là đối chứng âm getter cũ; mặc định tắt. Không bật trong bản chơi.

`Tools/game/publish_equipment_client.py --live <mode3> --contracts <mode4>` đòi cả hai kết quả đạt trên đúng hash Game và manifest hiện tại, không có Lua failure, không có Game đang chạy. Công cụ sao lưu rồi cập nhật riêng Game/UI_CEGUI và PDB vào Play21, giữ profile chơi và xóa cờ probe khỏi launcher. Không tự coi gate phát hành này là kiểm hình thức UI: phải xem ảnh mode3 trước.

## Server

Kỹ năng trang bị: `Tools/server/equipment_skills.py plan/apply`. Khi đã apply một lần, `plan --base` phải trỏ backup gốc `backups/equipment-skills-20260921T173946Z`, tránh nhân đôi đoạn chèn. Module sở hữu nằm trong `equipment_skills_lua`. Plan24tệp và backup/hash được giữ dưới Build/Logs và server/backups.

**Thứ tự bắt buộc:** sau khi apply/regenerate equipment plan, chạy `Tools/server/shimen_target_fix.py --out <plan>` rồi kiểm `test_shimen_targets.lua`, cuối cùng `--apply --out <deploy>`. Hai bộ có chung script_base.lua; không dùng hash plan-v5 cũ để khẳng định file hiện tại chưa đổi. Bộ sư môn chỉ thay đúng GetOneMissionNpc và10dòng nhận tuple, giữ toàn bộ sửa kỹ năng có sẵn.

Sau sửa lualib phải restart server riêng bằng `cys_server.sh restart --confirm-root /home/ubuntu/cys-test-20260913`, đợi đủ16cổng và kiểm log mới. Không dùng snapshot nguồn làm đích ghi.

Kiểm hồi quy: `test_equipment_skills.lua`, `test_equipment_passives.lua`, `test_lingpai.lua` nhận root + staging (dùng root hai lần để kiểm bản đã triển khai); `test_shimen_targets.lua` cùng quy ước. Fixture `equipment_skills_fixture.py` chỉ test15/GUID200016, bắt buộc backup/restore, không đưa bản sao DB vào commit.

Các phần chưa đóng và bằng chứng đầy đủ: `Timeline/MOC-22-09-RA-SOAT_vi.md`, `Timeline/handoff/equipment-skills-cy371-22-09.md`.
