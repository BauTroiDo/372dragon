# Server riêng CY-Source và hồ sơ máy chủ của client — 14/09/2026

Chỉ thị người dùng 14/09: không nhắm server gốc nữa; dùng server gốc làm nguồn để dựng **server riêng** được phép sửa và khởi động lại. Server riêng là clone `/home/ubuntu/cys-test-20260913` đã dựng ngày 13/09 (giữ tài khoản `test00`, nhân vật `CYTest00` GUID 200001 và bản sửa route Tool/.textfilter). Tài liệu này mô tả server đó, cách quản lý phiên bản, vận hành an toàn, sao lưu, và cách Game.exe biết endpoint bằng cấu hình.

Phương án server lâu dài (giữ skynet riêng rồi chuyển dần sang CY, hay server khác) do agent `cy-switch` quyết. Mọi thứ dưới đây dùng được cho cả hai: đổi server hay giao thức chỉ là đổi hồ sơ máy chủ.

## 1. Thành phần

Mọi đường dẫn nằm trong WSL `TLBB`, gốc `R=/home/ubuntu/cys-test-20260913` (root, quyền 0700).

| Dịch vụ | Tiến trình | Cổng (chỉ 127.0.0.1 trừ khi ghi khác) | Cấu hình |
|---|---|---|---|
| MongoDB 4.4 riêng | `/usr/bin/mongod --config R/mongod.conf` | 27018, có xác thực | dữ liệu `R/db`, log `R/log/mongod.log` |
| MQTT | `/usr/sbin/mosquitto -c R/mosquitto.conf -d` | 1884 | |
| Manager | `R/GameServer/framework/Manager_tlbb_8 R/GameServer/config_8` | 18888 | |
| DataCenter | `…/DataCenter_tlbb_9 …/config_9` | 12531, 16009 | |
| Tool | `…/Tool_tlbb_6 …/config_6` | 12532, 16006, 18000 (web), 23010–23013 | |
| Game (zone 1) | `…/Game_tlbb_2 …/config_2` | **login 15733, game 15734**, 12528, 16002 (debug_console) | |

- Script gameplay nằm ở `R/Game_2/Script`, scene ở `R/Game_2/Scene`, bảng ở `R/configs` (GBK). Cấu hình cụm nằm ở `R/confs/publish_yu`.
- `cluster_db_conf.lua` của server riêng là **lớp bọc** quanh `cluster_db_source.lua` (bản sao nguyên văn của server gốc). Lớp bọc chỉ bật tiến trình 2/6/8/9, cộng 10000 vào mọi cổng, ép `address` và `host_conf` về 127.0.0.1.
- `server_conf.lua` riêng có `server_ip = 127.0.0.1`. Đây là IP mà LCRetCharLogin trả cho client. Mongo trỏ 27018 với user riêng; mật khẩu không được ghi ở đây.
- `GameServer/config_N` do `config_maker.lua` sinh lại mỗi lần start (`thread = 16` thay cho 64).
- Trạng thái đo lúc 14/09 14:17 (`Build/Logs/2026-09-14-live-endpoint/cys-server/status-1.txt`): 6 dịch vụ chạy từ 13/09 14:47, PID file khớp, 16/16 cổng lắng nghe, 0 kết nối client.

## 2. Khác server gốc ở đâu

Đo bằng `diff -rq` chỉ đọc (`cys-server/diff_orig-1.txt`, `diff_orig-2.txt`, `diff_orig-3.txt`). Ngoài các file `*.bak*` không được chép sang, chỉ 13 file khác nhau:

| Nhóm | File | Thay đổi |
|---|---|---|
| Route Tool/.textfilter (13/09) | `GameServer/cluster/service/cluster_mgr.lua` | +7 dòng: manager phát lại peer cùng group cho node online muộn. Nhờ vậy Game không mất proxy `.textfilter`/`.ranking` khi Tool online lúc Game đang nạp scene. SHA sau vá `353c6f21…47ad`. |
| Chỉ bind nội bộ | `services/hs_admin.lua`, `pay.lua`, `payend.lua`, `register.lua` | `socket.listen("0.0.0.0")` → `"127.0.0.1"` |
| Đường dẫn gốc → gốc riêng | `lualib/preloader.lua`, `start_zone.sh`, `start_all.sh`, `r.sh`, `r_DataCenter.sh`, `r_tool.sh`, `Game_2/Script/scripts/CDK.lua`, `NewLua/daluandou/daluandou_npc.lua` | `/home/ubuntu/...` → `R/...` |
| Cấu hình cụm | `confs/publish_yu/{cluster_conf,cluster_db_conf,server_conf}.lua` | như mục 1 |
| Dữ liệu | Mongo 27018 **mới**, không chép DB live | account `test00`, nhân vật `CYTest00` |

- Bảng `configs`, `Game_2/Script` và phần còn lại của services giống server gốc từng byte tại thời điểm clone (13/09 07:26). Sau đó server gốc không có file nào mới hơn.
- Vì vậy các lỗi server đã biết (mục 5 việc 5 của TIMELINE) có ở cả hai server. Sáu bản vá dạng patch, đã kiểm tĩnh trên bản sao `/tmp` và **chưa áp**, nằm ở `Build/Logs/2026-09-14-live-endpoint/server-patches/`. Có áp hay không do phương án của `cy-switch` quyết; áp xong phải restart.

## 3. Quản lý phiên bản (git trong server riêng)

- Repo git nằm ngay tại `R` (nhánh `main`). Commit đầu `67fc059b27284029dee9e3c8294040625dcbf4f1` là trạng thái hiện tại: 9.791 file, `.git` 47 MB. Git 2.34.1 cài bằng apt trong WSL ngày 14/09.
- `.gitignore` loại:
  - `db/`, `log/`, `backups/`, `lifecycle-backups/`, `*.pid`, `nohup_*.out`, `account-created.json`;
  - `confs/publish_yu/server_conf.lua` (có mật khẩu). Thay vào đó git theo dõi `server_conf.lua.example`, đã xoá trống 4 trường user/password;
  - `GameServer/config_N` (sinh lại mỗi lần start);
  - binary: `framework/`, `3rd/`, `luaclib/`, `lualib-src/`, `cservice/`, `*.so`, `*.a`, `*.axp`;
  - scene nhị phân `Game_2/Scene/**/*.{path,stall,nav}`;
  - các bản sao lưu cũ `*.bak*`, `*.mapbak-*`, `*.pre-count-*`.
- Được theo dõi: `GameServer/services`, `lualib`, `cluster`, `msgagent_module`, script shell; `Game_2/Script` (3.854 lua); scene `.ini/.txt/.scn/...`; `configs` (txt/ini/ai/xml); `confs` (trừ file mật khẩu); `provision.json`, `source-manifest.json`, `mongod.conf`, `mosquitto.conf`.
- Lưu ý: `GameServer/lualib/app/routes/user.lua` có tài khoản mặc định của web admin (cổng 18000) viết cứng trong mã nguồn gốc. Repo chỉ nằm cục bộ; không push lên đâu.
- Sửa có lịch sử, chạy trong WSL bằng root:
  ```bash
  cd /home/ubuntu/cys-test-20260913
  git status
  git add -p GameServer/services/...
  git commit -m "..."
  ```
  Commit trên CY-Source chỉ ghi SHA của repo này, không chép file server.
- Kiểm nhanh không lộ bí mật: `git ls-files | grep -E 'server_conf.lua$'` phải rỗng.

## 4. Vận hành: `Tools/server/cys_server.sh` (+ `cys_server.ps1`)

Chạy từ `C:\TLBB\085\CY-Source`:

```powershell
powershell -NoProfile -File Tools\server\cys_server.ps1 status
powershell -NoProfile -File Tools\server\cys_server.ps1 backup truoc-khi-sua
powershell -NoProfile -File Tools\server\cys_server.ps1 restart --confirm-root /home/ubuntu/cys-test-20260913
powershell -NoProfile -File Tools\server\cys_server.ps1 restore /home/ubuntu/cys-test-20260913/backups/<thư-mục> --confirm-root /home/ubuntu/cys-test-20260913
```

- **`status`** chỉ đọc. Nội dung:
  - 6 dịch vụ, nhận diện bằng exe + config + cwd trong `R`;
  - cổng, tính bằng bảng LISTEN của kernel, không mở kết nối thử;
  - số kết nối client ESTABLISHED trên 15733/15734;
  - commit git và số file sửa dở;
  - bản backup cuối;
  - danh sách tiến trình server gốc, chỉ để nhìn.
- **`backup [nhãn]`** chạy được khi Mongo riêng đang chạy. Kết quả nằm ở `R/backups/<UTC>-<nhãn>/`:
  - `mongo/` (`mongodump --gzip`, gồm các DB `admin`, `tlbb`, `tlbb_log`, `world_10`);
  - bản sao `server_conf.lua` (0600);
  - `backup.json` (git HEAD, số file sửa dở, sha256 từng file).

  Mật khẩu Mongo được đọc trong tiến trình và đưa cho mongodump qua file `--config` 0600 ở `/run`, xoá ngay sau đó; không in ra màn hình. Đã chạy thật: `backups/20260914T071843Z-initial-git-67fc059`, 39 file, 130.610 B (`cys-server/backup-1.txt`); không còn file tạm.
- **`stop` / `start` / `restart`** cần `--confirm-root R`. Thêm chặn:
  - từ chối khi còn client kết nối 15733/15734;
  - uỷ quyền cho `Tools/server/provision_test_wsl.py`. Script này dừng theo thứ tự Game → Tool → DataCenter → Manager → MQTT → Mongo bằng SIGTERM qua pidfd, sau khi kiểm lại exe/config/cwd/start-time; **không SIGKILL**. Start sinh lại config, bỏ qua dịch vụ đã chạy đúng, và chờ Tool nạp `ranking` trước khi start Game.
  - Chưa chạy trong đợt này. Guard đã kiểm: `stop` thiếu xác nhận → rc 2.
- **`restore`** cần `--confirm-root`, backup nằm trong `R/backups`, sha256 khớp, 0 client, và 4 dịch vụ skynet đã dừng (Mongo vẫn chạy). Lệnh chạy `mongorestore --drop`, không đụng DB `admin`. Guard đã kiểm khi server đang chạy: từ chối, rc 2 (`cys-server/restore-guard-1.txt`).
- **Không dùng `R/GameServer/start_zone.sh stop`.** Script đó kill theo số trong PID file. Nếu WSL tắt đột ngột, PID cũ có thể trỏ sang tiến trình khác, và chính lỗi này đang xảy ra ở server gốc (mục 8).
- Không bao giờ đụng server gốc: tool cố định gốc `R` và chỉ nhận tiến trình có exe nằm dưới `R`.
- Snapshot trước/sau một lượt chơi (chỉ đọc; collector đọc credential Mongo riêng trong tiến trình):
  ```powershell
  wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py collect --label pre --out-dir Build/Logs/<ngày>/<lượt>
  ```
  Chạy lại với `--label post` sau lượt chơi, rồi dùng lệnh `review` như trong `world-gui-howto_vi.md` mục 5.

## 5. Client: hồ sơ máy chủ `Patch/CysServerProfile.txt`

Game.exe không còn cổng game viết cứng (`kCysWslTestGamePort` đã bỏ). Giao thức hiện đại cũng không còn phụ thuộc biến `CYS_WSL_LOGIN_TEST`. Khi bấm đăng nhập, `CGamePro_Login::CheckAccount` đọc `..\Patch\CysServerProfile.txt` và tìm hồ sơ có `login` trùng đúng host:port của máy chủ đang chọn trong `Patch/LoginServer.txt`.

```
VERSION 1
[profile]
name=cys-server
login=127.0.0.1:15733
game_port=15734            ; hoặc game_port=reply: nhận cổng LCRetCharLogin trả về
allowed_hosts=127.0.0.1    ; 1–8 IPv4 loopback/LAN riêng, phải chứa host login
accounts=test00            ; tuỳ chọn; bỏ trống = mọi tài khoản
```

- **Có hồ sơ khớp:** dùng NetCore với đúng chính sách của hồ sơ. Không có hồ sơ và không có biến: máy chủ đó đi đường 0.85 cũ. File hỏng thì báo "Hồ sơ máy chủ … không hợp lệ" và không kết nối.
- **Chính sách host** (`NetCommon.h: IsHostAllowed`). Áp cho endpoint login, host trong LCRetCharLogin, ticket game và mọi GCRetChangeScene:
  - danh sách rỗng: chỉ 127/8, như trước;
  - danh sách có mục: host phải trùng một mục, và là loopback, hoặc là IP LAN riêng (10/8, 172.16/12, 192.168/16) **đang gán cho card mạng của máy này** (kiểm bằng `GetAdaptersAddresses`, không mở socket).

  IP công cộng hoặc tên miền không bao giờ hợp lệ, nên server không thể chuyển hướng client ra ngoài máy.
- **Cổng game:** cố định (phải trùng LCRetCharLogin) hoặc `reply`. Với `reply`, GameClient duyệt theo cổng của ticket, và các lần đổi cảnh phải cùng cổng đó.
- **Tương thích:** stage cũ không có file hồ sơ nhưng đặt `CYS_WSL_LOGIN_TEST=1` vẫn chạy với hồ sơ `wsl-test-legacy` (127.0.0.1:15733/15734, tài khoản test00). Phát lại `CYS_WORLD_REPLAY` không đổi.
- **Đổi server hay giao thức sau này:** sửa hồ sơ (endpoint, cổng, allow-list) và `LoginServer.txt`. Không cần build lại. Một server LAN kiểu server gốc (`server_ip=192.168.1.109`) sẽ là `login=192.168.1.109:5733`, `game_port=reply`, `allowed_hosts=192.168.1.109`.
- **Mã nguồn:**
  - `Src/Client/NetCore/ServerProfile.{h,cpp}` (parser chặt: ASCII, khoá bắt buộc, không trùng khoá/endpoint, ≤64 KiB, ≤16 hồ sơ);
  - `NetCommon.{h,cpp}`, `LoginClient`, `GameClient`;
  - `WXClient/Procedure/GamePro_Login.cpp` (hook `// CYS:`), `Network/CysModernGame.*`.

### Stage tool

`Tools/game/stage_wsl_test.py`:
- `endpoints` in endpoint thật của server riêng. Tool chạy `Tools/server/cys_server_endpoints.lua` trong WSL để tính `cluster_db_conf.lua` (tiến trình 2 logind/gamed) và `server_conf.server_ip` y như skynet; chỉ đọc, chỉ in cổng và IP.
- `apply --stage <stage> [--profile cys-server|wsl-test] [--accounts a,b]`:
  - hồ sơ mặc định `cys-server`;
  - ghi `WXSystem.cfg`, `LoginServer.txt` (một máy chủ "CYS Server"), `WXLoginServer.txt`, `Patch/CysServerProfile.txt`, `Bin64/Run-CY-Server.cmd`;
  - sha256 trước/sau lưu trong `Bin64/game_data_stage.json` mục `wsl_test`.
- `revert` là phép ngược chính xác.
- `check` kiểm file, hồ sơ, 37 binary, và đọc lại cấu hình server để báo nếu endpoint đã đổi.
- Smoke offline cần trạng thái offline: chạy smoke trước rồi mới `apply`. Phát lại thì không cần.

## 6. Bản chạy cho người dùng

- **Stage:** `Build/world-gui/stage-481ba3c-cys`, dựng bằng `stage_game.py build --pdb`.
  - Nguồn: 37 binary của một lần build Release x64 `Build/wt-live-endpoint/Build/cmake/live-x64` tại commit 481ba3c.
  - Game.exe sha256 `8e3806dc9de9286f9f4da30952ab770889baaa9e731a3603d52d9222ed20ad46`.
- **Kiểm đã làm:**
  - Phát lại offline trước khi áp hồ sơ: `replay-run-1` PASS 20/20, 80,5 s, 0 socket, 0 dump. Kết quả gồm GCEnterScene cảnh 2, navmesh, ActionSet B, `limit_move=0`, 3 click đi bộ, `quit_flag=0`.
  - Sau đó `apply` (hồ sơ `cys-server`: 127.0.0.1:15733, game 15734, allow 127.0.0.1) và `check` 0 lỗi.
- **Các bước:**
  1. Đóng mọi Game.exe, kể cả client_GL và bản thử của agent. Chỉ một Game.exe chạy được; launcher tự từ chối nếu còn bản khác. Đăng xuất test00 ở nơi khác.
  2. `Tools\server\cys_server.ps1 status`: 6 dịch vụ chạy, 16/16 cổng. Nếu server vừa restart, chờ Game nạp scene xong (cổng 15733 lắng nghe).
  3. Nhấp đúp `stage-481ba3c-cys\Bin64\Run-CY-Server.cmd`. Chọn máy chủ "CYS Server", gõ `test00` và mật khẩu trong cửa sổ game. Gõ sai thì **không thử lại liên tục**, vì server đếm lần sai theo máy.
  4. Chọn `CYTest00` → Vào game → đi vài bước → thoát bằng menu hoặc Alt+F4 để client gửi CGAskQuit. Không tắt bằng Task Manager.
  5. Log nằm ở `Bin64\WXClient.log`: dòng `CYS WSL login: started profile=cys-server game_port=15734 hosts=1`, rồi các dòng `CYS world:` (xem `world-gui-howto_vi.md`).
- **Chưa làm được:** chat, kỹ năng, túi đồ, NPC, nhiệm vụ, giao dịch, đổi nhân vật. Client mới chỉ dịch 8 loại lệnh CG: đi, vào/đổi cảnh, hỏi thuộc tính, trang bị, danh sách nhiệm vụ, cài đặt.
- **Rủi ro:**
  - cùng tài khoản bị đá nếu đang đăng nhập ở client khác;
  - mật khẩu sai bị đếm theo MAC;
  - idx gói sai làm server ghi Mongo (NetCore giữ bộ đếm liền mạch, test `idx_contiguous`);
  - server riêng dùng Mongo riêng, không ảnh hưởng dữ liệu người chơi thật.

## 7. Bằng chứng (`Build/Logs/2026-09-14-live-endpoint/`)

- **Build:** `build-02-profile.log`, `build-04-481ba3c.log` (rc 0).
- **Test:**
  - `Build/wt-live-endpoint/Build/Logs/live-endpoint/world-run-2`: unit + replay-model + replay-source + 18 loopback (thêm `reply-port`, `unlisted-host`) + 2 bot, PASS;
  - `netcore-run-2` (unit/fuzz + replay 1699 + 20 loopback) PASS;
  - `probe-run-1` (10 loopback + 5 guard) PASS.

  Bản chép nằm ở `tests/`.
- **Stage:** `stage-build-1.log`, `stage-apply-cys.json`, `stage-check-cys.json` (0 lỗi). `stage-check-offline.json` báo `WXSystem.cfg` lệch; đây là bẫy 19, vì game ghi file này khi thoát sau lượt phát lại. `replay-run-1/`.
- **Server:** `cys-server/{status-1,backup-1,restore-guard-1,git_step2b,diff_orig-*,secret_scan-*}.txt`; chỉ đọc: `wsl-readonly/*`.

## 8. Ghi chú về server gốc (chỉ đọc, không làm gì)

- Game gốc không chạy từ lần khởi động WSL 12/09 11:53 và 13/09 13:34. Nguyên nhân: `GameServer/skynet_2.pid` còn PID 852 từ 11/09, và `start_zone.sh` coi `kill -0 852` thành công là "đã chạy, bỏ qua" (journal `tlbb-game.service`).
- Hiện PID 852 là **luồng `conn33` của mongod gốc (PID 275)**. Vì vậy `start_zone.sh stop` của server gốc sẽ gửi SIGTERM, rồi có thể `kill -9`, **tới mongod gốc**. Muốn chạy lại server gốc thì phải xoá `skynet_2.pid` trước.
- Clone được dựng sau lỗi này (13/09 14:47), không phải nguyên nhân.
