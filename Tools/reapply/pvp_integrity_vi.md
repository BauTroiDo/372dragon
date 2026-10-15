# Áp lại PK, Lôi đài và thuộc tính — CY 3.71

Chỉ thao tác server riêng `/home/ubuntu/cys-test-20260913` và CY-Source.
Đọc [bàn giao](../../Timeline/handoff/pvp-integrity-22-09_vi.md) trước khi áp.
Không sửa `client`, `client_GL`, CY sống, server gốc hoặc snapshot WSL.

## Server

`pvp_integrity.py` kiểm idempotence toàn bộ kế hoạch trước ghi, sao lưu các
file thay đổi dưới `Build/backups/pvp/<timestamp>`. Tạo kế hoạch trước:

```powershell
python -B -X utf8 Tools/server/pvp_integrity.py --stage Build/Logs/pvp-reapply/staged
python -B -X utf8 Tools/server/pvp_traits_audit.py
```

Chín file đích: cy_pvp.lua, human.lua, scenecore.lua, combat_core.lua,
eluoyang_challenge.lua, AttackTraits.txt, BaseValueTable.ini, skill/base.lua
và impact_logic/std_impact_114.lua. Nguồn impact114 cũng được cập nhật trong
server_impact_lua để áp lại hệ impact không ghi ngược lỗi đơn vị. Các hệ số theo
CY lấy từ `Tools/DATA NEW/DataCY31-08-26`. BaseValueTable giữ trường camp 40
và section 16 tắt; trường 41 đổi theo thứ tự trait GL đang dùng. Áp sau công
cụ đổi ID môn phái cũ để không bị công cụ đó ghi lại số liệu cũ.

Giữ khe `Tools/perf/game_slot.ps1`, chắc chắn không có người chơi kết nối,
áp và restart bằng wrapper riêng:

```powershell
python -B -X utf8 Tools/server/pvp_integrity.py --apply
wsl -d TLBB -u root -- bash /mnt/c/TLBB/085/CY-Source/Tools/server/cys_server.sh restart --confirm-root /home/ubuntu/cys-test-20260913
```

Chờ nạp scene, tối đa 900 giây; xác nhận 16/16 cổng và log mới không có lỗi do
bản vá. Không suy thất bại từ trạng thái 14/16 ngay sau khi wrapper khởi động.

Kiểm Lua:

```text
lua5.4 Tools/server/pvp_integrity_tests.lua R Tools/server/pvp_integrity_lua
lua5.4 Tools/server/pvp_attributes_tests.lua R CY/tlbb15/Server/Config/BaseValueTable.ini
lua5.4 Tools/server/server_impact_tests.lua R
```

R là gốc server riêng; dùng đường Linux thật khi chạy WSL. Kiểm cú pháp từng
Lua bằng `luac5.4 -p`. C++ quan hệ client độc lập:
`g++ -std=c++11 Tools/server/pvp_client_rules_tests.cpp -o /tmp/cys-pvp-rules`.

## Client và kiểm phiên chơi

Dựng x64 Release hai target `cys_wxclient cys_netbot` trong coord-x64, giữ
cụm DLL hiện hành. Stage test dùng CanonicalCY. Mỗi lượt vào thư mục mới,
kiểm nội dung WXClient.log cùng run.json, SHA của Game/manifest và thời gian.

`CYS_PVP_LIVE` bật probe: 1 đổi PK/timer/menu, 2 mời Lôi đài (từ chối rồi nhận),
3 nhận lời mời qua Lua CY, 4 PK tự do, 5 vùng an toàn. `CYS_PVP_OLD=1` đối chứng
tắt module. Mặc định tất cả probe tắt. NetBot `--pvp-peer 1` từ chối lời đầu,
nhận lời sau; `--pvp-peer 2` gửi lời mời cho đối thủ đã thấy.

Chạy peer với `--walk 1`: chuyển động thật gỡ bảo vệ đăng nhập theo luật
server. Peer đứng yên vẫn còn impact 54 nên không nhận sát thương; đây không
phải bằng chứng công thức đánh bị hỏng. `--dwell-ms 180000` của peer PvP tính
trên một mốc phiên kết nối game, không đặt lại khi chuyển vào/rời Lôi đài.
Kiểm `result.json`: thoát `quit_complete`, mã 0, không lỗi decode; PK tự do
và Lôi đài phải có `damage_taken > 0`, vùng an toàn phải bằng 0. Lượt Lôi đài
còn phải chuyển cảnh hai lần và trở về cảnh 0 tại 180,328.

Hai nhân vật thử riêng test14/test15 (200015/200016) phải sao lưu nguyên
document bằng `pvp_integrity_fixture.py seed --backup <thư_mục_mới>`. Các
mode reset/restore/verify chỉ dùng chính backup đó. **Restart server trước
mỗi lần ghi Mongo**, kể cả đã 0 socket. Các scenario mode/safe ở Đại Lý,
free ở Vô Lượng Sơn 6, arena ở area 806011 của Lạc Dương mới. Không seed cờ đủ điều kiện
Lôi đài: phải do callback vùng thật thiết lập. Không ghi fixture DB/credential
vào git. Sau mọi lượt, restart rồi restore+verify đủ hai document.

## Phát hành

`Tools/game/publish_pvp_client.py` yêu cầu sáu thư mục evidence qua
`--negative --mode --free --safe --arena --receive`, cùng Game/manifest.
Tất cả phải đạt world/move/quit; các lượt B có feature PASS, không Lua failure/
dump. Lượt A phải thực sự gọi host stub và không xác nhận đổi PK. Không nới
cổng để phát hành khi phép kiểm chưa chạy hoặc thất bại.

Giữ khe Game; publisher sao lưu Game/PDB/manifest/launcher Play21, chỉ thay
Game/PDB, từ chối DLL đổi, xóa hai cờ PvP kiểm trong launcher. Cuối cùng kiểm
stage DataTree, DLL cluster, profile và service/log. Hoàn tác bằng các file
trong backup đúng timestamp, giữ khe và restart để cache Lua/bảng nạp lại;
không phục hồi toàn DB hoặc toàn cây từ snapshot cũ.

Backup server đầu đợt 22/09 được chia theo lúc thêm phạm vi:

- `Build/backups/pvp/20260922-080755`: human, scenecore, combat_core, script
  Lôi đài và AttackTraits trước sửa. `cy_pvp.lua` trong backup này rỗng vì là
  file mới, không phải module Lua hợp lệ để chép lại.
- `Build/backups/pvp/20260922-083223`: BaseValueTable trước đồng bộ CY.
- `Build/backups/pvp/20260922-090430`: skill/base.lua và impact114 trước sửa
  đơn vị xác suất.

Nếu hoàn tác toàn đợt, dùng đủ ba nhóm này cùng backup client được ghi trong
`pvp_integrity_update.backup`; kiểm lại các thay đổi phát sinh sau mốc này
trước khi phục hồi. Chỉ gỡ module `cy_pvp.lua` mới sau khi các file gọi nó
đã được hoàn tác. Dừng/restart server riêng qua wrapper và giữ khe như lúc
áp; không chép đè khi còn phiên người chơi trong RAM.
