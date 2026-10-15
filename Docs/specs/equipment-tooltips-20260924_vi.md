# Hiển thị trang bị và SuperTooltips — 24/09/2026

Phạm vi: client CY-Source, profile Play `Build/world-gui/stage-play-21`, server riêng `/home/ubuntu/cys-test-20260913`. GL và CanonicalCY được dùng để đối chiếu, không sửa trực tiếp. Không thay công thức chiến đấu hay dữ liệu nhân vật thật.

## Dữ liệu và công thức đã đối chiếu

| Nội dung | Nguồn quyết định | Cách hiển thị |
|---|---|---|
| Cường hóa | `ItemInfo_bos.enhancement_level`, server `ItemEnhance.txt`, `human_attrib:cal_enhance_effect` | Tên có `(+N)`, dòng cấp cường hóa và phần cộng thực tế |
| Khắc minh | `status & 0x40`, `item:is_ebind`, `LuaFnEquipLock`, `human_attrib` | Trạng thái đã khắc minh; phần cộng 10% thuộc tính cơ bản, làm tròn xuống |
| Tư chất | 6 byte `qualifications`, `cfghelper:read_item_apt_rate`, `item:get_apt_config` | Hệ số %, số cộng và tổng; không nhầm chỉ số tư chất với phần trăm |
| Người chế tạo | `creator` | Tách tên khỏi mã `&SQ` và `&ZF`, không cho tên tạo mã màu/điều khiển |
| Thông linh/khế hợp thần khí | `item:set_qihedu` ghi `&SQnnn`; `weapon_jinjie.lua` | Hiện khế hợp `nnn % 100`; giá trị thuộc tính đã được server sửa, không nhân thêm lần nữa |
| Tăng phúc | `&ZF`, `human_attrib:get_zengfu_level`, `calc_zengfu_value` | Hiện cấp và số cộng; giữ đúng danh sách thuộc tính bị loại trừ của server |
| Ngọc | 4 vị trí `list_2`, `GemInfo.txt` | Giữ đúng lỗ trống xen kẽ; tên, icon và thuộc tính ngọc |
| Điêu văn | `diaowen_id * 8 + (dmc & 7)` | Tên/icon/cấp trong bảng và thuộc tính; không dùng thương số trên wire làm ID đầy đủ |
| Tinh khắc điêu văn | `dw_advance_level`, `dw_rankexp`, `DWJinJieInfo.txt` | Cấp, điểm và phần tăng thuộc tính theo `item:get_diaowen_attrs` |
| Khóa / tẩy luyện | `status & 1`, `reshuffle_count` | Trạng thái khóa ở đầu tooltip; số lần tẩy luyện khi khác 0 |

Thứ tự tính một thuộc tính cơ bản `B` đúng theo server:

1. `E = floor(B × hệ_số_cường_hóa / 100)`.
2. `K = floor(B × 10 / 100)` nếu khắc minh, ngược lại bằng 0.
3. `Q = floor(((B + E + K) × hệ_số_tư_chất + 50) / 100)`.
4. Áp tăng phúc lên `B + E + K + Q` với cách làm tròn của server.

Thứ tự byte tư chất của server là **ngoại công, ngoại phòng, nội công, nội phòng, chính xác, né tránh**. Thứ tự cột cơ bản của client khác; ánh xạ tường minh để không đổi chéo các hệ số.

Mẫu kiểm tra `10102001`, cơ bản 117/117, cường hóa +9, khắc minh, tư chất 100/200 ở hai chỉ số công, tăng phúc +3: tổng ngoại công **499**, nội công **537**. Món +3 không nâng cấp khác có tổng **141/141**. Các dòng ngọc/thuộc tính mở rộng được hiển thị riêng, không trộn vào hai số cơ bản này.

`Tools/game/equipment_tooltip_data.py` sinh `CysEquipmentTooltipTables.h`: hệ số lấy từ server riêng; tên/icon lấy từ GL. Không lấy hệ số của GL để ghi đè server. Hiện có 255 mức tư chất, 1.140 dòng điêu văn, 417 dòng ngọc và 50 mức tinh khắc.

## Giữ đúng từng vật phẩm

Cache dùng đủ GUID world/server/serial kèm mã vật phẩm, không dùng riêng mã vật phẩm. Bản tin mới thay toàn bộ metadata; bản tin sai mask/count xóa bản cũ. Chuyển scene giữ cache, đăng nhập phiên mới xóa cache. Shop template không dùng metadata của vật phẩm trong túi.

Các host cho tooltip chính và so sánh Alt dùng cùng bộ định dạng. Trang bị của người khác đã đi qua cùng `ToLegacyItem`/cache; không có công thức tooltip riêng.

## Bố cục

- Giữ skin/ảnh GL/CY hiện có, không thêm GLResponsive hoặc hook chung vào Lua UI.
- Loại trang bị ở dòng riêng rộng 160 px, căn trái; tránh cắt chữ trong ô cũ 80 px.
- Ô cấp yêu cầu rộng 138 px cả ở tooltip so sánh. Dòng loại cao 22 px, dòng người chế tạo cao 24 px để giữ dấu tiếng Việt.
- Khóa vật phẩm dùng dòng đầu riêng; khắc minh và tẩy luyện ở phần nội dung. Người chế tạo giữ dòng riêng nên không nhồi nhiều dòng vào khung cố định.
- Tooltip dài giới hạn chiều cao theo viewport. Giữ trỏ trên vật phẩm và cuộn chuột để đọc; tooltip so sánh đang mở cuộn theo. Khi tooltip ngắn/đóng, wheel tiếp tục đi vào menu hoặc camera như trước.
- Các phần văn bản được phép cao hơn màn hình bên trong vùng cuộn. Tọa độ cuộn tính lại từ đầu tài liệu, không cộng dồn tọa độ âm qua `PixelAligned` cũ: cách cộng dồn đã làm nội dung lệch 44 px sau nhiều lần cuộn tại đáy, che tên người chế tạo. Tooltip dài cũng giữ trong mép màn hình khi Lua so sánh Alt dịch vị trí sau `PositionSelf`.

## Số lần tẩy luyện trên server

`equip_data:init_from_data` trước đây không nạp `reshuffle_count`, dù `copy_raw_data` lưu trường này và packet gửi nó. Đã thêm lời gọi setter hiện có, mặc định 0 cho bản ghi cũ; giữ giới hạn 0–255 của setter. Công cụ tái lập và kiểm tra: `Tools/server/equipment_tooltip_state.py`. Chỉ áp vào server riêng, có bản sao tại `/home/ubuntu/cys-test-20260913/backups/equipment-tooltip-20260924-162721`. Kiểm thử thực thi thân hàm loader/setter/serializer xác nhận lưu–đọc lại các giá trị 0, 7, 255 và chặn ngoài giới hạn; lượt trong game xác nhận nhận lại `Tẩy luyện: 7 lần` sau đăng nhập.

## Giới hạn đã xác định từ nguồn

**Khắc tên và khắc minh:** server hiện chỉ đặt cờ khắc minh, không ghi tên chủ nhân/người khắc. `creator` là tên người chế tạo cùng metadata. Vì vậy không gán nhầm tên người chế tạo hoặc nhân vật đang xem thành tên người khắc.

**Thăng linh trang bị (EquipEducation_ShengLing)** chưa hoàn chỉnh ở lượt tooltip 16:42 được ghi trong tài liệu này: thiếu script 880036 và chưa xác minh metadata. Đợt cập nhật tiếp theo lúc 18:38 đã đối chiếu mã `&Wnn` của bản CY, bổ sung luồng Thăng Linh/tiến bậc, chức năng điêu văn và màu tooltip; xem [Thăng Linh, điêu văn và màu tooltip](equipcraft-20260924_vi.md). `&Wnn` khác với thông linh/khế hợp `&SQ`; các host cũ còn stub được thay bằng lối vào khung Chế tác mới trong overlay.

Các tính năng trang bị chuyên biệt như Long Văn/Linh Vũ/Võ Hồn/Thú Hồn giữ luồng riêng. Các khóa metadata chưa xác định và tên hiệu ứng điêu văn chưa có bảng dịch không được suy đoán công thức. Link vật phẩm trong chat không nằm trong lượt kiểm thử này.

## Kiểm chứng và phát hành

- Build Release x64 thành công: `Build/Logs/2026-09-24-equipment-tooltips/build08.txt`.
- Unit test cache/format: `unit-tests.txt`. Thực thi thân hàm tính thật của server: `server-reference.txt`; kết quả 499/537, thuộc tính cộng 143, giảm kháng 115 và đủ 58 trường hợp loại trừ tăng phúc đều khớp.
- Catalog sinh lại khớp byte với nguồn đang dùng; ba layout giữ nguyên cây control và event.
- Lượt cuối `Build/Logs/2026-09-24-equipment-tooltips/live07/run.json`: toàn bộ kiểm tra đăng nhập, vào cảnh, di chuyển, đóng game và kết nối server riêng đạt. `WXClient.log` có `CYS-EQUIP-TIP: RESULT errors=0`.
- Kiểm trong game ở 1280×720: trang bị +9 có khắc minh, tư chất, khế hợp, tăng phúc, tẩy luyện 7 lần, lỗ ngọc trống xen kẽ và tinh khắc; refresh từ `GCItemInfo`; so sánh Alt với món cùng mã +3; món thường cùng mã không giữ metadata cũ; hover SelfEquip; cuộn nhiều lần tới đáy không chồng phần nội dung; mép dưới tooltip so sánh nằm trong màn hình; Esc và di chuyển sau đóng khung đạt.
- Đã xem ảnh thật của đầu/cuối tooltip, so sánh và SelfEquip. Ảnh cuối tại `Build/world-gui/stage-equipment-tooltips-24/ScreenShots/cys-gl-15192515-equipment-tooltip-{top,bottom,compare,selfequip}.png`.
- Đã phục hồi toàn bộ BSON gốc của nhân vật thử test15, so sánh bằng nhau tuyệt đối: `fixture-restored.txt`. Không giữ trang bị thử trong tài khoản.
- Đã cập nhật bản Play tại `Build/world-gui/stage-play-21` lúc **16:42 ngày 24/09/2026**. Game.exe SHA-256: `44926826a9fccf2aee342eaf51f3a2ee34a955e47d08c0d03737feed66685618`. Công cụ phát hành kiểm hash executable, manifest, toàn bộ overlay và chỉ chép bản đã qua lượt live07.
- Bản sao trước cập nhật: `Build/backups/equipment-tooltips-play/20260924-164208`. Server có bản sao riêng như mục trên.

Lượt live04 thất bại vì server thử đang tắt; giữ nguyên báo cáo lỗi, không tính là đạt. Các lượt live05/live06 đã phát hiện và dùng để sửa lỗi hình ảnh dù kiểm tra dữ liệu đạt. Sau khởi động server, log vẫn có lỗi hoạt động `bg_CangJingGe` do thiếu monster 13565; không có traceback liên quan `item.lua`/tẩy luyện trong lượt này. Không sửa lỗi hoạt động đó trong thay đổi tooltip. Chưa kiểm trực tiếp một nhân vật thứ hai qua khung xem trang bị người khác trong lượt này; kết luận cho luồng đó mới dựa trên đường chuyển đổi packet dùng chung.
