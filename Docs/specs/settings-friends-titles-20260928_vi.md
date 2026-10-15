# Cài đặt, Bạn bè và Danh hiệu — 28/09/2026

Phạm vi là CY-Source và server CY riêng `/home/ubuntu/cys-test-20260913`.
Không sửa client_GL, dữ liệu CanonicalCY hay server TLBB chính.

## Cài đặt

- Các host `GetIsConfigChanged`, `SetIsConfigChanged`, capture phím, lưu/khôi phục phím vốn còn là stub. Nối chúng vào bảng phím CysAccel đang được game sử dụng.
- Đọc/ghi đủ tuple 39 giá trị của GameSetup; giữ các bit server chưa biết. Bảy bit đầu vốn đã đúng với `define.GAME_SETTING_FLAG`, không đổi thứ tự của chúng. Cờ tự theo đội dùng bit 24.
- Tùy chọn riêng của client lưu theo GUID nhân vật trong WXSystem.cfg; cờ tương tác gửi CGModifySetting và nhận xác nhận GCRetSetting. Lưu ngay khi Áp dụng.
- Áp dụng cập nhật mốc Hủy ở GameSetup, SoundSetup, ViewSetup. Sửa lỗi View_GetData không trả giá trị cho các khóa mới và chấp nhận giá trị slider dạng số thực.
- Độ trong suốt chat/theo dõi nhiệm vụ dùng sự kiện CY sẵn có; khóa kéo/thả và tắt tooltip chỉ tác động thanh phím tắt. Không chặn cập nhật icon/số lượng từ server.
- Công tắc DisableAllSound trước đây không được mixer đọc. Đã nối vào GetTypeVolume, cùng từng công tắc loại âm thanh; giữ riêng trạng thái tắt tiếng khi mất focus.
- Tự so sánh trang bị tuân theo ô **Tắt so sánh trang bị**; vẫn có thể dùng Alt để so sánh thủ công.
- Một số tùy chọn từ client CY mới chưa có dịch vụ hoặc bộ xử lý trong bản port này. Chúng được vô hiệu hóa và có tooltip giải thích, thay cho nút bấm nhận giá trị nhưng không có tác dụng. Chưa triển khai mới hệ thống thư, xem bạn đời, ẩn mũ, chat animation, tooltip so sánh từng thuộc tính, thiết lập bar phụ, hồi chiêu dạng số, tự cưỡi/hạ cánh, hiệu ứng vợ chồng, gửi lỗi hay các lựa chọn ưu tiên phụ. Bộ render chưa có consumer cho animation quality, particle quality, model logic, fog switch, transparency, model-effect switch, substitute-model, Mars water, high-FPS switch. Đây là giới hạn còn lại, không phải các tính năng đã hoàn thiện.
- Đồng bộ dọc vẫn cần khởi động lại như thông báo trong giao diện gốc.

## Bạn bè

- Nối CGRelation/GCRelation vào client hiện đại; cache theo GUID, cập nhật danh sách và trạng thái từ phản hồi server.
- Thêm theo tên/GUID, chuyển nhóm, xóa, chặn/bỏ chặn; sửa nhánh thêm blacklist còn trống, lỗi ghi nhầm loại quan hệ, chuyển nhóm với nguồn cũ/không tồn tại và danh sách vượt giới hạn.
- Giữ mã quan hệ từ server: bạn 1, kết bái 2, hôn nhân 3, chặn 4, tạm 5, sư đồ 7/8, cừu nhân 9. Không coi sư phụ là blacklist.
- Mọi thay đổi được đồng bộ về actor trước phản hồi, và lưu khi nhân vật thoát. Không tự chèn thành công vào giao diện khi server từ chối.
- Đối tượng từ chối kết bạn bị server từ chối thật. Từ chối mời đội cũng được kiểm tra tại world; từ chối giao dịch đã có xử lý trong scenecore.
- Tra người không tồn tại trả kết quả thất bại thay vì assert server.
- Danh sách chặn được dùng bởi bộ nhận chat thật. Nhấp đúp bạn bè chuẩn bị kênh tư mật; không gửi tin nhắn trong kiểm thử.
- Khung thông tin lấy đúng GUID số, ảnh đại diện, level, môn phái, online và nhóm; đánh dấu phản hồi thuộc khu thường để không mở nhầm khung KVK.
- Nới khung thông tin, tách chỗ cho GUID và nút tư mật, mở rộng ô môn phái; dùng tên môn phái/bản đồ thay cho ID số.
- Chưa triển khai mới các dịch vụ IM ngoài game, nhóm chat liên server, lịch sử chat IM hay quà tặng IM.

## Danh hiệu

- Nối gói danh sách/chọn danh hiệu. Chỉ cho chọn danh hiệu đã được server cấp; 0/0 thực hiện ẩn tên.
- Giao diện dùng khung CY hiện hữu với danh sách đã sở hữu và phản hồi từ server; không báo đổi thành công trước khi nhận dữ liệu mới.
- Khôi phục ID cửa sổ 2 trong InterfaceEx: khung từng bị loại bởi blocklist tương thích từ ngày 14/09. Giữ blocklist đối với Lua CY gốc chưa được chuyển đổi; overlay mới dùng các host đã nối. Nút **D.hiệu** ở khung Hảo Hữu gọi OpenTitleList như CY gốc.
- Sửa ô xem trước tên có kích thước 0, bố cục thuộc tính/thời hạn/trạng thái và mô tả; giữ skin CY. Tên và mô tả lấy nguyên văn dữ liệu máy chủ, một số còn là tiếng Trung.
- CharTitle.txt và CharTitleNew.txt có ID trùng nhưng ý nghĩa khác. Metadata tạo từ **1.187 dòng CharTitleNew.txt của server thực tế**, gồm tên, mô tả, nguồn và IA/IV. Không ghép tên khác vào cùng ID chỉ vì giống vị trí dòng.
- TransTitleStr tra theo ID, không dùng ID làm số thứ tự dòng. Cùng bảng tên dùng cho tên trên nhân vật và danh sách danh hiệu.
- Sửa biến title ra khỏi phạm vi trong set_title; chặn cấp trùng/ID không có bảng; đánh dấu tính lại thuộc tính khi cấp danh hiệu số; tránh crash với ID lịch sử thiếu cấu hình.
- Server hiện cộng thuộc tính của **tất cả danh hiệu đang sở hữu**. Chọn/ẩn danh hiệu chỉ đổi tên hiển thị, không tắt cộng chỉ số. Khung giải thích rõ cơ chế này và hiện giá trị IA/IV của danh hiệu được chọn.
- Chưa có cơ chế riêng để chọn một danh hiệu ngoại hình và một danh hiệu thuộc tính; không dựng nút giả cho cơ chế đó.

## Nguồn và kiểm thử

Nguồn đối chiếu: Lua/layout CY hiện dùng, Friend/Agname client_GL, schema ProtocolGen và packet_domains/social.lua, human.lua, human_attrib.lua, define.lua, CharTitleNew.txt của server riêng.

- `Tools/server/community_test.lua`: 286 kiểm tra quan hệ, giới hạn, đối tượng không tồn tại, từ chối, dữ liệu cũ và quan hệ được bảo vệ.
- `Tools/server/community_titles_test.lua`: 15 kiểm tra chọn/ẩn/cấp danh hiệu, ID giả, cấp trùng, thay danh hiệu cùng loại, đánh dấu thuộc tính và hàm cộng chỉ số thật (ẩn vẫn cộng, chọn không cộng trùng, bỏ qua ID cũ thiếu cấu hình).
- `CysCommunityProbe.h`: kiểm thử trong game qua UI và mạng thật; Áp dụng/Hủy/Esc, mixer, đổi/khôi phục phím, thêm/chuyển/chặn/xóa bạn, mở thông tin bạn, chọn/ẩn danh hiệu, đăng nhập lại và di chuyển sau đóng khung.
- Dữ liệu hai nhân vật test15/test14 được sao lưu mới, kiểm tra sau khi thoát và phải phục hồi nguyên BSON trước publish. Không chuyển cài đặt âm thanh thử nghiệm từ candidate sang Play.

Bằng chứng từng lượt, kể cả lượt thất bại, nằm ở `Build/Logs/2026-09-28-settings-friends-titles`. Công cụ publish kiểm tra đúng hash EXE/DLL, overlay và manifest của ba lượt cuối, cùng bằng chứng khôi phục dữ liệu. Trạng thái phát hành cuối cùng đọc tại `release-report.json`; khi file chưa tồn tại thì chưa được publish.


## Kết quả phát hành

Đã publish vào `Build/world-gui/stage-play-21/Play.cmd` lúc **05:11:41 ngày 28/09/2026**.

- Game SHA256: `bc0dea97326f6fc29478ae3c4577f6ffc8b215a6a63f3c366dcea08af94d48e6`.
- Candidate: `stage-community-28`; Game build `build-game-15.log`, UI build `build-ui-3.log` đều đạt. 8 file overlay nguồn được đặt ở cả Pre/Post; không ghi vào CanonicalCY.
- `live11` / mode 1: **PASS**, 141 giây. Áp dụng/Hủy/Esc, mixer, capture/khôi phục phím; thêm/chuyển/chặn/bỏ chặn/xóa/thêm lại bạn; thông tin bạn; chọn danh hiệu; dữ liệu và hình tên trên nhân vật; di chuyển.
- `live12` / mode 2: **PASS**, 111,2 giây. Đăng nhập lại thấy cài đặt, bạn nhóm 2 và danh hiệu đã chọn; ẩn danh hiệu, xóa bạn, thoát sạch. DB xác nhận title rỗng và friends rỗng.
- `live13` / mode 3: **PASS**, 105,1 giây. Đăng nhập tiếp thấy trạng thái ẩn/xóa được giữ; di chuyển và thoát sạch.
- Cả ba phiên cùng Game SHA và cùng manifest `8d950d13ee63dae23ae312f084cd3c0a3ec7a09f0c7da4270ce7b05d2c0170b6`; không có lỗi probe/Lua/packet hay crash. Các lượt thất bại trước đó được giữ nguyên trong hồ sơ.
- Unit: 286 kiểm tra quan hệ + 15 kiểm tra danh hiệu = **301 kiểm tra đạt**. Unit kiểm thuộc tính dùng hàm server thật với dữ liệu cấu hình kiểm soát, không thay cho cân bằng toàn bộ danh hiệu.
- Hai nhân vật test15/test14 được phục hồi nguyên BSON và đối chiếu lại sau publish. WXSystem.cfg của Play không đổi; không mang thiết lập mute của candidate sang Play.
- Server CY riêng: tất cả dịch vụ và cổng trong status đạt; bảy file nguồn khớp hash đã áp dụng; log Game mới nhất không có Lua call error/stack traceback. Chi tiết `server-final-health.json`.
- Sao lưu Play: `C:/TLBB/085/CY-Source/Build/backups/community-play/20260928-051141`.
- Hồ sơ cuối: `Build/Logs/2026-09-28-settings-friends-titles/release-report.json`, `final-verification.json` và `fixture-restore.json`.

Các giới hạn đã nêu ở phần Cài đặt/Bạn bè/Danh hiệu vẫn còn hiệu lực; phát hành này không xác nhận các dịch vụ IM, thư hay mọi tùy chọn render của CY mới đã được chuyển đổi.
