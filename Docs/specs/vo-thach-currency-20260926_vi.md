# Võ Thạch — hai ví tiền tệ của CY

Ngày: 26/09/2026. Phạm vi: `CY-Source`, Play21 và server riêng `/home/ubuntu/cys-test-20260913`. Đã phát hành vào Play lúc 10:37; đối chiếu cuối lúc 10:38 (giờ Việt Nam).

## Quy tắc

- Hai số dư tiền tệ: **Võ Thạch** và **Nguyên Bảo**.
- Võ Thạch lưu dưới dạng số nguyên hạ phẩm. Khi hiển thị: `thượng = n // 10000`, `trung = (n // 100) % 100`, `hạ = n % 100`.
- **100 hạ = 1 trung; 100 trung = 1 thượng; 1 thượng = 10.000 hạ.** Các phẩm là mệnh giá của cùng một ví, không phải ba stack vật phẩm trong túi.
- Tiền cơ sở cũ chuyển 1:1 sang hạ phẩm. Do tiền cũ vốn chia đồng/bạc/vàng theo 100–100, giá trị mua bán được giữ: đồng → hạ, bạc → trung, vàng → thượng.
- Giao tử cộng vào Võ Thạch; Nguyên Bảo khóa cộng vào Nguyên Bảo. Không tạo tỷ giá giữa Nguyên Bảo và Võ Thạch.
- Trường Điểm tặng của cả 16 nhân vật đang bằng 0; trường cũ này được đưa về 0 cùng nhóm ví phụ. API tương thích chuyển khoản cộng vào ví Nguyên Bảo.
- Giữ giới hạn số nguyên hiện tại 2.147.483.647 đơn vị cơ sở. Giao dịch không hợp lệ, thiếu tiền hoặc vượt giới hạn bị từ chối; không trừ thành số âm và không cắt phần vượt giới hạn.

Các câu hỏi tùy chọn về tỷ lệ chuyển đổi và gộp ví được gửi trong khi khảo sát; triển khai theo mặc định đã thông báo: giữ giá trị cơ sở và gộp thành hai số dư. Điểm tiến trình của môn phái, danh vọng hay sự kiện là dữ liệu hệ thống riêng, không bị xóa như số dư tiền tệ.

## Đối chiếu nguồn và thay đổi

Đã đọc `FalMoney.cpp`, `UIString.cpp`, Lua/layout Túi, looknfeel và `wowanimate.xml` của CY; đối chiếu human/script_base/db và luồng mua bán trên server đang dùng. Widget tiền vốn đã chia 100–100. Các gói số dư hiện tại đủ dùng, không thêm gói giao thức hay thay GUID vật phẩm.

Server:

- `Tools/server/cys_currency.lua`: chính sách hai ví, quy đổi khi nạp, chuyển khoản ghi các trường cũ, kiểm tiền, phí, thưởng và các shop loại 8/9 cũ.
- Getter Giao tử và Nguyên Bảo khóa của nhân vật trả 0 để những đoạn cộng hai ví cũ không nhân đôi tổng. Các hàm thưởng/tiêu hao cũ chuyển sang ví chính tương ứng.
- `script_base:GetBindYuanBao` phục vụ script cũ bằng số Nguyên Bảo hiện có; thao tác đổi vàng sang Giao tử trở thành thao tác không thay số dư. Script đạo cụ `893252` và mua điểm Kim Qua Hiệu Lệnh (`event/zhenghe.lua`) được sửa riêng vì trước đây tự cộng và chia phí giữa hai ví Nguyên Bảo.
- Hai nguồn human cùng được cập nhật. Bán vật phẩm tại shop vốn trả Giao tử nay cộng vào số Võ Thạch hiện có.
- Migration có kiểm tra miền số, bản sao toàn bộ bản ghi trước đổi, điều kiện cập nhật chống thay đổi đồng thời và đối chiếu dữ liệu ngoài ví.

Client:

- `Tools/game/vothach_ui.py` là nguồn sinh overlay: ba icon, skin widget tiền, chữ tiền trong chat/tooltip, các biến thể icon ở layout, từ điển, Túi và Cường hóa.
- Túi chỉ hiện hai hàng tiền; có chú thích tỷ lệ. Vị trí theo chiều cao số hàng được chỉnh khi số hàng đổi để Túi 100 ô không đẩy tiền ra dưới màn hình.
- Shop loại 8/9 dùng loại tiền tương ứng trên client. Tooltip giá bán dùng bộ định dạng mệnh giá; giá mua dùng widget tiền hiện có.
- `FalMoney.cpp` sửa khoảng cách giữa mệnh giá, chiều cao icon và kiểm null. `UIString.cpp` tránh đọc/ghi cùng bộ đệm trong định dạng tiền, hiện được số 0.
- Các skin tiền dùng chung được cập nhật qua overlay. Không sửa donor GL/CY, không thêm hook/inject.
- Nguồn overlay được chọn theo đường dẫn không phân biệt hoa/thường trên Windows; bản sửa đang dùng có ưu tiên hơn canonical. Gate trước phát hành đối chiếu hash toàn bộ overlay và từ chối đường dẫn trùng, tránh ghi đè nhầm `SuperToolTip`/`SuperTooltip`.

## Tài nguyên icon

Tạo bằng **built-in image_gen**; prompt đầy đủ: `Tools/game/vothach/prompts.json`.

| Phẩm | Hình/màu | PNG nguồn |
|---|---|---|
| Hạ | Đá thô xanh ngọc | `Tools/game/vothach/ha-pham.png` |
| Trung | Tinh thể xanh lam | `Tools/game/vothach/trung-pham.png` |
| Thượng | Tinh thể tím, vân vàng | `Tools/game/vothach/thuong-pham.png` |

Ảnh có alpha thật, được xuất cơ học thành atlas RGBA `CysVoThach.tga` (64×32), ba icon 16×16 và `CysVoThach.imageset.xml`. Bản gốc được giữ nguyên. Atlas đăng ký vào scheme hiện tại; có cả Pre/Post overlay. Giữ phong cách khung CY, thay hình đồng tiền bằng đá.

## Kiểm chứng và vận hành

Bằng chứng: `Build/Logs/2026-09-26-vothach`.

- `unit-currency.log`: 31 ca về các mốc mệnh giá, quy đổi lặp không cộng lại, ví cũ, thưởng, phí shop, thiếu tiền, giá trị không hợp lệ và vượt giới hạn.
- `unit-events-candidate.log`: 6 ca chạy hàm mua điểm thật của script Kim Qua Hiệu Lệnh với ví thử: thiếu tiền, xem trước, trừ đúng một lần, mua lặp khi hết tiền, mua nhiều và số lượng sai. Bản cũ thất bại ở ca có 60 Nguyên Bảo mua gói giá 100; không được cộng hai getter thành 120 rồi cấp thưởng. `unit-events-baseline.log` giữ bằng chứng đối chứng này.
- `migration-result.json`: 16 nhân vật đã chuyển, bảo toàn tổng tiền, dữ liệu ngoài ví không đổi. Backup ở `currency-before.bson.json`; đây là dữ liệu riêng, không đưa nội dung vào báo cáo công khai.
- `gui-03`: mua một vật phẩm tại Vân Phiêu Phiêu với giá 100 hạ phẩm; Võ Thạch từ 230.745 còn 230.645, Nguyên Bảo giữ 345; một vật phẩm được tạo. GUI, tooltip, Cường hóa và di chuyển đều qua.
- `fixture-persistent.json`: kiểm BSON sau thoát sạch, số tiền và vật phẩm đúng.
- `gui-01`: kiểm chức năng qua nhưng gate kiểm log không qua vì giá trị tiền thử trùng chuỗi kiểm tra riêng tư. Giữ nguyên bằng chứng, thay dữ liệu thử cho lượt cuối, không bỏ gate. Ảnh lượt này cũng giúp phát hiện phần tiền của Túi bị khuất ở dưới màn hình.
- `gui-02` và `relogin-01` qua kiểm chức năng; bước phát hành phát hiện đường dẫn SuperTooltip trùng hoa/thường và dừng trước khi sửa Play. `gui-03` và `relogin-02` kiểm lại bằng manifest không trùng.
- `relogin-03`, `fixture-restore.json`, `release-report.json`, `final-verification.json`: đã qua đăng nhập lại sau lần cập nhật server cuối, phục hồi toàn BSON fixture **sau migration**, phát hành và đối chiếu hash cuối.
- `final-database-verification.json`: cả 16 bản ghi nhân vật khớp chính xác dữ liệu trước thử cộng với phép chuyển đổi tiền tệ; tổng tiền bảo toàn và toàn bộ dữ liệu ngoài ví không đổi.
- Bản Play có 383 file cập nhật khớp candidate. Kiểm hash toàn bộ 8.026 tài nguyên overlay, 37 binary trong manifest và 7 file server đã sửa đều qua. Sáu tiến trình server và toàn bộ cổng riêng hoạt động; log Game mới nhất không có lỗi quy đổi, lỗi dispatch hoặc traceback trong các mẫu đã quét.

Game SHA-256: `e6dd49b65cdad5fc1a03ff6d8fda0b0c7a87a613faf8ce933b113c75a7d338f2`.

Manifest SHA-256: `65c1233064b0a001b26813fa36f1dc963bd51ea765bdb50b929035665edc472f`.

Backup Play trước cập nhật: `Build/backups/vothach-play/20260926-103712`.

Lượt này kiểm mua hàng Võ Thạch thật trong game; đường thưởng và phí các ví cũ có unit test. Không coi đây là việc thử thủ công mọi NPC, mọi sự kiện hoặc mọi shop đặc thù.

Để tái tạo: dùng `Tools/game/deploy_currency.py stage` từ baseline Play, build các target `cys_wxclient`, `cys_uisystem`, `CEGUIFalagard.dll`, thử hai chế độ `-CurrencyProbe 1/2`, rồi publish bằng đúng hash. Các generator tính năng cũ cần chạy trước bước overlay Võ Thạch khi dựng lại từ donor. Server dùng `Tools/server/deploy_currency.py`, `migrate_currency.py`; không chạy migration lên server chính.
