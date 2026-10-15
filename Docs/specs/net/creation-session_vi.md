# NetCore: phiên tạo nhân vật tương tác — 13/09/2026

Từ mốc GUI `bc363c3`, `LoginClient` bổ sung chế độ giữ socket login sau danh sách nhân vật, xin quyền tạo rồi gửi yêu cầu tạo trên **cùng phiên đã xác thực**. Mặc định `SessionMode::Probe` vẫn là ba TX đăng nhập/list rồi đóng socket. Không đổi ProtocolGen sinh tự động hoặc transport legacy. Native đã chọn GUID để hiển thị đúng record trong màn chọn; lệnh charlogin/socket game/world chưa triển khai.

## API cho Game

Header `Src/Client/NetCore/LoginClient.h` không phụ thuộc WXClient/stdafx:

```cpp
cys::net::Options options;
options.mode = cys::net::SessionMode::Interactive;
options.overallTimeoutMs = 600000;
options.idleTimeoutMs = 300000;
client.start(endpoint, account, password, options);
// Caller xoa ban password cua minh sau start.

// Sau CharacterList duoc pump, nut Create xin phep server:
if (client.canRequestCreatePermission()) client.requestCreatePermission();
// Sau CreatePermission flag=1 duoc pump, GUI cho nguoi dung chon va submit:
cys::net::CreateCharacterRequest request;
request.nickname = selectedUtf8Name;
request.model = selectedSex; // 0 female, 1 male; khong phai CharModelEx asset ID.
request.hairStyle = selectedHairId;
request.faceStyle = selectedFaceId;
request.portraitId = selectedPortraitId;
request.newPlayerSet = selectedOutfit;
if (client.canCreateCharacter()) client.createCharacter(request);
```

`start`, `pump`, `cancel` và hai hàm gửi lệnh chỉ dùng từ thread tạo client. Không chờ socket trên main thread. `lastCommandError()` trả enum cố định: InvalidInput/NotReady/Busy/Limit/WrongThread. Lệnh trả false không enqueue packet hoặc bắt đầu kết nối mới. Client không tự gửi lại password, xin quyền hoặc tạo nhân vật.

| Event | Payload owned | Hợp đồng |
| --- | --- | --- |
| CharacterList | `pg::LCRetCharList` | Ở interactive, socket còn mở. Packet và vector sống độc lập buffer RX. Khi event được pump mới cho xin quyền nếu ít hơn 3 nhân vật. |
| CreatePermission | `pg::LCRetCheckAllowCreateChar` | `permissionFlag=1` cho phép tạo; 0 từ chối. Chỉ khi event được pump mới mở `canCreateCharacter()`. Cờ ngoài 0/1 là lỗi protocol. |
| CharacterCreated | `pg::LCRetCreateChar` | `createResult=0` là server báo thành công, **còn phải chờ list mới**. Result khác 0 là từ chối thao tác, không phải tạo thành công. Lệnh tiếp chỉ do người dùng submit rõ ràng. |
| Error/Cancelled/Refused | Metadata hoặc payload login đã có | Event terminal sau đóng socket, readiness false. Diagnostic cố định, không lấy text peer. |

Game giữ owner xuyên các procedure Login/CharSel/CharCreate và pump trên main thread; khi Back/thoát phải cancel. Phần nối WXClient do root thực hiện riêng. `creationAvailable` là metadata readiness của event, không thay cho `canCreateCharacter()` vốn còn kiểm permission và session đang chạy.

## Wire và state

1. Handshake cũ `355 → 311`, `299 → 223/554`, `711 → 319`. Probe giữ hành vi cũ. Interactive kiểm list thành công, count đúng vector, tối đa 3, GUID khác 0 và không trùng; giao list owned rồi chờ lệnh.
2. `requestCreatePermission`: `CLCheckAllowCreateChar776` body0 → `LCRetCheckAllowCreateChar777` body4. Từ lúc admission, mọi lệnh permission/create khác bị chặn đến phản hồi được pump.
3. `createCharacter`: `CLAskCreateChar522` body53 → `LCRetCreateChar440` body4. Success0 chuyển sang chờ **server tự đẩy LCRetCharList319**, không gửi thêm711. List phải tăng đúng một role và giữ toàn bộ GUID cũ; sai count/identity là lỗi rõ. Result và list có thể coalesce hoặc fragment bất kỳ.
4. Result từ chối trở lại trạng thái sẵn sàng sau main nhận event. Một lần sửa tên và submit lại rõ ràng được phép; không có vòng retry tự động. Sau success/list, cần xin quyền mới cho thao tác tạo tiếp theo.

Sequencer giữ nguyên trong worker, bắt đầu `7B00`; luồng một tạo bình thường TX IDs `355/299/711/776/522`, idx `7B00/7C00/7D00/7E00/7F00`, next `8000`. Tăng index chỉ sau khi encode và admission frame. Không reset vì chuyển procedure hoặc tạo nhân vật.

Một command slot main→worker dùng chung permission/create; worker lấy lệnh rồi gửi nonblocking. Tối đa **16 lệnh tương tác mỗi phiên**, tức tối đa19 TX kể cả handshake. Worker được đánh thức bằng cờ atomic kiểm mỗi WSAPoll quantum25ms, không đợi hết timeout mạng trước xử lý lệnh.

Giữ RX64 frame/256KiB, pending frame65541B, UI queue16event/256KiB và decoder strict. Unknown Login ID mới tra Game; Game/script ngoài state tạo bị từ chối, không chạy text peer. Packet sai thứ tự, result lạ, frame lỗi, unsolicited list/result, hoặc list sau create không đúng identity đều đóng socket. Có thể đã giao createResult0 trước khi phát hiện list lỗi; GUI phải chờ list để kết luận màn chọn đã cập nhật.

Connect/reply vẫn50..30000ms. Interactive idle50..600000ms; overall50..900000ms, mặc định overall vẫn90000ms nên Game đặt rõ thời lượng mong muốn. Reply timeout chuyển sang idle khi sẵn sàng; từng reply có deadline không kéo dài vì byte trickle. Overall giới hạn cả phiên. Cancel xóa event/lệnh chờ và đóng socket; hủy client trong callback được kiểm. Nếu request tạo đã TX trước cancel, server có thể đã tạo nhân vật: không tự thử lại; phải đối chiếu list/DB trong lượt tiếp theo.

## Field và encoding có nguồn

Nguồn server chỉ đọc trong clone; đường dưới đây tính từ GameServer của clone. Không sửa server/config hoặc DB trong phần triển khai này.

- `confs/publish_yu/server_conf.lua:10` của runtime clone chọn wire `utf8`; `lualib/wire_charset.lua:50` giữ nguyên UTF-8 khi nhận. Request nickname dùng UTF-8 strict, **1..29 byte**, thêm NUL trong field30; không có giới hạn codepoint riêng và không truncate. Từ chối NUL, byte control ASCII<0x20, DEL, `#`, `*`, space ASCII đầu/cuối, sequence UTF-8 lỗi/overlong/surrogate/out-of-range. Server còn textfilter/kiểm trùng tên; transport không thay chính sách đó.
- `services/login/packet.lua:532..543` đọc đúng nickname30/modeli32/unknownu8/u8/hairi32/facei32/portraitu8/newPlayerSeti32/unknowni32. Hai byte unknown và int cuối bằng0 theo ctor `:521..530`; đường create không dùng chúng. API yêu cầu model/hair/face/newPlayerSet không âm; caller chọn ID có thật, transport không lookup hoặc bịa model.
- `lualib/playermanager_core.lua:62..75` chuyển tên theo wire profile, kiểm tên, lưu nguyên model/hair/face/portrait/newPlayerSet. Không validate asset ID trong đường này. `services/login/logind.lua:492..502` trả `sex=attrib.model`, hair/head/portrait/newPlayerSet nguyên; vì vậy gửi sex0female/1male từ UI, không đảo sang assetID của CharModelEx.
- `services/login/logind.lua:333..356`: xin quyền trả object777 mới, ctor `packet.lua:655` đặt flag1. Create cần auth[fd], trả440 và tự gửi319 khi success0.
- `lualib/define.lua:1472`: result0success,1server busy,2too frequent,3full,4same name,5operation flow error,6internal error,8invalid name. **Không có result7**; transport không ánh xạ nó thành thành công.

S2CY được người dùng chỉ định ở `../Tools/DATA NEW/DataCY31-08-26/Config`. Metadata `Build/Logs/2026-09-13-gpt-create-role/net/appearance-server-rows.json`: face nữ1/2/3/4/5/14, nam100/101/102/103/104/113; hair nữ1/17/19, nam5/12/14 đều có trên server. **18/18 shared ID/race/base_mesh bằng byte**. Full schema khác: face S2=12 cột/server=11, hair14/13; IV mesh/icon khác nên không copy theo ordinal. Model/outfit/model preview được kiểm riêng; bằng chứng tạo thật và đọc lại bên dưới chỉ bao phủ bộ ngoại hình đã gửi, không suy toàn bộ tổ hợp đã qua WSL.

## Kiểm chứng

Từ gốc CY-Source, dùng thư mục output mới:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/net/build_netcore_tests.ps1 -OutDir Build/Logs/create-build-NEW -TestSource creation_session_tests.cpp
python -B Tests/net/run_creation_session_tests.py --exe Build/Logs/create-build-NEW/cys_netcore_tests.exe --out Build/Logs/create-run-NEW
```

Evidence chính `Build/Logs/2026-09-13-gpt-create-role/net`:

- `build-3`: MSVC C++14 /W4, một compiler, exit0, không warning. `build-1` thất bại vì test thiếu include PgFactory; sửa ở test và build2/3 đều đạt, không xóa evidence cũ.
- `run-2`: unit xác minh nickname UTF-8/bounds/invalid/inactive/threadowner; **28/28 loopback** trên listener cổng động riêng. Có permissiondeny/unknown/timeout; create refusal/correction explicit; 440+319 coalesced và split; 0→1,1→2 role; owned UTF-8/GUID qua nhiều pump và cancel; bấm lặp/bỏ gate; max3/duplicateGUID/count/identity mismatch; sai thứ tự/malformed/unknown result; timeout/trickle/peerclose; cancel trước và sau TX522; hủy trong callback; cap16 lệnh với TX19 giữ seq.
- `probe-regression`: **18unit +100000fuzz +1699 replay strict byte-identical +20/20 loopback** của mode mặc định vẫn PASS; nguồn production giống build3, chỉ test mới bổ sung hai case sau build2. `probe-build` không warning.

Runner không đọc credential thật, bỏ CYS_BOT_PWD của child. Wire fixtures do ProtocolGen tạo với tên/GUID tổng hợp chỉ nằm RAM; report có hash/counter/ID/index, không body. Output trong Build/Logs mới, kiểm ancestor junction; không WSL auth/DB mutation/Game/GPU. Thành công của các bài này chưa chứng minh GUI tạo nhân vật, chưa tạo/chọn nhân vật hoặc vào world trên clone.

## WSL thật: tạo đã lưu và phiên chọn mới

Gốc bằng chứng `Build/Logs/2026-09-13-gpt-create-role`. Sau khi `net/cluster-route-activate-5` phục hồi Game→Tool, GUI `wsl-create-a272cbe-2` gửi tạo một lần lúc16:10:31, nhận440/result0 và319/list1, tx6/rx8/closed0. Hai permission trong phiên là do kiểm Back/mở lại; không xác thực thêm giữa các màn. Snapshot `net/role-pre-7.json`→`net/role-post-create-observation2.json` chứng minh0→1 role, GUID200001, model1/hair5/face100/portrait13/newPlayerSet0. Full GUI Create vẫn FAILED vì harness đọc nhãn SimpleText bằng getter Editbox sau khi server đã lưu. Giữ nguyên thất bại này tại `net/create2-server-success-client-failure.json` và không tạo lại record.

Sau reader riêng `5a2fb6a`, phiên `wsl-select-91148e1` đăng nhập lại lúc16:24:25, nhận list1 bằng3TX/4RX; không gửi permission/create. Harness kiểm tên CYTest00 từ record owned, actor native trên scene, nhãn tên thật và bấm slot0; PASS Select lúc16:24:42 và sống tới hạn182,369 giây. `net/role-post-select-1.json` và `net/fresh-select-review-1.json` giữ cùng GUID/ngoại hình, một auth thành công trong cửa sổ, không thêm abnormal packet/error/traceback, cả6PID/16cổng giữ nguyên. Đây là chọn nhân vật để hiển thị trên màn chọn; chưa gửi charlogin và chưa vào thế giới.

Manager clone đã được vá bổ sung replay peer cùng group sau giai đoạn nạp scene; tiến trình Manager hiện tại vẫn là code đã nạp trước sửa. Route hiện tại được xác nhận qua dịch vụ đang chạy, bản vá startup được kiểm bằng Lua thật40 assertions; chưa khởi động lại toàn bộ clone để kiểm cold start. Không thay module/từ điển lọc tên hoặc server gốc. Công cụ và RCA ở `Tools/server/repair_test_cluster_routes.py` và `net/textfilter-route-repair_vi.md`.

Lượt xác nhận cuối `wsl-select-91148e1-2` (16:33:09–16:36:09,180,226giây) PASS Select sau sửa câu nhãn ô trống ở controller; protocol/native không đổi. `net/role-post-select-2.json` và `net/fresh-select-review-2.json` đạt13/13 điều kiện: một auth trong cửa sổ GUI, không gửi permission/create, cùng GUID200001 và ngoại hình, không thêm abnormal/error/traceback, giữ6PID/16cổng. Delta auth của toàn khoảng từ post-create bằng2 do có hai phiên Fresh Select; mỗi phiên xác thực đúng một lần. Chưa gửi charlogin/socket game/world; không đổi raw full Create FAILED thành PASS.
