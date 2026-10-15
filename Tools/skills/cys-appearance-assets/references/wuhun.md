# Võ hồn và huyễn hóa đã hoàn thiện 25/09

Nguồn mới nhất trong lượt tổng hợp: [fix 25/09](C:/TLBB/085/CY-Source/Docs/specs/client/wuhun-appearance-fix-20260925_vi.md). [Audit trước sửa](C:/TLBB/085/CY-Source/Docs/specs/client/wuhun-appearance-audit-20260925_vi.md) mô tả bản cũ, không là trạng thái cuối. [Preview](C:/TLBB/085/CY-Source/Docs/specs/client/wuhun-preview-20260925_vi.md) chỉ nói widget VH.

## Hợp đồng

- CY ItemVisualLocator cột 9 = KFSObj, cột 10 = material. Model nam/nữ đều cần slot này. Dữ liệu cơ bản từ KFSBase item 10156001..4, cấp hợp thành quyết định visual; không lấy visual cache 723 nếu không tương ứng item.
- Sáu Huyễn hồn, hai dạng Càn/Khôn, ba bậc hình ảnh từ GL. Level 1/5/8 chuyển tier. Server tính visual theo unlocked/grade/slot/yy/show; chuẩn hóa trạng thái ẩn/không đeo về không attachment.
- GL skill 3238 để gắn Huyễn hồn khác CY 3238 (“赠送竹节”); không map mù. Native CGWuhunWG type 2 được server xác thực trực tiếp với equipped/unlocked/level >= 80 / slot.
- Script 888800: ActiveWg/LevelUpWg/TakeOut/SwitchYY/SetShowWuhun/CysState, GCWuhunWG 1345 unlock data; custom GCUICommand 888800 trả yy/qian/kun/show+ack theo implementation. Giữ allowlist, ready/busy/ACK của tuyến hiện tại; không báo UI thành công trước ACK.
- Phí do Lua GL/server hiện có, kể cả nguyên liệu khóa thay thế. Count và tiêu hao phải đọc đúng vùng nguyên liệu, đừng nhầm fixture sai tab là lỗi phí.

## Điểm sửa

`Network/CysWuhunNet.*`, `CysInventoryNet.cpp`, `Object/Character/Obj_PlayerOther.*`, `Obj_PlayerMySelf`, `Procedure/CysCreateRoleGame.cpp`, `LuaApiGen/CysHost_MeshWin.cpp`, `DataPool/CysWuhunData.h`.

Generators `Tools/game/wuhun_appearance_data.py`, `wuhun_appearance_ui.py`; state/server `Tools/server/cys_wuhun_appearance.lua`, `deploy_wuhun_appearance.py`. File human.lua trùng tên không chứng minh cả hai được dùng: lần theo scenecore/require, patch chỉ tuyến cần thiết.

UI gốc có MessageBoxSelf3 stub: inline xác nhận đủ phí đã được dùng. Parent trong suốt rộng toàn cửa sổ từng chặn tab trái; nhóm controls bên phải đúng hình học, hide controls cũ khi overlay mới hiện. `DataPool:Lua_GetItemNameByIndex` có thật; global cùng tên không mặc nhiên tồn tại. Nhãn dài có thể rút ngắn ở dòng chính nhưng xác nhận phải giữ đủ chi phí/loại thay thế.

## Bằng chứng mẫu

`Build/Logs/2026-09-25-wuhun-appearance/live-09`, `relogin-02`, `persistent-result.json`, `restore-result.json`. Giao dịch thật kích hoạt 2 hồn/nâng tiến độ/gắn, đổi, ẩn/hiện, render 36 mẫu, world/SelfEquip/màn chọn nhân vật 750, chuyển Võ Đang→Đại Lý. Test từ 10 triệu→8.960.000 và stack 100→50/50/98, khôi phục BSON chính xác. Các giá trị này là fixture lịch sử, không phải số dư/phí mặc định của người chơi.
