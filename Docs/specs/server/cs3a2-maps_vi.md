# CS3a phần 2 — Lạc Dương, Tô Châu, Vô Lượng Sơn theo bản đồ CY; chỉ giữ 4 bản đồ; 0 MONSTER_CFG_FAIL

Ngày: 14/09/2026. Agent `cs3a2-maps`, nhánh `cs3a2-maps`. Bằng chứng: `Build/Logs/2026-09-14-cs3a2-maps/`.
Tiếp nối `cs3a-maps_vi.md` (Đại Lý, cách nạp cảnh, số đo) và `cs3c-tables_vi.md` (bảng theo ID CY, `retype`). Server riêng: `Docs/specs/net/cys-server_vi.md`.

Quy ước: **[DK]** dữ kiện đo được (đường dẫn/dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`. Nguồn CY: S4 = `Assets/CanonicalCY/Data`
(`.path`), bảng text `Tools/DATA NEW/DataCY31-08-26/Config`; tlbb15 = `…/tlbb15/Public/Scene` (chỉ đọc tĩnh). Bảng GL để đối chiếu tên quái: `git show 995c2df:configs/MonsterAttrExTable.txt` trong `R`.

## 0. Chỉ thị người dùng 14/09 (qua người điều phối, nguyên văn)

> "Chúng ta không làm nhiều map, chỉ cần 3 thành chính (lạc dương, tô châu, đại lý) và 1 map quái (vô lượng sơn) sau đó không làm map nữa, chỉ tập trung vào các chức năng chỉnh để hoàn thiện nó."

Điều chỉnh DoD của người điều phối: (1) Lạc Dương + Tô Châu theo CY; (2) thêm **Vô Lượng Sơn** theo bản đồ CY, đủ quái/NPC/hồi sinh/cổng nối Đại Lý;
(3) cảnh khác **không làm bản đồ**: tắt hoặc để nguyên nếu vô hại, ưu tiên server nạp sạch với ít công nhất, có thể tắt hẳn trong bảng scene và ghi lại để bật lại;
cổng tới cảnh đã tắt thì chặn/chuyển về thành gần nhất; (4) DoD 3–5 (dời CYTest00, restart + bot, hoàn tác) giữ nguyên.

Cách thực hiện (tự quyết theo luật, ghi ở mục 2–5): giữ **17 cảnh** = 4 bản đồ {0 洛阳, 1 苏州, 2 大理, 6 无量山} + phân tuyến cùng file {71, 72, 1320, 1321; 1311, 1315, 1316; 1312; 73, 74}
+ 地府 {77, 1500, 2218} (`define.SIWANG`, cơ chế chết/hồi sinh); **183 cảnh type 0 khác `active=0`** (`configs/cys_scene_off.json`, bật lại bằng `cs3a_scene.py scenes-on`).

## 1. Kết quả

| Việc | Trạng thái |
|---|---|
| Lạc Dương (0 + 1311/1315/1316) = `luoyang_new` 512×512 | Đã cài, commit `R` `259f934` |
| Tô Châu (1 + 1312) = `suzhou_new` 512×512 | Đã cài, `7282a76` |
| Vô Lượng Sơn (6 + 73/74) = `wuliang` (CY cùng bản đồ, `.path` bản 0x2000) | Đã cài, `e863482` |
| Đại Lý: 25 mục `pos_x=;` đổi tên section (56003/56007 hết MONSTER_CFG_FAIL) | `da9fe60` |
| Cổng đi bộ tới cảnh tắt → `script_id=-1` (12 cổng), giữ 大理↔无量山 | `7aa1bb6` |
| 183 cảnh `active=0` | `c7e7865` |
| `define.DEFAULT_SCENEID_AND_WORLD_POS` (165,170) → (160,150) | `5110685` |
| Kiểm tĩnh (`verify-1.txt`) | 17 cảnh active; 4 bản đồ 0 type ngoài CY (sống 179/218/167/339); luac 42/42; GBK 73/73 file đổi; 87/87 đích script đi được; dựng lại trùng byte (trừ area.ini do block-portals) |
| `luoyang_new.scn` bỏ `busfile` (lần restart 1 có 4 `SCENE_INIT_FAIL 公交创建异常`) | `76e15ba` (HEAD server riêng) |
| Restart + log | 3 lần (23:01, 23:04, 23:10): lần 2–3 **0 traceback / 0 SCENE_*_FAIL / 0 MONSTER_CFG_FAIL** (trước: 127), 17 cảnh, 15733 LISTEN sau ~30 s, không loại lỗi mới so với 22:15 |
| CYTest00 | (73; 59,153) → **(2; 160,150)**, `char-move-1.json`; sau bot goto về lại 73 → dời lần 2 về (2; 160,150), `char-move-2.json` |
| Bot live | lượt 1 `run_world_live.ps1` **PASS 8/8** vào cảnh 2 (160,150), 13 đối tượng; lượt 2 `run_core_live.ps1 --goto 304,149`: đi tới cổng, server `AUTO_ROUTE_TRANSFER 2→73 (43,172)`, vào 无量山2, 25 đối tượng, quit sạch, 0 lỗi log (review "FAIL" chỉ vì mẫu đòi vị trí không đổi) |

## 2. Công cụ `Tools/server/cs3a_scene.py` (mở rộng) [DK]

| Lệnh | Việc | Chạm `R`? |
|---|---|---|
| `build --city luoyang\|suzhou\|wuliang --out DIR` | dựng `<new>.scn` + ini/txt + `report.json` (vị trí, affine, cổng, retype, sửa script, ô sạp) | không |
| `install --city X --staging DIR [--force]` | chép file + `.path` CY; `SceneInfo.ini file=` cho cảnh gốc **và phân tuyến** (`shards`); `SceneAttr` cột 4/5, `SceneDefineEx` cột 2–16 theo CY; `Stall_Info.txt`; toạ độ đích script theo `report.script_fixes` | có |
| `retype-plan --city X --out F` / `retype … --disable-mode rename` | map type GL→CY theo tên (luật cs3c) cho file đã cài; tắt = đổi tên section | plan: không / retype: có |
| `block-portals --city X [--dry-run]` | area.ini đã cài: script cổng mà mọi cảnh đích ∉ `KEEP_SCENES` → `script_id=-1` | có |
| `scenes-off [--dry-run]` / `scenes-on` | `SceneInfo.ini` `active=1→0` cho cảnh type 0 ∉ `KEEP_SCENES`; ghi/đọc `configs/cys_scene_off.json` | có |
| `default-pos --x --z` | `define.DEFAULT_SCENEID_AND_WORLD_POS.world_pos` | có |

Lệnh cũ (`path-info`, `query`, `audit-scripts`, `survey`, `retype --disable-mode pos`) giữ nguyên; `dali` không dựng lại.

### 2.1 Vị trí NPC/quái (thứ tự nguồn, ghi từng mục trong `report.json`)
1. CY `MissionNPC_HashTable` + `TransportDefine` cùng tên [DK-CY]; 2. tlbb15 `<city>_monster.ini` cùng tên (+ tiêu đề) khi tlbb15 dựng cho cùng navmesh [DK-HJ];
3. bản đồ đổi kích thước → **affine** khớp bình phương tối thiểu trên cặp NPC cùng tên duy nhất, bỏ ngoại lai > 3×trung vị rồi khớp lại [SL-affine];
4. cùng kích thước → giữ toạ độ cũ nếu đi được [SL-giu]; 5. không đi được → ô đi được gần nhất ≤ 12 ô cùng vùng liên thông với điểm hồi sinh [SL-doi].

### 2.2 Tắt mục quái: đổi tên section, không dùng `pos_x=;` [DK]
`lualib/inireader.lua:26` lấy tên section bằng `%[([_%w]+)%]`, `scenecore:create_monsters` chỉ tra `monster0…monstercount-1` và bỏ qua khoá không có.
Quy ước cũ `pos_x=;giá trị` chỉ làm khoá `pos_x` biến mất; `create_monster_data` **vẫn tra `monster_attr_ex[conf.type]`** → type không có ở CY vẫn ra `MONSTER_CFG_FAIL`
(đo 22:15: 56003/56007 ở cảnh 2/71/72/1320/1321 dù đã `pos_x=;`), còn type có ở CY thì tạo quái với `world_pos` nil. Vì vậy `[monsterN]` → `[monsterN_off]`, thân giữ nguyên để bật lại.
Hai mục Đại Lý gốc có `pos_x=` **rỗng** (`monster165` 新宠大使 type 18, `monster167` type 12251) vẫn để nguyên như server gốc [DK, không đổi hành vi].

### 2.3 Retype theo tên CY (luật `cs3c_tables.scene2_retype`, port sang `retype_plan_for_ini`)
type GL đổi nghĩa ở CY → ID CY cùng tên (tên trong ini rồi tên GL); nhiều ứng viên: cùng 外型ID (CY cột 36 ↔ GL 44) → cùng cờ NPC (CY 5 ↔ GL 13) + cấp gần nhất (cột 3) → ID nhỏ nhất.
Không có tương đương (ID không có ở CY; NPC chỉ-GL; dòng GL không tên) → tắt.

### 2.4 Cổng đi bộ (area.ini) [DK + SL]
- Cổng = mục có `script_id` là script `scripts/event/chuansong/echuansong_*` (đích lấy từ `local x = {n,…}` hoặc `TransferFunc(…, N, x, z`); `eSceneAreaTransfer` (998568) lấy `target_scene` trong khối `TransferConfig[<cảnh>]`.
- Vị trí: cổng CY `ScenePosDefineEx` loại 0 gần nhất sau affine ≤ 20 ô; nếu xa hơn (cổng nằm sát biên, bản 512 rộng hơn nên affine tâm thành lệch 25–80 ô) → cổng CY **cùng hướng so với tâm** (lệch ≤ 45°; đo 0–14°) [SL hướng].
  Giữ khuôn mục cũ: hình chữ nhật `left/top/right/bottom` (dời tâm, giữ kích thước) hoặc `x/z/radious`.
- Vùng không phải cổng (擂台 806011, 113007, `script_id=-1` guid 11/12/111/611–613) → affine [SL].
- `block-portals`: mọi cảnh đích ∉ KEEP → `script_id=-1` (chặn hẳn, không rơi về Đại Lý).

### 2.5 Toạ độ đích trong `Game_2/Script` (`plan_script_fixes`) [DK + SL]
Mẫu `(TransferFunc|NewWorld|SetPos|ChangeScene) … , <cảnh>, x, z` (47 Lạc Dương, 40 Tô Châu, 0 Vô Lượng Sơn cần sửa):
1. affine rồi **bám điểm đích CY vào cảnh** (`ScenePosDefineEx` loại 1 + vị trí NPC `TransportDefine`) trong ≤ 12 ô [DK-CY-dest] — 36 + 33 mục, ví dụ 驿站→洛阳 (132,183)→**(235,322)**, (234,132)→**(326,269)** 九州商会/汪旱; →苏州 (114,162)→**(204,256)**, (235,132)→**(335,225)** 铁匠铺; 考场/珍珑 (268,87)→(366,228) 王积薪;
2. script truyền tống (`echuansong_*`/`chuan_song_*`) có điểm cũ sát biên bản 320 (≤ 70 ô) → đích cổng đi bộ CY cùng hướng [DK-CY-arrival] — 嵩山→洛阳 (256,465), 雁南→洛阳 (446,259), 太湖→苏州 (279,44), 镜湖→苏州 (65,270), 西湖→苏州 (279,416);
3. còn lại affine → ô đi được gần nhất ≤ 15 ô [SL] — 9 + 7 mục (神境/擂台/地宫/蹴鞠/帮会…).
Sau sửa `audit-scripts` = 0 điểm không đi được cho cả 3 cảnh (`verify-1.txt`). Chỉ đổi số trong dòng, số dòng không đổi; `luac5.4 -p` 42/42.

### 2.6 Bàn thao tác, tuần tra, thu thập, ô sạp
- `platform.ini`: tlbb15 (Tô Châu) hoặc affine + dời tới ô đi được gần nhất ≤ 60 ô vùng chính (Lạc Dương: 3/4 bàn rơi vào nhà, dời 39–40 ô) [SL]; `class=10` là bảng chỉ đường, server không tạo (`create_platform`).
- `patrolpoint.ini`: tlbb15 hoặc affine (Lạc Dương 519 điểm, 479 đi được); `growpoint.txt`: Lạc Dương/Tô Châu rỗng, Vô Lượng Sơn 363 điểm giữ.
- `stallinfodata=` giữ file `.stall` cũ: `scenecore:init_stall_info` đã bị chú thích, **server không đọc `.stall`** (`scenecore.lua:416`); ô sạp lấy từ `configs/Stall_Info.txt` (`cfghelper:read_stall_info`) → 3 dòng của cảnh 0/1 affine rồi trượt ≤ 30 ô tới chỗ tỉ lệ ô đi được cao nhất (Tô Châu 0,69 → 0,97) [SL].
- `portalfile=` (Tô Châu) giữ như .scn cũ: scenecore không đọc [DK].

## 3. Lạc Dương — cảnh 0 (`luoyang_new`) [DK]
- Navmesh CY `luoyang_new.path` nguyên byte (10.546 đỉnh / 21.080 tam giác / 9.737 chặn, 64×64 ô 8). Điểm đứng CY `SceneAttr` (256,416) vùng 1.
- Affine bản cũ→CY: x' = 1,0006x − 0,0022z + 96,34; z' = −0,0101x + 1,0268z + 137,85 (110 cặp; sai số trung vị 2,9 ô, p90 16,1; 5 ngoại lai 程颐/程颢/程安/游酢/杨时 43–61 ô = NPC CY dời hẳn chỗ).
- 254 mục `luoyang_monster.ini`: DK-CY 113, affine 105, affine + dời ≤ 2,5 ô 12, `pos_x=;` cũ 24. Retype 4 (52124 韩世忠→14, 43629 贝师师→50409, 52590 #Y左/右护法→52671 悟空残念), tắt 36 (24 `pos_x=;` cũ + 50147 庄云饰 không có ở CY + 11 NPC chỉ-GL: 孟闯 莫问之 张伏虎 张笑狮 满血满怒 欧冶安/画/菡 玄智法师 墨知愁 裂隙入口). 32 NPC CY không có ở skynet (迷失的* thú đi lạc, 帮会弟子, 孟华/木夏/云凛凛… 驿站 CY) — không thêm vì thiếu type/script.
- Cổng: 敦煌 (85,257), 嵩山 (256,465), 雁南 (446,259) = `ScenePosDefineEx` #1/#2/#3, cả ba **chặn** (cảnh 8/3/18 tắt); Summoner Rift (`area7`, 998568) affine (256,411) r7 sát điểm đứng → chặn (2219 tắt).
- `SceneInfo` scene0 `_clientres=242` (tuyết) với `BeginPlus/EndPlus` 2008–2009 đã hết hạn, giữ nguyên; `SceneDefineEx` dòng 242 không đổi.

## 4. Tô Châu — cảnh 1 (`suzhou_new`) [DK]
- Navmesh CY `suzhou_new.path` (9.363 / 18.710 / 8.715). Điểm đứng (279,371). tlbb15 `suzhou.path` = CY `suzhou_new_SP.path` (sha256 `505c8f14…`) nên `suzhou_monster/platform/patrolpoint/growpoint/portal` tlbb15 dùng được (cùng hệ toạ độ 512).
- Affine: x' = 1,0814x + 0,0278z + 76,33; z' = −0,0366x + 1,0350z + 98,43 (78 cặp, trung vị 7,8 ô, p90 23,6 — kém hơn Lạc Dương, chỉ dùng cho 58 + 27 mục không có ở CY/tlbb15).
- 179 mục: DK-CY 79, tlbb15 15, affine 58, affine + dời ≤ 7,5 ô 27. Retype 2 (49668 云四合→100, 49463 周仲青→48261), tắt 12 (49781 艾虎, 49970 云宸宸 không có ở CY; 10 NPC chỉ-GL 云深深/云晓晓/沈夜雨/云兰舟/云决决/陈德/苏陶/谢云亭×2/种师道). 37 mục tlbb15 không gắn (khác nhánh, bẫy 7.4), 1 NPC CY 龙禹 không có.
- Cổng 太湖 (279,44), 镜湖 (65,270), 西湖 (279,416) = #5/#4/#6 (trùng rect tlbb15), cả ba chặn (4/5/30 tắt).

## 5. Vô Lượng Sơn — cảnh 6 (`wuliang`, + 73/74) [DK]
- CY giữ tên file; `wuliang.path` CY bản 0x2000 (303.424 B) cùng hình học với bản 0x1000 của server (2.632 đỉnh, 5.258 tam giác, 2.434 chặn) → chép CY (bản cũ lưu `staging/pre/wuliang.path`). `SceneAttr` (43,172) và `SceneDefineEx` dòng 6 đã trùng CY.
- 339 mục: 339/339 type cùng tên CY (không retype, không tắt); 19 NPC có ở CY `MissionNPC` → vị trí CY (14 trùng ≤ 2 ô), 319 giữ, 1 dời 2 ô. 2 NPC CY không có ở skynet (芦苇草人, 货商).
- Cổng CY #21 大理 (32,176) **giữ** (đích 2/71/72/1320/1321); 镜湖 (287,77), 天龙寺 (94,286), 凌波洞 (116,32) chặn. Đại Lý → 无量山 giữ `dali_new_320_area.ini` area2 (304,149) → script 400006 → (43,172) cảnh 6/73/74 ngẫu nhiên [DK `echuansong_dali_wuliang.lua`].

## 6. Áp, restart, kiểm, hoàn tác
- Sao lưu `cys_server.ps1 backup truoc-cs3a2-maps` → `R/backups/20260914T155451Z-truoc-cs3a2-maps` (4 DB, 39 file, git 2ccf33a). Bản sao file bị ghi đè: `staging/pre/` (+ `sha256.txt`).
- Áp: `scripts/30-apply.sh` (7 commit, `apply-1.txt`), kiểm `scripts/31-verify.sh` (`verify-1.txt`).
- Restart: `scripts/45-idle-restart.ps1` (rảnh: 0 Game.exe, 0 TCP 15733/15734, `status` 0 client; kiểm mỗi 60 s ≤ 20 phút) → `40-restart-move.sh` (stop → `mongod --config R/mongod.conf` → `cs3a_move_test_char.py apply --scene 2 --x 160 --z 150` → start) → `41-wait-and-logcheck.sh 900`.
- Kết quả restart / nhân vật / bot: **[điền ở mục 6.1]**.
- Hoàn tác: `git -C R revert 5110685 c7e7865 7aa1bb6 da9fe60 e863482 7282a76 259f934` rồi chép lại `staging/pre/wuliang.path` (git không theo dõi `.path`) và restart; hoặc `cys_server.sh restore backups/20260914T155451Z-truoc-cs3a2-maps` cho Mongo. Nhân vật: `char-move-1.json` có bản ghi trước khi dời. Bật lại cảnh: `cs3a_scene.py scenes-on`.

### 6.1 Restart, nhân vật, bot [DK]
- **Restart 1** 23:00:44 (rảnh: Game.exe 0, TCP 0, client 0; `idle-wait-1.txt`) → stop → Mongo riêng → `CYTest00` (73; 59,1;153,4) → (2; 160,150) (`char-move-1.json`, matched/modified 1) → start 23:01:33 → 15733 LISTEN 23:02:03 → `SceneManager scene startup done, total = 17`; 0 traceback, 0 MONSTER_CFG_FAIL (trước 127), nhưng **4 `SCENE_INIT_FAIL 场景 0/1311/1315/1316 公交创建异常 … nil 'patrol'`** (`wait-logcheck-1.txt`): `luoyang.scn` gốc không khai `busfile` (bus `patrolPathID=53` trong khi `PATROLNUMBER=53` → `get_patrol_path_by_index(53)` nil), tool đã thêm vì `luoyang_bus.ini` tồn tại → sửa tool + `.scn`, commit `76e15ba`.
- **Restart 2** 23:04:16 → LISTEN 23:05:11 → **0/0/0/0/0**, 17 cảnh, không loại lỗi mới (`wait-logcheck-2.txt`; còn 2 cảnh báo cũ clock/Memory).
- **Bot 1** 23:05:53 `Tests/net/run_world_live.ps1` (bot ghim hash): login → `AUTO_ROUTE_ENTER scene=2 x=160 y=150` → 13 đối tượng, 2 bước, CGAskQuit → review **PASS 8/8** (`bot-live-1/`).
- **Bot 2** 23:07:17 `run_core_live.ps1 -Bot Build/cmake/coord-x64/bin/CysNetBot.exe -Goto 304,149`: vào cảnh 2, đi thẳng tới cổng `dali_new_320_area.ini` area2 (304,149) → `AUTO_ROUTE_TRANSFER scene=2 to=73 x=43 y=172` → `AUTO_ROUTE_ENTER scene=73 client_res=6` → 25 đối tượng tạo, quit sạch, `transfers: 1`, `portal_asks: 1`, `final_scene: 73`, `final_pos: [43,172]` (`bot-live-2-goto/run-20260914-230717/bot/result.json`); log server 0 lỗi từ 23:05 (`post-bot-1.txt`). Review FAIL `position_unchanged`/`bot_result` = mẫu review của lượt đứng yên, không phải lỗi.
- **Restart 3** 23:09:33 (dời `CYTest00` 73 → (2; 160,150), `char-move-2.json`) → LISTEN 23:10:50 → 0/0/0/0/0, 17 cảnh (`wait-logcheck-3.txt`). Trạng thái cuối: server riêng HEAD `76e15ba`, cây sạch, 16/16 cổng, nhân vật ở cảnh 2 (160,150).
- Lạc Dương/Tô Châu chưa vào bằng bot (không có cổng đi bộ từ Đại Lý; 驿站 cần thoại NPC — bot chưa dịch lệnh này): kiểm tĩnh (`verify-1.txt`) + nạp cảnh sạch trong log.

## 7. Rủi ro còn lại / việc sau
- Cảnh đã tắt: mọi 驿站/nhiệm vụ/hoạt động trỏ tới cảnh đó rơi về Đại Lý (160,150) qua `msgagent.lua:971/990` (không traceback [DK mã]); môn phái (9–17, 139–147) tắt → dạy kỹ năng/gia nhập phái ở cảnh phái không dùng được; cs3b đã cho gia nhập qua 阿紫 ở Đại Lý. 4 cảnh cy4 2220–2223 (唐门/鬼谷/桃花岛/绝情谷) tắt — nếu bật lại phải `retype` (ID 56000–56167 chỉ-GL → CY 16456…, xem `scripts/02-explore.out.txt`).
- 小木人巷 (61), 钱庄 (181), 监狱 (151), 竞技场 (414), 苏州休息室 (518)… nằm trong 183 cảnh tắt; nếu tính năng cần thì bật lại từng cảnh (`cys_scene_off.json`).
- Affine [SL] cho 105 + 58 mục và vùng/bàn: đúng tương đối (2,9 / 7,8 ô trung vị); người dùng nên xem trong game NPC có đứng trong nhà không.
- Client dự án vẫn vẽ `.Scene` GL cho clientres 0/1 tới khi CS2 dùng `SceneDefineEx` CY (như Đại Lý, cs3a 3.4).
- `TransferConfig[0]`/`[2219]` trong `eSceneAreaTransfer.lua` còn toạ độ cũ (Rift đã tắt, area7 chặn) — không sửa.

## 8. Bẫy gặp trong pha này
- `pos_x=;` **không** tắt được mục type ngoài bảng (mục 2.2). Dùng đổi tên section.
- Affine tâm thành sai ở cổng biên (25–80 ô) → cổng phải khớp theo hướng; `eSceneAreaTransfer` là bảng theo cảnh, không phải cổng đơn — phân tích đúng khối `[<cảnh>]`.
- `build --city wuliang` đọc file cùng tên đã cài → lần dựng sau bằng bản đã cài (idempotent) nhưng không tái lập từ bản gốc; bản gốc ở `staging/pre/`.
- PowerShell `git commit -F -` với here-string không nhận stdin → ghi message ra file UTF-8 rồi `-F file`.
- `Build/` là ignore của CY-Source; bằng chứng chỉ nằm trên đĩa, không trong git.
