# Native evidence và navmesh

## Nguồn chính xác

Đợt 24/09 dùng `Build/re/wuliang-parity/CYGame/Bin64/Game.exe` SHA256 `9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b`. Không chuyển RVA sang binary khác mà không xác nhận hash.

- `0x140613380`: CharMount 109, cột 19, request bay và khóa 2000 ms.
- `0x1407861a0 / 0x14083b640`: codec 2242, body 5 byte.
- `0x1405ee030 / 0x1405ee430`: action cất/hạ cánh; `0x1405ec038 / 0x1405f4690`: action trên không.
- Render `0x18008e020` đọc `scene.fly`; `StrDictionary` FLY_101118_01/02 là tổ hợp phím, các message còn lại mô tả giới hạn.
- `Tools/game/audit_mount_flight.py` có công cụ đọc tĩnh; dùng skill reverse engineering khi cần phân tích binary sâu, không mặc định decompile cho mọi sửa đổi.

## Lưới bay và mặt đất

.fly có u32 count rồi 16 byte reserved và float độ cao tuyệt đối; có dạng legacy header 4 byte. Phân biệt bằng kích thước chính xác, kiểm count/size/finite/bounds trước nội suy. Có 181 mục scene có grid ở mốc khảo sát; grid hỏng/thiếu thì từ chối, không tự cho Y cố định.

Đường bay dùng mặt bay, không dùng navmesh đất; hạ cánh cần kiểm tam giác và cờ blocked của CY. `findpath(pos,pos)` có thể trả thành công dù điểm không đứng được. Nav_adapter cũ đọc đa giác 5 điểm không tương đương .path CY; không vá di chuyển đất toàn cục để chữa bay.

`cys_mount_flight_nav.bin` là dữ liệu gộp .path nguyên byte/loại trùng, không phải DLL. Lua đọc khi cần theo scene, float32 làm tròn tương đương C++ PathLib ở cạnh/đỉnh. Test đối chiếu 258.204 điểm/181 mục (ngẫu nhiên, đỉnh, sát đỉnh) từng có 0 sai lệch; cần dùng dữ liệu hiện tại nếu thay importer.

## Xác thực server

Kiểm actor/phạm vi điều khiển/mount/scene/trạng thái sống/đội/shop, tọa độ hợp lệ và chu kỳ chuyển tiếp. Chặn đổi thú/hủy buff cưỡi/theo đội khi bay. Kiểm skill/item cả lúc chọn và lúc impact; Lạc Mã Tiễn 37 từ đất là ngoại lệ theo nguồn, không tự mở mọi skill đánh người bay. Callback cũ không được khôi phục trạng thái sau chết/mất mount/chuyển scene.

Các kiểm tra: `Tools/server/test_mount_flight.lua`, `test_flight_nav.lua`, `Tools/game/tests/mount_flight.cpp`, `mount_flight_nav.cpp`; bằng chứng `Build/Logs/2026-09-24-mount-flight-actions`. Lượt `live-01-dragon` thất bại đã phát hiện server cho hạ cánh sai; các lượt `live-02-dragon`, `live-03-kite`, `live-04-ground` mới là bản đạt sau sửa.
