# Cấp 200, quyền GM tài khoản test, thanh Alt và tự chiến đấu

Phạm vi: client CY-Source và máy chủ riêng `/home/ubuntu/cys-test-20260913` (15733/15734, Mongo 27018). Không sửa server gốc hoặc client GL tham chiếu.

## Cấp nhân vật và GM

- Cấp chơi được 1–200. Hằng số server 201 là cận trên loại trừ; không dùng 200 ở vị trí đó vì sẽ chặn lên cấp 200.
- Nối yêu cầu thăng cấp legacy với CGReqLevelUp, cập nhật level từ GCLevelUp và EXP từ GCLevelUpResult. Giữ điều kiện gia nhập môn phái, tâm pháp tại các mốc 90/100/110 của server.
- Giữ chi phí EXP hiện có. Dòng 150 vốn là 0 tại mốc kết thúc cũ được điền theo plateau 151–200 là 262362285. Không tự suy diễn một đường cong cân bằng mới.
- AttrLevelUpTable gốc kết thúc 150. Đã đối chiếu chu kỳ 10 cấp của 110–150, nối đúng chu kỳ 141–150 cho 151–200, đủ 17 cột môn phái × 5 thuộc tính.
- Giữ tích luỹ EXP tối đa 3,5 lần yêu cầu cấp hiện tại. Client đọc unsigned 32-bit thành số 64-bit và truyền Lua number, tránh số âm khi EXP > 2147483647.
- Tâm pháp vẫn dùng giới hạn và bảng skill riêng, không kéo theo cap nhân vật một cách máy móc.
- 16 tài khoản hiện có `test00`–`test15` nằm trong GmCeshi của GmTool_Self, quyền 98. Không thay trường đăng nhập hoặc mở quyền cho tên tài khoản ngoài danh sách.

Nguồn sửa/tái tạo: `Tools/server/progression_200.py`; kiểm tra độc lập `Tools/server/test_progression.py`.

## Thanh Alt + số

Các ActionButton của MainMenuBar_2 dùng look có sẵn TLBB_ActionButtonNULL, bỏ BackImage. Icon vật phẩm/kỹ năng, hover, cooldown và nhận kéo thả vẫn do FalActionButton xử lý. Không dùng alpha cho cả nút vì sẽ làm mờ icon. Thanh F giữ nguyên.

Generator: `Tools/game/round2_ui.py` và `Tools/game/stage_progression.py`. XML cần khai báo `utf-8`, không dùng bí danh `utf8`: Expat của game không nhận bí danh này. Bản thử cũ từng không nạp được thanh Alt; ảnh không thấy ô chưa đủ chứng minh nền trong suốt. Kiểm tra phải có nút và icon thật, phím Alt, kéo thả và di chuyển.

## Tự chiến đấu

Đối chiếu AutoAttackSkill.lua, MiniMap.lua, Assistant.lua, ZdZdSkill và ZdZdPotion của CanonicalCY. `IsWorking()` phải trả chuỗi `"true"` cho Farm và `"false"` khi dừng: nút bật/tắt và biểu tượng bản gốc so sánh chính xác hai chuỗi này.

Server `cys_battle_assist.lua` thực thi qua AI, skill engine và `char_use_item` đang có. Không cộng EXP, sửa HP hoặc trừ vật phẩm bằng đường riêng. Client gửi cấu hình, máy chủ xác thực và trả trạng thái đã chấp nhận.

- Bắt đầu cần cấp 50, có môn phái, đang sống và không theo đội.
- Tìm mục tiêu còn sống, nhìn thấy được, trong phạm vi 15/25; giữ mục tiêu hiện tại còn hợp lệ. Mặc định không đánh người chơi.
- Kỹ năng lấy từ ZdZdSkill theo phái CY, có kiểm tra đã học, hồi chiêu và trạng thái. Có ngưỡng số mục tiêu cho AOE, khoảng lặp buff, hồi máu bản thân/đồng đội và kỹ năng hồi phục của thú.
- Thuốc lấy từ ZdZdPotion, mức HP–MP và đúng loại theo lựa chọn. Chỉ số lựa chọn 0 là “Không dùng”, không được tự chọn một thuốc khác. Sử dụng túi thật, kiểm tra khoá và cooldown, đi qua normal item handler. Đã nối các hàm Lua đọc tên, cấp yêu cầu và số lượng thuốc với item dữ liệu thật.
- Có hồi phục ngoài tự chiến đấu theo nhóm cấu hình riêng; Thiên Linh Đan/Huyền Linh Đan qua script vật phẩm thường; đông kết giờ EXP khi dừng nếu được chọn.
- Ô cấp là tự thăng cấp đến mức đặt, tối đa 200; đạt mức đó vẫn tiếp tục đánh. Dùng điều kiện thăng cấp thường của máy chủ.
- Giới hạn quái trong ngày dùng counter có sẵn; dừng và thử kỹ năng hồi thành 22. Tuỳ chọn 22–24 dùng giờ hệ thống server. Chết/chuyển bản đồ/theo đội/bấm di chuyển đều dừng; xuất hồn theo lựa chọn, không tự hồi sinh bằng cách chỉnh HP.
- Tự nhận yêu cầu vào đội chỉ gửi trả lời đồng ý khi đang chạy và người chơi đã bật lựa chọn; server vẫn kiểm tra đội và quyền trưởng đội.
- Lưu 11 mảng cấu hình vào nhân vật; trạng thái đang chạy không lưu. Gửi Begin/Chunk/Commit có revision và thời hạn, không nhận thiếu mảng, giá trị sai hoặc revision cũ.

Giới hạn chưa hoàn thiện: server không có bộ đếm Võ ý nên điều kiện này được vô hiệu trên giao diện, không giả có tác dụng. Tự đi chuỗi phó bản (`FB`) là hệ khác, chưa triển khai trong thay đổi này. Hỗ trợ kỹ năng/thú/đội dựa trên code đối chiếu; không coi một lần thử Võ Đang là bằng chứng đã chơi thử mọi tổ hợp môn phái và thú.

## Thiên phú: chưa thay đổi cơ chế

Đã gửi câu hỏi lựa chọn cho người dùng. Có hai hệ không tương đương:

1. CY Tông môn: ZongMenSkill.lua, bảng ZongmenTalent 255 dòng/37 cột, bí bảo ô 23, điểm thường/cốt lõi và hai bộ điểm. Script donor 998633 nZongMneg.lua dùng native LuaFnGet/SetZongMenData. Private server thiếu các native này. Donor script cũ còn dùng bảng 38 cột và cơ chế điểm khác, không thể chép nguyên rồi coi là hoàn tất.
2. GL Võ đạo: Talent.lua, SectInfo/SectDesc, CGSectOper/GCSectDetail, talent engine hiện có 984 định nghĩa. Chọn nhánh tại NPC Võ đạo và điểm lĩnh ngộ. Không phải dữ liệu Tông môn CY; các phái mở rộng không có đầy đủ cây trong UI GL tham chiếu.

Chưa gắn điểm/hiệu ứng Võ đạo GL vào ID của Tông môn CY. Chưa công bố Thiên phú hoàn tất. Tra cứu ELF donor chỉ dùng đọc tĩnh, không chạy binary donor; binary không có bảng symbol hữu ích.

## Kiểm tra và triển khai

Chạy `test_progression.py`, `test_battle_assist.lua` và thử trực tiếp trong `Build/world-gui/stage-progression-24`. Kết quả trong `Build/Logs/2026-09-24-progression`. PASS của runner chung không thay thế PASS của probe chức năng và kiểm tra log CEGUI.

Fixture chỉ dùng test15/GUID200016. Bản BSON đầy đủ trước sửa nằm tại `Build/Logs/2026-09-24-progression/test15-original.json`; khôi phục bằng `progression_live_fixture.py restore` sau kiểm tra, không dùng backup của đợt trước. Script triển khai client tạo backup đầy đủ và chỉ chấp nhận binary/manifest đã thử.

Các kiểm tra đạt trước triển khai:

- `test_progression.py`: gọi chính hàm IsGM cho đủ 16 tài khoản, từ chối tài khoản ngoài danh sách; kiểm tra bảng EXP và tăng chỉ số đủ 200 cấp.
- `test_battle_assist.lua`: lưu cấu hình nguyên vẹn, chống revision cũ/thiếu mảng/giá trị sai; yêu cầu gia nhập môn phái; tự thăng cấp đúng handler; dừng, đóng băng EXP, theo đội; lựa chọn thuốc 0 không tiêu hao và lựa chọn 1 dùng normal handler.
- `test_auto_text.py`: gọi trực tiếp LuaPlus.dll của game để kiểm tra Lua 5.0, nhãn thuốc/số lượng/ phần trăm và thông báo cấp 200; generator lặp lại cho cùng kết quả. Không dùng GetDictionaryString để lấy template có tham số: host này cố ý không nhận template tiêu thụ tham số. Generator đọc các template từ StrDictionary và định dạng riêng cho khung AutoAttackSkill.
- `live-cap-05`: từ 199 lên 200, chặn 201, mở GM bằng test15, di chuyển sau khung chung.
- `live-cap-relog-03`: cấp 200 giữ nguyên sau đăng nhập.
- `live-wide-alt-02`: EXP 3000000000 dương, cấu hình auto giữ lại nhưng trạng thái chạy đã dừng; kéo kỹ năng thật, 50 ô phím tắt, ba trang F và Alt+số; không còn lỗi Lua ở mask hồi chiêu.
- `live-battle-09`: mở cấu hình, chọn thuốc qua callback giao diện, dùng đúng túi thật, hạ quái (EXP 1000 → 1090 tại điểm đo), bật/dừng qua nút giao diện, dừng theo lệnh di chuyển. Đã xem ảnh thực tế: nhãn phần trăm và tên thuốc không còn mã định dạng; không có CYS Lua failure hoặc lỗi probe.

Đã triển khai lúc **24/09/2026 08:05:07** vào `Build/world-gui/stage-play-21/Play.cmd`, 10 file thay đổi. Game SHA256: `50721241f8b3f6c8776cde8a2e60af45ba00b26d3125b7f5334ba05caaf43f37`. Bản sao client và manifest bằng chứng: `Build/backups/progression-play/20260924-080507/deployment.json`. Publisher kiểm tra khớp binary/manifest thử trực tiếp và hash từng overlay. Đã khôi phục và so sánh chính xác BSON ban đầu của test15 trước khi triển khai.

Kiểm tra vận hành: private server đủ 6 tiến trình và 16/16 cổng listen. Khi đọc thêm trạng thái server gốc, mongod/mosquitto active; service tlbb-game gốc failed từ **20/09/2026 15:09:52**, trước thay đổi này. Script status.sh gốc còn báo PID Game cũ; không dùng thông tin đó làm bằng chứng game gốc đang hoạt động và không tự khởi động lại server gốc.
