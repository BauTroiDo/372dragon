# Chiến đoàn, chia EXP, bang hội và giao diện — 28/09/2026

Phạm vi thực thi là CY build từ source và máy chủ riêng `/home/ubuntu/cys-test-20260913`. Không sửa máy chủ TLBB chính, client GL hoặc dữ liệu CanonicalCY. Đã đưa bản kiểm chứng từ `Build/world-gui/stage-social-completion-28` vào Play lúc **10:01:10, 28/09/2026** (giờ Việt Nam). Chạy bằng `Build/world-gui/stage-play-21/Play.cmd`. Bằng chứng là `Build/Logs/2026-09-28-social-completion/release-report.json`; bản Play trước đó được lưu tại `Build/backups/social-completion-play/20260928-100110`.

Đây là đợt sửa các luồng đã nêu bên dưới, không phải xác nhận toàn bộ thành bang/phúc lợi nâng cao đã hoàn thiện. Danh sách giới hạn ở cuối tài liệu vẫn áp dụng cho bản phát hành.

## Nguồn đối chiếu và thay đổi

- Chiến đoàn dùng giao thức CY hiện có, tối đa 30 người, 5 tổ × 6 người. `GCRaidList` là danh sách phẳng có chỉ số tổ/ô trong từng bản ghi; bộ sinh trước đây không giải mã được cấu trúc này. Override mới giới hạn số người, độ dài tên, chỉ số, vị trí quyền và GUID trùng, rồi ghép lại 5 tổ.
- `cys_social_world.lua` kiểm tra quyền trên máy chủ cho tạo đoàn từ đội, mời, xin vào, trả lời, chuyển tổ, bổ nhiệm, đuổi và rời đoàn. Lời mời gắn với phiên người gửi/người nhận và chiến đoàn, hết hạn sau 60 giây, tiêu thụ một lần. Khi trưởng đoàn rời, ưu tiên trợ thủ làm người kế nhiệm. Người gửi không được tự khai GUID thao tác.
- Client dùng cửa sổ `UnionFrame`, `UnionChoose` và HUD CY. `CysRaidNet` lưu danh sách, vai trò, HP/MP, ngoại hình và trạng thái cảnh; danh sách đầy đủ thay thế danh sách cũ, tránh lưu thành viên đã rời. Sự kiện cập nhật phải truyền `-1,-1,1` theo Lua gốc. Bổ nhiệm dùng đúng thứ tự `(vai trò, tổ, ô)`; GUID từ menu có thể là chuỗi số và được đọc đúng. Chọn thành viên kiểm tra GUID của đối tượng để tránh chọn nhầm khi mã đối tượng cảnh được tái sử dụng.
- `Player:GetGUID()` được nối với GUID thật. Trước đó nhiều giao diện bang/đoàn/liên minh so sánh quyền với kết quả của một hàm tạm.
- `Player:GetData("GUILDLEAGUE")` đọc tư cách liên minh từ gói thuộc tính của chính nhân vật và phản hồi liên minh. Nút `OpenNewGuildWarDlg` trên các trang bang hội được nối với giao diện bang chiến; phiên thử phải bấm nút thật, không chỉ gọi một host tương đương.
- Chuyển cảnh theo đội giữ điều kiện của cổng: cấp, trạng thái nhiệm vụ, thương phiếu, song nhân cưỡi. Sau những lời gọi có thể nhường luồng, phải kiểm tra lại đúng đối tượng, đúng đội, trạng thái theo sau và còn sống. Danh sách trùng hoặc thành viên chưa vào cùng cảnh bị từ chối trước khi chuyển.
- Chia EXP giữ công thức của server. Loại bản ghi người nhận trùng và người chết; chế độ chia vẫn được lấy từ người nhận hợp lệ nếu đội trưởng đứng ngoài phạm vi. Một lần chết của quái chỉ được phát thưởng một lần, và cờ này được xóa khi quái hồi sinh. Quy tắc gốc không phát EXP/thưởng thông thường khi quái thuộc chiến đoàn vẫn tồn tại; chưa thay thế bằng công thức riêng cho 30 người.
- `cys_social_guild.lua` bao quanh thao tác bang/liên minh bằng khóa hàng đợi server, kiểm tra quyền trước khi tiêu phí, chặn mục tiêu không tồn tại, tuyên chiến trùng và tuyên chiến đồng minh. Yêu cầu chiến tranh chưa nhận cũng hết hạn. Mã thao tác chiến tranh không hợp lệ không được làm phát sinh assert.
- Danh sách chiến tranh được gửi lại sau khi RPC xử lý xong, tránh yêu cầu đọc đồng thời trả về dữ liệu trước thao tác. Danh sách chọn mục tiêu trong Lua đọc đúng bộ dữ liệu mà yêu cầu danh sách bang chiến nhận được.
- Liên minh dùng danh sách tối đa 3 bang như giao diện và gói tin hiện có. Bang đang chờ duyệt không được tính là thành viên hoặc được kế nhiệm minh chủ. Client nối tạo, danh sách, xin vào, duyệt, đuổi, rời và thông tin; dữ liệu thành/tên/ngày lập được hỏi bằng gói thông tin bang, không điền số giả.
- Quỹ bang đọc và ghi thống nhất `founded_money`; điểm cống hiến đọc từ đúng thành viên. Trừ điểm không làm giảm tổng cống hiến đã kiếm được; cấm âm, tràn số và giá trị không hữu hạn.
- Thương nhân: đủ quỹ mới cấp phiếu; sửa thứ tự giá trị/kiểu khi ghi tham số phiếu; hoàn quỹ khi túi đầy hoặc không thêm được phiếu; phải xóa phiếu thành công mới phát thưởng. Khóa trên người chơi ngăn bấm lặp trong lúc chờ RPC. Đây không phải giao dịch phân tán chịu mất điện giữa hai dịch vụ.
- Quan tâm bang: trừ thành công 1 điểm cống hiến rồi mới ghi ngày nhận/phát buff. Cấp 161–200 dùng bậc cao nhất đã có (buff 30005, như cấp 150–160), không tạo chỉ số mới. Truy vấn bảo trì đọc thành đã lưu; thành cũ chưa có trường trạng thái tiếp tục trạng thái thường, không tự suy ra hoặc thu phí bảo trì mới.
- `CityGetBuildingLevel` tra loại công trình trong `CityBuilding` rồi đọc cấp công trình đã lưu, thay cho trả cố định 1. Loại công trình và chỉ số vị trí đặt mô hình là hai miền ID khác nhau.
- Nhiệm vụ 442/443 trước đây xóa nhiệm vụ và trừ 50.000 đơn vị cơ sở rồi gọi `CityIncProgress` chưa tồn tại. Khi thiếu API tiến độ, nay không nhận/nộp nhiệm vụ và không tiêu tiền; 8 kiểm thử riêng xác nhận cả yêu cầu nhận trực tiếp và nộp lặp không chạm tiền/nhiệm vụ. Đây là chặn mất tài sản, không phải đã hoàn thiện xây dựng/nghiên cứu.
- Bố cục thông tin bang và quan chức được sinh từ overlay hiệu lực của Play. Giữ skin CY, tăng chiều cao dòng và chia chiều rộng nhãn/giá trị. Không bật GLResponsive.
- Sửa thêm bảng liên minh và bang chiến: tiêu đề cột tiếng Việt, dữ liệu danh sách đúng nguồn, ngày lập/ngày vào nằm dưới bảng liên minh, nhãn và điều khiển không chồng nhau. Khung chính rộng 750 để không buộc người chơi dùng cửa sổ lớn hơn 800 pixel.

## Kiểm thử và tái lập

- `Tools/server/social_completion.py plan`: sinh staging từ bản nguồn đã sao lưu và các module thuộc dự án. `apply` yêu cầu máy chủ riêng đã dừng, kiểm hash trước/sau và sao lưu file bị thay.
- `Tools/server/test_social_suite.py`: chạy kiểm thử cô lập đối với mã thật; kết quả trong `Build/Logs/2026-09-28-social-completion/server-regressions.json` và các log cùng thư mục. Có 8 nhóm: đội, bang cơ bản, chiến đoàn, bang nâng cao, thương nhân/phúc lợi, EXP, chuyển cảnh, truy vấn thành.
- Lượt kiểm thử server sau sửa cuối: 172 trường hợp (27 + 32 + 25 + 27 + 37 + 6 + 10 + 8), tất cả qua; 16 file server qua `luac -p`. Không dùng trình biên dịch Lua server để đánh giá LuaPlus client.
- Protocol: `cys_protocol_tests --unit`, gồm danh sách 30 thành viên, round-trip, cắt ngắn từng byte, GUID trùng, chỉ số tổ sai và danh sách rỗng.
- Client: `run_world_gui_live.ps1 -PartyGuildProbe` chế độ 1 (đội/tạo bang), 5 (thông tin/quan chức), 6 (chiến đoàn hai người), 7 (liên minh/danh sách chiến tranh). Mỗi phiên phải thoát sạch, không lỗi Lua, không lỗi giải mã và nhân vật vẫn di chuyển được. Các phiên thất bại ban đầu được giữ nguyên để truy vết.
- `Tools/server/social_fixture.py` lưu trọn BSON hai nhân vật test trước khi sửa. Sau thử phải phục hồi đúng toàn bản ghi, xóa đúng bang/liên minh do bộ thử tạo, khởi động lại và đọc xác nhận lần nữa.
- `Tools/game/deploy_social.py publish` kiểm bốn chế độ trên cùng hash Game/manifest, bản phục hồi fixture và hash server. Không thay profile cá nhân. Bằng chứng phát hành nằm trong `release-report.json`.

### Bằng chứng client cuối cùng

Game.exe: `fae39743edb1c52e876a7ee2720e64d8325df70e93c7aa90221d178faa0d5745`, được build bằng `build-game-11.log`. Tám file giao diện được sinh bằng `Tools/game/social_ui.py` và đặt ở cả Pre/Post overlay.

| Chế độ | Thư mục bằng chứng dưới `Build/Logs/2026-09-28-social-completion` | Kết quả |
| --- | --- | --- |
| 1 — đội và tạo bang | `gui-release-basic`, `peer-release-basic` | Qua; người chơi di chuyển, thoát sạch |
| 5 — thông tin bang, quan chức | `gui-release-officers` | Qua; đã kiểm tra ảnh nhãn/giá trị sau sửa Lua |
| 6 — chiến đoàn hai client | `gui-raid-menu`, `peer-menu` | Qua; chuyển tổ, bổ nhiệm và đuổi bằng menu CY, rời đoàn |
| 7 — liên minh và danh sách chiến tranh | `gui-release-alliance` | Qua; tạo/rời liên minh, GUID/vai trò thật, bấm nút Bang chiến, có hàng mục tiêu trong bảng |

Cả bốn `run.json` cùng hash Game và manifest dữ liệu; không có lỗi Lua, lỗi giải mã hoặc lỗi handler trong các phiên được chọn. Các phiên thử lỗi trước khi sửa vẫn được giữ nguyên. `git diff --check` với quy tắc CRLF của Windows không có lỗi khoảng trắng ở các file được kiểm tra.

Ảnh được kiểm tra ở 1280×720. Sau kiểm thử, hai nhân vật test đã khôi phục đúng toàn bộ BSON; chỉ bang `CYSQA0928` và liên minh `CYSAL0928` của bộ thử bị xóa. Đọc lại sau khởi động xác nhận dữ liệu không đổi (`fixture-verified-after-restart.json`). `server-health-final.json` ghi nhận đủ sáu dịch vụ riêng, cổng 15733/15734 sẵn sàng, không có dịch vụ trùng và 16 file nguồn đang chạy khớp hash. Log Game của lần khởi động cuối không có dòng lỗi; các lỗi kết nối ở Manager xuất hiện trước khi các dịch vụ phụ lắng nghe trong lúc khởi động và được giữ trong bằng chứng.

## Những phần chưa được chứng minh hoàn chỉnh

Không đồng nhất việc mở cửa sổ hoặc nhận một gói tin với hoàn thành cả hệ thống.

- Cửa sổ tổ chiến đoàn tách rời và toàn bộ biểu tượng buff chưa được nối đầy đủ. Menu chuột phải quản lý đoàn đã nối với các menu CY sẵn có, theo vai trò và GUID thành viên.
- Chuyển cảnh nhiều bản đồ và chia EXP hiện có kiểm thử cô lập; cần thêm phiên nhiều client thật đi qua cổng và cùng đánh quái để xác nhận đường đi xuyên suốt.
- Tuyên chiến/ứng chiến, danh sách và quyền có kiểm thử; chưa có trận bang chiến đầy đủ từ mở bản đồ đến thắng/thua/phát thưởng trong đợt này.
- Thành bang nâng cao còn các API xây dựng, nghiên cứu, thương lộ, bảo trì định kỳ và phúc lợi dạng công tắc chưa được chuyển đầy đủ. Không bật các menu thử nghiệm đặt thẳng cấp công trình 0–4 và không tự tạo chi phí.
- Đã tìm được bảng `Condition.txt` trùng giữa bản 085 và `Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Config`. Điều kiện 72–75 nâng huyện nha lần lượt yêu cầu quỹ 2/4/8/16 triệu đơn vị cơ sở, 100/200/400/800 nhiệm vụ và 100/200/400/800 điểm mở rộng. Máy chủ riêng chưa nạp bảng này. Chỉ thêm nút nâng cấp mà bỏ phần nhiệm vụ sẽ sai cơ chế gốc.
- Lua liên minh có chức năng đổi lời tuyên ngôn nhưng server/giao thức hiện chưa có handler tương ứng `CGWGuildLeagueChangeInfo`; không coi chức năng đó là đã sửa.

Những giới hạn này phải được giữ trong báo cáo cho người dùng, không gộp thành kết luận “toàn bộ bang hội đã hoàn thiện”.
