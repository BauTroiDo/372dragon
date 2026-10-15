# Khung tên và danh hiệu trên đầu NPC — 23/09/2026

Phạm vi: client CY dựng từ nguồn, bản Play `Build/world-gui/stage-play-21`.

## Đối chiếu và nguyên nhân

Đã đọc `client/Data/Interface/Schema/TLBBLook_CreatureBoard.looknfeel.xml`, bộ CY canonical, `TLBBLook_StaticText.looknfeel.xml`, `CCreatureBoard::SetPosition`, `FalagardSelfFitWindow::updateSelfSize` và đường vẽ `FalagardSimpleText`/`FontBase` trước khi sửa.

Trong look CY, ô tên `__auto_playername__` có MaxWidth 250, ô danh hiệu `__auto_playertitle__` có MaxWidth 500/MinHeight 32. Cả hai dùng `TLBB_Look_SelfWindow`, TextArea trừ 3 px ở mỗi cạnh và chữ căn giữa một dòng.

Bộ tự tính kích thước cũ luôn đo theo WordWrapLeftAligned và chỉ cộng 2 px tổng mỗi chiều. Vì vậy:

- Tên dài được **đo như nhiều dòng**, nhưng **vẽ như một dòng**, khiến phần đầu/cuối nằm ngoài vùng cắt.
- Ô chữ chỉ cộng 2 px trong khi lề lấy mất 6 px. Tên ngắn có chiều cao vùng chữ nhỏ hơn chiều cao font, gây mất dấu/nét phía trên hoặc dưới.
- Giới hạn tên 250 px quá hẹp với nhiều tên tiếng Việt.

## Thay đổi

`patch_creatureboard_readability.py` sinh overlay từ canonical đã khóa hash, chỉ chỉnh bốn property của hai ô tên/danh hiệu: MaxWidth **600**, MinHeight **32**, HorzFormatting **WordWrapCentred**, FitTextArea **True**. Generator kiểm tra cây cửa sổ và các property khác được giữ nguyên; đã nối vào `stage_game.py` để dựng stage mới không mất bản sửa. Overlay được đặt ở cả Pre/Post để thắng mọi cách tra resource của engine.

`FalagardSelfFitWindow` có property `FitTextArea`, mặc định False. Khi được bật, đo theo đúng định dạng vẽ, tính cả lề TextArea, chừa thêm đệm nét chữ và làm tròn kích thước lên pixel. Tên ngắn co theo nội dung, tên dài rộng tối đa 600 px, chuỗi quá dài tự xuống dòng và tăng chiều cao. `CCreatureBoard::SetPosition` sẵn xếp danh hiệu phía trên tên theo chiều cao thực. Không tăng đồng loạt kích thước cố định của bảng tên.

Chỉ hai ô trên bật cách đo mới. PaoPao và các SelfFitWindow khác giữ đường tính cũ; điều này tránh cộng lề hai lần cho PaoPao, vốn có hàm tự thêm lề riêng. Màu chữ, font, FitType, nội dung và sự kiện được giữ theo look gốc.

## Kiểm chứng

`CysNameboardProbe`/`CysNameboardFixture` chỉ chạy trong smoke có `CYS_NAMEBOARD_LIVE=1`. Bộ đo mượn bảng tên NPC đang tồn tại, kiểm cấu hình overlay thực đã nạp, thử chuỗi Việt có dấu, sau đó trả đúng chuỗi gốc. Không thay thuộc tính nhân vật hoặc dữ liệu máy chủ.

- Đối chứng cũ: tạm dùng cách đo/kích thước trước sửa để bắt lỗi tên dài và thiếu chiều cao tên ngắn.
- Cách đo mới: đối chiếu diện tích TextArea với kích thước chữ theo font và định dạng đang vẽ, kiểm ô tên/danh hiệu không chồng nhau.
- Chuỗi rất dài: kiểm xuống dòng, chiều rộng không quá 600 px, chiều cao tăng đủ cho các dòng.
- Kiểm bảng tên thật, mở hội thoại NPC qua luồng tương tác game, trả chuỗi gốc và kiểm vị trí nhân vật đổi sau bấm đất.

Ứng viên `Build/world-gui/stage-nameboards-23`; công cụ `deploy_nameboards.py` kiểm marker chức năng, 20 tiêu chí phiên chơi, hash Game/manifest và toàn bộ binary, overlay đúng generator, sau đó sao lưu trước phát hành. Bộ kiểm chụp ảnh trước/sau và trường hợp xuống dòng trong `Build/Logs/2026-09-23-npc-nameboards`.

## Kết quả phát hành

- `live-02`: 20/20 PASS, exit 0, 120,6 giây, không dump/lỗi Lua/handler/decode. Runtime xác nhận overlay đúng đã nạp. Đối chứng tên ngắn cần 238×22 px nhưng chỉ có TextArea 234×18; đối chứng tên dài cần 541 px nhưng vùng vẽ chỉ 246 px. Sau sửa, tên dài có ô 551×32 và TextArea 545×26; các mẫu xuống dòng có ô 600×57, đủ vùng chữ. Đã xem ảnh trước/sau, tên thường và tên rất dài ở giữa màn hình.
- Tương tác NPC nhận menu từ máy chủ; chuỗi thật được khôi phục chính xác; nhân vật di chuyển được sau kiểm tra. `live-01` cũng đạt 20/20 nhưng ảnh mẫu sát mép màn hình, nên lượt cuối đưa NPC vào giữa trước khi chụp.
- Đã phát hành lúc 20260923-113716; backup `Build/backups/nameboards-play/20260923-113716`. Game SHA-256 `251eb9302e943c43f44e831e14bb54c45fdd1a0f92fc01070f66ad0fd00ea572`. Hai overlay khớp generator; 37 binary khớp manifest. Launcher tắt `CYS_NAMEBOARD_LIVE` cho Play thường.
- Phiên Play sau phát hành `play-final`: 20/20 PASS, exit 0, bộ đo bảng tên tắt; vào cảnh, di chuyển ba lượt, thoát sạch `quit_complete` lúc 11:39:05. Kiểm lại 37 binary, hai overlay và hash phiên chơi đều khớp bản trên đĩa.
