# CS3a — Server riêng dùng bản đồ CY 3.71 (+ 6 bản vá lỗi server)

Ngày: 14/09/2026. Agent `cs3a-maps`, nhánh `cs3a-maps`. Bằng chứng: `Build/Logs/2026-09-14-cs3a-maps/`.
Kế hoạch mẹ: `Docs/specs/cy-switch_vi.md` mục 6 (CS3). Server riêng: `Docs/specs/net/cys-server_vi.md`.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`.
Nguồn CY: S4 = `Assets/CanonicalCY/Data` (CY 3.71.9609), bảng text S2 = `Tools/DATA NEW/DataCY31-08-26/Config`
(cùng nội dung bảng S4, bản text dễ đọc). tlbb15 = `Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Scene`, chỉ đọc tĩnh.

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| 6 bản vá lỗi server | Đã áp trên `R`, mỗi bản một commit git (`181a55a`…`3ef6774`), `luac -p` 5.4.4 đạt, đã restart |
| Cảnh 2 Đại Lý = `dali_new_320` (CY) | Đã cài + 4 bản phân tuyến (71/72/1320/1321); navmesh CY nguyên byte; NPC/cổng/hồi sinh theo CY; 23 toạ độ đích trong script đã chỉnh; commit `db6a0c2`, `75c5b91`, `995c2df` |
| Nhân vật `CYTest00` | Dời (165,170) → (160,150) cảnh 2 = điểm đứng CY (`SceneAttr` CY dòng 2); sao lưu bản ghi trước khi ghi |
| Restart | 15:42:29 stop → 15:44:56 cổng 15733 LISTEN; log khởi động 0 `traceback`/`error`, 0 `SCENE_LOAD_FAIL`/`SCENE_INIT_FAIL`; 3 cảnh báo đều có ở lần khởi động trước |
| Bot live | **Chưa chạy**: cần mật khẩu test00 (`CYS_BOT_PWD`) do người dùng cấp; không có trên máy. `Tests/net/run_world_live.ps1` sẵn sàng (bot hash khớp) |
| Lạc Dương / Tô Châu | Chưa cài. Đã đo (mục 5) và lập kế hoạch; công cụ `survey` có sẵn |

### 1.1 Danh sách cảnh
- `R/configs/SceneInfo.ini` (GBK, LF): 790 section `[sceneN]`; N = **scene ID phía server** (ID trong DB nhân vật, `NewWorld`, `TransferFunc`).
  Khoá dùng: `threadindex`, `clientres`, `name`, `active`, `file`, `type`, `PvpRuler`, `IsReLive`, (tuỳ) `BeginPlus/_clientres/EndPlus`.
- `lualib/scenemanager_core.lua:177-182`: khi khởi động tạo sẵn **mọi** cảnh `active=1 and type=0` (đo được 200/507 cảnh active). Khoá `[system] scenenumber` không dùng.
- `clientres` = **chỉ số dòng `SceneDefineEx` phía client**. Server gửi scene ID + clientres; client chọn `.Scene/.path/.jpg` theo dòng đó. Vì vậy mọi cảnh có cùng `clientres` phải dùng cùng bộ file cảnh server. Đại Lý: scene 2, 71, 72, 1320, 1321 đều `clientres=2`.
- Không có service cho scene đích → người chơi rơi về Đại Lý (guard `IsSceneAvailable`, `Game_2/Script/scripts/event/team.lua:11`).

### 1.2 Một cảnh
`services/scene/scenecore.lua:102-149` `scenecore:load(conf)` đọc `Game_2/Scene/<file>` (ini `[System]`), rồi theo thứ tự:

| Khoá `.scn` | Hàm | Định dạng | Ghi chú |
|---|---|---|---|
| `navmapname` | `init_navmap` (`:315`) | `.path` navmesh tam giác 0x2000 (memory `tlbb-path-navmesh-format`) | Chỉ cho AI/robot tìm đường (`lualib/nav_adapter.lua`). **Server không chặn người chơi.** Nếu có `<tên>_block.bin` thì bật `blockmap` (tuỳ chọn) |
| `patrolpoint` | `init_patrol_point` | ini `[PATROLk] PATROLPOINTNUM, POSXi/POSYi/POSZi` | đường tuần tra/xe |
| `monsterfile` | `init_monster` | ini `[monsterK] guid,type,name,title,pos_x,pos_z,dir,script_id,respawn_time,group_id,team_id,base_ai,ai_file,patrol_id,shop0..3,ReputationID,level` | `type` = `MonsterAttrExTable.id` của **server skynet**; `pos_x=;151` (giá trị bị chú thích) = NPC tắt |
| `eventfile` | `init_event_area` (`:365`) | ini `[areaK] guid,script_id,x,z,radious` | vùng sự kiện/cổng; tlbb15 dùng `left/top/right/bottom` (khác khuôn) |
| `platformfile` | `init_platform` | ini `[platformK] index,class,pos_X,pos_Z,dir,script_id,Tip` | bàn chế tạo, bảng tin, "thông tới …" |
| `busfile` | `init_bus` | ini `[busK] guid,dataId,patrolPathID,athwart` | xe/ngựa chạy theo patrol |
| `stallinfodata` | `init_stall_info` | nhị phân, 1.835.020 B cho bản đồ 320×320 | ô bày sạp |
| `growpointdata` + `growpointsetup` | `growpointenginer` | txt tab (GBK) | điểm thu thập |
| `petfile` | — | ini `[info] petcount` | |

Mọi toạ độ server là **đơn vị ô** (giống `.path`). Thiếu file hay lỗi đọc: ghi `SCENE_LOAD_FAIL`/`SCENE_INIT_FAIL`, cảnh vẫn đăng ký.
`.esd`, `_monster.preload`, `_SP.path` có trong thư mục nhưng `scenecore` không đọc.

### 1.3 Bảng cấu hình liên quan
- `configs/SceneAttr.txt` (24 cột, có dòng tên): `cfghelper.lua:736` chỉ lấy `ID`, `Name$1$`, `安全级别`. Cột `可以站立的位置X/Z` không được mã server đọc.
- `configs/SceneDefineEx.txt` (24 cột): `cfghelper.lua:4445` tra khoá `Index`/`Name`, nhưng cả hai dòng đầu file đều là **kiểu** (`INT STRING …`), không có tên cột → bảng phía server rỗng [DK: header; SL: txtreader lấy dòng 2 làm tên]. Chỉ `copyscenecore.lua:33` dùng (lấy tên cảnh).
- Toạ độ hồi sinh/đích **viết cứng trong script** `Game_2/Script` (`TransferFunc`, `NewWorld`, `SetPlayerDefaultReliveInfo`). Toạ độ nhân vật lưu ở Mongo `tlbb.character.attrib.{sceneid, world_pos.x, world_pos.y}` (y = trục z bản đồ).
- Nạp lại: bảng/scene đọc lúc tạo cảnh → **phải restart** (bẫy `08-BAY` 8.2).

## 2. SceneDefineEx CY ↔ server riêng [DK]

Đo bằng `Build/Logs/2026-09-14-cs3a-maps/scripts/51_scenedef_compare.py` → `survey/scenedefineex-compare.json`.

| | CY 3.71 | server riêng |
|---|---:|---:|
| Số dòng / số cột | 679 / 25 | 547 / 24 |
| ID chung | 426 | |
| — cùng tên | 268 (261 cùng file `.Scene`, **7 khác file**) | |
| — **khác tên** (ID bị dùng cho cảnh khác) | 158 (từ ID 156 trở đi, ví dụ 548 四象天门阵 ↔ 宋辽战场; **1052 Summoner Rift ↔ 群雄争霸休息室**) | |
| Chỉ có ở CY / chỉ có ở server | 253 / 121 | |
| `clientres` của cảnh active không có ở CY | | 35 (42, 79–81, 230, 281, 546, 611–675…) |
| `clientres` active trùng ID nhưng khác tên ở CY | | 28 |

Bảy dòng cùng tên nhưng CY đổi bản đồ: 0 洛阳 `luoyang`→`luoyang_new` (512×512), 1 苏州 `suzhou`→`suzhou_new` (512×512), 2 大理 và 71/72 `dali`→`dali_new_320`, 236 燕子坞 `yanziwu`→`new_yanziwu`, 242 洛阳 `luoyang_snow_MN`→`luoyang_new_snow`, 280 凤凰古城 `PhoenixPlain`→`fenghuangpingyuan`. CY thêm cột 25 (dòng 0–3 = 0). Cột 8 (id minimap/đường đi) cảnh 2: server 101, CY 2106.

### 2.1 Kế hoạch ánh xạ scene ID theo CY
1. **Giữ nguyên scene ID server** cho 268 ID cùng tên (DB nhân vật, script, cổng không đổi). `clientres` của chúng = ID CY cùng số.
2. **7 cảnh đổi bản đồ**: giữ ID, đổi bộ file server theo bản đồ CY (đã làm 2/71/72/1320/1321; tiếp 0, 1, 242, 236, 280).
3. **158 ID khác tên**: server giữ scene ID của mình (không đổi dữ liệu đã lưu), nhưng `clientres` phải trỏ sang **dòng CY có cùng tên cảnh/bản đồ** (tra theo tên + tên file `.Scene`, không theo số). Cảnh không có ở CY (Summoner Rift 1052, 35 clientres thiếu) cần dòng client riêng ở dải ID trống của CY (≥ 1100 chưa dùng) — việc của CS1/CS3c cùng lúc với bảng client.
4. Cảnh chỉ-CY (253 ID) chỉ mở khi có script/quái tương ứng (CS3c/CS4).
5. Việc 3–4 đổi `SceneInfo.ini` hàng loạt → làm theo đợt, mỗi đợt commit + restart + snapshot.

### 3.1 File server và nguồn

| File trong `R/Game_2/Scene` | Nguồn | Loại |
|---|---|---|
| `dali_new_320.path` | S4 `SceneFolder/dali_new_320.path` nguyên byte, sha256 `eed3f96f…`; 11.669 đỉnh, 23.324 tam giác (10.559 chặn), 11.665 cạnh, lưới 40×40×8, đọc hết đúng byte cuối | DK, CY |
| `dali_new_320.scn` | dựng mới theo khuôn `dali.scn` | |
| `dali_new_320_monster.ini` | `dali_monster.ini` skynet, **chỉ đổi `pos_x/pos_z/dir`** (diff khoá khác = 0) | xem 3.2 |
| `dali_new_320_area.ini` | 3 cổng theo CY `ScenePosDefineEx` #7 (160,295)→洱海, #8 (32,149)→剑阁, #9 (304,149)→无量山 (loại 0 = cổng đi bộ); giữ `script_id` 400008/400007/400006 và `radious=4` của skynet. tlbb15 có cùng vị trí (hình chữ nhật) | DK, CY |
| `dali_new_320_patrolpoint.ini` | tlbb15 (10 tuyến; 9 tuyến đầu **trùng từng số** với skynet, thêm PATROL9) | DK, HJ |
| `dali_new_320_platform.ini` | tlbb15 (khác skynet 1 bàn: 打造台 (216,110) thay (232,90)) | DK, HJ |
| `dali_new_320_growpoint.txt` | tlbb15 (trùng từng số với skynet) | DK, HJ |
| `dali_new_320_growpointsetup.txt`, `_bus.ini`, `_pet.ini` | skynet cũ (tlbb15 `growpointsetup` rỗng) | |
| `stallinfodata` | dùng lại `dali_StallInfo.stall` của bản đồ cũ (cùng 320×320) | SL |

Vì sao tin tlbb15: `tlbb15/Public/Scene/dali.path` có sha256 `c2bc7788…` **trùng** `dali_new_320_SP.path` của CY, và vị trí NPC trong `dali_monster.ini` của nó trùng `MissionNPC_HashTable` CY ở mọi NPC có trong cả hai (trừ 凤朝阳: CY (46,240), tlbb15 (95,234) → dùng CY). Server cài `dali_new_320.path` (bản thường, khớp `SceneDefineEx` CY dòng 2), không phải `_SP`.

### 3.2 Vị trí NPC/quái (`dali/report.json`, từng mục có nguồn)
Thứ tự: CY `MissionNPC_HashTable` (92 NPC cảnh 2) + `TransportDefine` → tlbb15 cùng tên (hoặc cùng type + tiêu đề) → toạ độ skynet cũ nếu đi được trên navmesh CY (cùng vùng liên thông với điểm hồi sinh) → ô đi được gần nhất (≤ 12 ô).

| Loại | Số mục | |
|---|---:|---|
| DK — CY | 91 | vị trí CY, cả 91 nằm trên tam giác đi được |
| DK — tlbb15 | 21 | |
| SL — giữ toạ độ cũ (đi được) | 70 | chủ yếu 36 稻草人, 16 大理禁军, NPC "第一人", NPC skynet thêm (51646…) |
| SL — dời ≤ 4 ô | 15 | 稻草人, 大理禁军, 巡城禁卫, 玄智法师 |
| Giữ nguyên mục tắt (`pos_x=;…`) | 7 | 都大爽, 龚彩云, 新宠大使, 神秘商人, 祝富贵, 陈星福, 1 mục không tên |

- CY có mà skynet không có NPC để gắn: 木思锐 (220,154, truyền tống 侠客山庄) và 都大爽 (skynet tắt). tlbb15 có 26 mục skynet không có (主考核/副考核 5143x, 皇榜, 悬赏告示牌…) — không thêm vì `type`/`script_id` tlbb15 thuộc nhánh HJ, không dùng chéo ID (bẫy 7.4).
- Kiểm điểm trên navmesh CY: tuần tra 35/49 điểm đi được, bàn 6/8, điểm thu thập 47/60. Các điểm này trùng dữ liệu tlbb15 cho cùng bản đồ nên giữ [SL: NPC tuần tra/thu thập không cần đứng trên tam giác đi được].

### 3.3 Điểm hồi sinh, đích truyền tống, nhân vật
- Điểm đứng/hồi sinh CY: `SceneAttr` CY dòng 2 cột 4/5 = **(160,150)**, đi được (vùng 5). Server `SceneAttr.txt` dòng 2 đổi 160,277 → 160,150; `SceneDefineEx.txt` dòng 2 cột 2–16 theo CY (vẫn 24 cột; số cột mọi dòng không đổi; toàn file giải mã GBK).
- `cs3a_scene.py audit-scripts --city dali`: 32 toạ độ đích `…, 2, x, z` trong `Game_2/Script`; **23 rơi vào tam giác chặn** của navmesh CY (tất cả đi được trên `dali.path` cũ). Đã sửa:
  - 241,141 và 242,137 (驿站 cũ, 20 chỗ) → **253,121** = đích vào 大理 của CY (`TransportDefine` #65–81, `ScenePosDefineEx` #216/232/248/264/299…).
  - 玄武岛 263,129 → **253,125** (`ScenePosDefineEx` #529).
  - 275,50 → 276,50 (ô đi được gần nhất) [SL]; CY 小木人巷→大理 là (160,153).
  - Đích từ cảnh kề đều đi được, không sửa: 洱海 (160,277), 剑阁 (39,152), 无量山 (280,154), 新手 (154,154), 死亡 (241,148).
- `CYTest00` (GUID 200001): Mongo `tlbb.character` `attrib.world_pos` (165,170) → (160,150), `sceneid` 2 giữ. Ghi khi skynet đã dừng, Mongo chạy riêng; bản sao trước/sau: `char-move-1.json`; backup Mongo đầy đủ `backups/20260914T082902Z-truoc-cs3a-maps`.

### 3.4 Client
- Client dự án (CS1/CS2 chưa xong) vẫn nạp `dali.Scene` từ `Assets/Canonical` (GL) cho `clientres=2`. Nhân vật và NPC giờ có toạ độ theo bản đồ CY: vẽ lệch so với nhà cửa GL nhưng không kẹt vì server không chặn di chuyển. Khớp hình khi CS2 dùng `SceneDefineEx` CY.

## 4. Vận hành, hoàn tác

```powershell
# Dựng lại / cài (trong WSL root)
python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3a_scene.py build --city dali --out /dev/shm/cs3a/dali
python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3a_scene.py audit-scripts --city dali --out <json>
python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3a_scene.py install --city dali --staging /dev/shm/cs3a/dali
python3 -B .../cs3a_scene.py query <file.path> x,z ...        # (tam giác, flag, vùng)
python3 -B .../cs3a_scene.py survey --city suzhou|luoyang|dali
python3 -B .../cs3a_move_test_char.py inspect|apply ...        # chỉ bản ghi GUID 200001
```

- Chuỗi restart có dời nhân vật: `Build/Logs/2026-09-14-cs3a-maps/scripts/40-restart-move.sh` (stop → `mongod --config R/mongod.conf` → move → start). Kiểm trước: `Get-Process Game` rỗng, `cys_server.ps1 status` 0 client.
- Hoàn tác bản đồ: `git -C R revert 995c2df 75c5b91 db6a0c2` rồi restart (file `dali.*` cũ không bị sửa). Hoàn tác vá: `git revert 3ef6774 fc2c65b 9926765 2fc43ec 45d0b3c 181a55a`. Nhân vật: `$set attrib.world_pos` về (165,170) theo `char-move-1.json` hoặc `cys_server.sh restore backups/20260914T082902Z-truoc-cs3a-maps`.

### 5.1 Số đo `survey` (`survey/survey-*.json`)

| | Đại Lý (đối chứng) | Tô Châu | Lạc Dương |
|---|---|---|---|
| Bản đồ server cũ → CY | `dali` 320 → `dali_new_320` 320 | `suzhou` 320 → `suzhou_new` 512 | `luoyang` 320 → `luoyang_new` 512 |
| Navmesh CY | 11.669 đỉnh / 23.324 tam giác | 9.363 / 18.710 | 10.546 / 21.080 |
| Điểm đứng CY (`SceneAttr`) | (160,150) đi được | (279,371) đi được | (256,416) đi được |
| NPC CY (`MissionNPC_HashTable`) | 93 tên | 80 | 145 |
| Mục monster skynet / đi được nếu giữ toạ độ | 197 / 146 | 179 / 86 | 230 / 92 |
| Cặp tên dùng khớp affine cũ→CY | 88 | 78 | 110 |
| Affine (x' = a·x + b·z + c) | 1,080x −0,077z +0,04; z' = 1,163z −26,9 | 1,081x +0,028z +76,3; z' = 1,035z −0,037x +98,4 | ≈ **x+96,3; z+137,8** (tỉ lệ 1,00/1,03) |
| Sai số khớp trung vị / p90 | 10,2 / 26,4 ô | 7,8 / 23,6 ô | **2,9 / 16,1 ô** |
| Mục đi được sau affine | 154/197 | 116/179 | 202/230 |
| Toạ độ đích trong script / đi được sau affine | 32 / 10 | 40 / 37 | 47 / 47 |
| Server tlbb15 cùng bản đồ | có (`dali`) | có: `suzhou.path` = CY `suzhou_new_SP.path` (sha256 `505c8f14…`), 129 NPC, 90 tên trùng skynet, `suzhou_portal.ini` | không (`luoyang.path` tlbb15 ≠ `luoyang_new`) |

### 5.2 File cần cho mỗi thành
- **Server**: chỉ `.path` lấy từ client S4 (`SceneFolder/<tên>.path`, nguyên byte) + các ini/txt dựng (monster, area, patrolpoint, platform, bus, growpoint, pet, portal nếu có) + `stallinfodata` **phải dựng lại cho 512×512** (không dùng lại bản 320). `.Scene`, `.Terrain`, `.GridInfo`, `.Heightmap`, `.WCollision`, `.lightmap.png`, `.Region`, `.Fly`, `.skysphere` chỉ client cần (đã có trong CanonicalCY).
- **Vị trí**: CY `MissionNPC_HashTable`/`TransportDefine`/`NpcPosLimit` → tlbb15 (Tô Châu) → affine từ bản cũ (ghi SL) → ô đi được gần nhất. Cổng: `ScenePosDefineEx` loại 0 + `SceneAreaTransfer`. Điểm hồi sinh: `SceneAttr` CY.
- **Script**: audit mọi toạ độ đích vào cảnh (không chỉ mẫu `, N, x, z`): bảng `TransferConfig` (`eSceneAreaTransfer.lua`), `g_mpInfo`, bảng 驿站 (`chuan_song_system.lua`), cổng Summoner Rift ở Lạc Dương (160,268 ↔ Rift, memory `tlbb-map-summoner-rift`), shop/sạp.
- **Phân tuyến**: cảnh cùng `clientres` (Lạc Dương còn 242 tuyết `luoyang_new_snow`, `_clientres=242` theo mùa).

### 5.3 Thứ tự đề xuất
1. **Lạc Dương trước** (dịch chuyển gần như thuần, 47/47 đích script đi được sau affine): mở rộng `CITIES` + `build` (thêm bước affine cho mục không có vị trí CY), dựng `stall` 512, audit bảng truyền tống dạng bảng, cài, restart, bot vào 洛阳 bằng truyền tống 驿站.
2. **Tô Châu**: như trên, ưu tiên tlbb15 (cùng navmesh `_SP`), thêm `suzhou_portal.ini`.
3. Sau khi CS1/CS2 dùng `SceneDefineEx` CY phía client: đổi `clientres` 158 cảnh khác tên (mục 2.1).

## 6. Bẫy gặp trong pha này
- `dali_monster.ini` gốc có 7 mục `pos_x=;151` (chú thích) = NPC bị tắt; parser phải bỏ qua, không "sửa". `monstercount=216` nhưng chỉ có 204 section.
- Server `SceneDefineEx.txt` không có dòng tên cột → mã tra `Index` không thấy gì; đừng dựa vào nó để đổi hành vi.
- `.path` bị `.gitignore` của `R` loại (`Game_2/Scene/**/*.path`) → `git add -f` cho navmesh CY.
- Gói `stop` của `provision_test_wsl.py` dừng cả Mongo; ghi DB khi skynet dừng phải tự bật `mongod --config R/mongod.conf` (lệnh `start` sau đó nhận là "already running (verified identity)").
- `fix_server_utf8_rows.py` (`Tools/rasoat-4phai`) cố định thư mục server gốc `/home/ubuntu/configs`; không chạy trên server riêng. `install` tự kiểm tương đương: sửa ở mức byte trên đúng một dòng, số tab giữ nguyên, cả file giải mã GBK.
- Toạ độ cũ "gần đúng" với Đại Lý mới (tuần tra/thu thập trùng từng số) nhưng 驿站 dời 241,141 → 253,121: đích truyền tống cũ nằm trong nhà.
- Bash tool làm hỏng `\$` khi gọi `wsl bash -c` qua PowerShell: luôn viết script `.sh` rồi chạy file.
