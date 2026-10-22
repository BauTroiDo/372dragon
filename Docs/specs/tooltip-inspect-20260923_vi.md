# Tooltip và xem thông tin người khác — 23/09/2026

Phạm vi: client CY ở `Build/world-gui/stage-play-21`. Dữ liệu gốc `Assets/CanonicalCY` và máy chủ TLBB gốc không chỉnh sửa. Thử trực tiếp trên server riêng `/home/ubuntu/cys-test-20260913`, dùng test15 xem test13. Bản sao đầy đủ hai nhân vật được lưu trước khi tạo tình huống thử tại `Build/Logs/2026-09-23-tooltip-inspect/fixture.json`.

## Giới hạn dữ liệu hiện có

`scenecore.ask_detail_attrib` chỉ gửi tập thuộc tính cho phép khi xem người khác. Không gửi điểm chiến đấu hoặc điểm trang bị: khung hiện `--`. `char_ask_private_info` chỉ trả GUID và các trường mặc định/trống: không tự tạo tuổi, nghề nghiệp, trường học, phối ngẫu hoặc lời giới thiệu. Chưa khôi phục phép tính xuyên thích/cường hóa nâng cao và các trang tính năng khác nằm ngoài hai khung trang bị/hồ sơ.

Tên bang hội hiện chưa phân giải từ mã bang hội mà server gửi. Nhánh so sánh hai vị trí nhẫn/hộ phù đã có trong mã, nhưng tình huống trực tiếp của đợt này dùng một vũ khí; không xem đó là bằng chứng đã thử đủ hai khung so sánh đồng thời.

## Kiểm tra

- Baseline tooltip vật phẩm: `tooltip-baseline-01`, 20/20 kiểm tra phiên chơi; hover, hỏi lại dữ liệu, giữ/thả Alt, đóng và di chuyển. Baseline Alt chỉ làm mới tooltip, chưa so sánh.
- `inspect-live-01` phát hiện lỗi gọi hàm cường hóa còn thiếu; `inspect-live-03` mở đúng người và vật phẩm nhưng phép thử Alt bộc lộ bộ bơm phím chưa giữ trạng thái modifier. Đây là lượt thử thất bại, không dùng để phát hành.
- `Tools/game/tests/tooltip_instance.cpp`: đã chạy, kiểm tra hai GUID cùng mã vật phẩm, ngọc ở vị trí không liên tiếp, cập nhật lỗi không giữ metadata cũ, làm mới và vòng đời kết nối.
- `inspect-live-09`: 20/20 kiểm tra phiên chơi, `CYS-INSPECT-PROBE: RESULT errors=0`; không có `CYS Lua failure`. Xác nhận người được xem khác người đăng nhập, môn phái/cấp/slot thời trang, giới hạn chỉ số ô trang bị, từ chối phản hồi không đúng người, tooltip vũ khí, so sánh Alt có nội dung, tooltip tiếng Việt, hồ sơ/ID, Esc, phản hồi muộn và di chuyển sau đóng cửa sổ.
- Ảnh đã kiểm tra trong `Build/Logs/2026-09-23-tooltip-inspect/inspect-live-09`: `cys-gl-239229640-inspect-equipment.png`, `cys-gl-239229640-inspect-alt-compare.png`, `cys-gl-239229640-inspect-normal-tooltip.png`, `cys-gl-239229640-inspect-profile.png`.
- `tooltip-live-02`: 20/20 kiểm tra phiên chơi, `CYS-FT-TOOLTIP-PROBE: END old=0`, không có lỗi Lua; hover trang phục ở mép phải, kích thước/vị trí tooltip, resize lặp sáu lần, nhận lại `GCItemInfo`, giữ/thả Alt, đóng túi và di chuyển 8,01 đơn vị. Cả lượt này và `inspect-live-09` dùng cùng hash Game và manifest.

## Phát hành vào Play

- Đã cập nhật `Build/world-gui/stage-play-21` lúc 09:24:51 ngày 23/09/2026.
- Bản sao khôi phục: `Build/backups/tooltip-inspection-play/20260923-092451`, gồm sáu binary/PDB được thay, manifest, launcher và các Overlay đã có; `deployment.json` ghi riêng đường dẫn Overlay mới.
- Game SHA-256: `bfa98a1a22ac9946b508b39454bec9ddbfb79d9db9d71fc8706680e6eb45fcff`.
- Manifest ứng viên đã được thử: `94b231116dbb3422254cc580899935384cceacc86f73e2980de8387ac433fd3b`.
- Đã đối chiếu 37 hash binary trong manifest của Play sau cập nhật. Launcher Play xóa các biến môi trường kiểm tra tooltip/inspection để các probe không chạy trong phiên chơi thường.
- `play-final`: đăng nhập vào đúng bản Play đã cập nhật, 20/20 kiểm tra; di chuyển ba lần, thoát sạch (`quit_complete`, `decode_failures=0`, `handler_errors=0`), không có lỗi Lua và không chạy các probe tooltip/inspection.
- Đã dừng toàn bộ client thử và hoàn trả đầy đủ hai document nhân vật test13/test15 từ bản sao trước thử nghiệm; so sánh nguyên document sau ghi đạt bằng nhau tuyệt đối. Bằng chứng: `Build/Logs/2026-09-23-tooltip-inspect/fixture-restore.txt`.
- Không thay mã/config server trong đợt này. Các cổng riêng 15733/15734/27018/1884 vẫn nghe trên 127.0.0.1.

Nguồn sinh Overlay: `Tools/game/patch_inspection_ui.py`, được gọi từ `stage_game.py`. Không dùng GLResponsive. Công cụ phát hành `publish_tooltip_inspection.py` kiểm tra hash bản build, hash manifest và kết quả phiên chơi trước khi sao lưu/cập nhật Play.
