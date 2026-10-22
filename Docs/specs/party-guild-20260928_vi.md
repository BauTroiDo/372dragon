# Tổ đội và bang hội CY — 28/09/2026

Trạng thái: **đã phát hành lúc 06:59 ngày 28/09/2026** vào `Build/world-gui/stage-play-21/Play.cmd`. Bằng chứng phát hành: `Build/Logs/2026-09-28-party-guild/release-report.json`.

Game SHA-256: `35f0d49a5180f287db8f633b7cf226eceb7b4fcd9f814a8663a192c09eaac86b`.
UI_CEGUI.dll SHA-256: `9f39c3de1210c3bc7a2de2b59ed0bc52038b40017ee9fa94dc134d671c3e504e`.
Backup Play: `Build/backups/party_guild-play/20260928-065956`.

## Đích sửa và nguồn đối chiếu

- Client từ source: `Src/Client/WXClient`, CEGUI/Lua bridge tại `Src/Client/CEGUISystem`.
- Giao diện đối chiếu: Lua/layout CY hiện có trong `Assets/CanonicalCY/Data/InterfaceFolder`, cùng overlay Play đang dùng. Không sửa trực tiếp CanonicalCY hoặc client GL.
- Server CY riêng: `/home/ubuntu/cys-test-20260913`, WSL `TLBB`, login/game `15733/15734`. Không đổi server chính `/home/ubuntu/GameServer`.
- Dữ liệu nhân vật ở `tlbb.character`; dữ liệu bang ở **`world_10.guild`**. Hai collection thuộc hai database khác nhau.

### Tổ đội

`CysPartyNet` chuyển lệnh native sang packet CY và đưa phản hồi vào `CTeamOrGroup`. Các event phải dùng tên của giao diện CY: `TEAM_REFRESH_DATA`, `TEAM_UPDATE_MEMBER`, `TEAM_NOTIFY_APPLY`, `TEAM_OPEN_TEAMINFO_DLG`.

- Tạo đội, mời/xin vào, chấp nhận/từ chối, đề nghị mời qua đội trưởng, rời đội, đuổi thành viên, đổi đội trưởng, giải tán và tùy chọn EXP đã được nối với trạng thái server.
- Roster thay thế toàn bộ danh sách, không cộng dồn khi tải lại. Thông tin thành viên cập nhật HP/MP, vị trí, ngoại hình và model của khung đội.
- Lời mời/đơn xin có thời hạn 60 giây, gắn với đúng phiên và đúng tổ đội; kiểm quyền đội trưởng, giới hạn sáu người, lời mời đã dùng và cài đặt từ chối mời.
- Rút gọn nhãn nút; tên môn phái và cấp không còn dùng chung một hàng quá hẹp.

Các thao tác theo đội đã được nối giao thức; chưa có kiểm thử di chuyển theo đội đa bản đồ trong đợt này. Tùy chọn EXP đã kiểm phản hồi server; chưa đo phân phối EXP khi nhiều người cùng hạ quái. Raid/chiến đoàn và bảng tuyển đội nâng cao không thuộc phần đã nghiệm thu.

### Bang hội

`CysGuildNet` cấp dữ liệu thật cho khung danh sách, tạo bang, thành viên, đơn xin, bổ nhiệm và thông tin bang. Cache danh sách quan chức công khai tách khỏi cache bang của bản thân để việc xem bang khác không làm đổi quyền.

- Nút **Lập bang** trong danh sách bang: cấp 40, phí 500.000 đơn vị tiền cơ sở = **50 Võ Thạch thượng phẩm**. Xác nhận trước khi gửi; phí chỉ được giữ khi tạo thành công. Lỗi từ chối thông thường hoàn lại phần đã giữ; chặn thao tác tạo trùng trong lúc đợi RPC.
- Xin vào chỉ tạo đơn chờ, không tự cấp quyền thành viên. Cấp tối thiểu 10. Duyệt, từ chối/loại, bổ nhiệm, rời bang, nhường chức và sửa tôn chỉ đều qua kiểm quyền ở server.
- Sửa lỗi kiểm tên trùng, cấp ID mới theo ID lớn nhất, đọc `attrib.guild_id` của người ngoại tuyến, cập nhật guild/title đúng người và không ghi đè dữ liệu actor đang online bằng đường cập nhật offline.
- Khôi phục biến cục bộ chứa danh sách chức vụ trong hàm server `guild_appoint_info`; biến bị comment khiến truy vấn bổ nhiệm không trả được kết quả. Danh sách bang chỉ đếm thành viên chính thức, không cộng đơn chờ vào số người.
- Loại bỏ ký tự xuống dòng cuối do ô nhập nhiều dòng CEGUI tự thêm; vẫn giữ xuống dòng chủ động bên trong tôn chỉ. Kiểm giới hạn byte theo packet và buffer native.
- Nới khung thành viên, rút gọn nhãn, sửa tiêu đề cột và xóa số mẫu trước khi điền dữ liệu.

Bang chiến, thành bang, liên minh, đấu giá/phúc lợi, hoạt động và điểm trang bị nâng cao còn phụ thuộc các host/backend khác. Việc mở được các khung đó không phải bằng chứng chức năng đã hoạt động. Chưa chứng minh giao dịch tạo bang có thể phục hồi tự động nếu cả RPC tạo và RPC tra cứu kết quả cùng hỏng; các kiểm thử phí hiện tại bao phủ thành công, từ chối và gửi lặp, không mô phỏng mất điện/crash giữa các dịch vụ.

### Lỗi bảng CEGUI dùng chung

- `AddNewItem` từng yêu cầu ảnh `Common/HoverTextBak` của client cũ; chuyển sang ảnh `CommonFrame/CommonEditBoxBK` có trong CY.
- Bổ sung `SetSelectItem(row)` với kiểm biên. `GetSelectItem()` trả **chỉ số dòng**, thay vì ID của ô/cột. Điều này tránh chọn dòng thứ hai mà lại thao tác lên dòng đầu.
- `AddTextItem` của combobox đi qua bộ xử lý chuỗi hiện có để các khóa từ điển hiển thị thành chữ.

## Kiểm thử và phát hành

- Kiểm thử module server: `Tools/server/party_test.lua` — 27 kiểm tra; `Tools/server/guild_test.lua` — 32 kiểm tra, có nạp hàm trả danh sách chức vụ từ manager thật. Đây là kiểm thử logic với transport/RPC giả lập, không thay thế GUI.
- Probe GUI trong `CysPartyGuildProbe.h` chỉ chạy khi có biến môi trường thử. Các chế độ: (1) đội hai người và tạo bang; (2) gửi đơn; (3) duyệt ngoại tuyến, bổ nhiệm và chọn dòng thứ hai; (4) đăng nhập phó bang chủ, từ chối sửa tôn chỉ vượt quyền và rời bang; (5) bang chủ kiểm danh sách, thông tin và quan chức công khai.
- Sau mỗi phiên: đóng khung, bấm đi bộ, xác nhận vị trí thay đổi và thoát bằng giao thức. Lưu marker riêng, Lua/packet errors, ảnh và hash EXE/manifest.
- Fixture chỉ dùng `test15`/`test14`; sao lưu toàn BSON trước khi sửa. Thư chào mừng nằm trong `mail_list` của bản ghi nhân vật nên cũng được phục hồi cùng BSON. Xóa bang thử đúng tên/chủ bang, khởi động lại cache server riêng rồi kiểm tra lại equality.
- `Tools/game/deploy_party_guild.py` chỉ publish khi cả năm chế độ đạt trên cùng Game/manifest, fixture đã phục hồi, server còn đúng hash và Play chưa bị thay đổi. Có backup trước khi chép; giữ profile người chơi và junction Data.

Bằng chứng của đợt nằm trong `Build/Logs/2026-09-28-party-guild`. Giữ nguyên các lần thất bại để phân biệt lỗi sản phẩm với lỗi thiết lập phiên thử. Danh sách phiên nghiệm thu cuối, hash Game và đường backup được ghi trong `release-report.json`.

| Phiên cuối | Chế độ | Kết quả |
|---|---:|---|
| `gui-9` | 1 | Hai người vào đội; HP/model; tải lại không trùng; nút đuổi/giải tán; lập bang, trừ phí một lần |
| `gui-10` | 2 | Chọn đúng bang và gửi đơn, chưa tự cấp tư cách thành viên |
| `gui-11` | 3 | Đăng nhập lại bang chủ; duyệt người ngoại tuyến; sửa tôn chỉ; bổ nhiệm phó bang chủ; chọn dòng thứ hai đúng người |
| `gui-12` | 4 | Đăng nhập lại đúng chức vụ; server từ chối sửa tôn chỉ vượt quyền; xác nhận rời bang |
| `gui-13` | 5 | Danh sách còn một người; xem thông tin/quan chức; quyền và cache bang của mình không bị đổi |

Cả năm phiên dùng cùng hash Game và manifest, marker `errors=0`, không lỗi Lua/packet handler, có kiểm di chuyển sau đóng khung và thoát sạch. Kiểm logic server: 27 tổ đội + 32 bang hội. Ảnh đã được xem; khung thông tin bang/quan chức vẫn còn một số nhãn dài bị cắt, chưa phải đợt chỉnh toàn bộ bố cục các tab nâng cao.

`fixture-verified-after-restart.json` xác nhận bằng đọc lại rằng toàn bản ghi của cả hai nhân vật khớp backup, bang thử không còn sau restart. `server-final-status.json` xác nhận sáu dịch vụ riêng chạy đúng PID, không trùng tiến trình, login/game đều lắng nghe. Các log `nohup_2.out`/`nohup_8.out` của đợt cuối không có traceback/lỗi đối số hoặc lỗi module mới trong bộ lọc kiểm tra đã lưu ở `final-server-errors.txt`.
