# Nền ô nhỏ và thanh độ bền — 23/09/2026

Phạm vi: client CY từ mã nguồn, bản Play `Build/world-gui/stage-play-21`. Giữ dữ liệu CanonicalCY, client và client_GL nguyên trạng. Ứng viên nằm ở `Build/world-gui/stage-cell-skin-23`.

## Thay đổi

- SimpleText vẽ state Enabled/Disabled của look trước khi vẽ chữ, kể cả khi ô chưa có chữ. Đồng thời đọc vùng `TextArea` của look để chữ nằm trong lòng viền; trước đây bỏ qua vùng đệm này. Không thay màu, ảnh hoặc kích thước control.
- Tách phần vẽ chữ để ResizeText và Star không vẽ nền hai lần; hai lớp này đã vẽ phần nền riêng trước đó.
- Bổ sung **thanh độ bền riêng** ở mép phải bên trong ô trang bị SelfEquip và TargetEquip. Thanh rộng 3 px, giữ nguyên hình học của ô và không thêm đối tượng nhận chuột. Dùng ảnh `ProgressGreenM`/`ProgressRedM` sẵn có; dưới 10% chuyển đỏ, tỷ lệ 0 để nền thanh trống, ô không có dữ liệu độ bền ẩn thanh.
- Property `ShowDurability` chỉ bật trên ô trang bị của hai khung này; action ở túi, thanh kỹ năng và các cửa sổ khác không tự thêm thanh. `ActionButton::Update` lấy `dam`/`dam_max` từ chính object vật phẩm, `BeDestroyed` xóa tỷ lệ cũ.
- Nguồn Overlay: `patch_selfequip_readability.py` và `patch_inspection_ui.py`; giữ nguyên widget, cây và callback. Không dùng GLResponsive.

## Kiểm chứng

`CYS_CELL_SKIN_LIVE` mở SelfEquip qua sự kiện phím C, đọc tỷ lệ từ dữ liệu thật, chụp tooltip, thử mức nửa/nhỏ hơn 10% ở bản sao client rồi hoàn trả độ bền, thử xóa binding của ô và gắn lại, đóng bằng Esc và xác nhận di chuyển. Các mức thử không gửi gói sửa vật phẩm hoặc ghi database.

Lượt kết hợp còn chạy kiểm tra tooltip trong túi và xem trang bị/hồ sơ người khác. Hai document nhân vật được sao lưu trước khi đặt cùng cảnh tại `Build/Logs/2026-09-23-cell-skin/fixture.json` để hoàn trả sau thử nghiệm.

`live-02` đạt 20/20 kiểm tra phiên chơi và cả ba marker chức năng:

- `CYS-FT-TOOLTIP-PROBE: END old=0`: tooltip túi, refresh GCItemInfo, resize lặp, giữ/thả Alt và di chuyển.
- `CYS-CELL-SKIN: RESULT errors=0`: độ bền thật 111/114, trạng thái nửa, dưới 10%, ô trống, trả độ bền ban đầu, Esc và di chuyển.
- `CYS-INSPECT-PROBE: RESULT errors=0`: trang bị người khác, so sánh Alt, tooltip thường tiếng Việt, hồ sơ, đóng khung, phản hồi muộn và di chuyển.

Không có `CYS Lua failure` trong lượt này. Đã xem ảnh SelfEquip, tooltip vật phẩm, thanh nửa/đỏ, ô trống và tooltip so sánh. Ảnh ở `Build/Logs/2026-09-23-cell-skin/live-02/cys-gl-240870593-*.png`. `live-01` là lượt trước sửa vùng đệm chữ; không dùng để phát hành bản cuối.

Đã phát hành vào Play lúc 09:51:39 ngày 23/09/2026, sao lưu tại `Build/backups/cell-skin-play/20260923-095139`. Công cụ `publish_cell_skin.py` chặn nếu thiếu bất kỳ marker nào, có lỗi Lua, hash Game/manifest khác lượt thử, binary khác build, hoặc còn Game đang chạy. Launcher xóa cờ `CYS_CELL_SKIN_LIVE` trong phiên chơi thường. Game SHA-256: `2973e4bf5c95b9224aa9b839c8be8edc7d3df3706a6eb1439aee4837ec29b958`; manifest của lượt thử cũng khóa đúng UI_CEGUI/CEGUIFalagard đi kèm.

Lượt `play-final` chạy trực tiếp bản Play đã cập nhật, không bật ba probe chức năng, đạt **20/20** kiểm tra; kết thúc lúc 09:53:29, exit code 0, di chuyển bằng ba lần bấm đất, thoát với `quit_complete`, không lỗi handler/decode hoặc lỗi Lua. Hash Game đang nằm trong Play khớp chính xác lượt thử này. Sau khi tất cả client thử nghiệm đã thoát, đã hoàn trả toàn bộ hai document nhân vật từ `fixture.json`; công cụ xác nhận bằng phép so sánh toàn bộ document: `Both complete original character records restored; exact equality verified`. Bằng chứng ở `Build/Logs/2026-09-23-cell-skin/fixture-restore.txt`.
