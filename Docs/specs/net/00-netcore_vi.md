# NetCore async — lát cắt đăng nhập và danh sách nhân vật

Ngày 13/09/2026, từ HEAD 902ecf8. cys_netcore hiện thực một kết nối login hiện đại trên worker riêng, nhận packet ProtocolGen có quyền sở hữu rồi giao cho UI qua pump trên luồng chính. Phạm vi là CLConnect355 → CLAskLogin299 → CLAskCharList711 → đóng socket. Không có game socket, tạo/chọn nhân vật hoặc vào thế giới; kết quả NetBot trước đó không thay thế kiểm chứng của lớp này.

## API và quyền sở hữu

Header Src/Client/NetCore/LoginClient.h không phụ thuộc stdafx hoặc lớp packet 0.85:

    cys::net::LoginClient client; // Tạo trên main thread.
    cys::net::Endpoint endpoint;
    endpoint.host = approvedHost;
    endpoint.port = approvedPort;
    bool started = client.start(endpoint, account, password);
    // Caller xóa bản password của mình sau start.
    client.pump([](cys::net::Event&& event) {
        // Connected; Authenticated; Refused; CharacterList; Error; Cancelled.
        // packet là unique_ptr<pg::Packet>, không mượn buffer của worker.
    }, 16);
    client.cancel();

start chỉ kiểm tham số, dựng packet xác thực trong bộ nhớ và mở worker. Không đợi phản hồi mạng hoặc chạy vòng poll trên UI. Worker cũ đã hoàn tất mới được join khi bắt đầu phiên khác; start khi worker còn chạy, còn event chưa pump hoặc đang ở callback trả Busy, không tạo socket thứ hai. lastStartError() trả lỗi cố định. Đầu vào chỉ được mượn trong thời gian gọi.

pump và cancel phải chạy trên thread tạo client; gọi sai thread bị từ chối, không dispatch handler. pump giao tối đa 16 event một lượt và chặn pump lồng nhau. Callback có thể cancel hoặc hủy client/procedure: implementation còn sống tới khi pump trả về, worker được dừng, và không gọi callback cũ tiếp theo. Cancel xóa event UI đang đợi, yêu cầu worker đóng socket; phiên đang chạy kết thúc bằng một Cancelled. Nếu worker đã hoàn tất trước cancel, event chưa giao bị loại bỏ.

Authenticated/Refused mang pg::LCRetLogin; CharacterList mang pg::LCRetCharList, có thể đọc vector charlist sau khi buffer nhận đã bị xóa. Không ép kiểu sang DB_CHAR_BASE_INFO. Connected chưa có packet; Error/Cancelled không chuyển raw payload lên UI. Mọi terminal event được đưa vào queue sau khi socket đã đóng. Counters::txFrames đếm frame đã được admission vào slot gửi duy nhất, không khẳng định toàn bộ bytes đã gửi khi có lỗi I/O.

## Wire, giới hạn và credential

- Dùng lại nguyên implementation thuần FrameAssembler, DecodeInbound, LoginConversation, TxSequencer tại Src/Tools/CysNetBot/LoginProbe.cpp; component compile nguồn này vào NetCore. Không dùng vòng mạng đồng bộ trong CysNetBot/main.cpp hoặc policy account của bot. NetCore có transport/thread/queue/pump/cancel riêng và kiểm riêng.
- Endpoint phải được truyền rõ, IPv4 loopback literal thuộc 127/8, port khác 0; không DNS, redirect hoặc fallback endpoint. Library không hardcode tài khoản/cổng test. Profile opt-in của Game và runner có trách nhiệm ghim endpoint/tài khoản đã duyệt, trong lượt hiện tại là clone riêng.
- Account ASCII chữ/số/dấu gạch ngang; không để server tự cắt ký tự account ngoài quy tắc. Password không rỗng, không control/NUL/DEL hoặc %, account + % + password vừa 49 byte, không truncate. Dạng login mới đúng 949 byte, version 0, encrypted_data rỗng. MAC CYS-GUI là marker tổng hợp được khai báo, không phải fingerprint phần cứng.
- Secret packet và hai buffer body/frame có RAII xóa byte sau dùng, lỗi hoặc cancel. Worker không giữ bản password string riêng. Caller phải xóa password của mình; NetCore không ghi credential vào config, argv, environment, log hoặc file.
- Seq bắt đầu 0x7B, idx=(seq&255)<<8. Chỉ tăng khi một frame đã encode và được nhận vào slot gửi có giới hạn; ba frame bình thường là 7B00/7C00/7D00. Giá trị nextTxIndex 7E00 có trong counter. Chưa có chuyển socket game hoặc giữ seq qua scene; bước sau phải mang sequencer của phiên sang game, không dùng một LoginClient mới để giả lập continuation.
- Một worker Winsock nonblocking, WSAPoll quantum tối đa 25 ms; TCP_NODELAY. Timeout mặc định connect 5 s, mỗi reply/send 10 s, cả lượt 90 s. Options chỉ nhận 50–30000 ms cho connect/reply và 50–90000 ms tổng; reply deadline không kéo dài bởi byte trickle.
- RX read tối đa 16 KiB; assembler giữ một frame dở tối đa 65541 byte và giới hạn 128 frame mỗi feed. Tối đa 64 frame RX/256 KiB tổng/3 TX mỗi phiên. Queue UI tối đa 16 event/256 KiB body wire được tính; vượt giới hạn đóng socket với lỗi. Luồng đăng nhập có số gửi cố định, chưa phải token bucket của framework in-world.
- Decode strict trên worker. ID đã có trong Login mà parse lỗi không tra Game. Chỉ ID chưa biết trong bảng Login mới tra Game; hướng CL/CG/CGW trên đường RX bị từ chối. Game397 parse được nhưng chưa hợp lệ trong state đăng nhập này nên báo UnexpectedPacket và đóng; không hiển thị script/text từ peer.
- LCRetLogin flag khác 0 dừng, không gửi charlist hoặc thử lại password. Flag8/21 trả retryAfterSeconds tối thiểu 20 s, làm tròn uNeedWaitTime lên giây. Caller phải dùng backoff nếu cho người dùng submit lại; library không tự retry. Charlist trả lỗi, packet sai thứ tự, frame sau terminal hoặc suffix dở đều là lỗi rõ.
- Diagnostic chỉ có enum, thông báo cố định, proto/ID, tên field parser, offset, size và counter. Không hex dump, packet body, server key hoặc text peer.

## Kiểm chứng offline

Native compile tại Build/Logs/2026-09-13-gpt-netcore/build-2: MSVC C++14, /MD /W4, 1 job, exit 0, không warning. Biên dịch LoginClient + nguồn framing/conversation dùng chung + test, link cys_protocolgen.lib CI. CMake component đã thêm target cys_netcore/cys_netcore_tests; build toàn Game do root tích hợp riêng.

Build/Logs/2026-09-13-gpt-netcore/run-2:

- **18/18 unit**, gồm mọi điểm tách header/body, coalescing, seq wrap, direction/fallback strict, cap, input validation và thread ownership.
- **100.000 đầu vào fuzz** đưa fragment/mutation/random/coalesced qua chính assembler/strict decode dùng trong NetCore; 73.913 frame decode được, không crash hoặc vượt pending cap.
- **1699/1699 capture frame** từ file ignored Build/cmake/protocol-x64/test-data/capture_frames.bin: ghép thành stream, feed chunk ngẫu nhiên 1–512 byte, có 225 feed chứa nhiều frame; strict decode và encode byte-identical, pending 0. Replay kiểm mọi proto/hướng theo metadata capture, không ép toàn bộ game capture vào state login. Không ghi bản sao body capture ra báo cáo.
- **20/20 loopback async** trên listener cổng động do Python runner sở hữu: auth/list; main không pump; cancel đang đợi; cancel event đã queued; hủy client trong callback; flag1/8/21; known-short/trailing; unknown-ID; sai hướng; Game397; list refused; timeout; trickle; peer close; flood; partial suffix và frame sau terminal. Server quan sát 355/299/711 cùng idx liên tục, socket đóng và không tự kết nối lại. Mỗi child process chỉ dùng credential giả trong test, không đọc environment CYS_BOT_PWD.

    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/net/build_netcore_tests.ps1 -OutDir Build/Logs/netcore-build-NEW
    python -B Tests/net/run_netcore_tests.py --exe Build/Logs/netcore-build-NEW/cys_netcore_tests.exe --out Build/Logs/netcore-run-NEW

Runner chỉ ghi thư mục mới dưới CY-Source/Build/Logs, từ chối đường dẫn qua junction; body listener giữ trong RAM. Log subprocess được quét không chứa credential giả trước khi ghi. Bằng chứng chi tiết: unit.log, replay.log, 20 log scenario và summary.json.

## Còn chưa đạt

Agent không kết nối WSL hoặc dùng credential thật. Lát cắt này chưa chứng minh Game.exe GUI submit → auth → danh sách thật; root và agent procedure phải tích hợp profile/tick và kiểm gate riêng. Chưa có registered handler framework, token bucket tổng quát, RX index monitor game, create/select character, charlogin, scene handoff, heartbeat, movement hoặc CGAskQuit. Không gửi CGAskQuit lên login socket khi chưa có game session. Replay/fuzz ở đây không đóng toàn bộ P1-3 hoặc P1-5.
