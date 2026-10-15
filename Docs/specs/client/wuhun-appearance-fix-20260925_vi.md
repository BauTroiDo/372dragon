# Hoàn thiện ngoại hình và huyễn hóa Võ hồn — 25/09/2026

Phạm vi: CY-Source và máy chủ thử riêng `/home/ubuntu/cys-test-20260913`.
Tài nguyên GL/CY và máy chủ chính chỉ được đọc để đối chiếu.

## Đường hiển thị

`GCCharEquipment` có cờ `0x40000` cung cấp item và visual Võ hồn. Client lưu
hai giá trị vào dữ liệu nhân vật và cập nhật thuộc tính `KFSObj` của actor.
Đường này dùng chung cho người chơi thật và avatar; SelfEquip nhận lại trạng
thái từ nhân vật chính. Mô hình riêng trong tab VH vẫn dùng `CharModelEx`,
không dựng cả nhân vật. Tháo trang bị hoặc ẩn Võ hồn xóa `KFSObj`.

Máy chủ chọn visual từ Võ hồn đang đeo, mức hợp thành, cờ ẩn/hiện và hồn
Càn/Khôn đã mở khóa. Khi đăng nhập, danh sách nhân vật tính lại visual từ
trang bị và trạng thái lưu trong DB, tránh dùng cache visual cũ. Client áp dụng
visual đó vào actor màn chọn nhân vật.

## Đối chiếu với bản có sẵn

- CY có slot actor `KFSObj`; cột 9 của `ItemVisualLocator` chỉ đối tượng đó.
- Các visual Huyễn hồn 729–764 của GL không được tra trực tiếp vào bảng CY:
  các số này trùng đối tượng khác trong CY. Dùng bảng ánh xạ riêng.
- Sáu loại Huyễn hồn, hai dạng Càn/Khôn và ba bậc ngoại hình lấy từ GL.
  Import 36 đối tượng cùng 291 phụ thuộc đã được bộ pipeline thu thập và
  đổi tên riêng. Giữ bảng CY gốc nguyên byte; thêm model ID 9995–10030.
- Skill 3238 mà server GL dùng khi gắn Huyễn hồn là kỹ năng khác trong CY.
  `CGWuhunWG` được xử lý trực tiếp tại máy chủ sau kiểm tra quyền sở hữu,
  cấp nhân vật, trang bị và chỉ số Càn/Khôn.
- Phí kích hoạt và nâng cấp dùng cấu hình server hiện tại; Lua GL gốc thực
  hiện khấu trừ vàng/giao tử và nguyên liệu, kể cả bản khóa thay thế.

## Giao diện

Mở **VH → Huyễn hóa**. Chọn loại hồn để xem trạng thái, cấp, tiến độ và phí.
Kích hoạt hoặc nâng cấp yêu cầu bấm xác nhận sau khi xem vàng và vật phẩm.
Sau khi mở khóa có thể gắn vào Càn/Khôn, tháo khỏi từng ô hoặc đổi dạng đang
sử dụng. Cần cấp 80 và đeo Võ hồn để thực hiện các thao tác Huyễn hồn.
Ô chọn **Võ Hồn** điều khiển việc hiển thị trên người.

Các tệp sinh:

- `Tools/game/wuhun_appearance_data.py`: dữ liệu và bộ tài nguyên GL cô lập.
- `Tools/game/wuhun_appearance_ui.py`: layout/Lua dùng skin CY hiện có.
- `Tools/game/deploy_wuhun_appearance.py`: stage, đối chiếu hash và publish.
- `Tools/server/cys_wuhun_appearance.lua`: xác thực và tính ngoại hình server.
- `Tools/server/deploy_wuhun_appearance.py`: chuẩn bị, kiểm Lua, sao lưu và áp
  dụng riêng cho máy chủ thử CY.

Công cụ chung `canon_lib.mesh_set_submat` cũng được sửa: cursor do validator
trả về đã nằm sau index buffer; header submesh phải lấy tại `q - 6`. Trước đó
việc đổi tên material có thể ghi nhầm vào geometry. Test
`Tests/test_wuhun_material_rewrite.py` kiểm geometry, chunk size và khả năng
đổi tên ngược; `mesh-integrity.json` xác nhận việc đổi ngược tham chiếu của
21 mesh khôi phục đúng toàn bộ byte của file GL gốc.

## Kiểm chứng và giới hạn

Đã publish vào `Build/world-gui/stage-play-21` lúc **08:50:19 ngày 25/09/2026**.
Game SHA-256:
`65a7f3abb3bbaa8171c0d1ca72e448d9bae4581f8939e3fc2d98ee7a43c28e72`.
Sao lưu Play: `Build/backups/wuhun-appearance-play/20260925-085019`.

- `live-09`: PASS, 265,2 giây, 59 ảnh. Bấm giao diện thật để kích hoạt hai
  Huyễn hồn, nâng tiến độ một lần, gắn Càn/Khôn, đổi dạng, ẩn/hiện, tháo/đeo;
  tiếp theo dựng 36 biến thể và xác nhận di chuyển sau đóng UI.
- `relogin-02`: PASS, 118,5 giây, 21 ảnh. Ngoại hình 750 giữ đúng ở màn chọn,
  nhân vật thật, SelfEquip; trạng thái giữ đúng sau chuyển Võ Đang → Đại Lý.
- DB kiểm đúng số vàng còn **8.960.000** từ 10.000.000, nguyên liệu còn
  **50 / 50 / 98** từ ba chồng 100, hồn cấp 1/tiến độ 1 và cấp 1/tiến độ 0,
  Càn 1/Khôn 3, không có thêm bản Võ hồn trong túi sau đeo lại.
- 83 kiểm tra Lua về ánh xạ ngoại hình và kiểm soát đầu vào; regression
  đổi tên material và kiểm byte ngược toàn bộ 21 mesh đều PASS.
- `restore-result.json`: BSON của test15 được khôi phục đầy đủ và đối chiếu
  bằng bản sao trước thử. Sáu dịch vụ máy chủ riêng và cổng 15733/15734 hoạt động.

Hai lượt cuối không có lỗi Lua của Wuhun, lỗi giải mã mạng hoặc crash dump.
Log vẫn ghi cảnh báo tài nguyên minimap Võ Đang thiếu từ trước và cảnh báo
queue của một số scene nền; không gộp chúng thành lỗi đã sửa ở đây.

Kết quả chạy cuối, ảnh và hash được ghi trong
`Build/Logs/2026-09-25-wuhun-appearance` và manifest Play khi publish.
Các lần thử thất bại được giữ lại, không được dùng làm bằng chứng hoàn tất.

Kiểm tra model trực tiếp không chứng minh một giao dịch đã thành công.
Probe tách riêng phần bấm giao diện và giao dịch thật, phần duyệt 36 model,
phần đăng nhập lại/chuyển cảnh. DB test15 được sao lưu toàn bộ BSON trước
khi cấp fixture và phải được khôi phục nguyên trạng sau thử nghiệm.

Chưa mở rộng các hệ thống chiến đấu hoặc chỉ số Võ hồn ngoài luồng sẵn có;
trọng tâm thay đổi là huyễn hóa, trạng thái trang bị và hiển thị ngoại hình.
