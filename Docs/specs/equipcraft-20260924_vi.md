# Thăng Linh, điêu văn và màu tooltip — 24/09/2026

Phạm vi: client CY-Source, bản Play `Build/world-gui/stage-play-21`, server riêng `/home/ubuntu/cys-test-20260913`. Nguồn đối chiếu GL/CY được đọc tại chỗ; không thay các bản tham khảo.

## Sử dụng

Mở **Hành trang → Chế tác**. Khung dùng skin `TLBB_MainFrame2`, nút và ô vật phẩm hiện có. Tháo trang bị vào túi rồi kéo vào ô Trang bị. Sáu mục: Thăng Linh, Khắc, Nâng cấp, Tháo, Hợp thành, Chuyển.

- Khắc: đặt trang bị và viên điêu văn phù hợp; dung dịch được lấy từ túi.
- Nâng cấp: đặt trang bị đã khắc; mỗi lần tăng đúng một cấp, dùng đủ Kim Tàm Ti còn thiếu của cấp đó.
- Tháo: trả viên điêu văn cùng cấp và số Kim Tàm Ti đã tích lũy, vật phẩm trả lại có khóa. Cần đủ ô trống trước khi bắt đầu.
- Hợp thành: đặt đồ phổ; lấy Đan Thanh và giấy vàng theo bảng cấu hình.
- Chuyển: đặt trang bị nguồn và đích; cùng vị trí, cấp trang bị từ 50, đích chưa có điêu văn. Giữ cả cấp, tiến độ, cấp tinh khắc, kinh nghiệm tinh khắc và hiệu ứng; khóa trang bị nhận.

Khung hiển thị phí, nguyên liệu và kết quả dự kiến trước khi bật nút thực hiện. Nguyên liệu phụ lấy từ các chồng không khóa thao tác trong túi; áp quy tắc khóa thành phẩm khi dùng nguyên liệu khóa. Không tự mua nguyên liệu bằng nguyên bảo. Tiền dùng thứ tự vàng/giao tử hiện có của server.

## Nguồn và quy tắc Thăng Linh

- CY `Config/ZhiZunEquipRate.txt`, khớp bản `Assets/CanonicalCY/Data/ConfigFolder/ZhiZunEquipRate.txt`.
- CY `tlbb15/Public/Data/Script/NewHJ_Script/EquipmentRelated/JingTong/EquipEducationClient.lua` (900113), bản GBK trong `C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26`.
- Điêu văn: script server 809272, `DiaowenInfo.txt`, `DiaowenRule.txt`, các phương thức thật của `equip_data` trong `item.lua`.
- Màu: `client_GL/Data/ConfigFolder/SystemColour.txt` và Lua SuperTooltip của GL.

Nhân vật cần cấp 85 để Thăng Linh; đồ thường cần cấp 80 và ít nhất 6 sao. Loại vũ khí, ám khí và các vị trí đặc biệt bị loại theo kiểm tra trong nguồn tham khảo. Các dải mã Trùng Lâu có ngoại lệ riêng. Chưa đưa ngoại lệ Lưu Bác vào vì chưa xác định được hàm kiểm tra tương ứng của bản nguồn; không coi mọi vật phẩm là hợp lệ.

| Bậc | Phần trăm theo cấp 0…9 | Nguyên liệu để lên cấp 1…9 | Tiền mỗi lần |
|---|---|---|---|
| Chí Tôn | 0, 1, 2, 4, 6, 8, 10, 13, 16, 19 | 5, 6, 8, 10, 12, 14, 16, 19, 22 | 100.000 đơn vị, tức 10 vàng |
| Vương Quyền | 25, 28, 31, 34, 37, 40, 43, 46, 50, 54 | 25, 28, 32, 36, 40, 45, 50, 55, 62 | 200.000 đơn vị, tức 20 vàng |
| Thiên Đạo | 60%, giới hạn cuối | — | — |

Chí Tôn 9 → Vương Quyền 0 và Vương Quyền 9 → Thiên Đạo đều cần 60 nguyên liệu và 500.000 đơn vị tiền. Hai mã nguyên liệu được chấp nhận: 20800031, 20800032. Lưu cấp bằng mã `&Wnn` đã có trong bản CY; đặt trước hậu tố `&ZF` để giữ parser tăng phúc của server, giữ tên người chế tạo, giới hạn chuỗi 32 byte trước khi trừ phí.

Phần cộng Thăng Linh áp vào thuộc tính mở rộng: `floor(giá trị × tỷ lệ / 100)`, rồi mới tính tăng phúc. Tích hợp vào cả bốn nhánh `common_equip_effect_flush*`. Giữ cùng danh sách thuộc tính loại trừ như nhánh tăng phúc của server hiện tại: IA 1, 7, 10, 13, 16, 18, 54…57. Đây là lựa chọn tích hợp với công thức server CY đang dùng; bảng tỷ lệ và chi phí đã đối chiếu trực tiếp, chưa có kết quả chạy native GL độc lập để chứng minh toàn bộ công thức thuộc tính của GL. Không nhân lại phần ngọc, điêu văn hoặc thuộc tính cơ bản.

## Tooltip

- Màu tên theo phẩm chất trong bảng vật phẩm, không dùng số sao: `C8C8C8`, `00FF00`, `00CCFF`, `FF53FF`.
- Thuộc tính mở rộng `FFCC00`; tên ngọc `B3DB35`; phần cường hóa xanh theo Lua GL; tăng phúc dùng các mốc màu GL.
- Thăng Linh có bậc/cấp/tỷ lệ, phần cộng riêng trên từng thuộc tính. Ẩn mã `&Wnn` khỏi tên người chế tạo.
- Host `Lua_GetEquipZhiZunType` trả bậc thật để SelfEquip có thể chọn hiệu ứng viền bậc cao hiện có. Lượt live này kiểm tra trực tiếp tooltip và chế tác; chưa chụp riêng từng hiệu ứng viền Vương Quyền/Thiên Đạo.

## Giao dịch và lưu dữ liệu

Server quyết định mã vật phẩm, giá, nguyên liệu và kết quả. Báo giá giữ revision và toàn bộ dữ liệu từng vật phẩm được chọn, gồm GUID. Gói thực hiện cũ hoặc vật phẩm đổi sau báo giá bị từ chối. Khóa thao tác, khóa bảo mật, nhân vật chết/rời cảnh đều được kiểm tra.

Tạo vật phẩm thưởng trước khi trừ tiền vì cấp GUID có thể nhường luồng. Sau đó giữ các ô trống và kiểm lại đầy đủ vật phẩm, nguyên liệu, tiền, báo giá. Phần commit không nhường luồng, vô hiệu hóa báo giá trước khi trừ. Túi đầy, lỗi tạo vật phẩm, đổi GUID trong thời gian cấp thưởng hoặc gửi lặp không được trừ thêm phí. Không sử dụng ô nguyên liệu sẽ bị tiêu hao làm chỗ thưởng dự kiến.

Các API điêu văn cơ bản cũ và `880036:LevelUp` dẫn vào báo giá mới. Script `990029:Action` và lối vào cũ đều được đăng ký trong `AllowableScriptFunc.txt`; không bỏ qua bộ lọc script. Các chức năng tinh khắc riêng vẫn theo luồng hiện có. Tháo điêu văn có cấp/kinh nghiệm/hiệu ứng tinh khắc bị chặn để tránh mất dữ liệu; dùng Chuyển để giữ các trường này.

## Mã nguồn và tái lập

- `Tools/server/cys_equipcraft.lua`, `deploy_equipcraft.py`, `test_equipcraft.lua`: quy tắc, triển khai 6 file trên server riêng, kiểm thử.
- `Src/Client/WXClient/Network/CysEquipCraft.*`: host Lua, kéo vật phẩm và packet; tích hợp C++ build từ nguồn.
- `Tools/game/equipcraft_ui.py`, `stage_equipcraft.py`: nguồn sinh layout/Lua và phát hành có kiểm hash.
- `Src/Client/WXClient/Network/CysEquipmentTooltipFormat.h`: màu, metadata và phần cộng hiển thị.
- `Src/Client/WXClient/Procedure/CysEquipCraftProbe.h`: lượt kiểm tra quang cảnh thật, chỉ bật bằng cờ kiểm thử và tài khoản test15.

## Bằng chứng

Thư mục bằng chứng: `Build/Logs/2026-09-24-equipcraft`.

- `reference.json`: hash nguồn, bảng tỷ lệ/cost và palette khớp nguồn GL/CY.
- `server-tests.log`: 54 kiểm tra, gồm hai chuỗi 9 cấp, hai lần tiến bậc, giữ metadata khi chuyển, lưu–nạp bằng lớp thật, báo giá lặp, túi đầy, đổi GUID, lỗi cấp thưởng, khóa, thiếu phí và giới hạn tiến độ.
- `build06.log`: build Release x64; `tooltip-unit.log`: kiểm cache/định dạng C++.
- `live07/run.json`, `live07/WXClient.log`: đủ sáu thao tác, kéo trang bị bằng input thật trong client; `CYS-EQUIPCRAFT: RESULT errors=0`; Esc và di chuyển đạt.
- `persistence-live07.log`: dữ liệu Mongo sau thoát game đúng 9 tổng nguyên liệu và 9.700.000 tiền còn lại từ 10.000.000 ban đầu. Không nhân đôi GUID trong kiểm tra client.

Các lượt live03…live06 thất bại được giữ nguyên: ban đầu nút bị đặt vào hàng tiêu đề, sau đó thiếu đăng ký script cho phép. Các lỗi đã được sửa trước live07, không tính các lượt thất bại là đạt. Log client còn thông báo thiếu một số ảnh JunXian và host ngoài phạm vi, log server có cảnh báo hàng đợi nền; kiểm tra riêng lỗi Lua/packet và traceback của chế tác.

- `live08/run.json`, `live08/WXClient.log`: lượt cuối trên server đã bổ sung kiểm tra điểm tinh khắc và giới hạn tiến độ, toàn bộ kiểm tra đạt; `RESULT errors=0`. Danh sách ảnh thật kèm hash nằm trong `run.json`.
- `persistence-live08.log`: đối chiếu lại dữ liệu lưu sau lượt cuối đạt; `fixture-restored.log`: phục hồi toàn bộ BSON gốc của test15 và so sánh bằng nhau tuyệt đối.
- Phát hành vào bản Play lúc **18:38 ngày 24/09/2026**, công cụ kiểm Game.exe, manifest và hash từng overlay trước khi chép. Game.exe SHA-256: `8ea733c1edd2d2be3b6d54db7db50029bc5dd363b72d1493176fa5947b015727`.
- Bản sao client trước cập nhật: `Build/backups/equipcraft-play/20260924-183804`. Bản sao server trước đợt triển khai đầu: `/home/ubuntu/cys-test-20260913/backups/equipcraft-20260924-173832`; bản sao trước sửa cuối: `equipcraft-20260924-183145`.

Lượt trực tiếp kiểm tra Thăng Linh cấp đầu và điêu văn cấp 1→2, khắc/chuyển/tháo/hợp thành. Toàn bộ các cấp Thăng Linh và tiến bậc được chạy trong kiểm thử server; không mô tả chúng thành toàn bộ lượt bấm thủ công trong game. Việc hiển thị thuộc tính dùng chung đường tooltip trước đó; chưa kiểm thêm tài khoản thứ hai ở khung xem trang bị người khác trong lượt này.
