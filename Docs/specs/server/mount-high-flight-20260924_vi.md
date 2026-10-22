# Bay cao trên thú cưỡi — 24/09/2026

Phạm vi: client CY-Source và máy chủ riêng `/home/ubuntu/cys-test-20260913`,
cổng 15733/15734. Thư mục `client_GL`, dữ liệu CanonicalCY và máy chủ gốc chỉ dùng
để tham khảo. Điểm vào của người chơi: cưỡi thú hỗ trợ, giữ **Ctrl + bấm chuột trái
xuống nền bản đồ**; lặp lại để hạ cánh.

Bản Play hiện tại đã cập nhật **22:17:55 ngày24/09**, Game SHA256
`63576a979f52b2e8fe25b5ab9094f3f89e05b6962c9e7c9f5bab41ace2769032`.
Chi tiết lượt hoàn thiện động tác và sửa kiểm tra hạ cánh nằm ở phần cuối tài liệu;
lượt publish20:43 bên dưới là lịch sử của bản trước.

## Bằng chứng của CY

Đã phân tích tĩnh, không sửa binary tham khảo:


**Đính chính tài liệu 17–18/09:** cột22 và hình thú lơ lửng sát đất không chứng minh
chức năng bay cao đã hoạt động. Cột19 mới là điều kiện cất cánh của native CY.
Các phép thử “bay” trong `ride-data_vi.md` và `ride-finish_vi.md` trước đây chỉ xác
nhận model/hover. Nguồn GL cũ và Game CY3.71 là hai binary khác nhau.

## Phần đã triển khai

- Ctrl + chuột trái trên nền: khi đang cưỡi, xử lý bay cao; khi đi bộ, giữ luồng khinh công.
  Nhánh bay cao ưu tiên hơn kỹ năng đang chọn có mục tiêu mặt đất; bấm trong UI vẫn do UI xử lý.
- Điều kiện thú lấy từ 103 dòng CharMount có cột19 hợp lệ. Không cấp quyền chỉ vì cột22 > 0.
- Nạp lưới `.fly` theo scene, nội suy độ cao, giữ bên trên mặt đứng thực tế.
  Có 181 mục SceneDefineEx khớp lưới trong dữ liệu hiện có; bản đồ thiếu/hỏng lưới từ chối bay.
- Máy chủ xác thực actor, mount đang cưỡi, scene, trạng thái sống/điều khiển/bày hàng/theo đội,
  thao tác đang chạy, chu kỳ cất/hạ cánh và tọa độ hữu hạn trong biên scene.
- Cất/hạ cánh trong2 giây với nội suy mượt; khóa di chuyển/động tác cả ở client lẫn server.
  Khi trên không được di chuyển theo mặt phẳng bay, không bị navmesh mặt đất cản đường.
  Hạ cánh cần vị trí mặt đất đi được; sau đó mới xuống hoặc đổi thú được.
- Chặn kỹ năng của người đang bay và vật phẩm tác động lên người đang bay. Kiểm tra mục tiêu
  ở cả chọn mục tiêu và lúc đánh trúng. Lạc Mã Tiễn37 được giữ làm ngoại lệ từ mặt đất.
- Chặn đổi thú, hủy buff cưỡi và bắt đầu theo đội khi còn bay. Cần thoát theo đội trước khi cất cánh.
- Trạng thái bay được broadcast và gửi khi người khác vào AOI; có thời gian chuyển tiếp còn lại.
  Chết, mất mount, đăng nhập/chuyển scene xóa trạng thái tạm. Callback cũ không làm sống lại trạng thái đã xóa.
- Cập nhật lại chiều cao ngay khi xuống thú; không phải di chuyển mới hết offset hover.
- Khi cưỡi thú phù hợp, hiện hướng dẫn phím tắt trong game.

Phần tương thích với server hiện có: request dùng đúng CGFlyOperation2242 native;
server085 thiếu phần mở rộng flight của GCCharBaseAttrib CY nên phản hồi/AOI dùng
GCUICommand990030, gồm actor/state/mount/remainingMs. Hai phía đều được build/cài từ
nguồn. Bốn trạng thái0/1/2/3 và đường nội suy2 giây là quy ước của phần port; chưa
khẳng định timing/animation native CY trùng tuyệt đối. Hiện xử lý người cưỡi đơn;
chưa port việc mang cả đội nhiều người trên một thú bay.

## Nguồn và cách cài lại

- Client: `Network/CysRideNet.cpp`, `CysMountFlightPacket.h`,
  `World/CysFlightGrid.h`, `Scene.cpp`, `Path.cpp`, `Cursor/CursorMng.cpp`,
  `Object/Character/Obj_Character.cpp`, `AI/GMAI_MySelf.cpp`, `Object/Obj_Phy.cpp`.
- Server nguồn lưu trong repo: `Tools/server/cys_mount_flight.lua`,
  `cys_mount_flight_packet.lua`, `deploy_mount_flight.py`.
  Cài bằng `python Tools/server/deploy_mount_flight.py --out <plan> --apply`;
  kiểm syntax, chặn khi có client riêng đang nối, so hash trước ghi, sao lưu đầy đủ.
  Installer hiện tái dùng hạ tầng `deploy_equipcraft`, nên tên thư mục backup có tiền tố `equipcraft-`;
  manifest bên trong liệt kê đúng các file bay cao.
- Data server `cys_mount_flight_data.lua` sinh từ CanonicalCY, không chép thủ công danh sách thú.
- Stage/publish: `Tools/game/deploy_mount_flight.py`. Candidate `stage-mount-flight-24`;
  đích Play `Build/world-gui/stage-play-21`.
  Publish yêu cầu cả `--check <live-03-final>` và `--ground-check <live-04-ground>`,
  cùng hash Game/manifest và đúng baseline Play đã chụp trước thay đổi.

## Kiểm chứng

- Build Release x64 bằng wrapper của dự án; không dùng hook/inject DLL cho chức năng này.
- `Tools/server/test_mount_flight.lua`: **34 kiểm tra qua**, gồm native codec5byte,
  gói thiếu/thừa byte, giả actor, spam, eligibility, bản đồ, chuyển tiếp/AOI,
  tọa độ NaN/vô hạn, hạ cánh bị chặn, Lạc Mã Tiễn và callback quá hạn.
- `Tools/game/tests/mount_flight.cpp`: đọc **toàn bộ181 mục lưới thực**, cả hai header,
  kiểm biên, nội suy, dữ liệu thiếu/NaN và native request codec. Log `grid-tests.txt`.
- `live-01`: lượt thử đầu có ảnh mặt đất/cất cánh/trên không/hạ cánh/xuống thú.
- `live-03-final`: bản Game SHA256
  `1fa430fc41a5bbc159738d41a2352f104c46240d0c4d987f464570d5ec43b76d`;
  cưỡi model94, tổ hợp Ctrl được xử lý qua input + Cursor command thật, server trả trạng thái,
  có tăng độ cao, di chuyển trên không, khóa lúc chuyển tiếp, hạ cánh, xuống thú,
  di chuyển lại. Runner thoát bình thường, không dump/handler error, chỉ nối cổng server riêng.
  Điểm cuối trước/sau tháo thú Y28.66 →23.66 chứng minh hover được bỏ ngay.
- `live-04-ground`: model21, Ctrl + chuột trái bị từ chối ở client; gửi trực tiếp
  gói2242 vẫn bị server từ chối và trả trạng thái0. Xuống thú, di chuyển và thoát game bình thường.
- **Đã publish20:43:10**, backup `Build/backups/mount-flight-play/20260924-204310`.
  Kiểm lại37 binary và202 overlay của Play đều khớp manifest. BSON test15 đã được
  phục hồi toàn bộ và đối chiếu bằng nhau sau hai lượt kiểm cuối.

Vận hành sau thay đổi: server riêng đủ6 tiến trình, cổng15733/15734 LISTEN, log mới
`Game2_20260924_202218.log` ghi nhận op0/op1 và không có traceback/lỗi flight.
Theo kiểm tra AGENTS, Mongo/MQTT máy chủ gốc active, status.sh thấy bốn tiến trình gốc,
LAN192.168.1.109:5733 kết nối được. Unit `tlbb-game` của máy chủ gốc báo failed từ
15:11:28 (trước lượt sửa này); không thay đổi unit hay tiến trình gốc trong tác vụ bay cao.

Lượt GUI kiểm chuyển trạng thái/dáng/camera trên một nhân vật. AOI và mất/chết/đổi scene
được kiểm ở controller; chưa có lượt quay đồng thời hai client để đối chiếu trực quan.
Fixture chỉ dùng test15, giữ BSON gốc để phục hồi toàn bộ sau thử nghiệm.

## Hoàn thiện động tác và kiểm tra hạ cánh (lượt tiếp theo 24/09)

Đối chiếu tiếp **đúng binary CY3.71 có SHA ở trên**, không suy từ tên model:


Đã nối các action trên vào ChangeAction, giữ animation chuyển tiếp không bị
FreshAnimation/động tác đứng ghi đè, dọn lệnh cũ khi bắt đầu cất/hạ cánh. Tên animation
tra từ asset hiện có, không tự đặt hoặc tạo animation mới. Kiểm dữ liệu103 mount
đủ922–927 cho bộ động tác thú và cả hai bộ người cưỡi; log
`Build/Logs/2026-09-24-mount-flight-actions/action-assets.json`.

Lượt live đầu phát hiện lỗi thật tại Võ Đang: điểm `(72.54,103.23)` bị client coi là
vật cản, nhưng server vẫn cho hạ cánh khi gửi native packet trực tiếp. `nav_adapter`
cũ đọc navmesh theo đa giác5 điểm, và findpath(pos,pos) không chứng minh vị trí đứng
hợp lệ. Bản sửa dùng `cys_flight_nav.lua` kiểm chính tam giác và cờ blocked của CY.
File `cys_mount_flight_nav.bin` là **dữ liệu**, chứa các `.path` canonical nguyên byte
được gộp và loại trùng; không phải thư viện thực thi. Đọc lười theo scene; không sửa
nav_adapter, đường đi bộ hay các `.path` của server. Thiếu/hỏng lưới thì từ chối cất
cánh để tránh cho bay nhưng không thể xác nhận nơi hạ cánh.

Bộ kiểm tra dùng C++ PathLib của client làm oracle: **258.204 điểm trên181 mục scene**,
gồm điểm ngẫu nhiên, đỉnh tam giác và sát đỉnh. Lua làm tròn float32 theo cùng phép
toán để kết quả tại biên khớp client. Kết quả:93.957 điểm đi được,164.247 điểm bị chặn,
không sai khác; thêm kiểm dữ liệu hỏng, NaN/vô hạn và điểm lỗi live phía trên.
Controller/native packet có35 kiểm tra qua. Nguồn kiểm thử:
`Tools/game/tests/mount_flight_nav.cpp`, `Tools/server/test_flight_nav.lua`,
`Tools/server/test_mount_flight.lua`.

Candidate mới `stage-mount-flight-actions-24`; log tại
`Build/Logs/2026-09-24-mount-flight-actions`. Installer server hiện liệt kê12 file,
backup lần này `cys-test-20260913/backups/equipcraft-20260924-213427`.
Publisher chụp hash manifest Play lúc tạo candidate, yêu cầu hai lượt thú bay khác
nhau và một lượt thú mặt đất trên đúng cùng binary/manifest trước khi publish.

Kết quả live sau khi sửa server:

- `live-02-dragon`: Kim Dực mount94, có ground-hover5. Cất/hạ cánh922/923,
  đứng924, bay di chuyển927 đều được tra và đưa vào renderer.
- `live-03-kite`: 与春归 mount271, **ground-hover0**; xác nhận quyền bay không phụ
  thuộc việc model có lơ lửng sát đất hay không. Cùng quy trình bay thành công.
- Cả hai lượt thử đều đi tới vị trí có vật cản dưới đất, client từ chối hạ cánh,
  gửi trực tiếp native2242 cũng bị server từ chối; quay lại vị trí đi được thì hạ
  cánh thành công, xuống thú rồi đi bộ bình thường. PathDirect trả đường một đoạn
  xuyên vật cản mặt đất và từ chối đích ngoài scene.
- `live-04-ground`: mount21 bị cả client và server từ chối cất cánh; tháo thú/đi bộ
  vẫn hoạt động. Cả ba lượt thoát bằng giao thức bình thường, không dump hay lỗi
  packet handler, dùng cùng Game63576a… và manifest775cbc4f…; probe `errors=0`.
- `live-01-dragon` được giữ làm bằng chứng lỗi hạ cánh trước sửa server; mặc dù
  runner tổng quát ghi passed, probe flight đã báo FAIL. Không dùng lượt này để
  chứng minh chức năng đạt và không dùng làm điều kiện publish.

Đã publish**22:17:55**, backup
`Build/backups/mount-flight-play/20260924-221755`. Toàn bộ BSON test15 được phục hồi
và so sánh bằng bản gốc. Server riêng đủ6 tiến trình/các cổng; file nguồn và dữ liệu
khớp12 hash trong manifest (thực tế4 file thay đổi so với bản server trước).
Log `Game2_20260924_213830.log` ghi op0/1 cho mount94 và271; không có traceback ở
module flight. Có các lỗi khởi động MonsterAI_SetIntParamByIndex của DynamicNPC/
thiếu cấu hình quái đã có, không chỉnh trong tác vụ này. Kiểm máy chủ gốc vẫn thấy
Mongo/MQTT active, bốn tiến trình chạy và LAN5733 kết nối được; unit tlbb-game vẫn
failed như trạng thái trước tác vụ.

Giới hạn chưa đổi: server port dùng nội suy2 giây và phản hồi990030; chưa khẳng định
quỹ đạo/timing bằng tuyệt đối CY (native có thêm dịch chuyển theo hướng nhìn và
thời lượng phụ thuộc độ cao). Chưa hỗ trợ chở đội trên thú bay.
