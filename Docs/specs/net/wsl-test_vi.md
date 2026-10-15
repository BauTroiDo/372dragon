# Probe đăng nhập WSL — 13/09/2026

Người dùng đã mở phạm vi test kết nối WSL, tạo tài khoản `test00` và dùng máy chủ test độc lập khi cần. `CysNetBot` hiện thực phần nhỏ đầu tiên của P1-3/P1-4: **CLConnect → CLAskLogin → CLAskCharList → đóng socket**. Chưa thực hiện NetCore nhiều luồng, tạo nhân vật, charlogin, vào cảnh, đi lại, heartbeat hoặc đổi cảnh; chưa nối Game.exe với WSL. Vì chưa tạo session nhân vật nên probe không gửi `CGAskQuit` trên socket login.

## Hợp đồng đã triển khai

- Chỉ chấp nhận đúng tài khoản `test00`. Mật khẩu chỉ lấy từ biến môi trường `CYS_BOT_PWD`, không nhận qua argv, file hay giá trị mặc định. Xóa biến trong process con sau khi đọc; xóa nội dung các buffer mật khẩu/auth đã dùng. Từ chối rỗng, quá giới hạn 50 byte của trường account, NUL, `%` và ký tự điều khiển; không cắt cụt mật khẩu.
- Bắt buộc chỉ định IPv4 và port; không DNS, không theo địa chỉ chuyển hướng trong reply. Một socket non-blocking Winsock2 + `WSAPoll`, `TCP_NODELAY`; timeout trạng thái mặc định 10 giây, cấu hình 1–30 giây, tổng tối đa 90 giây. Không mở game socket hoặc thử lại tự động.
- CLConnect dài 110 byte, version text `tlbb`. CLAskLogin dùng profile hiện hành 949 byte: `account%password`, encrypted size 0, uVersion 0, định dạng mới, phần còn lại bằng 0 trừ MAC nhận diện riêng `CYS-test00`. Không giả mạo thiết bị thật. CLAskCharList dài 50 byte, chỉ gửi sau cờ đăng nhập 0.
- Header `{u16 id,u16 body_size,u16 idx}` little-endian. Bộ đếm phiên bắt đầu `0x7B`, idx = seq << 8; ba gói gửi dùng `0x7B00`, `0x7C00`, `0x7D00`. Chỉ tăng sau khi gửi trọn frame. RX idx là metadata, không dùng để loại gói login idx 0.
- Giải mã ProtocolGen **strict**. Chỉ ID chưa biết ở bảng Login mới tra bảng Game; ID Login đã biết nhưng decode lỗi không fallback. Từ chối chiều C→S ở đầu nhận, packet sai thứ tự và Game packet/refusal; không in nội dung script từ server.
- Cờ 1 dừng ngay. Cờ 8/21 cũng dừng, báo thời gian chờ tối thiểu 20 giây; với `uNeedWaitTime` lớn hơn thì làm tròn lên giây. Không tự thử lại, không gửi charlist khi auth chưa qua. List rỗng được xem là lấy danh sách thành công.
- Giới hạn tổng 3 TX frame, 64 RX frame, 256 KiB nhận. Assembler giữ tối đa một frame đang dở (6+65535 byte), một lần feed tối đa 65536 byte và tối đa 128 frame đầu ra. Gói lỗi/cạn thời gian/peer đóng đều giải phóng socket.
- Báo cáo `report.tsv`, `frames.tsv`, `failures.tsv`, `result.json` chỉ có ID, tên lớp, chiều, số lượng, kích thước, idx, cờ, offset/tên field lỗi và trạng thái. Không raw body, hex, mật khẩu, khóa chuyển game hay nội dung nhân vật. `--out` phải là thư mục mới bên dưới `Build/Logs`, tương đối từ **cwd CY-Source lúc chạy**, được xác nhận bằng `Src/CMakeLists.txt`, `Timeline/TIMELINE_vi.md` và `.git`. Không dùng root của compiler vì CI biên dịch trong `Build/ci/wt`. Từ chối `..`, path tuyệt đối và reparse point từ các thư mục cha của cwd đến output.

## Bằng chứng nguồn

Các điểm nguồn server dưới đây tương đối từ cây `GameServer` WSL theo đường dẫn vận hành trong AGENTS; đây là nguồn được đọc nguyên trạng, không phải file CY được sửa:

- `services/login/packet.lua:40–46`: CLConnect; `193–272`: CLAskLogin hiện hành; `293–310`: cờ login; `432–509`: charlist thành công có 55 byte đầu + 332 byte/nhân vật + 8 byte placeholder cuối.
- `services/login/logind.lua:240–294`: handshake, tách account/mật khẩu và trả Login/Status; `318–332`: auth bắt buộc trước charlist.
- `lualib/net.lua:91–112`: kiểm tra seq. Chuỗi seq liên tục đã được đo từ capture trong `Timeline/handoff/net.md`; không dùng cách reset counter về 0 của công cụ tham khảo cũ.
- `Src/Shared/ProtocolGen/PgPackets_login.{h,cpp}` và `PgFactory.{h,cpp}`: adapter dùng trực tiếp code sinh; không sửa tay ProtocolGen.

## Build và kiểm thử offline

Chạy qua wrapper `.cmd` để giữ nguyên dấu `;` trong danh sách component:

```bat
set CMAKE_BUILD_PARALLEL_LEVEL=2
call Tools\build\build.cmd x64 gpt-netbot-20260913 Release "protocolgen;netbot"
Build\cmake\gpt-netbot-20260913\bin\cys_netbot_tests.exe
```

```powershell
& 'C:\Program Files\Python313\python.exe' -B Tests/net/run_login_probe_tests.py --out Build/Logs/2026-09-13-gpt-netbot/loopback-NEW
```

- C++: **27/27 ca**, gồm mọi vị trí tách header/body, frame gộp/rỗng/cỡ tối đa, trần input/output, strict trailing/short/unknown/direction, state/flags và **100.000 đầu vào fuzz**. Đây là fuzz của assembler/probe nhỏ, không thay DoD NetCore hoặc replay capture 1699 frame.
- Loopback riêng: **10/10 ca** chạy executable thật với listener tạm `127.0.0.1` do test sở hữu: thành công, cờ 1/8/21, known short/trailing, unknown ID, list từ chối, timeout, peer đóng. Thêm **5/5 guard cwd/path**, xác nhận bị từ chối trước khi connect. Kiểm đúng seq/949B/không retry/socket đóng và không rò credential fixture vào tất cả báo cáo/stdout/stderr. Không kết nối WSL trong test này.
- Evidence cuối: `Build/Logs/2026-09-13-gpt-netbot/unit-tests-final.log`, `loopback-root-fix/summary.json`. `build-4.log` build thành công với 1 job, không warning. Thử loopback đầu dùng fixture charlist thiếu placeholder 8 byte cuối, strict decoder bắt đúng; fixture đã sửa theo source server, không nới codec. `build-1.log` là lần wrapper bị tách tham số component, không phải lỗi C++.

## Lệnh chạy máy chủ test

Root phiên làm việc chịu trách nhiệm khởi tạo máy chủ, tạo tài khoản và cung cấp môi trường mật khẩu; không ghi giá trị mật khẩu vào lệnh/tài liệu. Với endpoint test đã được kiểm tra:

```powershell
& Build/cmake/gpt-netbot-20260913/bin/CysNetBot.exe --host 127.0.0.1 --port 15733 --account test00 --out Build/Logs/2026-09-13-gpt-netbot/wsl-NEW
```

Chỉ chạy khi process con đã có `CYS_BOT_PWD`. Mã thoát 0 nghĩa là xác thực và charlist đạt; không đồng nghĩa vào được thế giới hoặc Game.exe đăng nhập được.

## Kết quả máy chủ test độc lập

Root đã chạy một lần tới `127.0.0.1:15733`: **exit 0, login flag 0, danh sách 0 nhân vật, 14 ms, 3 TX/4 RX, 0 lỗi decode, 0 byte dở, 0 retry, socket đóng**. TX dùng đúng ba idx `0x7B00/0x7C00/0x7D00`; RX là LCRetConnect 64 byte, LCRetLogin 78 byte, LCStatus 6 byte, LCRetCharList 63 byte. Tài khoản mới chưa có nhân vật; probe không tự tạo hoặc vào thế giới.

Evidence: `Build/Logs/2026-09-13-gpt-netbot/wsl-1/{result.json,report.tsv,frames.tsv,failures.tsv}`; file failures chỉ có header. Không sửa máy chủ trong probe. Máy chủ và tài khoản test được root cấp riêng; cấu hình/vòng đời máy chủ nằm ở `Tools/server`, độc lập với công cụ login này.

## Vòng đời bản máy chủ test

`Tools/server/provision_test_wsl.py` chỉ chấp nhận đúng root riêng `/home/ubuntu/cys-test-20260913` trên WSL; từ chối root khác, traversal và symlink ở đường ghi. Cơ sở dữ liệu Mongo mới trên 27018 và MQTT trên 1884; login/game trên 15733/15734. Không sao chép database live. File cấu hình có credential chỉ nằm trong root private và không được in.

`status` nhận diện cả Mongo, MQTT và bốn process Skynet bằng executable thật cùng argv chỉ đến config private; Skynet còn phải có cwd private. File PID chỉ là chẩn đoán. Vì MQTT đang chạy nhưng thiếu pidfile sau một lần launch thừa trước đó, status vẫn nhận đúng service; không chạy thêm daemon theo PID file thiếu. `start` bỏ qua process đã xác minh, kể cả khi Game đang nạp scene và chưa mở port; port bận mà không tìm thấy process thuộc bản test sẽ bị từ chối.

Kiểm tra port đọc `/proc/net/tcp` và `tcp6`, chỉ chấp nhận trạng thái LISTEN `0A`. Endpoint IPv4 localhost đạt khi bind đúng `127.0.0.1` hoặc `0.0.0.0`; kết nối ESTABLISHED, listener ở IP khác và IPv6-only không bị nhận nhầm thành endpoint IPv4 hoạt động. Khi kiểm tra xung đột trước launch, mọi binding/family có cùng port đều được xem là bận. Không tạo TCP connect trống chỉ để xem status.

Khi thực sự khởi động lại process đã dừng, PID cũ, config sinh cũ và nohup output cũ được chuyển vào `lifecycle-backups` với tên có thời gian; không xóa bằng chứng hoặc ghi đè archive. `stop` yêu cầu `--confirm-root` trùng chính xác root test. Chỉ gửi SIGTERM qua Linux pidfd sau khi kiểm lại executable/config/cwd và start-time; PID bị tái sử dụng không nhận tín hiệu. Dừng theo thứ tự Game → Tool → DataCenter → Manager → MQTT → Mongo. Nếu chờ hết 30 giây vẫn chưa dừng thì báo lỗi, không SIGKILL.

Các lệnh sau chạy bằng Python WSL với script CY; thay `ACTION` bằng `status` hoặc `start`. Lệnh stop chỉ dùng khi chủ động muốn dừng bản test:

```powershell
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py ACTION
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py stop --confirm-root /home/ubuntu/cys-test-20260913
```

`record-supplement` thêm provenance riêng cho `GameServer/config_maker.lua` đã được khôi phục sau khi sửa ignore rule của lần init đầu. Ghi hash nguồn/bản test/hash manifest gốc vào file mới bên dưới `manifest-supplements`; không viết lại `source-manifest.json`, không ghi lại cùng cặp hash lần hai.

Kiểm thử vòng đời: **21/21 ca** tại `Tests/net/server_lifecycle_tests.py`, bao gồm root/port guards, trạng thái/binding trong bảng TCP kernel, nhận diện process, start no-op khi không có PID file, restart sao lưu đủ ba file, thứ tự stop, pidfd, PID tái sử dụng và timeout không force-kill. Toàn bộ process/launch/signal trong test đều mock; scratch chỉ nằm trong Build/Logs. Evidence `Build/Logs/2026-09-13-gpt-netbot/server-lifecycle-listen-tests.log`. Root đã thử start lặp lại: sáu service được giữ nguyên PID; đã chạy record-supplement.

## Phân loại log hiện có

`Build/Logs/2026-09-13-gpt-netbot/server-error-review.json` chỉ lưu metadata và phân loại, không raw log hoặc credential:

- Manager: ba lỗi connect lúc 07:27:38, khi DataCenter/Tool/Game chưa được launch. Ba sự kiện tạo sáu lua error-call và 12 traceback; số đếm substring `error=12` không phải 12 sự kiện độc lập. Không thấy lặp lại sau startup.
- Tool: hai lỗi MySQL tại 13306 lúc 07:27:40/41; đây là dependency baseline chưa có ở máy gốc, được giữ riêng trong clone. Auth/charlist dùng Mongo vẫn đạt.
- Tool: bảy `[Socket Error]` trùng bảy lần status trước đây. Các lần connect-close để dò port tạo request rỗng cho HTTP/pay/admin và cluster accepts. Đã sửa công cụ quan sát sang bảng LISTEN kernel. Một status WSL thật sau sửa thấy sáu service và 16 port, **0 lỗi mới và 0 byte log mới** ở cả Manager/Tool. Không restart hoặc xóa log để đạt kết quả này.
