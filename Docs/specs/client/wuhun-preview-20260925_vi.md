# Sửa xem trước Võ hồn — 25/09/2026

## Nguyên nhân và đối chiếu

Khung `Wuhun_FakeObject` đã gắn đúng fake object `My_Wuhun`. Lỗi nằm trong
`CDataPool::Wuhun_SetModel`: đưa mã của `KFSBase.txt` vào `Set_RaceID`, khiến
`CObject_PlayerNPC` tra `MonsterAttrExTable.txt` và dựng một NPC hình người.

Ví dụ, Võ hồn `10156001` trả về `2341`. `CharModelEx[2341]` là
`武魂琉璃焰20090722.obj`, trong khi creature `2341` là `逍遥身份不明者`.
Loại `10156002` trả về mô hình đĩa `2346`, `武魂御瑶盘20090722.obj`.
Hai loại còn lại dùng lại hai nhóm mô hình này. Bốn dòng KFS chứa tổng cộng
20 ánh xạ, gồm 10 mô hình riêng biệt (2341–2350).

CY gốc: `Game.exe` SHA-256
`9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b`.
Hàm `0x1400db200` lấy equip point 18, gọi `0x1404fd780` để đọc mô hình, và
truyền `-1` khi không có Võ hồn. `0x1404fd820–0x1404fd835` chọn cột 10–14
của `KFSBase`. Chú thích cũ gán tên `Set_RaceID` cho setter trong CY là suy luận
sai; dữ liệu thực và đường dựng NPC trong mã nguồn chứng minh mã này phải
được dùng trực tiếp với `CharModelEx`.

Lua CY và GL đều làm cùng chuỗi: tháo liên kết khung, gọi
`DataPool:KFS_UpdateKFSModel()`, rồi gắn lại `My_Wuhun`. Giữ nguyên chuỗi này
và camera từ tài nguyên của Võ hồn.

## Thay đổi

- Dùng `Set_ModelID` cho avatar Võ hồn của mình và avatar Võ hồn mục tiêu.
- Luôn cập nhật cả giá trị `-1` để tháo Võ hồn không lưu lại mô hình trước đó.
- Giữ nguyên bảng mô hình, ảnh, layout và các hệ thống gameplay.
- Không đồng nhất cấp chiến đấu `wh_level` (1–120) với chỉ số biến thể ngoại
  hình (0–4). Luồng hiện tại tiếp tục chọn ngoại hình cơ bản từ cột 10;
  lần sửa này xử lý đúng loại mô hình và vòng đời xem trước.

## Kiểm chứng

Mã kiểm tra: `CysWuhunPreviewProbe.h`, bật riêng qua `-WuhunPreviewProbe` của
`run_world_gui_live.ps1`. Không bật trong Play. Chỉ dùng test15 trên máy chủ
riêng `cys-test-20260913`; sao lưu toàn bộ BSON trước khi chuẩn bị dữ liệu.

Kiểm tra gồm: mở Võ hồn đang trang bị; tháo/lắp qua thao tác thật tới server;
đóng/mở lại; dựng lần lượt 10 mô hình CY cho avatar mình và mục tiêu; xóa
mô hình; mở lại SelfEquip; đóng khung và di chuyển bằng click trên mặt đất.
Phần duyệt 10 mô hình kiểm tra trực tiếp lớp xem trước, không thay đổi cấp
hay ngoại hình vật phẩm lưu trên server.

Bằng chứng tại `Build/Logs/2026-09-25-wuhun-preview/`: bảng ánh xạ JSON,
disassembly CY, build log và các lượt chạy GUI. Công cụ phát hành
`Tools/game/deploy_wuhun_preview.py` yêu cầu kết quả probe thành công, cùng
hash Game/manifest đã kiểm tra, và Overlay/Patch trùng Play trước khi chép.

Kết quả cuối: `live-03` hoàn tất trong 139,5 giây, thoát bình thường,
`CYS-WUHUN-PREVIEW: RESULT errors=0`; toàn bộ kiểm tra login, scene, di chuyển,
socket máy chủ riêng và không có crash dump đều đạt. Đã xem ảnh Lưu Ly Diễm,
Ngự Dao Bàn, ô trống sau tháo và SelfEquip. Hai lượt đầu giúp sửa thao tác
của probe (tháo bằng chuột phải; dùng hàm trang bị của game cho vật phẩm trong
túi), không được dùng làm bằng chứng thông qua phát hành.

Game cuối có SHA-256
`71f4bba0b964726bc7e165c4e1a8a26d01d1a64a158d1f8dd83bfcf8aa78195d`.
Đã khôi phục và so sánh chính xác toàn bộ BSON gốc của test15 trước phát hành.
Bản Play nhận đúng các binary đã kiểm tra; manifest ghi `wuhun_preview_update`
với đường dẫn bằng chứng và bản sao lưu trước thay đổi.

## Nới mô hình theo phản hồi người chơi

Camera mặc định 2,2 (Lưu Ly Diễm) / 2,0 (Ngự Dao Bàn) khiến mô hình nhỏ trong
vùng vẽ cao 110 px. `power_ui.py` nay sinh vùng vẽ cao 150 px, giữ nguyên tâm
mô hình và vị trí các nút/chữ, đồng thời đặt camera riêng cho Wuhun ở
`height=0.08, distance=1.0, pitch=0.21`. Kích thước chiếu tăng khoảng 3 lần
cho Lưu Ly Diễm và 2,7 lần cho Ngự Dao Bàn. Camera và model ngoài thế giới,
SelfEquip và các cửa sổ khác không thay đổi.

`CysWuhunPreviewCamera()` đặt giá trị tuyệt đối sau mỗi lần `Wuhun_Update`,
kể cả khi mesh đang đợi nạp; gọi cập nhật nhiều lần không phóng đại cộng dồn.
Generator cập nhật Lua và layout ở cả Pre/Post. Thử nghiệm ban đầu chỉ giảm
distance xuống 0,75 trong vùng vẽ 110 px: mô hình lớn nhưng hiệu ứng lửa của
biến thể cuối bị cắt, nên không phát hành cấu hình đó.

Bản cuối ở `Build/Logs/2026-09-25-wuhun-scale/live-02`, hoàn tất 142,1 giây,
`RESULT errors=0`, có ảnh cả 10 mô hình, ảnh xoay, tháo và SelfEquip. Đã xem
trực tiếp ảnh hai loại cơ bản và hai biến thể cuối: hình/hiệu ứng nằm trong
vùng vẽ. Tháo/lắp, mở lại, cập nhật lặp và di chuyển sau khi đóng đều đạt.
Test15 được khôi phục toàn bộ BSON gốc và so sánh chính xác trước phát hành.
Game kiểm tra: `e83e88560eb4b41a84bfe72b743660ab552108e7b543dfb5a87225367c8d876f`.
Phát hành bằng `deploy_wuhun_preview.py --scale`; manifest Play ghi
`wuhun_preview_scale_update`, có bản sao lưu binary và bốn file overlay.
