# Vào thế giới bằng Game.exe CY (giao diện) — hướng dẫn thử, 14/09/2026 (bản world3b)

> **Cập nhật 14/09 13:30 — dùng world3b.** Bản world2 (`stage-91148e1-world2`) dừng ở màn nạp cảnh (struct DBC 0.85, `SceneDefine.txt` rỗng). Bản world3 đầu tiên (`stage-02a820e-world3`, 12:20) **cũng không dùng được**: thiếu `Bin64\create_role_profile.json` và chưa có các bản vá UI GL, nên Game.exe thoát ngay khi mở màn chọn nhân vật (chứng minh bằng phát lại offline, `Build\Logs\2026-09-14-world3\replay-run-1…3`). **world3b** gộp main (world3 + world-replay + navmesh + actionset + hud-widgets) và đã vào cảnh 2 Đại Lý bằng GUI phát lại offline 11/11, có HUD, ActionSet và navmesh. world2 và các stage world3/world3r cũ giữ nguyên để đối chiếu, **không dùng nữa**.

**Mục đích:** lần đầu vào thế giới bằng giao diện Game.exe mới, không phải bot. Chỉ nối clone thử nghiệm riêng 127.0.0.1:15733/15734, không phải server thật và không phải client_GL.

**Bản chạy:** `C:\TLBB\085\CY-Source\Build\world-gui\stage-798a682-world3b`

- Dựng bằng `Tools\game\stage_game.py build` (worktree `Build\wt-world3`, nhánh `world3` tại 798a682 = main 13cebf3 + 2 chuỗi Việt hoá phát lại + sửa NameError `stage_game` + navmesh tìm nhóm "Scene"). `Bin64` = Game.exe + mọi DLL của **một** cây build Release x64 (`Build\wt-world3\Build\cmake\world3-x64\bin`, log `Build\Logs\2026-09-14-world3\build-17-2d337f3-full.log`, `build-18-navmesh-group.log`), PDB đầy đủ; `Data` = junction tới `Assets\Canonical\Data`; `Overlay` = profile tạo nhân vật CY (controller chọn nhân vật c552d37, nút Vào game bật) + `Bin64\create_role_profile.json`; ui_compat: 85 kiểu Falagard, **0 cửa sổ bị lọc**.
- Game.exe sha256 `e96fe4950a37f911de126cc4f03c780c2e359b9bac52078c91284cc7e4b90972`. Toàn bộ hash: `Bin64\game_data_stage.json` và `Build\Logs\2026-09-14-world3\stage-world3b-hashes.txt`.
- Endpoint đã chuyển sang clone WSL bằng `Tools\game\stage_wsl_test.py apply` (`game_data_stage.json` mục `wsl_test`; `wsl-test-check-world3b.json` 0 problem): `WXSystem.cfg` GameServer_Port=15733, `Patch\LoginServer.txt` một máy chủ "CYS WSL Test", `Patch\WXLoginServer.txt` PORT=15733, launcher `Run-CY-Test.cmd` / `Run-World-GUI.cmd`. Cổng game 15734 nằm trong Game.exe. Muốn chạy lại smoke offline thì `stage_wsl_test.py revert` trước (phát lại `CYS_WORLD_REPLAY` không cần revert: nó không mở socket).
- Có sẵn: con trỏ GL, 60 fps trước/30 fps sau, hậu kỳ mặc định client_GL, thông báo đăng nhập/chọn nhân vật/vào game bằng tiếng Việt, HUD GL (thanh kỹ năng, chat, khung minimap), ActionSet của B (`CYS action-set: B tables loaded: 1724 sets …`), navmesh `dali.path` (`points=3734 tris=7453 … invariant_violations=0`).

**Kiểm offline của đúng bản này** (`Build\Logs\2026-09-14-world3\replay-world3b-2`, `Tools\game\run_world_replay.ps1`, 81 s, 0 socket): đăng nhập phát lại → chọn CYTest00 → `GCConnect generation=1 scene=2` → `GCEnterScene scene=2 res=2 obj=216` → `stats phase=in_world scene=2 … objects=19 … handler_errors=0` → `terminal=quit_complete … quit_flag=0 … decode_failures=0`; 5 PNG (login, charsel, world-1/2/final). Click-to-move tính được đường (`path=1 unreachable=0`) nhưng còn `limit_move=1` cho tới khi GCDetailAttrib được port (agent world-replay đang làm): **đi bộ có thể chưa chạy**.

**Chưa có, không phải lỗi mới:** minimap chưa có ảnh bản đồ (client_GL dùng ô `jpg_*.dds`), đi bộ bị `limit_move` như trên, nhiều cửa sổ GL còn thiếu hàm host Lua (log `missing host function`, `CYS Lua failure`).

## 1. Trước khi chạy

- Đóng mọi client đang đăng nhập **test00**, kể cả world2 và bản `stage-91148e1`, vì cùng tài khoản sẽ bị đá.
- Đóng **mọi Game.exe khác**, kể cả bản thử của agent khác (xem Task Manager). Client chỉ cho một bản chạy: nếu còn Game.exe khác, bản mới tự thoát ngay mà không báo lỗi.
- Clone đang chạy là đủ; không khởi động lại gì.
- Nếu Claude/orchestrator muốn đối chiếu, họ chụp snapshot "trước" (mục 5) **trước** khi bạn mở game. Snapshot 14/09 13:31 nằm ở `Build\Logs\2026-09-14-world3\gui-2\gui-pre.json`; nếu đã cũ thì chụp lại.

## 2. Các bước

1. Nhấp đúp `...\stage-798a682-world3b\Bin64\Run-World-GUI.cmd`.
2. Màn đăng nhập (một máy chủ "CYS WSL Test"): gõ `test00` và mật khẩu của bạn, bấm **Vào game**.
   - Mật khẩu chỉ gõ trong cửa sổ game và không được lưu ở đâu.
   - Nếu báo "Máy chủ thử nghiệm từ chối đăng nhập…" thì **dừng**, đừng thử liên tục: server đếm lần sai theo máy.
   - Các dòng trạng thái mong đợi: "Đang kết nối máy chủ thử nghiệm…", "Đang kiểm tra tài khoản thử nghiệm…", "Đang tải danh sách nhân vật…".
3. Màn chọn nhân vật: chọn **CYTest00**, bấm **Vào game** hoặc nhấp đúp vào thẻ nhân vật ("Đang vào game…").
4. Chờ nạp cảnh, thường vài giây. Mong đợi: CYTest00 đứng trong cảnh 2 (Đại Lý, `dali.Scene`) gần tọa độ (165, 170), xung quanh có quái và xe. Nhân vật có hoạt cảnh (ActionSet của B).
5. Đi vài bước: nhấp chuột trái lên mặt đất gần nhân vật 3–5 lần, mỗi lần chờ nhân vật chạy tới. Nếu nhân vật không đi (còn `limit_move`, GCDetailAttrib chưa port): ghi lại, không phải lỗi mới.
6. Thoát bằng menu: mở menu hệ thống (Esc hoặc nút hệ thống), chọn **Thoát game**, rồi xác nhận.
   - Sau khi bấm, cửa sổ có thể đứng yên vài giây, tối đa khoảng 15 giây. Đó là lúc client gửi lệnh thoát (CGAskQuit) và chờ server xác nhận.
   - **Đừng tắt bằng Task Manager.** Nếu không thấy menu, Alt+F4 cũng đi đúng đường thoát này.

## 3. Cần để ý

- Con trỏ chuột GL phải hiện rõ trên cửa sổ game. Khung hình khoảng 60 fps khi cửa sổ ở trước, 30 fps khi chuyển sang cửa sổ khác.
- Nạp cảnh mất bao lâu; nhân vật và tên trên đầu có hiện không; có đi được không; quái/NPC/xe xung quanh; có hộp thoại lỗi không (có thì chụp lại).
- **Chưa hỗ trợ, không phải lỗi mới:**
  - chat, kỹ năng, túi đồ, hội thoại NPC, nhiệm vụ, mua bán, đổi nhân vật hay đăng xuất về màn đăng nhập;
  - client mới chỉ gửi 8 loại lệnh: đi, vào/đổi cảnh, hỏi thuộc tính, trang bị, danh sách nhiệm vụ và cài đặt;
  - động tác nhân vật/quái, click-to-move theo navmesh, HUD/minimap đầy đủ (xem "Chưa có trong world3").

  Lần đầu đừng dùng kỹ năng, đừng giao dịch và đừng đi qua cổng dịch chuyển.
- Nếu kẹt ở màn nạp quá 30 giây hoặc game tự đóng: ghi giờ, chụp màn hình rồi đóng game.

## 4. Gửi lại cho Claude

- Giờ bắt đầu và giờ thoát.
- Kết quả từng bước 2–6: được hay không, thấy gì.
- Ảnh chụp: phím Print Screen trong game lưu vào `...\stage-798a682-world3b\ScreenShots`.
- Không cần gửi file: Claude tự đọc `Bin64\WXClient.log`. Log chỉ có ID và trạng thái, không có mật khẩu.

## 5. Dành cho Claude/orchestrator

**Snapshot không cần mật khẩu test00.**

- Collector chạy trong WSL bằng root và đọc Mongo của clone bằng credential DB riêng nằm trong config clone.
- Credential đó được đọc trong tiến trình và không in ra.
- Collector chỉ đọc và không đăng nhập game.

Chạy từ `C:\TLBB\085\CY-Source`:

```powershell
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py collect --label gui-pre --out-dir Build/Logs/2026-09-14-world3/gui-2
# ... người dùng làm mục 2 ...
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py collect --label gui-post --out-dir Build/Logs/2026-09-14-world3/gui-2
& 'C:\Program Files\Python313\python.exe' -B Tests/net/collect_world_snapshot.py review --pre Build/Logs/2026-09-14-world3/gui-2/gui-pre.json --post Build/Logs/2026-09-14-world3/gui-2/gui-post.json --allow-move --out Build/Logs/2026-09-14-world3/gui-2/review.json
```

- `--allow-move` chỉ báo độ lệch vị trí đã lưu, vì người dùng đi tự do.
- Các check còn lại giữ nguyên: service/PID/cổng, account, không có dòng mới ở `record_xy_rec`, `log_CGEnterScene`, `log_CGAskChangeScene`, đúng một bản ghi đăng nhập, log clone không thêm traceback/error.
- `one_login_record` FAIL có chủ đích nếu người dùng đăng nhập hơn một lần.

**Kiểm offline trước khi nhờ người dùng (đã làm 14/09, `Build\Logs\2026-09-14-world3\`):**

- `smoke-1`: `Tools\game\run_game_smoke.ps1` 75 s trên stage ở trạng thái offline: Game.exe sống, không dump, `DBC: 59 table(s) … 0 error(s), 4 absent`, dòng mới `DBC: SceneDefineEx scene 2 resolved name=Đại Lý scene=dali.Scene path=dali.path size=320x320`, UI Error 0, 4 PNG màn đăng nhập GL. Validator chỉ dừng ở luật "missing host" (`ZBS:IsViewerWatching`, `GMVisible:LuaFnGetViewType` là stub GL, như dbc-3).
- `world-run-1`, `netcore-run-1`: `cys_world_tests.exe`/`cys_netcore_tests.exe` của cùng build: unit + replay-model + 16 kịch bản loopback + 2 kịch bản bot PASS; NetCore unit/fuzz + replay + 20 loopback PASS.
- `profile-tests` 78/78, `selection-tests` 10/10 với LuaPlus.dll của build này.
- `stage-check-1`: reachability resolved 55.834, unreachable 0, CJK 0, missing 2.382 (client_GL tự thiếu, như dbc-3).

**Dòng `CYS world:` trong `...\stage-798a682-world3b\Bin64\WXClient.log`**, theo thứ tự mong đợi:

1. `game session started guid=200001 next_idx=7f00 port=15734`
2. `game socket 1 connected; CGConnect sent first next_idx=7f00`
3. `GCConnect generation=1 scene=2`
4. `GCEnterScene scene=2 res=… obj=… city=…`
5. `stats phase=in_world scene=2 my=… objects=… created=… deleted=… moves=… self_moves=…`, mỗi 10 giây.
6. Khi thoát: `CGAskQuit on shutdown; waiting for the server close`. Tiếp theo là `terminal=quit_complete code=… phase=closed quit_flag=0 … decode_failures=0 …` và `session summary …`. Lúc tắt máy thì 128 bị bỏ qua, nên không có dòng `GCRetAskQuit`.

Dòng thông tin, không phải lỗi, nhưng cần đếm:

- `legacy packet N has no modern mapping; not sent`: lệnh 0.85 chưa dịch sang giao thức mới.
- `first unhandled GC id=N`: packet GC chưa có handler.
- `model note …`
- `CYS action-set: … not found`: ActionSet kiểu client_GL chưa vào.

Dòng lỗi:

- `handler exception`
- `send refused`
- `game session rejected`
- `scene load failed on the client`
- `quit wait expired`
- `terminal=error`
- `quit_flag` khác 0
- `decode_failures` khác 0
- `DBC ERROR` (bảng lệch cột hoặc thiếu cảnh 2)
