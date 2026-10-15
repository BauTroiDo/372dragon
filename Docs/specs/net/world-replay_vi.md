# Phát lại offline phiên vào world — `CYS_WORLD_REPLAY` (14/09/2026)

Tiếp nối [world-session_vi.md](world-session_vi.md). Mục đích: kiểm màn vào world bằng **GUI Game.exe mà không cần server** và lặp lại được. Khi biến môi trường `CYS_WORLD_REPLAY` trỏ tới một fixture PGWORLD1, hai worker của NetCore (LoginClient, GameClient) chạy **nguyên vẹn** nhưng trên "nguồn dữ liệu" phát lại thay vì socket Winsock: không mở socket nào, đăng nhập nhận mọi tài khoản, danh sách nhân vật trả CYTest00/GUID 200001, charlogin cấp phép, rồi 741 khung GC ghi âm ngày 27/08 được đẩy vào client theo nhịp. Không đặt biến thì mọi đường thật giữ nguyên byte.

## 1. Cách chạy

Stage riêng (Game.exe + toàn bộ DLL từ một cây build của nhánh `world-replay`, dữ liệu Canonical qua junction `Data`):

```
Build\world-gui\stage-4eadede-replay\
  Bin64\Game.exe, *.dll, *.pdb, Run-World-Replay.cmd, game_data_stage.json
  Fixtures\world_session_1.bin       (PGWORLD1, sha256 21f59c88…339e)
  Data -> Assets\Canonical\Data      (junction; KHÔNG xoá đệ quy)
```

- **Chạy tay:** nhấp đúp `Bin64\Run-World-Replay.cmd`. Gõ tài khoản/mật khẩu bất kỳ, bấm Vào game, chọn CYTest00, vào world, nhấp đất để đi, thoát bằng menu. Không có server nào bị đụng tới.
- **Chạy tự động (≤ 90 s, tự tắt):** `Bin64\Run-World-Replay.cmd auto`, hoặc bộ chạy có kiểm chứng:

```powershell
# từ C:\TLBB\085\CY-Source (worktree world-replay có script này ở Tools\game)
powershell -NoProfile -ExecutionPolicy Bypass -File Build\wt-world-replay\Tools\game\run_world_replay.ps1 `
  -Stage Build\world-gui\stage-4eadede-replay -Fixture Build\Logs\2026-09-14-world-replay\world_session_1.bin `
  -OutDir Build\Logs\2026-09-14-world-replay\replay-run-NEW -Seconds 90
```

`run_world_replay.ps1`: chờ tới khi không còn Game.exe nào (tối đa `-WaitMinutes` 10, kiểm mỗi 30 s; không bao giờ tắt Game.exe của người khác), dời log cũ vào `prior-logs`, chạy `Game.exe -fl` với các biến bên dưới, ghi nhận mọi socket của tiến trình (phải rỗng), thu log/PNG/dump, rồi chấm 11 phép kiểm trong `run.json` (`checks`, `passed`).

Dựng lại stage từ worktree:

```powershell
python -B Build\wt-world-replay\Tools\game\stage_game.py build --name stage-<sha7>-replay `
  --out C:\TLBB\085\CY-Source\Build\world-gui\stage-<sha7>-replay `
  --bin C:\TLBB\085\CY-Source\Build\wt-world-replay\Build\cmake\wr-x64\bin --pdb
copy Build\Logs\2026-09-14-world-replay\world_session_1.bin Build\world-gui\stage-<sha7>-replay\Fixtures\
```

(`stage_game.py` chạy từ worktree tự lấy Canonical/CI stage/profile/client_GL từ cây chính — hằng `MAIN`.)

## 2. Biến môi trường

| Biến | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `CYS_WORLD_REPLAY` | (không đặt) | Đường dẫn fixture PGWORLD1. Không đặt = tắt hoàn toàn. Fixture hỏng thì ghi `CYS replay: fixture rejected` và **không** bật replay (cũng không mở socket vì không có ticket). |
| `CYS_WORLD_REPLAY_GAP_MS` | 20 | Nhịp giữa các khung world sau GCEnterScene (0 = đẩy hết một lượt). 738 khung × 20 ms ≈ 15 s. |
| `CYS_WORLD_REPLAY_DWELL_MS` | 12000 | Sau khi hết luồng, ở lại world thêm chừng này rồi tự đóng (chỉ khi AUTO). |
| `CYS_WORLD_REPLAY_DEADLINE_MS` | 80000 | Hạn tự đóng dù chưa vào được world (chỉ khi AUTO). `run_world_replay.ps1` đặt = (Seconds − 15) × 1000. |
| `CYS_WORLD_REPLAY_AUTO` | 1 | `0` = chỉ thay socket, người dùng tự thao tác. `1` = driver tự động: chọn server (1,5 s) → chụp `login` → `CheckAccount("replay","replay")` → chờ màn chọn nhân vật (2,5 s) → chụp `charsel` → `SelectRoleIndex(0)` + `SendEnterGameMsg(0)` → vào world → chụp `world-1` (+3 s), `world-2` (+8 s) → hết luồng + dwell → chụp `world-final`, ghi một dòng `stats`, `WM_CLOSE` (CGAskQuit đi trong `NetManager::Release → CysModernGame::Shutdown`). |

Ảnh PNG lưu ở `<stage>\ScreenShots\cys-replay-<tick>-<nhãn>.png` (qua `CysCaptureOfflineUi` của Render.dll, nên chụp được cả khi cửa sổ không ở trước).

## 3. Định dạng fixture (PGWORLD1)

Sinh bởi `Tests/net/make_world_fixture.py` từ capture PGFRAME1 (`Build/cmake/protocol-x64/test-data/capture_frames.bin`): 8 byte `PGWORLD1`, rồi các bản ghi `{u8 c2s, u16 id, u16 idx, u32 size, body[size]}` little-endian. Luồng C→S ghi trước (83 khung, bắt đầu 49 CGConnect), luồng S→C sau (741 khung, bắt đầu 67 KeyExchange, 456 GCConnect, 1764 GCEnterScene). Không có dấu thời gian (capture gốc cũng không có) nên nhịp phát là tổng hợp (`GAP_MS`). `LoadFixture` từ chối file thiếu hình dạng này. Khung login của phiên gốc (tài khoản, khoá) **không** có trong fixture.

Hành vi của nguồn phát lại (`Src/Client/NetCore/ReplayStream.cpp`):

| Client gửi | Trả lời cục bộ |
| --- | --- |
| 355 CLConnect | 311 LCRetConnect |
| 299 CLAskLogin (mọi tài khoản; thân không được đọc) | 223 LCRetLogin flag 0 + 554 LCStatus |
| 711 CLAskCharList | 319 LCRetCharList: 1 nhân vật CYTest00, GUID 200001, sex 1, lv 15, face 100, hair 5, portrait 13, scene 2 |
| 426 CLAskCharLogin guid | 38 LCRetCharLogin result 0 (GUID khác → 1), ip 127.0.0.1, port 15734, key cố định |
| 49 CGConnect (phải là khung đầu, đúng GUID/key) | 67 + 456 ghi âm (scene 2, pos 162,156); sai → im lặng như server |
| 824 CGEnterScene | 1764 ghi âm (obj 216), rồi 738 khung world theo nhịp |
| 3 CGHeartBeat | không trả lời, đếm |
| 352 CGCharMove | 564 GCCharMove của chính obj 216 với đúng đường đích (như broadcast của scene); 1090 không bao giờ gửi (server thật cũng không) |
| 1727 CGAskQuit | 128 GCRetAskQuit flag 0, rồi đóng luồng |
| khác (402, 404, 5, 957, 687, 753, 414, …) | đếm `unexpected`, ghi log lần đầu theo id `client packet id=N size=M recorded; no reply` |

Log của nguồn phát lại đi vào `WXClient.log` với tiền tố `CYS replay:` (chỉ id/cỡ/bộ đếm; không body, không khoá, không chữ đăng nhập).

## 4. Mã

- NetCore (giao diện nguồn dữ liệu, cách duy nhất replay chạm vào NetCore):
  - `NetStream.h/.cpp`: `Stream` (connect/write/wait/read/close), `StreamFactory`, `WinsockStreamFactory()` = socket cũ (non-blocking, TCP_NODELAY, WSAPoll) với đúng thông báo lỗi cũ.
  - `LoginClient`/`GameClient`: `Options::streamFactory` / `GameOptions::streamFactory` (null = Winsock). Worker chỉ đổi lời gọi socket sang `Stream`; máy trạng thái, idx, timeout, backpressure không đổi.
  - `ReplayStream.h/.cpp`: `replay::LoadFixture`, `replay::Session` (loginFactory/gameFactory/stats/drainLog).
- Game.exe (`// CYS:`): `Network/CysWorldReplay.{h,cpp}` (đánh giá biến một lần, factory, driver), hook ở `GamePro_Login::CheckAccount` (nhánh replay trước nhánh WSL test), `CysModernGame::Start` (gắn factory) + `LogStatsNow`, `GameProcedure` (Tick driver; render cả khi cửa sổ không focus), `wxclient.cmake`.
- Test: `cys_world_tests --replay-source <fixture>` (20 check) và ca `replay-source` trong `run_world_session_tests.py`.

## 5. Kiểm chứng

Bằng chứng ở `Build\Logs\2026-09-14-world-replay\`:

- `world-run-1`: unit + replay-model + **replay-source** + 16 loopback: PASS. `netcore-run-2`: unit/fuzz + replay1699 + 20 loopback: PASS (không đổi sau khi tách seam).
- `replay-run-N`: chạy GUI tự động; xem `run.json` (`checks`), `WXClient.log`, PNG. Mục kết quả bên dưới.

## 6. Kết quả chạy GUI (14/09)

**`replay-run-12` PASS 11/11** (stage `stage-4eadede-replay`, Game.exe sha256 `8d96505d…`): 78,3 s, rc 0, tự thoát, **0 socket**, 0 dump, 5 PNG (login, charsel, world-1, world-2, world-final). `replay-run-10` và `-11` cũng PASS 11/11. Các dòng chính trong `WXClient.log`:

```
CYS world: game session started guid=200001 next_idx=7f00 port=15734
CYS world: GCConnect generation=1 scene=2
CYS world: GCEnterScene scene=2 res=2 obj=216 city=0
CYS replay: in world 7266 ms after start
CYS world: stats phase=in_world scene=2 my=216 objects=20 created=103 deleted=83 moves=19 self_moves=11 ...
CYS replay: counters ... game_tx=205 game_rx=741 world=738/738 first_idx=7f00 idx_contiguous=1 connect_first=1 protocol_errors=0
CYS world: terminal=quit_complete code=none phase=closed quit_flag=0 ... decode_failures=0
```

Ảnh world: nhân vật (tên hiển thị "bot001", lấy từ GCCharBaseAttrib ghi âm) đứng trên quảng trường Đại Lý (cảnh 2), có HUD GL, khung chat, thanh kỹ năng và minimap. Quái/NPC có trong model (objects tới 20) nhưng không lọt khung hình ở hai ảnh.

Từ lượt 1 tới lượt 9, mỗi lượt lộ ra một lỗi chặn đường vào world trên dữ liệu Canonical. Các lỗi đã được sửa lần lượt, mỗi lỗi một commit:

| Lượt | Lỗi | Sửa |
| --- | --- | --- |
| 1 | `TDThrow "CY creation profile is not installed."` khi nhận danh sách: stage thiếu `create_role_profile.json`, còn thông điệp lỗi thì bị mất | `stage_game.py` chép profile; `tThrowStringException` ghi dòng `TDThrow:` vào log |
| 2 | AV ghi 0x378 trong CEGUIBase: `FalagardComplexWindow::setActionButtonSize` gọi `d_ParentWindow->requestRedraw()` trước `initialise()` | kiểm null ở 6 chỗ |
| 3 | `RendererException` thiếu `CysCreateRole/Common/button06.tga`: overlay bỏ file vì trùng byte với một file Canonical ở đường dẫn khác | overlay vẫn thêm file khi chỉ trùng tên cơ sở |
| 4 | `WoWLook/CreatureBoard` chưa đăng ký | dùng `TLBB_CreatureBoard` khi có |
| 5 | `WoWLook/StaticImage` chưa đăng ký (MiniMap) | alias WoWLook/* → TLBB_* sau khi nạp scheme |
| 6 | Không có `daliscene.jpg` (minimap GL dạng ô) | `FalagardSceneMap::getImageByName` bắt ngoại lệ, để nền trống |
| 7 | `AnimateManager::getAnimate('')` (look GL không có AnimateImage) | 8 chỗ ở SceneMap/MiniMap/Radar kiểm `isAnimatePresent` |
| 8 | `getStateImagery 'Enabled'` không có trong `TLBB_Look_SceneMap` | `FalagardStaticImage` bỏ qua trạng thái không có |
| 9 | AV đọc 0x8 ở `TransTitleStr` ← `OnGCCharBaseAttrib` (ID danh hiệu không có trong bảng GL) | trả chuỗi rỗng |
| 10–12 | PASS | driver thêm click-to-move và dòng bộ đếm |

Phân tích crash không cần debugger:

- `TDCrashReport` ghi minidump vào `%TEMP%`; runner đặt TEMP trong thư mục bằng chứng nên file nằm ở `replay-run-N\tmp\dmpNNN.tmp`.
- Chạy `python -B Tools/game/minidump_frames.py <dump> --symbolize`; script dùng `llvm-symbolizer` với PDB trong stage.
- Ngoại lệ CEGUI xem ở các dòng `(Error)` của `UISystem.log`.

**Cập nhật 13:40: di chuyển trên GUI ĐẠT** ở `replay-run-16` (20/20 với `-Move`): port GCDetailAttrib đặt `limit_move=0` từ gói của server, navmesh `dali.path` nạp, 3 click đất → 3 `CYS: click-move`, 3 CGCharMove + 3 echo, vị trí đổi (6,6), PNG trước/đang chạy/sau. Đoạn dưới là chẩn đoán trước khi sửa.

**(Trước sửa) Di chuyển trên GUI chưa đạt.** Lần click-to-move tự động có đường đi hợp lệ (`path=1 units=1 direct=1 unreachable=0`), nhưng `limit_move=1`. Vì vậy `CAI_MySelf::AI_MoveTo` từ chối và client không gửi CGCharMove (`moves=0`). Nguyên nhân: `m_bLimitMove` của MySelf chỉ được đặt trong `GCDetailAttribHandler` của 0.85, và handler này chưa được port sang nhánh hiện đại. Trong phiên, nhân vật vẫn đổi vị trí theo các GCCharMove ghi âm của chính obj 216 (self_moves 19). Phần echo di chuyển của nguồn phát lại đã được kiểm bằng unit test `--replay-source`.

## 7. Giới hạn

- Fixture không có thời gian thật: nhịp phát là đều (`GAP_MS`), không phải nhịp của phiên 27/08.
- Chỉ một socket game: fixture không có đổi cảnh (809/280), nên transfer không được phát lại; `GCNotifyChangeScene` sẽ không bao giờ tới, và `CGAskChangeScene` do client gửi chỉ được ghi log.
- Driver chạy 3 click sau khi hết luồng ghi âm; `run_world_replay.ps1 -Move` kiểm thêm 9 điều kiện đi bộ.
- Phản hồi di chuyển chỉ là echo đường đi (client tự đoán chuyển động; echo cùng handle bị `PushCommand` bỏ qua như với server thật). Không có navmesh phía server, nên đi xuyên vật cản không bị chặn.
- Mọi lệnh khác (thuộc tính, túi đồ, kỹ năng, chat…) không có trả lời: UI liên quan sẽ chờ mãi như khi mất gói.
- Nhân vật CYTest00 trong danh sách dùng ngoại hình cố định (face 100/hair 5/portrait 13) — phải có trong bảng CY của stage (profile tạo nhân vật), nếu không `SetModernCharacterList` từ chối danh sách.
- Cổng 15734 vẫn cố định (`kCysWslTestGamePort`), replay trả đúng cổng đó.
