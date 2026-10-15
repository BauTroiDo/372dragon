# NetCore: từ nhân vật đã chọn vào thế giới — 13/09/2026

Tiếp nối [creation-session_vi.md](creation-session_vi.md). Phần này triển khai **offline** toàn bộ đường `CLAskCharLogin → socket game (CGConnect là frame đầu) → CGEnterScene → thế giới → heartbeat/di chuyển → CGAskQuit`, kèm đổi cảnh 809/414/280 có kết nối lại. Code nằm ở ba lớp: NetCore (LoginClient/GameTicket/GameClient/WorldModel), seam trong Game.exe (CysModernGame + handler GC port từ 0.85) và `CysNetBot --mode world`. ID packet lấy từ `Registry/protocol`/packets.yaml và codec sinh ở `Src/Shared/ProtocolGen`; không dùng ID của tlbb_sim. **Chưa chạy live**: kế hoạch ở cuối, chờ orchestrator xác nhận người dùng đồng ý.

## Wire

| Bước | Client → server (idx) | Server → client | Ghi chú |
| --- | --- | --- | --- |
| Đăng nhập | 355 `7B00`, 299 `7C00`, 711 `7D00` | 311, 223+554, 319 | như creation-session; socket login luôn trả idx 0 |
| Charlogin | 426 CLAskCharLogin `7E00` {guid, PlayerID 0} | 38 LCRetCharLogin {result, port, ip, key} | từ chối: 38 result≠0, hoặc 397 GCScriptCommand cmd5 trên socket login |
| Kết nối game | **49 CGConnect `7F00`, frame đầu tiên**, 108 B {key, guid, `tlbb`} | 67 KeyExchange, 456 GCConnect {result, scene, pos} | result 0 lần đầu, 3 khi vào bằng key đổi cảnh; key sai thì server im lặng |
| Vào cảnh | 824 CGEnterScene `8000` {scene của 456, type 0, pos 0,0}, một lần mỗi socket | 1764 GCEnterScene {scene, pos, objId}, rồi NewPlayer/NewMonster/DelObject/CharBaseAttrib… | bytes trùng client thật trong capture |
| Nhịp | 3 CGHeartBeat thân rỗng, mỗi 15 s kể từ 456 | — | server không có ngưỡng kick; capture đo 15–16 s; dừng khi đang thoát |
| Đi | 352 CGCharMove 26 B {handle đếm từ 1 mỗi socket, obj, pos, count 1, đích} | 564 GCCharMove, broadcast cả cho chính người đi | 1090 GCCharMoveResult có định nghĩa nhưng server không gửi; field dừng chỉ có khi `flag & 0x4` |
| Đổi cảnh | 414 CGAskChangeScene, chỉ sau 809 | 809 GCNotifyChangeScene; 280 GCRetChangeScene {1, ip, port, key}, gửi lại sau 5 s nếu chưa nối | socket mới: 49 đầu → 456(3) → 824 → 1764 |
| Thoát | 1727 CGAskQuit (unknow_2 = 0) | 128 GCRetAskQuit flag 0, rồi server đóng socket | quit tick 3 hoặc 10 nhịp một giây |

Một bộ đếm cho cả phiên, đi qua login → game → đổi cảnh: `idx = (seq & 0xFF) << 8`, bắt đầu `0x7B`; không tạo nhân vật thì CGConnect mang `7F00`. Server đảo byte và đòi +1 so với frame trước (sau 255 thì nhận mọi giá trị); lệch thì ghi một dòng `record_xy_rec` và **không** tiến bộ đếm, `set_fd` đặt lại phép kiểm theo từng kết nối. GameTicket chuyển `nextSequence` từ worker login sang worker game; index chỉ tăng sau khi frame được admission.

## Nguồn server (clone `cys-test-20260913/GameServer`, chỉ đọc)

- `services/login/logind.lua:403–408`: LCRetCharLogin lấy `key = subid` từ `.gamed login`; `:429` ip là `server_conf.server_ip` (clone: 127.0.0.1), port là cổng game.
- `services/game/gamed.lua:178–189`: frame đầu của fd mới phải là CGConnect (assert); GUID lạ hoặc `key ≠ subid` thì `return` im lặng, không trả gì. `:29–56` `create_msgagent`: agent cũ bị `disconnect` (chuyển server), rồi `set_fd`.
- `lualib/net.lua:90–111`: đảo byte idx, `diff ≠ 1` và `last_idx ≠ 255` thì insert `record_xy_rec`, không cập nhật `last_idx`.
- `services/msgagent.lua`: `:121` set_fd; `:147–149`, `:258` 809 lưu `change_scene_args`; `:426–433` CGAskQuit đặt quit tick; `:878` CGHeartBeat; `:899–940` CGEnterScene, vào lại cùng agent mà không có `change_scene_args` và `login_user ≠ 1` thì ghi lỗi "重连" vào `log_CGEnterScene` rồi logout, nên chỉ một CGEnterScene mỗi socket; `:1171–1251` CGAskChangeScene cần `change_scene_args`; `:1280–1286` 280 mang ip/port/key, `skynet.timeout(500)` gửi lại sau 5 s.
- `services/scene/obj/character.lua:617–648`: GCCharMove `broadcast(self, msg, true)`. `services/game/packet_domains/movement.lua:568` định nghĩa GCCharMoveResult, không tìm thấy nơi gửi.

## NetCore (`Src/Client/NetCore`)

- **NetCommon**: `Endpoint`, `ErrorCode`, `IsLoopbackLiteral` (chỉ IPv4 dạng số trong 127/8) và `GameTicket`. Ticket chỉ move, không có accessor cho key, key bị xóa bằng ghi volatile khi clear. Chỉ LoginClient và GameClient là friend.
- **LoginClient**:
  - `Options::approvedGamePort` chỉ dùng ở Interactive. Giá trị 0 tắt charlogin, và mode Probe bắt buộc 0.
  - `canRequestCharacterLogin()` và `requestCharacterLogin(guid)` dùng chung slot lệnh với permission/create; GUID phải có trong list đã pump.
  - `CharacterLoginGranted` là event terminal, mang `unique_ptr<GameTicket>`. `CharacterLoginRefused` không terminal, quay về Ready.
  - ip không phải loopback, hoặc port khác `approvedGamePort`, thì báo `UnexpectedPacket` "game endpoint outside the approved profile" và không mở socket game. Mọi frame sau reply terminal đều là lỗi.
- **GameClient**:
  - Mỗi socket có một worker. Các phase: Idle, Connecting, AwaitConnect, Connected, Entering, InWorld, AwaitTransfer, Quitting, Closed.
  - Worker tự gửi CGConnect trước rồi xóa key. 456 chỉ nhận ở AwaitConnect và bật heartbeat; 1764 chỉ nhận ở Entering; 280 chỉ nhận ở AwaitTransfer.
  - Khi nhận 280 result 1, worker kiểm lại loopback và cổng, giữ key nội bộ, xóa key khỏi packet bằng `cysbot::Wipe` trước khi phát event Transfer, rồi kết nối lại.
  - 128 chuyển sang Quitting; peer đóng socket lúc Quitting thì phát QuitComplete kèm `quitFlag`.
  - Decode strict chỉ bằng `Proto::Game`, kèm kiểm chiều GC/WGC. Trước GCConnect nhận tối đa 1024 packet. Assembler cho tối đa 4096 frame mỗi lần feed.
  - Backpressure dừng đọc chứ không bỏ packet: tối đa 8192 event hoặc 8 MiB, và 256 lệnh gửi ra.
  - Timeout: connect 5 s, GCConnect 10 s, vào cảnh 30 s, chuyển cảnh 15 s, thoát 20 s, idle 600 s. Heartbeat 15 s. Tốc độ gửi 30/s, burst 60.
  - `send()` từ thread owner từ chối 49, 3 và 1727, cùng mọi packet không phải C→S của bảng Game. CGEnterScene chỉ gửi được ở Connected, một lần mỗi socket; 414 chỉ ở InWorld sau 809; mọi packet khác chỉ ở InWorld. `requestQuit()` chỉ gọi được ở InWorld.
- **WorldModel**: model thuần gồm `apply`, `onConnected` và `onTransfer`, cùng các bộ đếm created/refreshed/deleted/moves/selfMoves… Helper: `makeEnterScene` (bytes trùng capture), `makeMove(x, y)`, `makeAskChangeScene`, `makeAskBaseAttrib`.

## Game.exe (`Src/Client/WXClient`, sửa đều gắn tag `// CYS:`)

- `GamePro_CharSel::SendEnterGameMsg` gọi `RequestModernCharacterLogin(guid)`.
- `GamePro_Login::PumpModernLogin` xử lý kết quả:
  - Granted: reset login client, `CysModernGame::Start(ticket, 15734)`, đặt `User_GUID` và `ENTER_TYPE_FIRST`, rồi `SetActiveProc(ChangeScene)` với trạng thái `CHANGESCENE_CONNECTING`.
  - Refused: hiện thông báo cố định.
- `NetManager::Tick` gọi `CysModernGame::Pump()` và bỏ qua socket 0.85 khi phiên hiện đại đang chạy. Pump xử lý mỗi lần một event và dừng batch sau event làm đổi procedure. Packet thế giới được giữ trong stash (tối đa 4096) cho tới khi `WorldReady()`, tức Main có scene, MySelf và station `WS_ENTER`.
- `SendPacket` dịch 0.85 sang ProtocolGen theo danh sách trắng: CHARMOVE, ENTERSCENE, ASKCHANGESCENE, CHARASKBASEATTRIB, ASKDETAILATTRIB, CHARASKEQUIPMENT, ASKMISSIONLIST, ASKSETTING. Packet khác bị bỏ và ghi log.
- `Release` gọi `Shutdown(15000)`: gửi CGAskQuit nếu đang trong thế giới, nếu không thì cancel, có chờ giới hạn.
- ChangeScene và Enter chỉ đổi trạng thái khi phiên hiện đại đang chạy. Nếu client không nạp được cảnh thì thoát bằng `OnEnterSceneFailed` (CGAskQuit), không thử lại mỗi frame.
- Handler port từ 0.85, không dùng `TDThrow`; vị trí không hợp lệ bị bỏ qua và đếm:

  | Packet | Hành vi |
  | --- | --- |
  | 67 | bỏ qua |
  | 456 | đặt `Scene_ID`/`Scene_EnterPos`, trạng thái `RECEIVE_CGCONNECT_SUCCESS` |
  | 1764 | đặt MySelf/SetSceneID, `ENTERSCENE_OK` |
  | NewPlayer/NewMonster (+ _Move) | tạo đối tượng, mặc định MONSTER |
  | DelObject | không bao giờ xóa MySelf |
  | 564 | đi theo path, xử lý stop bit |
  | 1090 | dừng (`OnMoveStop`) |
  | CharBaseAttrib | ánh xạ flag |
  | 809 | gọi `CWorldManager::ChangeScene` |
  | Transfer | chuyển cảnh qua `GE_ON_SERVER_TRANS` |
  | 280 từ chối | ở lại cảnh hiện tại |
  | 128 | chờ server đóng |
  | Đóng phiên | `GE_NET_CLOSE` |

- Cổng game được duyệt đang cố định là `kCysWslTestGamePort = 15734` (profile clone). Màn đăng nhập offline không đổi: nhánh hiện đại chỉ chạy khi có ticket.

## CysNetBot `--mode world`

`--mode world --host 127.0.0.1 --port 15733 --game-port 15734 --account test00 --guid G --out Build/Logs/NEW [--dwell-ms 1000..300000] [--heartbeat-ms 100..60000] [--walk 0|1] [--timeout-ms 1000..30000]`.

- Chạy cùng LoginClient/GameClient như Game.exe. Host phải là loopback. Mật khẩu chỉ lấy từ `CYS_BOT_PWD` và bị xóa ngay sau khi đọc.
- Nếu GUID không có trong list thì thoát mã 6 và **không** gửi 426.
- Khi 456 tới thì gửi 824; khi 1764 tới thì gửi 404 cho chính mình.
- `--walk 1`: đi một bước +1,0 theo x, 1,5 s sau đi về đúng vị trí vào. Hết dwell thì gửi 1727, chờ 128 và server đóng. Không có retry.
- Output gồm `world-events.tsv` (ms/socket/event/generation/id/tên/cỡ/phase), `report.tsv` và `result.json`. Không lưu body, key hay text của peer.
- Mã thoát: 0 đạt, 2 setup, 4 mạng/timeout, 5 decode, 6 bị từ chối hoặc thiếu GUID, 7 protocol.

## Kiểm chứng offline

Từ gốc CY-Source, dùng thư mục output mới. Build theo lệnh của orchestrator đi qua wrapper ASCII, song song 4:

```bat
Build\Logs\2026-09-13-world\build_world.cmd Build\Logs\2026-09-13-world\world-build-cmake-NEW.log
Build\Logs\2026-09-13-world\build_world_targets.cmd Build\Logs\2026-09-13-world\tools-build-NEW.log "cys_world_tests cys_netcore_tests cys_netbot"
```

```powershell
& 'C:\Program Files\Python313\python.exe' -B Tests/net/run_world_session_tests.py --exe Build/cmake/world-x64/bin/cys_world_tests.exe --out Build/Logs/2026-09-13-world/world-run-NEW --bot-exe Build/cmake/world-x64/bin/CysNetBot.exe
& 'C:\Program Files\Python313\python.exe' -B Tests/net/run_login_probe_tests.py --exe Build/cmake/world-x64/bin/CysNetBot.exe --out Build/Logs/2026-09-13-world/probe-run-NEW
& 'C:\Program Files\Python313\python.exe' -B Tests/net/collect_world_snapshot_tests.py --out Build/Logs/2026-09-13-world/collector-test-NEW
```

Evidence nằm ở `Build/Logs/2026-09-13-world`:

- **`world-run-3`: PASS toàn bộ.**
  - Unit và replay-model: phiên thế giới đầu tiên trong capture 27/08, fixture PGWORLD1 gồm 83 C→S và 741 S→C, sha `21f59c88…`. Kết quả my 216, scene 2, còn 5 đối tượng; created 187, deleted 182, unknown delete 16, moves 37, self 19; khớp mirror Python.
  - 16 kịch bản loopback: enter-quit, transfer có reconnect, transfer bị từ chối, refuse-then-grant, endpoint/cổng sai, key im lặng, timeout vào cảnh, peer đóng, transfer không mời, decode lỗi, quit timeout, cancel, backpressure 20.000 frame, rate, replay. Replay có CGConnect/CGEnterScene trùng bytes client thật.
  - 2 kịch bản CysNetBot. `bot-world` có TX login 355/299/711/426 ở `7B00–7E00`, sau đó socket game bắt đầu bằng 49 `7F00` và kết thúc bằng 1727 `9400`, tổng 22 TX game gồm 16 heartbeat (nhịp thử 150 ms) và 2 bước đi; kết thúc `quit_complete`, flag 0. `bot-guid-missing` thoát mã 6 và không có kết nối game.
  - Idx liền mạch trong mọi ca.
- `probe-run-1`: 10/10 loopback và 5/5 guard của mode login cũ vẫn PASS. `collector-test-1`: collector live PASS với dữ liệu giả; allowlist không lọt field nhạy cảm; ca xấu FAIL đúng 6 check.
- Build cây chung `world-x64` (`world-build-cmake-2`): NetCore và bảy TU WXClient của phần này biên dịch không lỗi. Game.exe **không link được** vì 12 TU DataPool/Interface/Object/World lỗi member DBC, do agent dữ liệu đang sửa `TDDBC_Struct.h` (ngoài phạm vi phần này). `tools-build-1` build CysNetBot world (/W4) sạch. `world-build-cmake-3` chạy lại sau khi agent dữ liệu sửa các file dùng header: rc 0, 0 lỗi, Game.exe link xong (sha256 `7bd379e6…0ca6`). Bản này chứa thay đổi đang dở của agent khác (layout DBC mới) nên chưa smoke; smoke A/B dùng bản `pin-x64`. CysNetBot.exe không đổi sau build này.
- **Build snapshot `pin-x64`**: `Build/world-pin` = `git archive HEAD 0c641cf` cộng đúng 28 file của phần này (`OVERLAY_FILES.txt`) cộng FMOD core. Release giống `ci-x64`, `build_pin.cmd` cho `pin-build-1` với 1115 bước và 0 lỗi, Game.exe link xong. Build này tách Game.exe khỏi thay đổi đang dở của agent khác.
- Smoke màn đăng nhập offline A/B: xem mục sau.

## Smoke màn đăng nhập offline (A/B)

Stage riêng `Build/world-smoke/stage-91148e1-offline` được chép từ stage 91148e1; stage gốc chỉ được đọc. Bộ DLL 91148e1 đi cặp với HEAD, vì khác biệt 91148e1..HEAD trong `Src` chỉ là `WXEffect` bên trong Render.dll.

`Tests/net/prepare_world_smoke_stage.py prepare` đảo đúng phép biến đổi `--wsl-test` của `prepare_gl_login_profile.py`:

- `WXSystem.cfg` về cổng 14400.
- `Patch/LoginServer.txt` trở lại đúng fixture offline.
- `Patch/WXLoginServer.txt` về cổng 14400.

Sau đó script ghi lại hash trong profile. `WXSystem.cfg` của stage gốc đã bị client ghi lại ba khóa nhớ đăng nhập, nên dùng bản sạch của stage a272cbe có hash trùng bản ghi profile.

A là Game.exe gốc của 91148e1; B là Game.exe của `pin-x64`, được đưa vào bằng `use-game`. CiBin riêng cho hai bản là `Build/cmake/world-smoke-{a,b}/bin`.

**Kết quả** (`smoke-a-1`, `smoke-b-1`, `smoke-ab-diff.json`): cả A và B đều **PASS** validator `Offline GL input/runtime`.

- Mỗi bản chạy 60 s và không mở socket nào (`sockets: []`). Cặp GL và font trùng nhau.
- Ảnh account, server và unicode trùng từng điểm ảnh.
- Ảnh soft-keyboard khác 0,278 % điểm ảnh, chỉ trong vùng phím. `smoke-ab-softkeyboard-crop.png` cho thấy đó là thứ tự phím ngẫu nhiên của bàn phím mềm; khung và font giống hệt.
- WXClient.log (21 dòng) và UISystem.log (792 dòng) giống nhau sau khi chuẩn hóa chữ số. WXRender.log của B dư 2 dòng lặp; số dòng error/exception bằng nhau.
- B không có dòng `CYS world`, đúng vì nhánh hiện đại không chạy khi offline.

Kết luận: màn đăng nhập offline không đổi. Game.exe B có sha256 `e7ff630eb3593dec…` (xem `smoke-stage-b.json`).

## Kết quả chạy live — 13/09 19:40

Người dùng chạy `Tests/net/run_world_live.ps1`; script tự hỏi mật khẩu. Bot là `live-1/bin/CysNetBot.exe`, đúng hash `aa79ebcc…5d76`. Kết quả nằm ở `Build/Logs/2026-09-13-world/live-1/run-20260913-194018`. **PASS**: bot thoát 0 sau 64,1 s, review đạt 8/8.

- **Login và idx:** 4 TX (`7B00–7E00`), charlogin granted, ticket `7f00`. Socket game nhận GCConnect 125 ms sau khi kết nối và GCEnterScene ở 1,785 s. 10 TX game theo thứ tự 49, 824, 404, 352×2, 3×4, 1727, nên `next_idx 8900` đúng bằng `7F00` + 10: idx phía client liền mạch. Phía server không có dòng `record_xy_rec` mới (0→0), tức server cũng thấy chuỗi liên tục.
- **Thế giới:** my 220, scene 2, 4 đối tượng (created 4). GCCharMove 6 lần, trong đó 2 của chính mình; CharBaseAttrib 2. 128 flag 0 tới khoảng 2,3 s sau 1727, rồi server đóng socket, nên kết thúc là `quit_complete`.
- **Clone:** 6 service/PID và mọi cổng giữ nguyên; account vẫn 1 nhân vật. Vị trí lưu (165,0; 170,0) scene 2 trước và sau, delta 0,0. Sáu bộ đếm bất thường 0→0. Login flag 0: 10→11, đúng một đăng nhập. Log Game2 tăng 3110 B, Manager8 tăng 548 B, không traceback/error.
- **RX:** 170 frame, 23 ID, **0 lỗi decode strict** (số lần, cỡ body):

  | ID | Packet | n | body | ID | Packet | n | body |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 21 | GCNewMonster | 2 | 116 | 564 | GCCharMove | 6 | 22 |
  | 55 | GCDetailSkillList | 1 | 46 | 623 | GCItemInfo | 5 | 78–98 |
  | 67 | KeyExchange | 1 | 10 | 625 | GCNewBus_Move | 2 | 40 |
  | 128 | GCRetAskQuit | 1 | 1 | 872 | GCBusMove | 28 | 28 |
  | 334 | GCMSShopBuyInfo | 1 | 4 | 896 | GCMissionModify | 88 | 7–42 |
  | 335 | GCChatDecryption | 1 | 4 | 907 | GCMissionAdd | 2 | 41 |
  | 422 | GCBusRemoveAllPassenger | 4 | 4 | 1013 | GCNotifyEquip | 5 | 190 |
  | 455 | GCCharBaseAttrib | 2 | 23–275 | 1205 | GCUICommand | 11 | 10–18 |
  | 456 | GCConnect | 1 | 14 | 1750 | GCRMBChatActionInfo | 1 | 116 |
  | 472 | GCWorldTime | 2 | 12 | 1764 | GCEnterScene | 1 | 33 |
  | 479 | GCDiGongShopInfo | 1 | 128 | 481 | GCNewMonster_Move | 2 | 42 |
  | 530 | GCExteriorInfo | 2 | 42–157 | | | | |

## Kế hoạch chạy live (đã chạy 19:40, xem kết quả trên)

**Điều kiện trước:**

1. Orchestrator xác nhận người dùng đồng ý.
2. Người dùng đã **thoát** test00, vì cùng tài khoản sẽ bị đá.
3. Clone đang chạy: đủ 6 service, 15733 và 15734 LISTEN. Không start/stop/restart.
4. Người dùng tự đặt `CYS_BOT_PWD` trong chính shell chạy bot; không ghi ra lệnh, file hay log.
5. Không có Game/CysNetBot nào khác đang nối clone.
6. Binary đúng bản đã kiểm: `Get-FileHash Build\cmake\world-x64\bin\CysNetBot.exe` phải bằng `aa79ebccc293bcc6fc850a123868433e81d0779bf726c5aaddb26c968c4c5d76` (ghi trong `world-run-3/summary.json`).

**Lệnh** (PowerShell, cwd `C:\TLBB\085\CY-Source`, chạy theo thứ tự, dừng ngay ở bước đầu tiên lỗi):

```powershell
# 0. Trạng thái clone, chỉ đọc (/proc, không connect)
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py status
# 1. Snapshot trước, chỉ đọc (allowlist: account, vị trí/scene của 200001, bộ đếm bất thường, cỡ/đếm log)
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py collect --label pre --out-dir Build/Logs/2026-09-13-world/live-1
# 2. Một phiên bot (khoảng 65–75 s; trần cứng: login 40 s, game dwell + 60 s)
& .\Build\cmake\world-x64\bin\CysNetBot.exe --mode world --host 127.0.0.1 --port 15733 --game-port 15734 --account test00 --guid 200001 --out Build/Logs/2026-09-13-world/live-1/bot --dwell-ms 60000 --walk 1
# 3. Snapshot sau
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py collect --label post --out-dir Build/Logs/2026-09-13-world/live-1
# 4. Đối chiếu (Windows, không kết nối gì)
& 'C:\Program Files\Python313\python.exe' -B Tests/net/collect_world_snapshot.py review --pre Build/Logs/2026-09-13-world/live-1/pre.json --post Build/Logs/2026-09-13-world/live-1/post.json --bot Build/Logs/2026-09-13-world/live-1/bot/result.json --out Build/Logs/2026-09-13-world/live-1/review.json
```

Tổng thời gian khoảng 3 phút.

**Packet mong đợi:**

- C→S: 355 `7B00`, 299 `7C00`, 711 `7D00`, 426 `7E00` (GUID 200001). Trên socket game: 49 `7F00` là frame đầu, rồi 824 `8000`, 404 `8100`, 352 (khoảng +2 s), 352 (khoảng +3,5 s), 3 heartbeat ba đến bốn lần mỗi 15 s, và cuối cùng 1727. `next_idx` khoảng `8800–8900`.
- S→C: 311, 223, 554, 319 (một nhân vật, GUID 200001), 38 (127.0.0.1:15734; key không bao giờ ghi ra). Socket game: 67, 456 result 0, 1764, loạt packet thế giới đều decode strict, 564 cho hai bước đi của chính mình, 128 flag 0, rồi server đóng socket.

**Đạt khi đủ tất cả:**

- Bot thoát 0.
- `result.json` có `terminal=quit_complete`, `quit_flag=0`, `charlogin=granted`, `ticket_next_idx=7f00`, `first_game_frame=CGConnect`, `decode_failures=0`, `dropped_outbound=0`, `transfers=0`, `moves_sent=2`, `heartbeats≥3`, `automatic_retries=0`.
- `review.json` PASS: service/PID/cổng giữ nguyên; account và nhân vật giữ nguyên; scene và vị trí lưu không đổi (±0,05); **không có dòng mới** ở `record_xy_rec`, `log_CGEnterScene`, `log_CGAskChangeScene` (cả `tlbb` và `tlbb_log`); đúng một bản ghi đăng nhập mới; log clone không thêm traceback/error.

**Dừng ngay, không chạy lại, không thử lại:**

- Điều kiện trước không đủ: người dùng còn trong game, status thiếu service/cổng, thiếu mật khẩu.
- Bot thoát ≠ 0 (4 mạng/timeout, 5 decode, 6 bị từ chối, 7 protocol).
- Đăng nhập bị từ chối. Không bao giờ thử lại mật khẩu, vì server đếm lỗi theo MAC.
- Charlogin bị từ chối, không có 456 trong 10 s (key im lặng), 1764 không tới trong 30 s, hoặc có transfer không mời.
- Review FAIL.

Khi bot lỗi giữa phiên, socket bị đóng chứ không có CGAskQuit; phải chờ ≥60 s và xem status trước khi có bất kỳ đăng nhập nào khác. Khi lỗi chỉ đọc metadata (`world-events.tsv`, `review.json`), không đọc raw log có credential.

**Bước GUI (tùy chọn, cần đồng ý riêng):** Game.exe của `pin-x64` trong một bản sao stage WSLTest riêng. Người dùng tự đăng nhập, chọn CYTest00, bấm vào game, đi vài bước rồi thoát bằng menu. Kiểm log `CYS world:` trong WXClient.log và cùng review pre/post, không kèm `--bot`. Harness GUI tự động hiện mới tới màn chọn nhân vật.

## Stage GUI pin2 (13/09 20:50) — dùng bản này

- **Stage:** `Build/world-gui/stage-91148e1-world2`, bản sao mới của stage-91148e1. Stage gốc và `stage-91148e1-world` giữ nguyên.
  - Profile WSL test, `WXSystem.cfg` sạch (`f6c8c60a…`), launcher `Bin64/Run-World-GUI.cmd`.
- **pin2** (`Build/world-pin2`, chi tiết trong `PIN2_CHANGES.txt`) là pin cộng các phần sau:
  - Con trỏ GL: Game.rc, resource.h và `Res/gl/*.cur` của d2b47c6; `CursorMng.cpp` vòng 2 của 89644f2 (`ApplyCursorRobust`); dòng class cursor của c161d71.
  - Bộ đo CYS-PERF: 4 file của 5cd5b4c.
  - `apply_perf_hooks.py`: 9 file, áp sạch.
  - `apply_perf_fixes.py`: pacer, uiredraw, btnalpha, uiredraw2 áp sạch; rồi counters2 (chỉ là bộ đếm, nhưng khối mà psconst mong đợi đã có counters2); rồi psconst, áp sạch sau counters2.
  - **Không** lấy fd3898e hay bất kỳ thay đổi DBC nào. `diff -rq` giữa pin và pin2 có 24 mục, không có header DBC/struct nào; GameProcedure.cpp vẫn dùng `nLocalID` và biên dịch với struct DBC cũ.
- **Build:** `build_pin2.cmd` dựng một cây `pin2-x64` cho cả Game.exe và mọi DLL.
  - `pin2-build-1`: 1992 bước, 0 lỗi.
  - `pin2-build-2`: chỉ dịch lại CursorMng.cpp và link lại Game.exe.
  - Bộ 14 binary ở `Build/cmake/world-pin2b-set/bin`, hash ở `pin2b-set-hashes.txt`. Game.exe có sha256 `e56ab89f5762572ec4fe58ef42b6499f9bd42911eb2307457d8bce3176671986`.
- **Smoke offline `smoke-e-1`** trên bản sao offline, cùng bộ binary, `CYS_PERF=1`: PASS, không mở socket.
  - Pacer: front 60 fps, back 30 fps, dùng waitable timer.
  - `perf.log`: 29 cửa sổ đo, trung vị 60,0 fps (tối đa 60,1; cửa sổ thấp nhất 15 fps là lúc khởi động). p95 khung 17,0 ms, `uirebuild` 0.
- **Con trỏ, `cursor-proof-2`:** nhắm cửa sổ theo cách của `run_and_verify.ps1`.
  - Chờ tới khi không còn Game.exe nào; yêu cầu Game.exe sống quá 2 s.
  - Tìm cửa sổ bằng `FindWindow("WuXiaShiJie WndClass")` và kiểm đúng PID; đưa cửa sổ lên trên; rê chuột từng bước. `WindowFromPoint` trả về cửa sổ của ta ngay lần thử đầu.
  - `verify_cursor.py --hwnd` PASS: GetCursorInfo flags 0x1 (SHOWING); hCursor `0x5100819` khác NULL và **bằng class cursor** `0x5100819`; điểm ảnh khớp `GL_Normal.cur` 1024/1024 (lệch tối đa 0); ảnh chụp có vẽ con trỏ ở `cursor-proof-2/verify_cursor_screenshot.png`.
  - Chuột được trả về chỗ cũ, tiến trình của ta đã tắt, không còn Game.exe nào.
- **World2:** `run_gl_login_smoke.ps1 -Mode WSLTest -ValidateOnly` PASS; đã chép 13 PDB khớp.
- **Bẫy chỉ một bản chạy:** Game.exe mới tự thoát (rc 0, không log) nếu còn một Game.exe khác. Mọi lượt ở trên đều chờ tới khi không còn Game.exe nào mới chạy, và không để lại tiến trình nào. Các script chạy lại được nằm ở `Build/Logs/2026-09-13-world/scripts`.

## Stage GUI bản pin (13/09 20:05; đã thay bằng pin2 ở trên, giữ nguyên để đối chiếu)

- **Stage:** `Build/world-gui/stage-91148e1-world` là bản sao mới của stage-91148e1 (stage gốc chỉ đọc).
  - Giữ profile WSL test, cổng 15733/15734.
  - `WXSystem.cfg` là bản sạch của profile (hash `f6c8c60a…`, lấy từ a272cbe), không còn ba khóa nhớ đăng nhập của client cũ.
- **Bộ binary thống nhất:** `Build/cmake/world-pin-set/bin`, hash liệt kê ở `pin-set-hashes.txt`.
  - Từ `pin-x64`: Game.exe `e7ff630e…984e`, LuaPlus.dll và fmod.dll.
  - Từ `pin-full-x64` của cùng snapshot: 11 DLL gồm OgreMain, RenderSystem_Direct3D9, Plugin_CgProgramManager, Plugin_ParticleFX2, Plugin_Scorpio, PathLib, Render, CEGUIBase, CEGUIFalagard, CEGUIOgreRenderer, UI_CEGUI. Build bằng `build_pin_full.cmd` (`pin-full-build-2`, 943 bước, 0 lỗi); `CYS_CG_DLL` được đặt rõ tới cg.dll chỉ-đọc của client_GL, giống cây chính.
  - `prepare_world_smoke_stage.py use-set` thay đủ 14 binary 'ours', ghi lại manifest (`gui-stage-set.json`) và chép 13 PDB khớp để phân tích crash.
- **Launcher:** `Bin64/Run-World-GUI.cmd`, giống `Run-CY-Test.cmd`: đặt `CYS_WSL_LOGIN_TEST=1`, xóa biến smoke và mật khẩu, dùng TEMP riêng, chạy `Game.exe -fl`.
- **Kiểm:**
  - `run_gl_login_smoke.ps1 -Mode WSLTest -ValidateOnly` PASS, không mở Game.
  - Smoke offline `smoke-c-1` dùng đúng bộ binary này trên bản sao offline: PASS, không mở socket. So với A: 3/4 ảnh trùng từng điểm ảnh, bàn phím mềm chỉ khác thứ tự phím ngẫu nhiên, log bằng nhau.
- **Hướng dẫn:** `Docs/specs/net/world-gui-howto_vi.md`. Snapshot trước/sau không cần mật khẩu test00; review dùng `--allow-move`.

## Việc chặn khi vào thế giới bằng GUI trên dữ liệu Canonical (xếp theo mức chặn)

HEAD fbe4c25 đọc bảng theo layout client_GL, nên Game.exe HEAD không đi với stage dữ liệu Reference cũ. Thứ tự dưới đây theo đường vào thế giới của client; đây là suy luận từ code, chưa đo trên Canonical.

1. **`.path` navmesh.** `CScene` nạp navmesh PathLib ghi ở cột 5 của SceneDefineEx client_GL (`World/Scene.cpp:395`). Nạp hỏng thì EnterScene hỏng, và seam thoát bằng CGAskQuit: không vào được cảnh. Click-to-move (`CPath::CreateMovePath`/`BuildDijkPath`) cũng cần nó.
2. **ActionSet.** Mọi nhân vật, cả MySelf, tra CharModelEx cột 9 → ActionSetFile.txt → file action-set (`Object/Character/Obj_Character.cpp:1216`) để chạy động tác đứng/chạy. Không đọc được thì nhân vật vô hình hoặc đứng cứng, hoặc ném ngoại lệ ở động tác đầu.
3. **Đường item EquipBase.** Dùng cho ngoại hình trang bị của MySelf và người khác. Ngay khi vào cảnh đã có GCNotifyEquip, GCItemInfo và GCExteriorInfo (live: 5/5/2). Sai đường thì thiếu phần mesh; chỉ là lỗi hình ảnh trừ khi có assert.
4. **Lua host gaps.** Script HUD của procedure Main hỏng theo từng script, nên UI chết một phần. Thoát bằng menu cần `QuitApplication` (đã có, gửi WM_CLOSE); Alt+F4 là đường dự phòng.
5. **129 cửa sổ UI thiếu widget.** Phần lớn là cửa sổ tính năng. Để vào thế giới chỉ cần HUD, minimap và menu hệ thống, nên việc này xếp cuối cho mốc vào thế giới nhưng đứng đầu cho gameplay.

## Giới hạn

- Game.exe trong cây chung sẽ build lại khi agent dữ liệu chốt header DBC (`build_world.cmd`); lúc đó cần bộ DLL cùng layout DBC.
- Cổng 15734 đang cố định trong `GamePro_Login.cpp`, sau này nên lấy từ profile stage. Chỉ 8 packet CG được dịch; chat, kỹ năng và đồ còn bị bỏ và ghi log. Handler GC khác chưa port. Chưa có kiểm chứng GUI trong thế giới, vì offline không có server để nạp cảnh.
