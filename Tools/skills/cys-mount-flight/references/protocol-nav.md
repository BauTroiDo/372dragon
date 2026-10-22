# Native evidence và navmesh

## Lưới bay và mặt đất

.fly có u32 count rồi 16 byte reserved và float độ cao tuyệt đối; có dạng legacy header 4 byte. Phân biệt bằng kích thước chính xác, kiểm count/size/finite/bounds trước nội suy. Có 181 mục scene có grid ở mốc khảo sát; grid hỏng/thiếu thì từ chối, không tự cho Y cố định.

Đường bay dùng mặt bay, không dùng navmesh đất; hạ cánh cần kiểm tam giác và cờ blocked của CY. `findpath(pos,pos)` có thể trả thành công dù điểm không đứng được. Nav_adapter cũ đọc đa giác 5 điểm không tương đương .path CY; không vá di chuyển đất toàn cục để chữa bay.

`cys_mount_flight_nav.bin` là dữ liệu gộp .path nguyên byte/loại trùng, không phải DLL. Lua đọc khi cần theo scene, float32 làm tròn tương đương C++ PathLib ở cạnh/đỉnh. Test đối chiếu 258.204 điểm/181 mục (ngẫu nhiên, đỉnh, sát đỉnh) từng có 0 sai lệch; cần dùng dữ liệu hiện tại nếu thay importer.

## Xác thực server

Kiểm actor/phạm vi điều khiển/mount/scene/trạng thái sống/đội/shop, tọa độ hợp lệ và chu kỳ chuyển tiếp. Chặn đổi thú/hủy buff cưỡi/theo đội khi bay. Kiểm skill/item cả lúc chọn và lúc impact; Lạc Mã Tiễn 37 từ đất là ngoại lệ theo nguồn, không tự mở mọi skill đánh người bay. Callback cũ không được khôi phục trạng thái sau chết/mất mount/chuyển scene.

Các kiểm tra: `Tools/server/test_mount_flight.lua`, `test_flight_nav.lua`, `Tools/game/tests/mount_flight.cpp`, `mount_flight_nav.cpp`; bằng chứng `Build/Logs/2026-09-24-mount-flight-actions`. Lượt `live-01-dragon` thất bại đã phát hiện server cho hạ cánh sai; các lượt `live-02-dragon`, `live-03-kite`, `live-04-ground` mới là bản đạt sau sửa.
