# Phòng thay đồ: danh mục và sở hữu

Phạm vi runtime duy nhất là `/home/ubuntu/cys-test-20260913`. Không áp vào server gốc.
Client cần được tạo stage `CanonicalCY`, `--gui cy` từ cùng revision với bộ cài này.

## Dữ liệu và giao thức

- Danh mục sinh từ DBC CY: 4.113 item trang phục (gồm biến thể), 217 mặt, 301 tóc,
  75 avatar, 71 đầu sức, 27 bối sức, 956 huyễn sức, 297 thú cưỡi; 17 thú hồn xem thử,
  kích hoạt qua sự kiện riêng. UI gom 956 huyễn sức thành 196 nhóm có cấp độ;
  4.113 item trang phục thành 441 nhóm với 1.050 ngoại hình/màu; thú hồn có
  122 màu × 5 cấp (dung hợp 0/3/6/8/10). ID sở hữu cũ được giữ nguyên.
- Mã loại giao diện 1..9 là hợp đồng riêng của tính năng, không phải enum GL/CY gốc.
  Loại 8 luôn là thú hồn; loại 9 là thú cưỡi, hiển thị trước thú hồn.
- Loại 2..7 dùng native ID `10000 + ID CY`; giữ nguyên mọi dòng GL cũ để tránh đeo nhầm model.
- `CGExecuteScript` script 990021, hàm `Request`, tham số `[1,sequence,operation,type,id]`.
  Operation 0 đọc trạng thái, 1 nhận sở hữu, 2 áp dụng. Server tự lấy nhân vật từ phiên đăng nhập.
- Client mới dùng version 2, thêm operation 3 lưu vị trí đầu/bối sức. Khi dùng hoặc lưu
  hai loại này, gửi thêm `[x,y,z]`; server kiểm sở hữu và giới hạn từng trục từ DBC.
  Reply v2 giữ header 8 số; chuỗi `ids|id:packedPosition,...` chứa vị trí của các món
  đã sở hữu. Reply v1 giữ nguyên định dạng cũ. Vị trí nằm trong entry headinfo/backinfo;
  nếu món đang dùng, server cập nhật cả actor. Đổi món và đăng nhập lại giữ vị trí đã lưu.
- `GCUICommand` index 990021 trả header 8 số và một chuỗi ASCII chứa các ID đã sở hữu.
  Client kiểm sequence, loại, operation, ID, kích thước và số lượng trước khi cập nhật UI.
- Sở hữu chỉ thay đổi sau ACK. Không chạy Lua nhận từ mạng. Event nội bộ
  `CYS_WARDROBE_CHANGED` chỉ dành cho phòng thay đồ.
- Trang phục lưu bộ sưu tập vào `exterior.cys_fashions`; khi mặc dùng container/equip native.
  Giữ chỗ cho đồ đang mặc, không ghi đè kho đầy. Loại còn lại dùng API exterior native.
- Khi mặc trang phục, v2 gửi thêm visual màu sau ID. Server kiểm visual thuộc đúng
  nhóm, giới tính và dữ liệu hợp lệ trước khi lưu visual vào item và phát cập nhật
  trang bị native. v1 bỏ qua tham số thêm; không thể vượt whitelist màu của v2.
  Màu không có item shop riêng vẫn dùng ID của bộ gốc. Khi đăng nhập, preview đọc
  giới tính và visual trang phục thực tế từ nhân vật.
- Thú hồn bị chặn ở cả client và server cho operation 1/2; chỉ sự kiện native mới kích hoạt.
- Thú cưỡi dùng nguyên ID CY (server đã chuyển trục bằng `ride-finish`); installer đối chiếu
  đủ 297 ID/model với bảng server và từ chối khi lệch. Nhận qua `add_expiration_time(id,-1)`,
  lưu vào `exterior.rides`; chọn qua `char_exterior_request` type7 option3.
  Nút Lên / xuống thú dùng `CGCharAutoRide` và kỹ năng21/impact native; không sửa thẳng model thế giới.
  Preview dùng chế độ xem riêng thú của CY (`Exterior_Ride`, kiểu creature), qua
  host `LuaFnUpdateExteriorAvatarMount` tra CharMount → CharModelEx.
  Tháo RTT trước khi đổi model và gắn lại sau đó; không giữ con trỏ entity cũ.

## Tạo lại và áp dụng

Từ gốc repo bằng Windows Python:

```text
python Tools/game/wardrobe_render_data.py
python Tools/game/wardrobe_soul_models.py
python Tools/server/wardrobe/install.py plan --out Build/Logs/wardrobe-plan
python Tools/server/wardrobe/install.py apply --out Build/Logs/wardrobe-apply
python Tools/server/wardrobe/install.py verify --out Build/Logs/wardrobe-verify
```

`apply` giữ flock chung `configs/.scene_install.lock`, đọc lại file sống trong khóa,
sao lưu từng file trước khi thay thế. Xem đường dẫn backup trong `report.json`.
Không thay dòng cấu hình cũ. Mã namespace đã tồn tại với nội dung khác sẽ bị từ chối.
Sau thay đổi catalog/config, dùng wrapper `Tools/server/cys_server.ps1 restart
--confirm-root /home/ubuntu/cys-test-20260913`, nhận/trả khe theo luật dự án và chờ
cổng private 15733/15734 sẵn sàng (wrapper trả về trước khi Game nạp xong scene).

## Kiểm chứng

`test_wardrobe.lua` chạy handler thật với API native mô phỏng để kiểm whitelist,
không sở hữu, nhận trùng, 8 loại nhận được, thú cưỡi hết hạn, kho đầy, thú hồn và đọc lại trạng thái.
Kiểm chứng lưu dữ liệu và render phải chạy client thật, không suy ra từ mock.

Chỉ bật khi thử: `CYS_WARDROBE_LIVE=1` xem, `2` nhận/dùng, `3` kiểm sau đăng nhập;
`CYS_WARDROBE_ITEM=1` hoặc `2` chọn fixture; `CYS_WARDROBE_ACQUIRE_OFF=1`
là đối chứng âm cùng binary. Bình thường mọi cờ này tắt.
Riêng thú cưỡi: `CYS_WARDROBE_LIVE=4` nhận/chọn/lên/xuống, `5` kiểm sau đăng nhập;
`CYS_WARDROBE_MOUNT_ITEM=2` (hoặc ID CY 1..297). Probe thao tác qua nút thật và
kiểm riêng model thế giới cùng ACK, không coi ACK là bằng chứng render.
Kiểm lại thư mục đã kết thúc bằng `Tools/game/wardrobe_verify.py --arm ...`;
thêm `--mount` cho lượt kiểm thú cưỡi.
không chỉ đọc dòng PASS chung của world rig.

Huyễn sức và vị trí: `CYS_WARDROBE_LIVE=6` kiểm nút chỉnh ba trục, reset, lưu,
chọn lại và mở lại; `7` kiểm vị trí sau đăng nhập. Hai chế độ thử sáu huyễn sức
(đao, thương, song đoản, Type 92 và tên model khác hoa/thường), đọc hand model
và chụp ảnh thực tế. `CYS_WARDROBE_WEAPON_OLD=1` là đối chứng đường gắn cũ;
không bật trên launcher chơi. Preview vị trí chỉ cập nhật transform của model con,
không dựng lại nhân vật hoặc nạp lại texture. Tab Bối sức mặc định nhìn từ phía sau.

Biến thể: chọn một nhóm rồi dùng mũi tên Cấp độ / Màu sắc dưới preview. Tìm theo tên
hoặc nhập `=mã` để chọn đúng ID. `CYS_WARDROBE_LIVE=8` kiểm cấp/màu, mặc màu,
model thú hồn (gồm bướm/cánh cấp 5), điều kiện sự kiện và di chuyển sau khi đóng;
`9` kiểm trang phục màu sau đăng nhập. `CYS_PREVIEW_FX_OLD=1` bật lại cách ẩn actor
mỗi lượt RTT để làm đối chứng; `CYS_PREVIEW_FX_METRICS=1` ghi số particle đang sống.
Đếm particle gồm toàn bộ ngoại hình xem trước, không chỉ vũ khí. Hai cờ mặc định tắt.

`wardrobe_soul_models.json` bổ sung 18 liên kết CharModelEx thiếu trong CY, dùng đúng
object cấp 5 đã có trong all.obj và màu tương ứng cấp 4. Không sửa dữ liệu CanonicalCY,
không mượn ID GL. Chạy generator với `--write-header` khi thay mapping đã kiểm chứng.

Catalog dùng `wardrobe_fashion_validation.json` để chặn các chuỗi render thời trang
thiếu sẵn trong CY theo giới tính. File chứa hash đầu vào; khi DBC/material thay đổi,
phải chạy lại kiểm tra chuỗi mesh/skeleton/material/texture trong
`Tools/server/costume_data.py` và cập nhật bản kiểm kê trước khi sinh danh mục.

## Khôi phục

Khôi phục đúng từng đường dẫn được ghi trong backup/report của lượt áp dụng, trong
cùng khóa cấu hình và sau khi trả khe Game. File có dấu `.absent` là file mới của tính
năng; bỏ đăng ký script 990021 trước khi gỡ nó. Không khôi phục cả thư mục server từ
snapshot. Giữ bản sao dữ liệu nhân vật nếu muốn bỏ namespace: item đã nhận và trang
phục đang mặc là dữ liệu thật, không được xóa ngầm khi đổi client.
