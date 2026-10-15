# HJ05 — tiệm trân thú và tẩy Thú hồn, tiếp nối 28/09/2026

Đã phát hành phần sửa dưới đây vào Play. **Toàn bộ 143 mục vẫn được theo dõi; còn các tính năng thiếu và các ca chưa nghiệm thu, không ghi tất cả đã hoàn tất.** Báo cáo phát hành trước và các lượt thử thất bại được giữ nguyên.

**Cập nhật 29/09:** lớp mới [Tàng Kinh Các và vòng đời UI](cangjingge-20260929_vi.md) thay Game/UI DLL, bổ sung 36 monster và sửa sự kiện/phụ bản. Hash và phiên GUI trong tài liệu này là bằng chứng của lớp 28/09; bản mới có hồ sơ riêng.

## Bản chạy

- Launcher: [Play.cmd](<C:/TLBB/085/CY-Source/Build/world-gui/stage-play-21/Play.cmd>).
- Game.exe SHA-256: `df30ae217669fa156297d4a34a3926431eb5037a88914ec2a7937c6e4ec49a20`.
- Sao lưu client: `C:\TLBB\085\CY-Source\Build\backups\hj05-remaining-play\20260928-221920`.
- Máy chủ CY riêng: `/home/ubuntu/cys-test-20260913`; 22 file tích lũy khớp manifest.
- [Hồ sơ phát hành](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/release-report.json>), [hồi quy máy chủ hiện hành](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/verify-20260928-222337/report.json>).

Bổ sung DLL CEGUIFalagard build từ source để sửa đồng hồ: `e438e56f1d8f30d88d24f80bf33f0fbf654c97821ba7a6a7882dea0b5d248cbc`. Game.exe, các DLL khác và overlay giữ nguyên. [Hồ sơ đồng hồ](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/stopwatch/release-report.json>).

## Tiệm trân thú

- Dùng container pet đúng loại, giữ object/GUID, kỹ năng, trang bị và tư chất khi gửi, lấy về hoặc mua. Kiểm quyền chủ/đối tác, trạng thái quầy, số phiên, giá, túi đầy và yêu cầu lặp trước thay đổi.
- Sửa đọc/lưu quầy có khóa số hoặc chuỗi, trạng thái bán dạng boolean/số, số phiên và cờ dữ liệu thay đổi. Lưu shop dùng API thật; thay đổi đến trong lúc chờ lưu không bị mất cờ cần lưu.
- Nối gói danh sách/chi tiết/gửi/rút/đăng bán/mua của CY, phân biệt gói chủ tiệm và người mua. Khung xem trân thú đọc dữ liệu của đúng GUID, không trộn vào trân thú người chơi.
- Nối quyền chủ tiệm và mã loại tiệm theo Lua CY, nới bố cục quản lý, tên/ID chủ, doanh thu, giá bán, hàng quầy và các nút. Giữ skin có sẵn.
- Sửa sự kiện chọn trong kho dùng nhầm sự kiện mở khung Trân thú. Danh sách ẩn cập nhật sau khi rút trân thú ở tiệm không còn tự bật khung Pet.

Giao dịch GUI đã kiểm: người mua có 10000→9500 Võ Thạch hạ phẩm, tiệm có doanh thu 490 sau phí 2%, người bán giữ 10000; một GUID pet chuyển sang người mua đúng một lần, tư chất 1234 không đổi. Bấm mua lặp không nhân pet. Đăng nhập lại và dữ liệu Mongo xác nhận cùng kết quả.

Phần bày bán **Stall** là luồng khác. Kiểm hàm thật xác nhận nhánh trân thú KNB đã trả đúng KNB, nên hiệu chỉnh nhận định audit trước đó. Ca Võ Thạch tái hiện lỗi Lua 5.3 `%d` nhận số lẻ khi ghi nhật ký, sau khi pet và tiền đã chuyển. Bản sửa riêng `hj05_stall_format.py` lấy phần nguyên đúng ba mệnh giá 10000/100/1 và dùng nhãn Võ Thạch. 26 kiểm tiền, GUID và replay qua sau sửa. Đây là kiểm hàm máy chủ, chưa là nghiệm thu GUI Stall hai người.

## Thú hồn

- Đối chiếu script Vân Thâm Thâm, bảng PetSoulExtension và màu TIPS native GL/CY trước sửa. Không sao chép luật cho phép dòng trùng của HJ.
- Khóa loại dùng sáu chữ số theo dòng; phẩm 0/1/2–3 có 4/5/6 dòng. Tạo đúng số dòng rồi mới sắp xếp, tránh mất loại đã khóa ở cuối khi cắt danh sách.
- Không tạo hai thuộc tính cùng loại. Kiểm mask, dòng trống/ẩn, cấu hình và vật phẩm khóa màu trước thu phí. Vật phẩm khóa màu dùng điều kiện phẩm và số dòng bảo đảm từ nguồn; không mua nguyên liệu tự động.
- Phí tẩy 50000 Võ Thạch hạ phẩm; nguyên liệu theo số dòng khóa: 0→1, 1–2→2, 3–4→3, 5→4, 6→5. Một lượt có khóa màu tiêu thêm một vật phẩm phù hợp. Giữ bộ đếm nguyên liệu và luật khóa vật phẩm sau tiêu nguyên liệu khóa.
- Khóa loại giữ **loại**, trị số được tẩy lại. Kết quả tẩy nằm ở cột xem trước cho đến khi Nhận kết quả. Loại/giá trị trong tooltip và khung dùng bậc màu của từng thuộc tính, không dùng chung màu phẩm vật phẩm.
- Từng thuộc tính và nút khóa có hàng riêng; nội dung dài xuống dòng không làm lệch nút khóa. Dòng không tồn tại không có nút khóa.

GUI đã kiểm phẩm 1, khóa dòng thứ năm có loại 22, dùng khóa màu, tẩy, xem trước chưa đổi thuộc tính cũ, nhận kết quả và đăng nhập lại. GUID giữ nguyên, năm loại duy nhất, dòng thứ sáu rỗng, hai nguyên liệu tẩy và một khóa màu bị tiêu, tiền 100000→50000. Phẩm khác và các biên được kiểm bằng hàm thật; không nói đã bấm mọi phẩm trong GUI.

## Kiểm chứng

8 bộ hồi quy máy chủ qua sau bản sửa Stall: 112 assertion shop, 1891 Thú hồn, 62 power, 9461 hồi quy HJ05, 68 kho, 113 pet, 37 thương nhân/phúc lợi và 26 tiền tệ Stall. Đây là số assertion, không phải số tính năng hoàn tất. 22 file runtime tích lũy được kiểm cú pháp riêng từng file.

Các phiên GUI dùng cùng Game.exe. Sau ba phiên shop, chỉ bốn overlay Lua/layout Thú hồn được đổi để sửa hàng chữ dài. Manifest trước/sau được giữ; công cụ publish kiểm mọi thành phần của shop không đổi. Hai phiên Thú hồn và hai phiên kho dùng manifest cuối. Không lấy nhật ký của binary cũ làm bằng chứng.

- `shop_owner`: [shop-owner-17](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/shop-owner-17/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.
- `shop_buyer`: [shop-buyer-4](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/shop-buyer-4/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.
- `shop_relogin`: [shop-relogin-3](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/shop-relogin-3/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.
- `soul`: [soul-3](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/soul-3/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.
- `soul_relogin`: [soul-relogin-3](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/soul-relogin-3/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.
- `bank`: [bank-1](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/bank-1/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.
- `bank_relogin`: [bank-relogin-1](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/bank-relogin-1/run.json>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.

Đồng hồ dùng cùng dấu thời gian cho giờ/phút/giây; sửa hiện `4:60` khi giá trị thật là `4:59`. [Phiên GUI bổ sung](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/stopwatch/gui-2/run.json>) kiểm đồng hồ, gửi/rút kho, di chuyển và thoát. Ảnh được đọc trực tiếp, giây nằm trong 0–59. Phiên đầu `stopwatch/gui` đạt phía client nhưng kiểm log máy chủ kéo dài qua 23:00 gặp lỗi Tàng Kinh Các có trước; giữ nguyên kết quả server **không đạt**, không dùng phiên này làm điều kiện publish. Phiên nghiệm thu mới có biên log riêng và không lỗi máy chủ trong khoảng thử.

Kiểm cụm sau lần phục hồi cuối lúc `2026-09-28T23:28:15.820040+07:00`: sáu dịch vụ chạy, không trùng tiến trình, hai cổng game/login sẵn sàng. [Trạng thái cuối](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/stopwatch/health.json>), [log khởi động cuối](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/stopwatch/boot-log-summary.json>). Vẫn ghi nhận năm monster thiếu dữ liệu 49285–49289; không tính chúng là đã sửa.

Đã phục hồi toàn bộ BSON hai tài khoản test14/test15 và xóa đúng tiệm fixture, rồi khởi động lại cụm riêng và đối chiếu toàn bản ghi. Không chỉ đặt lại tiền hoặc túi. Bốn pet của ca kho giữ GUID duy nhất, đúng container, tư chất và linh tính sau đăng nhập lại. Cụm riêng có đủ sáu dịch vụ, không trùng tiến trình, cổng 15733/15734 sẵn sàng. Log khởi động không có traceback; còn năm lỗi dữ liệu monster 49285–49289 trong scene 9/13/15 đã có trước, được ghi riêng trong `boot-log-summary.json`.

Các lượt lỗi ban đầu vẫn còn trong thư mục log: nhầm collection shop, thiếu API tên pet, con trỏ output null khi giải mã, chỉ số tiệm chưa nối, khung Pet bị mở do trùng sự kiện và nhãn bị cắt. Chỉ các phiên trong hồ sơ phát hành được nghiệm thu. Cảnh báo tài nguyên/baseline có trước vẫn được giữ.

## Giới hạn còn lại

- Bày bán Stall (#123) khác PlayerShop: nhánh pet KNB đã cộng đúng KNB và lỗi nhật ký Võ Thạch đã sửa, nhưng client Stall chưa nối đầy đủ và chưa nghiệm thu GUI hai người. Đối tác/chuyển nhượng và toàn bộ tiệm vật phẩm chưa nghiệm thu. Giao dịch PlayerShop trong scene không nhường luồng ở đoạn đổi tài sản; chưa có cam kết nguyên tử qua nhiều collection khi tiến trình/máy mất điện giữa các lần lưu.
- Xây thành, nghiên cứu, tuyến thương nhân, nhiệm vụ thành và chiến trường Trác Lộc còn các luồng riêng chưa hoàn thiện.
- Mạn Đà và cây thiên phú CY/GL còn khác dữ liệu/schema. Chưa tự bật phái hoặc chép hệ số của HJ.
- Chưa kiểm mọi item/skill/boss không có ID, toàn bộ Q70/Sát Tinh/Thanh Khâu/Tào Vận, hoặc THDC4 một giờ.
- Particle `anim_pos1/2/3` (#119) vẫn cần chứng minh ảnh hưởng; không xóa cảnh báo để coi là đã sửa.
- Tàng Kinh Các: lỗi thiếu toàn họ 13565–13600 đã được xử lý trong [đợt 29/09](cangjingge-20260929_vi.md) bằng 36 ID riêng đã đối chiếu tài nguyên; có kiểm callback, scene thật và GUI NPC. Còn nghiệm thu cả phụ bản với đội người chơi, thưởng/drop và các nhãn tên dài/tiếng Trung. Khảo sát 28/09 được giữ như bằng chứng nguyên nhân trước sửa.

## Tái tạo

`Tools/server/hj05_remaining.py plan/apply` tích hợp từ baseline đã lưu, kiểm hash và backup trước ghi. Áp sau lớp HJ05 trước đó; không chạy generator cũ ghi đè nguồn hiện hành. `Tools/server/remaining_verify.py` đối chiếu manifest tích lũy và chạy hồi quy.

`Tools/server/hj05_stall_format.py` là lớp cuối sau `hj05_remaining.py`, yêu cầu dừng Game riêng khi apply. Bản phát hành client được kiểm với server trước lớp Stall; sau đó chỉ hàm ghi thông báo Stall thay đổi, giữ nguyên Game/overlay và các hàm shop/Thú hồn/kho. Hồi quy tích lũy sau khởi động xác nhận cả hai lớp. Manifest và backup Stall nằm trong `Build/Logs/2026-09-28-hj05-stall`.

Client dùng build wrapper, `Tools/game/stage_hj05_remaining.py`, `remaining_ui.py` và `remaining_shop_ui.py`. `publish_hj05_remaining.py` kiểm bản Play ban đầu chưa đổi, binary/PDB mới nhất, các phiên GUI và server, dữ liệu lưu–nạp và phục hồi fixture trước sao lưu/publish. Không thêm DLL hook/inject trong đợt này.

`Tools/game/deploy_stopwatch.py` là lớp client cuối, chỉ thay DLL/PDB CEGUIFalagard đã build từ `Src/Client/CEGUIFalagardEx/FalStopWatch.cpp`. Công cụ kiểm Game/overlay không đổi, manifest đúng phiên GUI, biên log server, ảnh đồng hồ và full BSON phục hồi trước publish. `Tools/audit/cangjingge_ids.py` chỉ đọc dữ liệu CY/GL và ghi báo cáo; không sửa bảng hay script runtime.

## Sổ theo dõi 143 mục

`SUA_GUI` xác nhận đúng phạm vi ghi trong hàng; `SUA_HAM` là kiểm hàm; `KIEM_MOT_PHAN` còn điều kiện gốc chưa nghiệm thu. Không đồng nhất các trạng thái này với game không còn lỗi.

Phân bố: CAN_THU=68, CO_XU_LY=20, DONOR_BASELINE=1, KHAC=18, KIEM_MOT_PHAN=3, SUA_GUI=4, SUA_HAM=6, THIEU=23.

[Hồi quy runtime hiện tại](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining/verify-20260928-222337/report.json>).

| Mục | Trạng thái | Bằng chứng / giới hạn |
|---|---|---|
| 1 | CO_XU_LY | Khung Võ hồn dùng host/nguyên liệu thật; đợt power đã thử hợp thành. Chưa thử lại mọi nguyên liệu của mọi nhánh nâng cấp. |
| 2 | CAN_THU | Tooltip trong túi đã nối metadata; link chat là đường riêng, chưa có ca post đúng Thất tinh đao rồi mở bằng nhân vật thứ hai. |
| 3 | KHAC | CY có lò rèn nhịp Space tối đa +9 và whitelist trang bị riêng; không được chép điều kiện equip point 8/9/10 của HJ vào CY vì ID có thể khác nghĩa. |
| 4 | CAN_THU | Chưa có mã item/model/effect cụ thể của Thất tinh đao trong log để xác nhận dependency đang dùng. |
| 5 | CAN_THU | Có lingwu_equip_effect_flush và bảng bộ; chưa thử mặc đúng sáu món, giữ HP trước/sau chuyển map. Không lấy kiểm tra Linh Vũ mới làm bằng chứng bộ sáu món HJ. |
| 6 | CAN_THU | Thú hồn, thú cưỡi và dung hồn dùng các đường riêng; chưa tái hiện đúng tổ hợp chuyển hồn lên ngựa. |
| 7 | CO_XU_LY | Pet calculator có cộng phần trăm tư chất và thuộc tính mở rộng Thú hồn khi xuất chiến. Bộ pet 113 ca qua, nhưng chưa đo mọi mẫu hồn trong thế giới. |
| 8 | CAN_THU | Không dùng CGCharUseSkillHandler của GS HJ; vẫn phải thử ẩn/hiện Thiên Sơn và tương tác party, map, mục tiêu. Không coi khác engine là miễn lỗi. |
| 9 | CAN_THU | Đây là thay giới hạn kinh tế 1000 thành 9999; chưa có yêu cầu đổi mức giá của CY và chưa thử biên giá ở UI thương hội. |
| 10 | SUA_GUI | Đã nối tiệm trân thú thật: gửi/rút bằng container pet, tìm ô trống thực, giữ GUID và tư chất. GUI chủ tiệm gửi→rút→gửi→đăng bán, người khác xem/mua và đăng nhập lại đạt. Kho đầy/quyền/serial/yêu cầu lặp được kiểm hàm; chưa kiểm mọi loại trân thú bằng GUI. |
| 11 | CO_XU_LY | CY đã sửa chọn ô trống nhẫn/hộ phù và đổi đúng instance/GUID; có GUI/relogin lịch sử. Không áp workaround HJ bắt kéo bằng tay. Hiệu ứng Trùng Lâu cụ thể còn cần ca riêng. |
| 12 | CAN_THU | Log không nêu 5–6 skill Ác Nhân nào. CY đã có đối chiếu kỹ năng cơ bản nhưng không đủ để xác nhận mọi hành vi cùng bản HJ. |
| 13 | THIEU | Mạn Đà được đánh dấu tắt ở slot 16 của CY. Condition cũ có mã tiêu hoa không chứng minh phái đã được mở và nối đúng dữ liệu CY. |
| 14 | CAN_THU | Đã có guard khóa/trao đổi/quyền sở hữu và tách hồn trước xóa pet; chưa tái hiện script xóa vật phẩm pet quý hiếm mà file nhắc. |
| 15 | CAN_THU | Đã nhập nhiều vũ khí HJ và kiểm dependency, nhưng log không chỉ item/mesh vũ khí Ác Nhân bị thiếu. |
| 16 | CAN_THU | Có mapping tên/item riêng CY; cần mã Linh Vũ cụ thể và tên kỳ vọng để khẳng định sai tên. |
| 17 | CAN_THU | Link vật phẩm Linh Vũ chưa có kiểm hai người; kiểm SuperTooltip trong túi không bao phủ link chat. |
| 18 | CAN_THU | Tổng xuyên thích đã nối; tooltip instance có metadata. Chưa thử đúng item liềm Ác Nhân của log. |
| 19 | KHAC | Là bổ sung các loại phụ thể, không mô tả lỗi hay danh mục cần có. Không coi việc chưa nhập tất cả loại HJ là cùng lỗi. |
| 20 | CAN_THU | Linh Vũ có đường cộng chỉ số riêng; cần snapshot đúng bộ trước/sau map/relogin để loại trừ reset op. |
| 21 | CAN_THU | Có skill trang bị/Thất tinh trong server nhưng cần đúng item kiếm và ID Ly ưu thương; chưa xác nhận đường nhận item tự cấp chiêu. |
| 22 | KHAC | Huyễn hồn CY hiện hiển thị cấp, tiến độ /10, phí và đột phá bằng luồng riêng; không dùng nguyên UI xác suất nâng cấp HJ được mô tả. |
| 23 | KIEM_MOT_PHAN | GUI kho + đăng nhập lại giữ nguyên linh tính và tư chất. Đã sửa hiển thị thế hệ 100–110 thành linh tính 0–10 theo CY gốc. Chưa thử nâng linh tính sau rút kho. |
| 24 | SUA_GUI | Đã nối giao thức 228/757/1706, số lượng và vị trí kho thực, chọn ô thưa 2/7. GUI gửi/rút/đổi chỗ, túi rỗng rồi rút lại, đăng nhập lại đạt; bốn GUID không trùng/mất. |
| 25 | SUA_HAM | Hai calculator đã cộng tư chất trang bị pet theo PetEquipItemAptRate CY; bonus chỉ tính trên base, không nhân thêm dòng thuộc tính. Ma trận 256 × 6 và làm tròn đạt. Chưa đo mọi vật phẩm trực tiếp trong GUI. |
| 26 | SUA_HAM | Lưu/nạp sáu byte tư chất vốn đạt; đã sửa thiếu hệ số khi tính chỉ số ở mục 25. Không kết luận tái hiện lỗi hook 2% của HJ. |
| 27 | CO_XU_LY | Loader thật giữ hai dòng attr_values và attr_types đã thử 123/456. Không dùng hook pos20 của HJ; chưa thử mọi loại vật phẩm pet/slot trong GUI. |
| 27.5 | KHAC | Ghi chú chuyển nhánh Việt hóa/copy bản vá, không phải lỗi game. Không làm theo như chỉ thị triển khai. |
| 28 | CO_XU_LY | UI Võ hồn và nguyên liệu đã có sửa nguồn sinh. Không thể nghiệm thu “nhiều UI khác” vì file không liệt kê chúng. |
| 29 | CAN_THU | Không có danh sách 10 file text, hash hay các dòng dịch sai; chưa thể đối chiếu từng lỗi Việt hóa. |
| 30 | CO_XU_LY | Khung chế tạo đã nối host nguyên liệu/icon, số lượng và ô thứ năm; thử 54 equipcraft + 978 gameplay ca đạt. Chưa bấm đúng NPC Bành Hoài Ngọc trong lượt này. |
| 31 | CAN_THU | Thẻ kỷ niệm là hệ riêng; chưa xác nhận đầy đủ text và cộng thêm thuộc tính trong UI card hiện hành. |
| 32 | CAN_THU | Chưa tái hiện chuyển trang thứ hai bằng đúng thẻ; kiểm tooltip trang bị không bao phủ trạng thái tên card. |
| 33 | CO_XU_LY | Đã sửa callback Đại Lý/nhận trả thưởng và 174 ca callback hiện tại đạt; chưa chơi toàn chuỗi tới cấp 10 với mọi NPC mà HJ nêu. |
| 34 | CAN_THU | Không có bản text chuẩn/danh sách dòng platform và kỹ năng để so. Mạn Đà hiện chưa mở. |
| 35 | CAN_THU | Có luồng equipment skills, nhưng chưa đối chiếu từng icon/tên của hai chiêu Thất tinh trên UI nâng cấp. |
| 36 | CO_XU_LY | Đã sửa khóa động tác/đích chết; GUI cùng Game hiện tại có di chuyển sau thao tác. Lỗi ngẫu nhiên dài phiên chưa được tái hiện bằng mô tả này. |
| 37 | CO_XU_LY | Khung chế tác CY mới từ chối loại/slot không phù hợp; 54 ca equipcraft đạt. Chưa thử mọi cửa sổ Thất tinh cũ còn tồn tại. |
| 38 | CAN_THU | Chưa chạy post item nhiều loại và mở link hai người; không thể xác nhận hết lỗi disconnect chỉ bằng kiểm codec túi. |
| 39 | CO_XU_LY | Server riêng đang chạy/nạp scene với dữ liệu hiện tại; không dùng hex loader HJ. Chưa thử mọi tên Việt hóa mới có thể thêm sau này. |
| 40 | CAN_THU | Map thành bang cần thành thật và thử render/entrance. Dữ liệu map có không đồng nghĩa map thành đã vào được và không đen. |
| 41 | KHAC | Không dùng workaround ép bang cấp 5. CY đọc thành/cấp từ dữ liệu; mục 108 trong chính file cũng hủy workaround này. |
| 42 | KHAC | Thay World binary không mã hóa là thao tác riêng nhánh HJ; server CY hiện dùng Skynet/Lua. Không chép binary trong log. |
| 43 | THIEU | Luồng thành bang chưa hoàn chỉnh, các API tạo/quản lý/cổng còn thiếu; chưa có nghiệm thu NPC ngoài thành → nội thành. |
| 44 | THIEU | AskCityShop/DoCityShop và luồng thương nhân thành chưa nối đủ; kiểm ngân phiếu nhận/trả không chứng minh shop chạy thương mở được. |
| 45 | THIEU | AskCityRoad/DoCityRoad còn stub, chưa hoàn thành tuyến thông thương và quyền bán theo tuyến. |
| 46 | CAN_THU | Chưa thử buff thương nhân rồi lên/xuống thú. Bộ test ngân phiếu không kiểm khóa mount theo buff. |
| 47 | CAN_THU | Cần kiểm tăng nộ theo từng chiêu/đòn trúng của Tiêu Dao, Thiên Long, Thiên Sơn. Không suy từ việc đánh có sát thương. |
| 48 | CAN_THU | Thiếu ID buff và chuỗi sai/đúng; bản dịch buff cần so từng dòng. |
| 49 | CAN_THU | CY wardrobe chọn màu theo catalog, đã có kiểm sở hữu/đổi màu. Chưa thử đúng chức năng nhuộm ngẫu nhiên/NPC HJ bị dừng sớm. |
| 50 | CAN_THU | Mô tả thiếu hệ/item/tab cụ thể; preview ngoại trang có cập nhật cấp nhưng chưa tái hiện thao tác nêu trong log. |
| 51 | KHAC | Bổ sung chuyển ngọc thời trang ở NPC Y Thiên Thải là tính năng; chưa chứng nhận tính năng này ở CY. |
| 52 | CAN_THU | Chưa kiểm rage buff của thẻ kỷ niệm; không gộp với tăng nộ từ môn phái. |
| 53 | CAN_THU | Có item_std_impact_effect khi item_flush pet; chưa kiểm chính bộ năm món có buff sau chuyển scene và triệu hồi lại. |
| 54 | KHAC | Giới hạn 19 ký tự là thay đổi thiết kế. Cần xét byte UTF-8/độ rộng packet; không áp con số HJ tự động. |
| 55 | CAN_THU | Chưa thử giá UI tẩy tư chất trang bị pet đối chiếu phí thật. Không nhầm với phí tẩy Thú hồn đã nối. |
| 56 | CAN_THU | Cần đúng skill ID/cấp và số kỳ vọng của các chiêu pet; bộ kiểm học skill chưa đo toàn bộ sát thương phóng thích. |
| 57 | CAN_THU | Các callback Đại Lý được kiểm, nhưng chưa chơi hết kịch tình tới Q70 Hư Trúc/hộ tống Kiều Phong. |
| 58 | KHAC | File giới hạn lỗi ở client HJ 32-bit 11 phái; CY hiện x64 dùng profile riêng. Không coi lỗi nhánh đó là lỗi đã xác nhận ở CY. |
| 59 | CAN_THU | Ác Nhân CY có mapping phái/camp riêng và từng chạy skill; chưa tái hiện tình huống mọi quái thành NPC sau nhập phái. |
| 60 | CAN_THU | Đã sửa điều kiện/registry chung, nhưng chưa thử riêng nhiệm vụ Đôn Hoàng Tào Diên Huệ và các quest không được liệt kê. |
| 61 | CAN_THU | Giao dịch lễ hộp hiện qua kiểm thiếu chỗ/replay/race. Cần ánh xạ đúng item Âm Kim Bảo Sương, không dùng một hộp khác làm bằng chứng. |
| 62 | SUA_GUI | Tẩy Thú hồn theo CY: loại thuộc tính duy nhất, khóa loại giữ dòng hợp lệ kể cả dòng cuối của phẩm có 4/5 thuộc tính; chỉ số vẫn được tẩy lại. Vật phẩm khóa màu bảo đảm đúng số dòng bậc cao theo nguồn. GUI khóa dòng 5, dùng khóa màu, xem trước→nhận→đăng nhập lại; phí/nguyên liệu/GUID đúng. Không áp yêu cầu dòng trùng của HJ. |
| 63 | CAN_THU | Catalog nhập HJ đã giữ 711 biến thể màu, nhưng chưa kiểm đúng dye columns29/30 của tính năng nhuộm cũ. |
| 64 | KHAC | Bổ sung full bộ phái và NPC đổi Ngự Tứ là thêm nội dung. Cần danh sách item/script để đối chiếu, không suy từ nhập ngoại hình. |
| 65 | CO_XU_LY | Hàm thật can_impactA_replace_impactB chặn ưu tiên thấp đè cao; probe đã đạt. Cấp buff cụ thể còn phụ thuộc mutex_priority trong bảng. |
| 66 | CO_XU_LY | CY có đường cấp tối đa200 và kiểm biên cấp; chưa tái hiện crash khi 10–15 trong server hiện tại. Không dùng patch hex Việt hóa HJ. |
| 67 | KHAC | Đổi tên hiển thị process là yêu cầu mỹ thuật/nhận diện, không phải lỗi gameplay. |
| 68 | CAN_THU | Importer HJ cô lập dependency và có census, nhưng chưa kiểm toàn bộ pack trùng hoặc file log Fairy1…11. Số file log không tự chứng minh trùng mesh. |
| 69 | CAN_THU | Chưa chạy Sát Tinh đủ30 hoạt động rồi lĩnh thưởng; callback nhiệm vụ chung không bao phủ điều kiện sự kiện này. |
| 70 | CAN_THU | Chưa thử đúng Thú hồn Chu Tước, miễn tử, công kích và hồi200giây; không kết luận từ mã pet tổng quát. |
| 71 | CO_XU_LY | Công thức pet lấy STR/CON đã refix để tính công/HP, có lan cờ dirty; chưa đo tất cả buff người → pet trong thế giới. |
| 72 | CAN_THU | Cùng nhóm mục8; cần ca ẩn/hiện Thiên Sơn thật. Không có patch hook HJ để xác minh một bản vá cụ thể. |
| 73 | KIEM_MOT_PHAN | Sửa lỗi riêng của thọ VẬT PHẨM Thú hồn: loader và hai dạng packet giữ thọ thật, kể cả 0. GCItemInfo hết lỗi nil khi Thú hồn có dưới sáu dòng thuộc tính. GUI Hồi thọ 100→200 tiêu đúng một nguyên liệu, đăng nhập lại vẫn 200. Tốc độ tụt thọ pet phụ thể trong mục gốc chưa nghiệm thu. |
| 74 | CAN_THU | Cần hai người, Thập Diện Mai Phục và map transfer. Các test party/chuyển map hiện có chưa bao phủ visibility của combo này. |
| 75 | CAN_THU | Chưa kiểm đồng thời Trùng Lâu/Lưu Tinh Cản Nguyệt và đổi Thú hồn; không suy từ việc model Võ hồn hiển thị được. |
| 76 | CO_XU_LY | cys_wuhun_appearance chọn visual theo cấp hợp thành, đã sửa KFSObj/world/SelfEquip/chọn nhân vật và có kiểm lịch sử. Không còn dùng một visual cố định cho mọi cấp. |
| 77 | THIEU | Chưa hoàn thiện UI/mapping thiên phú theo CY; không chứng nhận Nặc Ảnh Tuyệt Sát chuẩn hay đã chặn quái. Cần kiểm runtime riêng khi cây đúng được mở. |
| 78 | CAN_THU | Log không nêu tên/ID 4–5 thiên phú Minh Giáo; không thể nghiệm thu theo một nhận xét chung. |
| 79 | CAN_THU | Chưa thử đúng động tác/effect rồng Cái Bang; census ngoại trang không đo chiêu này. |
| 80 | CAN_THU | Chưa thử Hoành Tảo Thiên Hạ trong lúc chuyển trạng thái cưỡi; chưa xác nhận đủ điều kiện chặn mount. |
| 81 | CAN_THU | Chưa thử YQ80 Tinh Túc, mục tiêu chết và đủ sáu mục tiêu lân cận; chưa có mô tả ID để xác nhận. |
| 82 | CAN_THU | Chưa đo đứng yên10giây rồi tăng sát thương Tinh Túc; cần thiên phú cụ thể/level/công thức gốc. |
| 83 | CAN_THU | Chưa kiểm cooldown các chiêu khác sau Phi Long Tại Thiên theo cây thiên phú đang dùng. |
| 84 | CAN_THU | Chưa đo proc2%HPmax của đúng thiên phú Thiếu Lâm; không thay bằng kiểm sát thương cơ bản. |
| 85 | CAN_THU | Chưa kiểm Yết Thiên Ứng Hành đủ bốn kênh; hệ số băng/hỏa/huyền/độc chung đạt không chứng minh talent này đúng. |
| 86 | CO_XU_LY | Công thức bốn kênh hiện có giới hạn kháng âm và đã sửa cộng nhầm kháng/giảm sát thương. 978 ca gameplay gồm ma trận công thức đạt; chưa kiểm mọi buff riêng. |
| 87 | SUA_HAM | Một lần ra chiêu tính một đao, không tăng theo số mục tiêu; giữ token trước fork và theo dõi miss/hit riêng. Công thức cộng 1,5 × tổng 1..số đao trúng theo native CY, áp một lần trên sát thương tổng. Ma trận cô lập đạt, chưa có GUI chiến đấu AoE. |
| 88 | CAN_THU | Chưa đo damage Hoành Tảo theo từng cấp thiên phú/mô tả; không chứng nhận cân bằng toàn bộ Cái Bang. |
| 89 | CAN_THU | Mô tả “toàn bộ võ đạo đặt bẫy” thiếu danh sách; cần kiểm từng trap/talent, không suy từ việc map bẫy có dữ liệu. |
| 90 | THIEU | Mạn Đà chưa mở trong CY hiện tại; không có nghiệm thu hai chiêu hồi máu/tự chọn mục tiêu/tiêu hoa. |
| 91 | THIEU | Mạn Đà chưa mở, Phong Nhập Tùng giải phong huyệt chưa được nghiệm thu. |
| 92 | THIEU | Mạn Đà chưa mở, tiêu hoa khi Hoa Anh phát hiệu lực chưa được nghiệm thu. |
| 93 | THIEU | Mạn Đà/cây Chiếu Minh chưa được nối và nghiệm thu như HJ. |
| 94 | THIEU | Không tự áp hệ số40/75 của Vãn Lai/Quảng Lăng Tán khi phái chưa mở đúng CY. |
| 94.5 | KHAC | Là lời tổng kết của tác giả đã sửa40+talent trong4ngày, không là chứng cứ chúng ta đã có các bản vá đó. |
| 95 | THIEU | Mạn Đà chưa mở; còn rủi ro trùng ID giữa GL/CY nếu bật cây cũ. Không nhập mù nhánh nhận buff Thiếu Lâm. |
| 96 | CAN_THU | Chưa thử vào Thủy Nguyện/Nguyệt Sơn Trang; file không có scene ID và điều kiện mở để xác định đúng nhánh. |
| 97 | CAN_THU | Chưa chạy Sát Tinh Công Tôn Thắng qua phân thân/rời sớm; không nghiệm thu phụ bản từ test quest chung. |
| 98 | CO_XU_LY | Probe hàm thật: base100, cường hóa0, tư chất20% vẫn cộng20. Đường flush gọi quality ngoài điều kiện cường hóa; không tái hiện lỗi với trang bị thường. |
| 99 | CAN_THU | Đồ Thất tinh/Thần binh là đường đặc biệt; 98 không chứng minh giám định đúng loại này. Cần fixture item cụ thể. |
| 100 | SUA_HAM | Thêm guard self/nil/môi trường/pet mất chủ cho các nhánh sát khí và chết; kiểm hàm thật đạt. Chưa thử chết và tăng sát khí qua hai client. |
| 101 | SUA_HAM | Chặn đồng đội hợp lệ trước PERSONAL PK ở instance thường/type1 và liên server/type4; giữ luật world. Kiểm cùng đội/khác đội/solo và 83 ca PvP đạt; chưa trận party PvP live. |
| 102 | CAN_THU | Thần binh có đường cal_enhance_effect, nhưng UI rèn CY có whitelist riêng. Chưa thử đúng Thất tinh và tổng chỉ số sau nâng. |
| 103 | THIEU | Mạn Đà chưa mở; nhiệm vụ/chế dược/NPC/path không thể được coi là hoàn chỉnh. |
| 104 | THIEU | Chưa có phái Mạn Đà hoạt động để nghiệm thu aggro đạn phụ Quảng Lăng Tán. |
| 105 | CO_XU_LY | Danh hiệu đã nối danh sách sở hữu, chọn/ẩn và lưu. Chưa thử từng NPC đổi danh hiệu môn phái/điểm, nên không khẳng định mọi trang đổi hiển thị đúng. |
| 106 | THIEU | Chưa mở bản đồ/phái Mạn Đà theo luồng CY; không có nghiệm thu tự tìm đường tới phái. |
| 107 | THIEU | Thiên phú CY Tông môn và Võ đạo GL chưa thống nhất; hai quest dẫn đạo được log nêu chưa nghiệm thu. |
| 108 | CO_XU_LY | Có city database và đọc level thật, không ép level5. Test8 ca city query đạt; chưa có vòng tạo thành→restart→vào thành live đầy đủ. |
| 109 | THIEU | Một số quest thành còn thiếu CityIncProgress; hiện chặn trước khi mất tiền/nhiệm vụ. “Quest/phụ bản/text bang” rộng hơn phạm vi đã hoạt động. |
| 110 | THIEU | Đã có cống hiến authority và phúc lợi cơ bản; nâng nghề bang/đổi từng token chưa nghiệm thu, UI nghiên cứu thành còn stub. |
| 111 | THIEU | Xây/nghiên cứu thành chưa đầy đủ, các nhiệm vụ cần progress đang chặn an toàn. Không được gọi là nâng cấp thành đúng mọi loại điểm. |
| 112 | SUA_HAM | Callback lỗi 1/2/3/4 trả về trước khi trừ thẻ; thành công trừ đúng một, tên có * giữ ngoại lệ miễn phí của nguồn. Chưa nghiệm thu toàn bộ giao dịch đổi tên hoặc khả năng tranh chấp giữa các RPC. |
| 113 | THIEU | Đường shop thương nhân chưa nối đủ. Test ngân phiếu/túi đầy đạt không chứng minh mua full rương chạy thương không disconnect. |
| 114 | CAN_THU | Đã sửa thứ tự SetBagItemParam(value,type) của ngân phiếu; chưa thử UI đầy rương/giá trị biên packet ngân phiếu. |
| 115 | THIEU | Reset giá/shop đặc sản theo thành chưa hoàn thành; AskCityShop/DoCityShop thiếu đường hoạt động. |
| 116 | CAN_THU | UI nâng/tẩy Thú hồn đã có, nhưng quest dẫn hệ Thú hồn khác; thiếu hướng dẫn Origin được file viện dẫn và chưa thử chuỗi. |
| 117 | CAN_THU | Chưa chạy tới boss cuối Thanh Khâu rồi thử khiêu chiến lại; cần map/quest cụ thể. |
| 118 | KHAC | CY đã nhập68dòng huyễn sức HJ/195biến thể, khác danh sách50của log. Chưa chứng minh50món đó là đúng50món này khi thiếu ID. |
| 119 | DONOR_BASELINE | Hiệu chỉnh kết luận audit: 9 cảnh báo anim_pos1/2/3 có thật, nhưng source/evidence CY/GL gốc cũng không đăng ký các tham số này. Không tự xóa cảnh báo hay đoán cách áp animation. Chưa chứng minh sai hình/FPS của CY. |
| 120 | CO_XU_LY | Tổng xuyên thích/kháng từ mission602/603, snapshot login/map và chữ bay đã nối; có kiểm đơn vị và PvE/relogin lịch sử. |
| 121a | CO_XU_LY | Probe buy_back thật giữ cùng object/GUID/bound/+9/tư chất. Chưa thử mọi luồng thương hội/đấu giá; không mở rộng kết luận sang giao dịch khác. |
| 121b | SUA_GUI | Khung kho nhận dữ liệu pet thật, năm tư chất tách biệt; khung xem bổ sung ngộ tính, linh tính, hội công/hội thủ, cấp mang, tăng trưởng và sửa cột thuộc tính và tư chất bị tráo. GUI kiểm giá trị trong widget + GUID, sau relogin vẫn đúng. Nới khung/tên/nút, sửa mã màu và tên UTF-8. |
| 122 | CAN_THU | Đã sửa model riêng Võ hồn nhưng đó khác Thú hồn. Chưa thử liên tục nhiều model Thú hồn rồi đổi map để xác nhận cache/attachment chồng. |
| 123 | KIEM_MOT_PHAN | Đính chính audit: bày bán Stall khác tiệm PlayerShop. Hàm char_stall_buy hiện đã cộng Nguyên Bảo cho người bán pet nếu quầy là KNB; 26 kiểm hàm thật xác nhận tiền, GUID và yêu cầu lặp. Đã sửa riêng lỗi định dạng nhật ký nhánh Võ Thạch sau thanh toán. Client Stall chưa nối đầy đủ, chưa có GUI hai người; không dùng kiểm tiệm Võ Thạch để đóng mục KNB. |
| 124 | CAN_THU | Chưa có fixture đúng Thất tinh tăng base50→150 và HP/MP trước/sau relog; không suy từ metadata equip thường. |
| 125 | KHAC | CY đã nhập230thời trang,149cặp tóc,100cặp mặt HJ; không xác nhận trùng đúng30/20/20mẫu trong log thiếu ID. |
| 126 | CAN_THU | std_impact_022 có xác suất ngẫu nhiên, không mặc định luôn100%; cần kiểm mapping skill/personality/params để xác nhận từng loại phản kích/hấp huyết. |
| 127 | KHAC | Thêm2loại ngọc thời trang là nội dung mới; thiếu ID và công thức để đối chiếu. |
| 128 | CAN_THU | Chưa kiểm lịch17:30 và bộ câu hỏi khảo quan; không có danh sách đáp án chuẩn trong file. |
| 129 | CAN_THU | Tào vận là hệ khác chạy thương bang; chưa thử nhận/chở/trả theo tuyến, không gộp với test ngân phiếu bang. |
| 130 | CAN_THU | Chưa có soak test THDC4 một giờ của binary hiện tại. Phiên GUI vài phút/không crash không loại trừ lỗi dài phiên. |
| 131 | CAN_THU | Chưa kiểm đúng mapping thẻ kỷ niệm ngoại thủ→nội công và các trang; kiểm tư chất equip thường không bao phủ card. |
| 132 | CAN_THU | Thiếu monster ID/map của boss Long Quy; chưa theo dõi AI/đánh thường đúng boss. |
| 133 | THIEU | Danh sách/tuyên chiến cơ bản đã nối, nhưng Trác Lộc chiến trường/điểm công trạng/end-to-end chưa hoàn thiện. Tác giả HJ cũng thừa nhận fake/chưa đầy đủ; không dùng làm chuẩn chắc chắn. |
| 134 | KHAC | Giới hạn2→5account/PC là cấu hình/chính sách mới, không tự thay khi yêu cầu hiện tại chỉ là kiểm lỗi. |
| 135 | THIEU | Thiên phú phái mở rộng còn thiếu mapping/UI đúng CY; không công bố40+talent HJ đã được port. |
| 136 | CAN_THU | CY dùng actionset/bảng loại vũ khí từ source, nhưng chưa kiểm đủ nhịp đánh type8với vũ khí gốc. Không áp hook đè type HJ. |
| 137 | KHAC | Là việc reverse/unpack binary và tuyên bố virus/hiệu năng của tác giả. Không phải bằng chứng binary CY có virus hay phải bỏ pack; xem kiểm toán build riêng, có profiler hook nội bộ cần phân biệt injection. |
| 138 | CAN_THU | 132→24–30ms là số đo nhánh HJ; chưa có benchmark CY cùng tải/phần cứng/tuyến mạng. Không quy thành lỗi hay cam kết tăng4lần. |
| 139 | THIEU | Quest sư môn chín phái cổ đã kiểm, không bao phủ trọn Ác Nhân/đổi Võ đạo Quy Nguyên Đan và danh hiệu. |
| 140 | KHAC | CY đã nhập12đầu sức/21bối sức HJ và kiểm preview hai giới; không phải lỗi được mô tả trong mục này. |
