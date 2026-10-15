# Sửa 7 lỗi gameplay/UI — 23/09/2026

Phạm vi: client CY-Source x64 và server riêng `/home/ubuntu/cys-test-20260913`
(login 15733, game 15734), là profile của `Build/world-gui/stage-play-21/Play.cmd`.
Không sửa các cây client gốc, kho dữ liệu CanonicalCY hoặc server gốc `/home/ubuntu/GameServer`.

## Thay đổi

| Lỗi | Nguyên nhân và cách sửa |
|---|---|
| Phòng thay đồ chờ đối chiếu máy chủ | `GCUICommand` chung lấy mất phản hồi catalog 990021. Chuyển bộ xử lý catalog lên trước bộ xử lý chung. Kiểm phản hồi thật của cả 8 nhóm. |
| Khinh công sai action và bị lệnh chạy chen vào | `FreshAnimation` được gọi khi đổi đồ/idle nhưng lại tiến giai đoạn bay như sự kiện kết thúc animation. Chỉ chuyển giai đoạn ở `OnAnimationEnd`; giữ tốc độ action của khinh công; bỏ lệnh AI trong lúc bay và giữ khóa qua hết action tiếp đất. Có giới hạn chờ cho actor ngoài màn hình không có callback. |
| Nhập phái thiếu vũ khí Tân thủ | Thêm bảng vũ khí chiến đấu cấp 10 cho 15 phái vào luồng `LuaFnJoinMenpai`. Gộp với đồ NPC đã xếp hàng và kiểm sức chứa cả lô trước khi đổi phái. 11 script NPC cũ phải dừng nếu nhập phái bị từ chối. Chặn nhập cùng phái lần nữa. |
| Bấm bản đồ không di chuyển | Lua CY đăng ký `MouseLButtonClick`, widget cũ phát `MouseLClick`; host `AutoRunToTarget` còn là stub. Thêm đúng sự kiện của SceneMap, lấy tọa độ tại điểm bấm và gọi AI/navmesh thật. Kiểm tọa độ hữu hạn, trong scene và khóa khi đang khinh công. |
| Mất kỹ năng môn phái | Danh sách wire chỉ chứa chiêu đã học, còn sách cần cả danh mục chiêu chưa học và đủ 8 tâm pháp. Dựng lại danh mục theo phái, rồi phủ trạng thái đã học từ server. Lua CY nhận template ID thô thay cho cách mã hóa ID×100+level cũ. Phục hồi bộ lọc các chiêu phụ theo binary CY. Mộ Dung 788–800 là chiêu mượn tạm: giữ action khi server cấp, không đưa vào trang học cố định. |
| Esc không đóng khung | Khôi phục `CloseAllWindow()` trong xử lý Esc, giữ thứ tự xử lý nhập liệu sẵn có. |
| Màu tên sai | Ánh xạ quan hệ và trạng thái tấn công về đúng dòng SystemColour của CY. Các số enum GL 14–18 trước đây trỏ sang màu bang hoặc dòng không có trong bảng CY. |

Các chiêu chưa học vẫn chưa được phép sử dụng; hiển thị trong sách không tự cấp kỹ năng.
Danh mục 15 phái đã kiểm đủ 8 trang/phái, mỗi trang có 1–5 chiêu hiển thị.
Vũ khí khởi đầu dùng đúng loại: thương/côn, đao, kiếm, song đoản, hoàn, phiến,
nỏ, trượng, tiêu, nhận và liêm theo bảng môn phái. Không dùng vật phẩm mở huyễn hóa cấp 1 làm vũ khí chiến đấu.

## Đối chiếu màu tên

Binary CY tham chiếu: `Build/re/cy-oracle/CYGame/Bin64/Game.exe`, hàm
`GetNameWithColor` tại `0x1405db420`; bản disassembly nằm trong thư mục bằng chứng.
Đối chiếu thêm SystemColour từ client, client_GL, DataCY31-08-26 và CYHJ091026:
cả bốn nguồn đều có cùng ba cặp màu dưới đây.

| Loại | Dòng | Màu chữ | Màu viền |
|---|---:|---|---|
| NPC hòa bình | 3 | `ffffff` | `2727ff` |
| Quái chủ động đánh | 4 | `ff0000` | `880000` |
| Quái không chủ động đánh | 5 | `ffff00` | `888800` |

Do đó trí nhớ “NPC vàng không viền” không trùng các bản dữ liệu hiện có.
Bản sửa giữ màu có chứng cứ, không đổi bảng màu để khớp trí nhớ. Màu khi có
người tấn công dùng dòng 12 như CY; quan hệ bạn/địch dùng 9/10; thú dùng 7/8.
Kiểm live ba nhánh NPC/quái bằng fixture chỉ đổi dữ liệu client rồi trả lại ngay;
chưa dùng lượt PvP hai tài khoản để khẳng định toàn bộ tổ hợp chiến đấu.

## Bằng chứng kiểm tra

Tất cả nằm dưới `Build/Logs/2026-09-23-user-fixes/`.

- `live-final-01`: bản cuối, PASS 20/20 kiểm tra vòng đăng nhập/thế giới/thoát,
  162,4 giây, exit 0; mode 1, 2, 3 đều `errors=0`.
- Sách Võ Đang: số ô ở 8 trang là `3,4,3,4,4,3,4,2`; 13 chiêu đã học và 23 chiêu
  chưa học; đóng bằng Esc và đi lại được sau khi đóng.
- `live-murong-01`: PASS 20/20, mode 1 `errors=0`, 106,4 giây. Đủ 8 trang
  `3,4,3,4,4,3,3,2` khi server còn cấp chiêu mượn 788. Toàn bộ document test15
  được phục hồi và kiểm bằng nhau sau khi thoát; không giữ fixture trên server.
- Bản đồ: bấm widget thật qua CEGUI, Lua `AutoRunToTarget` nhận tọa độ, nhân vật
  đi tới điểm trên bản đồ rồi quay lại vị trí đầu; không gọi thẳng hàm di chuyển để thay phép thử cú bấm.
- Khinh công cơ bản 34: action `168/169/170`, đủ cất mình → bay → tiếp đất;
  lệnh chạy và nhảy trong lúc bay bị từ chối, cả sau cửa sổ gửi lệnh 500 ms;
  `landing-complete` xuất hiện trước khi mở khóa, đúng điểm đến ban đầu.
- Phòng thay đồ: cả 8 nhóm có `server-snapshot pass=1`, `RESULT errors=0`;
  nhân vật vẫn đi lại sau khi đóng.
- `catalog-audit.json`: bảng dữ liệu thật của 15 phái, 8 trang/phái và toàn bộ ID vũ khí khởi đầu.
- `starter-test.txt`: chạy các hàm Lua nhập phái/cấp đồ thật trong scene mô phỏng;
  15 phái, túi đủ, túi thiếu một ô, nhập lại và gọi phát đồ lại; PASS.
- `starter-npc.json`: 8 luồng script NPC với registry thật; PASS. Đây là kiểm
  mô phỏng script, không phải 8 lần tương tác GUI.
- `starter-live/result.json`, `starter-live/verification.json`: tài khoản test15
  tới NPC Võ Đang, chọn `12006/0` rồi `12006/3`, server cấp đúng
  `[10124004,30501001,10102001]`, 6 tâm pháp, 30 kỹ năng; thoát được xác nhận.
  Đã phục hồi toàn bộ document test15 và kiểm bằng nhau với bản sao ban đầu.
- `server-final-status.json`: 6 tiến trình server riêng khỏe, không trùng PID,
  16/16 cổng LISTEN. `menpai_starter_fix.py verify`: đúng hash 13 file đã triển khai.

Lượt baseline phòng thay đồ ở Play21 có lỗi chờ snapshot. Các lượt phát triển
`live-map-01..03` chưa đạt; `live-map-04` đạt sau khi liên kết/copy đúng DLL
CEGUIFalagard (target static `cys_falagardex` riêng chưa đủ để cập nhật DLL).
Không coi PASS vòng thế giới chung là PASS của một chức năng con.

## Triển khai và hoàn tác

Server đã sao lưu trước khi áp dụng tại:
`/home/ubuntu/cys-test-20260913/backups/menpai-starter-20260923T001615Z`.
Không thay Mongo/MQTT, không sửa khu/server gốc. Server riêng đã khởi động lại
và kiểm tra nhập phái qua giao thức thật.

`Tools/game/publish_gameplay_fixes.py` chỉ cho phát hành đúng hash Game.exe và
manifest đã kiểm, có đủ kết quả kỹ năng/bản đồ/khinh công/phòng thay đồ, không
có Lua failure hoặc kiểm tra chức năng thất bại. Công cụ sao lưu 6 binary/PDB,
manifest và launcher trước khi cập nhật Play21; giữ hồ sơ người chơi.
Không bật GLResponsive. Launcher xóa các biến môi trường thử nghiệm.

Đã phát hành lúc 07:50 ngày 23/09/2026 vào Play21. Bản sao client:
`Build/backups/gameplay-fixes-play/20260923-075005` (có `deployment.json`
ghi hash trước/sau và đường dẫn bằng chứng). Báo cáo kiểm sau triển khai:
`Build/Logs/2026-09-23-user-fixes/play-final-01/run.json`.
Lượt này PASS 20/20 trong 104 giây, exit 0, thoát được server xác nhận,
không có Lua failure; chạy đúng binary đã kiểm và không bật các probe chức năng.

Quan sát ngoài phạm vi: lúc đọc trạng thái server gốc, `mongod` và `mosquitto`
active nhưng unit `tlbb-game` báo failed dù status.sh vẫn thấy bốn PID gốc.
Không khởi động lại hoặc sửa hệ gốc trong tác vụ CY này. Log khởi động server
riêng có lỗi kết nối cluster trước khi DataCenter lên và thiếu monster 49285–49289;
không che các dòng này. Sau nạp scene và các lượt kiểm, không có traceback mới
liên quan bản sửa nhập phái.
