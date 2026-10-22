# NPC dịch chuyển nối các thành + mở 冰雪不夜城 Bất Dạ Thành (cảnh **1007**)

Ngày: 17/09/2026. Agent `transfer-npc`. Bằng chứng: `Build/Logs/2026-09-17-transfer-npc/`.
Tiếp nối `cs3a2-maps_vi.md` (cách nạp cảnh, chép `.path` CY, cổng đi bộ). Server riêng: `R` = `/home/ubuntu/cys-test-20260913`.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn / số / dòng lệnh). **[SL]** suy luận.

---

## 0. Kết quả một dòng

| Việc | Trạng thái |
|---|---|
| Cơ chế NPC dịch chuyển | **ĐÃ CÓ SẴN**, không tự chế: script `990010 = scripts/chuan_song_system.lua`, NPC 驿站老板 đứng sẵn ở cả ba thành |
| Cặp thành đã chạy thật | **22/22 lượt bot xanh, `traceback=0 error=0`**: 6 cặp giữa 0/1/2 (mục 4) + 6 cặp với 1007 + 2 cặp với 755 + 2 cặp với 495 + 3 lượt đi bộ (mục 4b) |
| ID cảnh của Bất Dạ Thành | **1007**, không phải 490 — DBC client không có dòng nào cho 490 (mục 1) |
| `buyecheng.path` có cùng địa hình `SnowWorld2024.path` không? | **KHÔNG.** 256×256 vs 320×320, trùng ô đi được 51,6 % — coi như không liên quan (mục 2) |
| Nội dung cảnh 1007 | Bộ file mới `Game_2/Scene/SnowWorld2024.*`: nav CY **nguyên byte** + **1 NPC 驿站老板 冰小舞** (type 52273) tại (160,290) |
| `buyecheng.*` / cảnh 490 | **Đã trả về đúng bản phát hành** và `active=0` trở lại |
| `SceneInfo.ini` | Thêm `[scene1007]` `active=1 clientres=728 file=SnowWorld2024.scn type=0`, qua `scene_install.py` |
| Script `chuan_song_system.lua` | Đổi sang bảng `g_Cities`; thêm 汴京 755 + 冰雪不夜城 1007 + 唐家堡 495; 恶人谷 1063 → 987; ẩn mục có cảnh đích chưa chạy. `luac -p` OK, kiểm ngoại tuyến **155/155** (bản cũ 80/116); menu TỰ CHIA TRANG (mục 7b.4) |
| 汴京 Biện Kinh (755) | Đã nối: NPC **唐松** type 49068 (530,937) do tôi tạo trong `bianjing_monster.ini`; thêm 1 dòng `monsterfile=` vào `bianjing.scn` (mục 7b.2) |
| 唐家堡 (495) | Đã nối: NPC **唐予诚** (126,68) vốn đã có sẵn với chính script 990010; chỉ thêm 1 dòng `g_Cities` (mục 7b.3) |
| 恶人谷 | Cổng đang hỏng vì còn trỏ cảnh 1063; đã đổi `g_mpInfo` sang **987** (mục 7b.1) |
| `SceneAttr` dòng 1007 | Đã sửa **đúng một ô**: tên `武当山洞天` → `冰雪不夜城`, có bằng chứng byte (mục 7b.5) |
| 鬼谷 Quỷ Cốc | Đã bật lại NPC cổng **杨渐** (Đại Lý 154,139.5 → cảnh 2221); **cố ý KHÔNG bật 唐昱** vì hub trỏ 2220 (tắt, không có dòng DBC, khác bản đồ) — mục 7b.6 |
| Vào được / đi lại được chưa? | **RỒI** — sau restart 18:47:56: `GCEnterScene scene=1007`, đi (160,290)→(160,250)→(160,210), ra/vào đủ ba thành cũ; 755 và 495 cũng đi/về được (mục 4b) |

---

## 1. ID cảnh: 1007, KHÔNG phải 490 [DK]

**Client tra bản đồ bằng ID cảnh SERVER (`packet.sceneid`), không phải `clientres`.**

- `Src/Client/WXClient/Network/CysModernHandlers.cpp:210` — `SetSceneID((INT)packet.sceneid, …)`;
  `packet.client_res` chỉ đi vào `TDU_Log`.
- `Src/Client/WXClient/World/WorldManager.cpp:107` —
  `Search_First_Column_Equ(_DBC_SCENE_DEFINE::SCENE_SERVER_ID_COLUMN, nSceneID)`;
  `Src/Engine/Interface/TDDBC_Struct.h:985` — `SCENE_SERVER_ID_COLUMN = 0`.
- Không tìm thấy dòng ⇒ `TDThrow("(CWorldManager::EnterScene) Invalid scene ID(%d,%d)")`
  (`WorldManager.cpp:113`) ⇒ client **không vào được**, dù server có chạy cảnh đó.

Bảng client là DBC `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt` — **692 dòng × 25 cột,
cột 0 = ID cảnh server** (682 lúc tôi đo lần đầu; `maps-sect` chèn thêm 10 dòng: 495, 1358 và 8 cảnh phân tuyến). Đo bằng `Tools/game/dbc_inventory.py`:

| cột 0 | tên | kích thước | `.Scene` |
|---|---|---|---|
| 0 | Lạc Dương | 512×512 | `luoyang_new.Scene` |
| 1 | Tô Châu | 512×512 | `suzhou_new.scene` |
| 2 | Đại Lý | 320×320 | `dali_new_320.Scene` |
| **755** | **Biện Kinh** | 1024×1024 | `bianjing.Scene` |
| **1007** | **Băng Tuyết Bất Dạ Thành** | 320×320 | `SnowWorld2024.Scene` |
| 490 | — | — | **KHÔNG CÓ DÒNG** |
| 4511 | — | — | **KHÔNG CÓ DÒNG** |

Phụ, **đã được bịt trong lúc tôi làm**: lúc 18:05 các cảnh phân tuyến 1311/1312/1315/1316/1320/1321/1500/2218 đều **không có dòng** trong DBC client (mọi đường sang shard sẽ ném "Invalid scene ID"); `maps-sect` đã chèn đủ 8 dòng, đo lại lúc 18:45 thì **cả 8 đều CÓ**. Ba ID vẫn không có dòng: **490**, **4511** và **2220** (lý do người điều phối chọn 495 cho 唐门).

Hệ quả cho đợt này:

- `[scene490]` trả về `active=0`; `Game_2/Scene/buyecheng.*` trả về **đúng bản phát hành**
  (sha256 `676a0052…` cho `.path`, `d252eddc…` cho `_monster.ini`).
  **Đừng bật lại 490** — dù server chạy, client không vào được.
- Cảnh mới là `[scene1007]`, nội dung mang tên `SnowWorld2024.*` để tên bản đồ phía server trùng tên
  tài nguyên phía client (đúng như `cs3a` đã làm với `luoyang_new` / `suzhou_new` / `dali_new_320`).

Bảng CY `ScenePosDefineEx.txt` cũng ghi Bất Dạ Thành theo ID **1007** (ba dòng 2071/2072/2073) —
thêm một dấu hiệu 1007 là đúng [DK].

---

## 2. Trả lời dứt điểm: `buyecheng.path` ≠ `SnowWorld2024.path` [DK]

`Build/Logs/2026-09-17-transfer-npc/nav-compare.txt`
(`scripts/nav_probe.py compare`, dùng lớp `NavMesh` của `Tools/server/cs3a_scene.py`):

| trường | `buyecheng.path` (server, đời GL) | `SnowWorld2024.path` (client, bản CY 2024) |
|---|---|---|
| byte | 499.814 | 464.269 |
| version | 0x2000 | 0x2000 |
| đỉnh | 4.787 | 4.284 |
| tam giác | 9.560 | 8.559 |
| tam giác chặn | 4.733 | 4.018 |
| cell / lưới | 8 / 32×32 | 8 / 40×40 |
| **thế giới** | **256 × 256** | **320 × 320** |
| bbox | 2,045 0,736 → 254,84 254,09 | 0,216 0,27 → 319,99 319,44 |
| vùng đi được lớn nhất | vùng 1, 4.799 tam giác | vùng 5, 4.305 tam giác |

Trên vùng chung 0…256 (lấy mẫu bước 2, 16.129 điểm): **trùng kết quả đi-được 51,6 %** — ngang tung
đồng xu, không có tương quan. Hai bản đồ khác nhau, không phải hai bản của cùng một bản đồ.

Cả hai bảng đều nói hình 320×320 / `SnowWorld2024`: bảng SERVER `configs/SceneDefineEx.txt` dòng
**728** (`冰雪不夜城 320 320 SnowWorld2024.Scene SnowWorld2024.path …`) và DBC client dòng **1007**.
⇒ dùng nav 256×256 chắc chắn ra đi xuyên tường; và mọi toạ độ > 256 — ví dụ cổng CY (160, 288) —
nằm hẳn ngoài navmesh.

**⇒ `Game_2/Scene/SnowWorld2024.path` = bản CY nguyên byte** (sha256 `713451f4…`, 464.269 B), chép từ
`Assets/CanonicalCY/Data/SceneFolder/SnowWorld2024.path`.

Kiểm chéo bằng chính bảng CY `ScenePosDefineEx.txt` (2071 洛阳 (253,253) → 冰雪不夜城 (160,288);
2072 (160,290) và 2073 (168,185) → 洛阳 (255,253)): **cả ba điểm đi được, đều thuộc vùng 5** trên nav
mới. Còn "vị trí có thể đứng" ghi ở `SceneAttr` dòng 490 là (40,40) thì **bị chặn**
[DK `nav_probe.py probe`] — thêm một dấu hiệu dòng 490 của `SceneAttr` không liên quan tới bản đồ này.

---

### 3.1 Ba đường dịch chuyển trong mã server [DK]

| Đường | Script | Ai gọi | Dữ liệu | Dùng được? |
|---|---|---|---|---|
| **Hộp thoại 驿站老板** | `990010` `scripts/chuan_song_system.lua` (`scripts.lua:2894`) | người chơi bấm NPC → `CGCharDefaultEvent` → `CGEventRequest` | **cứng trong Lua** | **CÓ — đây là đường đã đo live** |
| Danh sách nhanh của client | `889888` `scripts/quick_transfer.lua` (`scripts.lua:2899`) | client gửi `ClientQueryTrans(TransID)` | `configs/TransportDefine.txt` (1.036 dòng) | **KHÔNG** — xem 3.3 |
| Cổng đi bộ theo vùng | `998568` `event/chuansong/eSceneAreaTransfer.lua` + các `echuansong_*` | bước vào `area` của `<map>_area.ini` | bảng `TransferConfig` trong chính script | có, nhưng là cổng vùng chứ không phải NPC |

Cả ba cuối cùng đều gọi `CallScriptFunction(400900, "TransferFunc", …)` = `event/team.lua:44`.
`TransferFunc` đã có guard `IsSceneAvailable` (thêm 11/09) nên trỏ vào cảnh chưa chạy chỉ ra tip,
không traceback [DK `team.lua:51-56`].

### 3.2 Năm NPC 驿站老板 đã đứng sẵn [DK]

`Build/Logs/2026-09-17-transfer-npc/scripts/survey_npc.py`:

| Cảnh | Mục | type | **tên** (`name=`) | chức danh (`title=`) | vị trí |
|---|---|---|---|---|---|
| 0 Lạc Dương | `luoyang_new_monster.ini` `[monster86]` | 194 | 吴德昌 | 驿站老板 | (235, 322) |
| 0 Lạc Dương | `[monster184]` | 194 | 汪旱 | 九州商会传送人 | (326, 269) |
| 1 Tô Châu | `suzhou_new_monster.ini` `[monster25]` | 193 | 李乘风 | 驿站老板 | (204, 256) |
| 1 Tô Châu | `[monster152]` | 193 | 邓茂 | 铁匠铺传送人 | (335, 225) |
| 2 Đại Lý | `dali_new_320_monster.ini` `[monster0]` | 193 | 崔逢九 | 驿站老板 | (253, 121) |
| 6 Vô Lượng Sơn | — | — | **không có** | | |

**Toạ độ đích của mỗi mục menu TRÙNG ĐÚNG vị trí NPC của thành đó** — đi tới thành nào là rơi ngay
cạnh 驿站老板 của thành đó, nên một lượt bot = một chặng, không cần đi bộ thêm [DK, xem mục 4].

> **BẪY đã sập rồi bò ra:** tên NPC mà `chuan_song_system` so sánh (`GetName(targetId)`) là khoá
> **`name=` của từng mục trong `<map>_monster.ini`**, KHÔNG phải tên của `type` trong
> `MonsterAttrExTable`. Cả 5 NPC đều là type 193/194 tên 驿站老板; nếu chỉ tra bảng type thì tưởng cả 5
> trùng tên và không hiểu tại sao menu ở Đại Lý thiếu mục "Đại Lý".

### 3.3 `TransportDefine.txt` — bảng dữ liệu nhưng đang CHẾT [DK]

`cfghelper:read_tran_sport_define` (`cfghelper.lua:5630`) đọc `TransId / 原场景ID / 传送NPC名 / POSX /
POSZ / TARSCENE / NeedLevel / TARPOSX / TARPOSZ`. `quick_transfer:ClientQueryTrans` đòi
`Trans.source_scene_id == cảnh hiện tại` **và** khoảng cách từ người chơi tới `(POSX, POSZ)` ≤ 6 ô.

Nhưng toạ độ trong bảng là của bản đồ **đời cũ**: 吴德昌 ghi (139, 182) trong khi ở `luoyang_new` ông
đứng ở (235, 322); 冰雪不夜城 ghi cảnh **1335** (ID đời GL) trong khi cảnh thật là 1007.
⇒ Mọi dòng đều trượt điều kiện, `ClientQueryTrans` lặng lẽ `return`. **Không sửa trong đợt này**
(sửa = đè 1.036 dòng đang có, trái luật "chỉ thêm dòng"); xem mục 9.

Dù vậy bảng này là **nguồn dữ liệu thật** rất có giá trị: nó giữ tên + vị trí gốc của NPC dịch chuyển
từng bản đồ. Bốn dòng của Bất Dạ Thành chính là nguồn cho NPC mới ở mục 5.

---

## 4. Sáu cặp thành đã CHẠY THẬT bằng bot (trước restart, bản script cũ) [DK]

Bot `Build\bot-unknownid\CysNetBot.exe`, runner `scripts/transfer_turn.ps1` (khuôn lấy từ
`quest_turn.ps1` của agent quest-live, thu hẹp còn test07/test08). Một lượt = một phiên:
đăng nhập → đi tới NPC → `CGCharDefaultEvent` → chọn mục → `CGEventRequest` →
`GCNotifyChangeScene` → `CGAskChangeScene` → `GCRetChangeScene` → nối lại → `GCEnterScene`.

| # | thư mục bằng chứng | đi | đến | mục | kết quả bot | Mongo sau lượt | log server |
|---|---|---|---|---|---|---|---|
| a1 | `a1-dali-to-luoyang` | 2 Đại Lý (253,121) | 0 Lạc Dương | 1001 | `transfers=1`, `transfer scene 2->0` | `scene=0 pos=235,322` | `traceback=0 error=0` |
| a2 | `a2-luoyang-to-suzhou` | 0 (235,322) | 1 Tô Châu | 1002 | `transfer scene 0->1` | `scene=1 pos=204,256` | `0/0` |
| a3 | `a3-suzhou-to-dali` | 1 (204,256) | 2 Đại Lý | 1010 | `transfer scene 1->2` | `scene=2 pos=253,121` | `0/0` |
| b1 | `b1-dali-to-suzhou` | 2 (253,121) | 1 Tô Châu | 1002 | `transfer scene 2->1` | `scene=1 pos=204,256` | `0/0` |
| b2 | `b2-suzhou-to-luoyang` | 1 (204,256) | 0 Lạc Dương | 1001 | `transfer scene 1->0` | `scene=0 pos=235,322` | `0/0` |
| b3 | `b3-luoyang-to-dali` | 0 (235,322) | 2 Đại Lý | 1010 | `transfer scene 0->2` | `scene=2 pos=253,121` | `0/0` |

**6/6 cặp có thứ tự giữa ba thành đang có.** Toạ độ đến luôn nằm trong bản đồ đích và trùng đúng
vị trí 驿站老板 của thành đó.

Menu quan sát được (bot in nguyên `scriptId/index/type`), khớp đúng luật lọc theo tên NPC:

- tại 崔逢九 (Đại Lý): `1000 1001 1002 1006 1007 1011 1014 -999 1012` — **không có 1010** ✔
- tại 吴德昌 (Lạc Dương): `1000 1002 1007 1010 1011 1014 -999 1012` — **không có 1001/1006** ✔
- tại 李乘风 (Tô Châu): `1000 1001 1006 1010 1011 1014 -999 1012` — **không có 1002/1007** ✔

Ba mục `1011 楼兰` (cảnh 186), `1014 束河古镇` (420), `-999 昆吾` (1349) trỏ vào cảnh đang
`active=0` ⇒ bấm vào chỉ được cái tip. Bản script mới ẩn hẳn chúng (mục 6).

---

## 4b. Kết quả SAU RESTART 18:47:56 — 16 lượt bot [DK]

Server khởi động 18:47:56, log `Game2_20260917_184720.log`: **65 cảnh `type=0`**, `SCENE_LOAD_FAIL` **0**,
`SCENE_INIT_FAIL` **0**, `traceback` **0**, `MONSTER_CFG_FAIL` **5** — toàn bộ ở cảnh 13 (type 49287), 13 (type 49288), 15 (type 49289), 9 (type 49285), 9 (type 49286),
tức 5 ID đã biết của 少林/天龙/峨嵋, **không có ID nào của 1007 / 755 / 495** ⇒ cả 冰小舞 (52273) và
唐松 (49068) đều được tạo sạch.

Bằng chứng NPC tồn tại thật, lấy thẳng từ log server (không phải suy từ phía bot):
`[AUTO_ROUTE_DISPATCH] scene= 1007 … script= 990010 index= 1001 target_name= 冰小舞
target_script= 990010 target_x= 160.0 target_y= 290.0`.

Các cảnh bot đã vào được trong đợt này (`AUTO_ROUTE_ENTER`): 0, 1, 2, 9, 10, 11, 12, 13, 14, 15, 16, 17, 495, 755, 987, 1007, 1358, 2221, 2222, 2223.

| # | lượt | mục | chuyển cảnh | Mongo trước | Mongo sau | log server |
|---|---|---|---|---|---|---|
| 1 | `a1-dali-to-luoyang` | 1001 | **2->0** | lv=15 scene=2 pos=160,150 | lv=15 scene=0 pos=235,322 | lines=12 traceback=0 error=0 |
| 2 | `a2-luoyang-to-suzhou` | 1002 | **0->1** | lv=15 scene=0 pos=235,322 | lv=15 scene=1 pos=204,256 | lines=13 traceback=0 error=0 |
| 3 | `a3-suzhou-to-dali` | 1010 | **1->2** | lv=15 scene=1 pos=204,256 | lv=15 scene=2 pos=253,121 | lines=13 traceback=0 error=0 |
| 4 | `b1-dali-to-suzhou` | 1002 | **2->1** | lv=15 scene=2 pos=160,150 | lv=15 scene=1 pos=204,256 | lines=13 traceback=0 error=0 |
| 5 | `b2-suzhou-to-luoyang` | 1001 | **1->0** | lv=15 scene=1 pos=204,256 | lv=15 scene=0 pos=235,322 | lines=12 traceback=0 error=0 |
| 6 | `b3-luoyang-to-dali` | 1010 | **0->2** | lv=15 scene=0 pos=235,322 | lv=15 scene=2 pos=253,121 | lines=11 traceback=0 error=0 |
| 7 | `c1-dali-to-1007` | 1021 | **2->1007** | lv=15 scene=2 pos=253,121 | lv=15 scene=1007 pos=160,290 | lines=13 traceback=0 error=0 |
| 8 | `c2-walk-1007-leg1` | - | **-** | lv=15 scene=1007 pos=160,290 | lv=15 scene=1007 pos=160,250 | lines=5 traceback=0 error=0 |
| 9 | `c3-walk-1007-leg2` | - | **-** | lv=15 scene=1007 pos=160,250 | lv=15 scene=1007 pos=160,210 | lines=14 traceback=0 error=0 |
| 10 | `c4-1007-to-luoyang` | 1001 | **1007->0** | lv=15 scene=1007 pos=160,210 | lv=15 scene=0 pos=235,322 | lines=24 traceback=0 error=0 |
| 11 | `c5-luoyang-to-1007` | 1021 | **0->1007** | lv=15 scene=0 pos=235,322 | lv=15 scene=1007 pos=160,290 | lines=12 traceback=0 error=0 |
| 12 | `c6-1007-to-dali` | 1010 | **1007->2** | lv=15 scene=1007 pos=160,290 | lv=15 scene=2 pos=253,121 | lines=12 traceback=0 error=0 |
| 13 | `c7-dali-to-bianjing` | 1020 | **2->755** | lv=15 scene=2 pos=253,121 | lv=15 scene=755 pos=530,937 | lines=11 traceback=0 error=0 |
| 14 | `c8-bianjing-to-dali` | 1010 | **755->2** | lv=15 scene=755 pos=530,937 | lv=15 scene=2 pos=253,121 | lines=13 traceback=0 error=0 |
| 15 | `d1-dali-to-1007` | 1021 | **2->1007** | lv=15 scene=2 pos=253,121 | lv=15 scene=1007 pos=160,290 | lines=13 traceback=0 error=0 |
| 16 | `d2-1007-to-suzhou` | 1002 | **1007->1** | lv=15 scene=1007 pos=160,290 | lv=15 scene=1 pos=204,256 | lines=15 traceback=0 error=0 |
| 17 | `d3-suzhou-to-1007` | 1021 | **1->1007** | lv=15 scene=1 pos=204,256 | lv=15 scene=1007 pos=160,290 | lines=11 traceback=0 error=0 |
| 18 | `d4-1007-to-luoyang` | 1001 | **1007->0** | lv=15 scene=1007 pos=160,290 | lv=15 scene=0 pos=235,322 | lines=12 traceback=0 error=0 |
| 19 | `d5-luoyang-to-suzhou` | 1002 | **0->1** | lv=15 scene=0 pos=235,322 | lv=15 scene=1 pos=204,256 | lines=12 traceback=0 error=0 |
| 20 | `d6-suzhou-to-dali` | 1010 | **1->2** | lv=15 scene=1 pos=204,256 | lv=15 scene=2 pos=253,121 | lines=11 traceback=0 error=0 |
| 21 | `d7-dali-to-tangmen` | 1022 | **2->495** | lv=15 scene=2 pos=253,121 | lv=15 scene=495 pos=126,68 | lines=11 traceback=0 error=0 |
| 22 | `d8-tangmen-to-luoyang` | 1001 | **495->0** | lv=15 scene=495 pos=126,68 | lv=15 scene=0 pos=235,322 | lines=12 traceback=0 error=0 |

luot co loi log: 0

menu quan sat o luot cuoi: 990010/1000/t9 990010/1001/t9 990010/1002/t9 990010/1010/t9 990010/1020/t9 990010/1021/t9 990010/1006/t9 990010/1007/t9 990010/1012/t9

---

## 5. NPC dịch chuyển của Bất Dạ Thành — dựng từ dòng thật [DK]

`Game_2/Scene/buyecheng_monster.ini` của bản phát hành: 23 B, `monstercount=0`. Bản đồ rỗng hoàn toàn
(`_area.ini` 26 B, `_platform.ini` 26 B, `_patrolpoint.ini` 22 B, `_growpoint.txt` 40 B) — và rỗng y
như vậy ở cả `/home/ubuntu/Game_2` lẫn `wsl/source-snapshot`, tức là bản phát hành vốn đã rỗng, không
phải ai xoá.

Nguồn cho NPC mới, cả ba đều là dòng có sẵn trong dữ liệu server:

1. **Tên + vị trí** — `configs/TransportDefine.txt` dòng **939**:
   `939 冰雪不夜城 1335 冰小舞 0 160 290 -1 -1 -1 -1 0 洛阳 30 162 112`.
   Cột 5 = **chỉ số `monsterN`** của bản đồ gốc (kiểm chéo: dòng 1 `汪旱 184` ↔ `luoyang_new`
   `[monster184]`; dòng 15 `吴德昌 86` ↔ `[monster86]`) ⇒ 冰小舞 vốn là `[monster0]` của bản đồ này.
   Dòng 940 là 冰小歌 tại (168, 185) — **không dùng** vì 冰小歌 không có trong `MonsterAttrExTable`
   (sẽ ra `MONSTER_CFG_FAIL`).
2. **type** — `configs/MonsterAttrExTable.txt` dòng **52273 = 冰小舞**: `base_ai 3`, `阵营 8`,
   `是否可以交互 1`, `BOSS 0` — cùng bộ với 193 驿站老板, chỉ khác cấp (30 so với 20).
3. **Khuôn mục** — `dali_new_320_monster.ini` `[monster0]` (崔逢九), giữ nguyên mọi khoá còn lại.

Kết quả `Game_2/Scene/SnowWorld2024_monster.ini` (**GBK, xuống dòng LF**, 275 B):

```
[info]
monstercount=1

[monster0]
guid=1986678      ← chép nguyên; guid KHÔNG duy nhất trong dữ liệu gốc (1986678 có mặt ở 8 bản đồ,
type=52273           riêng erengu 25 lần) và server chỉ dùng nó làm `db_attribs.guid`, obj_id do
name=冰小舞          scenecore tự sinh (`scenecore.lua:701 create_monster_data`)
title=驿站老板
pos_x=160.0000
pos_z=290.0000
dir=27
script_id=990010
… (respawn_time / group_id / team_id / base_ai / ai_file / patrol_id / shop0..3 / ReputationID / level giữ nguyên)
```

Bộ nội dung đầy đủ của cảnh 1007 (`Game_2/Scene/`): `SnowWorld2024.path` 464.269 B,
`SnowWorld2024.scn` 281 B (khuôn `buyecheng.scn`, đổi tên file thành phần), `_monster.ini` 275 B,
`_area.ini` 26 B, `_platform.ini` 26 B, `_patrolpoint.ini` 22 B, `_growpoint.txt` 40 B,
`_growpointsetup.txt` 96 B (5 file cuối chép y nguyên bản rỗng của `buyecheng_*`).

(160, 290) đi được, vùng 5, và đường thẳng từ đó tới (160, 250) rồi (160, 210) **không chạm ô chặn nào**
(lấy mẫu mỗi 1 ô: 41 + 41 + 81 điểm, chặn 0) — chính là hai chặng bot sẽ đi để chứng minh nav khớp hình
(`nav_probe.py line`, `scripts/after_restart.ps1`).

---

## 6. Script `chuan_song_system.lua`: bảng `g_Cities` [DK]

Bản nguồn: `Tools/server/transfer_npc_lua/Game_2/Script/scripts/chuan_song_system.lua`.
Bản trước khi sửa: `Build/Logs/…/lua/chuan_song_system.lua.before` (md5 `45f23060c42a63ef3b4658f16151ae1c`).

Đổi gì:

1. Gom 8 khối `AddNumText` + 8 khối `if index == …` rải rác thành **một bảng `g_Cities`**.
   **Giữ nguyên** số mục, chữ hiển thị, cảnh, toạ độ, mức cấp và luật ẩn theo tên NPC của bản cũ.
2. Thêm hai dòng: `1021 = 冰雪不夜城` (cảnh **1007**, (160,290), cấp 10, ẩn với 冰小舞) và
   `1020 = 汴京` (**đang `scene = -1` = tắt**, chờ mục 8).
3. Mục chỉ hiện khi cảnh đích **đang chạy**: `chuan_song_system:SceneRunning` tra
   `skynet.localname(".SCENE_<id>")` — tra bảng tên cục bộ, không gọi sang service khác nên không làm
   nghẽn hộp thoại. Phép kiểm đầy đủ (`ensure_scene`, số người, cấp, tổ đội, song nhân cưỡi) vẫn do
   `team:TransferFunc` làm khi người chơi bấm chọn.
   ⇒ 楼兰 / 束河古镇 / 昆吾 tự ẩn; và khi `maps-sect` / `maps-cy4` bật thêm bản đồ thì **chỉ cần thêm
   một dòng bảng**, không phải viết thêm nhánh `if`.
4. `notify_tips` khi ai đó vẫn gửi mục có cảnh chưa chạy (client cũ, gói tay).

**Giới hạn gói**: `GCScriptCommand` chỉ nhận **16 mục** (`size > 0 and size <= 0x10`,
`services/game/packet_domains/mission.lua:71`). Menu hiện dùng 1 dòng chữ + `1000` + tối đa 10 dòng
bảng + `1012` = **13**. Còn dư 3 chỗ; thêm thành thứ sáu trở đi phải chia trang.

**Kiểm ngoại tuyến** `Tools/server/transfer_npc_tests.lua` (lua5.4, stub `script_base`/`skynet`/
`define`/`class`, nạp chính file thật): **74/74 ok** với bản mới, **61/74** với bản cũ — tức là bộ kiểm
có phân biệt, không phải kiểm suông (`lua-tests-after.txt`, `lua-tests-before.txt`). Nó khẳng định:
menu của cả 5 NPC (kể cả 冰小舞), tham số `TransferFunc` từng mục, ẩn mục khi cảnh tắt, ngưỡng 700
người của mục 1001, và **các nhánh cũ 2001 / 3011 / 1012 / 1000 còn nguyên**.

`luac5.4 -p` OK. Đã chép sang `R/Game_2/Script/scripts/chuan_song_system.lua`; bản cũ ở
`R/backups/transfer-npc-20260917T110759Z/`.

> **Server chỉ nạp script khi khởi động lại.** `scriptenginer` cache instance theo id
> (`lualib/scriptenginer.lua try_load`), `reload_scripts` có sẵn nhưng **không có chỗ nào trong
> `services/` gọi tới** — đúng kết luận agent `quest-live` đã đo đối chứng ngày 17/09.

---

## 7. Công cụ + cách áp / hoàn tác

`Tools/server/transfer_npc.py` — `plan | apply | verify | set-city`, idempotent, sao lưu trước khi ghi,
và **từ chối chép Lua nếu `luac -p` hoặc 74 phép kiểm không xanh**.

```
python3 -B Tools/server/transfer_npc.py plan            # không ghi gì
python3 -B Tools/server/transfer_npc.py apply           # trả buyecheng.* về bản gốc, dựng SnowWorld2024.*, chép Lua
python3 -B Tools/server/scene_install.py add --id 1007 --name 冰雪不夜城 --file SnowWorld2024.scn \
        --clientres 728 --type 0 --threadindex 91 --active 1
python3 -B Tools/server/scene_install.py disable --scenes 490
python3 -B Tools/server/transfer_npc.py verify          # mã thoát 0 = đạt
```

Đã chạy hết (`Build/Logs/…/plan-1/2.json`, `apply-1/2/3/4.json`, `scene-add-1007.json`,
`scene-disable-490.json`, `scene-enable-490.json` (bước đã bị thu hồi), `verify-3.json`):
**verify đạt, mã thoát 0**. `scene_install.py survey --scenes 0,1,2,490,755,1007,4511`
(`scene-survey.txt`) cho `client ve duoc? = OK` với 0/1/2/755/1007 và `THIEU` với 490/4511.

**Hoàn tác**:

```
# 1. bỏ nội dung cảnh mới
rm R/Game_2/Scene/SnowWorld2024.path R/Game_2/Scene/SnowWorld2024.scn R/Game_2/Scene/SnowWorld2024_*.ini R/Game_2/Scene/SnowWorld2024_growpoint*.txt
# 2. bỏ section cảnh (SceneInfo.ini trước khi thêm nằm ở backup của scene_install)
cp R/backups/scene-install-20260917T112142Z-add/SceneInfo.ini R/configs/
# 3. trả script
cp R/backups/transfer-npc-20260917T110759Z/chuan_song_system.lua R/Game_2/Script/scripts/
```

`buyecheng.*` và cảnh 490 **đã ở đúng bản phát hành**, không cần làm gì.

**Kiểm tĩnh trước restart** (`Build/Logs/…/scene-sanity.txt`): cảnh 1007 có đủ **7/7** file nội dung mà
`SnowWorld2024.scn` khai. Mọi khoá của `.scn` đều được `scenecore:load` bọc
`if self.scn.System.<khoá> then` và mỗi `init_*` gọi `create_*` trong `pcall` rồi ghi
`[SCENE_INIT_FAIL]` nếu hỏng (`scenecore.lua:136-145, 358, 375, 392, 409`) ⇒ thiếu file không làm sập
cảnh, chỉ mất phần đó. `threadindex` **không được đọc ở đâu trong Lua server** — chỉ là siêu dữ liệu.

**Báo trước cho người điều phối:** lần khởi động 15:59 tạo **17** cảnh; nay `active=1 & type=0` đã là
**34** — phần tăng là của `maps-sect` (9–17, 1063, 1358), `maps-cy4` (2221–2223), 495 唐家堡,
755 汴京, và 1007 của tôi. Và **755 汴京 hiện chưa có `bianjing_monster.ini`** (`.scn` mới có mỗi
`navmapname`) nên cảnh đó sẽ lên rỗng — không sập, nhưng cũng chưa vào chơi được.

**SAU RESTART** chạy đúng một lệnh, nó đo 12 lượt và in bảng tổng:

```
cd C:\TLBB\085\CY-Source ; & .\Build\Logs\2026-09-17-transfer-npc\scripts\after_restart.ps1
```

> Bẫy runner: **đừng gọi bằng `powershell -File`** — `-File` tách `'253,121'` thành hai phần tử nên bot
> báo `option requires a value`. Gọi bằng `& .\…ps1` trong một phiên PowerShell.

---

### 7b.1 恶人谷: cổng đang hỏng, đã sửa
`maps-sect` chuyển Ác Nhân Cốc 1063 → **987** (DBC client dòng 1063 là 凌云窟, dòng 987 mới là
`erengu.Scene`); 1063 nay `active=0`. `g_mpInfo[1]` trong file của tôi còn trỏ 1063 ⇒ **cổng chính của
Ác Nhân Cốc hỏng**. Đã đổi thành **987**, toạ độ (125,152) giữ nguyên — NPC dịch chuyển 孙三霸
"恶人谷传送人" của bản đồ đứng ở (123,150), **đi được, vùng 2**, cách (125,152) 2,8 ô [DK `nav_probe`].
Trong 13 chỗ nhắc 1063 mà `maps-sect` liệt kê, **chỉ 1 chỗ thuộc file của tôi**
(`chuan_song_system.lua:10`); dòng 33 là chú thích chết, 11 chỗ còn lại là file của người khác hoặc
không phải ID cảnh (`recipeId`, `script_id`).

### 7b.2 汴京 Biện Kinh — cảnh 755, NPC 唐松 (530,937)
CY `TransportDefine.txt` có **sáu** 传送NPC cho 汴京 (dòng 1034–1039): 金阅楼 idx3 (752,435),
余繁 idx4 (688,752), 梁民 idx5 (347,353), 许行之 idx6 (360,724), **唐松 idx0 (530,937)**,
杨中川 idx7 (542,554). Nhưng `configs/MonsterAttrExTable.txt` của server **chỉ có 唐松 = 49068**
(`base_ai 3`, `阵营 8`, `可交互 1`, cấp 99); năm cái kia **không có dòng nào** ⇒ dùng sẽ ra
`MONSTER_CFG_FAIL` [DK].

⇒ Không dùng điểm (757,435) cạnh 金阅楼 mà người điều phối đưa (ở đó sẽ **không có NPC nào**, người
chơi tới rồi mắc kẹt). Dùng **唐松 (530,937)**: đi được, vùng 2, và cách điểm-đứng của 汴京 (512,942)
**18,7 ô với đường thẳng sạch hoàn toàn** [DK `nav_probe.py line`].

Đã tạo `Game_2/Scene/bianjing_monster.ini` (273 B, GBK, LF) — `[monster0]` = 唐松 type 49068 tại
(530,937) `script_id=990010`, khuôn chép từ `dali_new_320 [monster0]` như 冰小舞.

**Sửa chéo phạm vi, chỉ THÊM một dòng:** `Game_2/Scene/bianjing.scn` của `map-bianjing` trước đó chỉ
có `navmapname=bianjing.path`. `scenecore:load` chỉ gọi `init_monster` khi `.scn` khai `monsterfile=`
(`scenecore.lua:142`) ⇒ không có dòng đó thì NPC **không bao giờ được tạo**. Đã **thêm** đúng một dòng
`monsterfile=bianjing_monster.ini` (34 B → 67 B, đọc lại file ngay trước khi ghi, kiểm phần cũ còn
nguyên vẹn). Nếu `map-bianjing` viết lại `.scn` thì phải giữ dòng này — `transfer_npc.py verify` sẽ bắt.

### 7b.3 唐家堡 — cảnh 495, NPC 唐予诚 (126,68)
`tangmen_monster.ini` **đã có sẵn** `[monster10]` = **唐予诚 "唐门传送人" type 16461 tại (126,68)
với chính `script_id=990010`** [DK] ⇒ chiều VỀ đã chạy sẵn ngay khi cảnh 495 lên; dòng `g_Cities`
mới (index **1022**) chỉ mở chiều ĐI.

> **ĐÃ KẾT LUẬN — (126,68) đúng là chỗ đứng được, đo sau restart.** Trước restart tôi để **[SL]** vì
> `tangmen.path` là bản **0x1000** mà trình đọc `NavMesh` của `cs3a_scene.py` giải sai (`cell` ra
> 2.097.160). Ba lượt bot đã trả lời dứt điểm: `d7` chuyển `2->495` rơi đúng **(126,68)**;
> `e2-walk-495` **đi được** từ (126,68) sang **(132,74)** ngay trong cảnh 495; `d8` nói chuyện với
> 唐予诚 rồi chuyển `495->0`. Cả ba lượt `traceback=0 error=0`.
> (Lỗi parser 0x1000 vẫn còn — để lại thành việc riêng ở mục 9.)

### 7b.4 Menu tự CHIA TRANG (thay cho "14/16")

`GCScriptCommand` chỉ chuyển được **16 mục** (`size > 0 and size <= 0x10`,
`services/game/packet_domains/mission.lua:71`); quá số đó client **bỏ lặng phần cuối, không báo lỗi
gì**. Vì `maps-all` còn mở thêm hàng trăm cảnh nên menu chắc chắn sẽ tràn — đã chia trang ngay bây
giờ thay vì để thành bất ngờ.

Cách làm (`chuan_song_system:BuildCityMenu`):

- chỗ cố định = 3 (1 dòng chữ `AddText` + mục `1000` + mục `1012`); riêng **崔逢九** chừa thêm **2**
  cho `OnEnumerate` của script 210279 (mục nhiệm vụ) ⇒ ngân sách 13, hoặc 11 với 崔逢九;
- còn dư chỗ thì **không** hiện gì thêm (menu y như một trang, không đổi trải nghiệm hiện tại);
- tràn thì mỗi trang lấy `ngân sách − 1` mục và thêm mục **"Trang sau (k/n)"** mang index
  `1900 + <trang muốn xem>` (dải 1901–1999, không đụng 1000–1022 hay 2001–4006 hay dải môn phái 0–1000);
- `OnEventRequest` thấy index trong dải đó thì **dựng lại menu**, không truyền tống gì;
- trang cuối vòng về trang 1, nên không có ngõ cụt.
- `OnEnumerate` của 崔逢九 chỉ chạy ở **trang 1** (không nhân bản mục nhiệm vụ ra mọi trang).

**Kiểm ngoại tuyến có ép tràn thật**: `BuildCityMenu` gọi `self:VisibleCities(...)` chứ không lặp
thẳng `g_Cities`, nên bộ kiểm thay hàm đó trên **một thể hiện** bằng danh sách **30 thành giả** rồi đi
hết các trang: **3 trang (16 + 16 + 10 mục, không trang nào > 16), 30/30 thành xuất hiện đúng một
lần**. Tổng bộ kiểm nay **155/155**.

### 7b.5 `SceneAttr.txt` dòng 1007 — đã sửa ĐÚNG MỘT Ô [DK]

| dòng | cột | trước | sau | nguồn của giá trị mới |
|---|---|---|---|---|
| 1007 | 1 (`Name$1$`) | `武当山洞天` | `冰雪不夜城` | `SceneAttr` dòng **1335** + `SceneDefineEx` (server) dòng **728**, cả hai đều là bản đồ này |

Bằng chứng không đụng gì khác (công cụ tự kiểm, ném lỗi nếu sai): file có **19.096 dòng**, **đúng một
dòng đổi** (chỉ số 1009), byte tổng **1.463.877 → 1.463.877** (hai tên đều 5 chữ Hán = 10 byte GBK),
và trong dòng đó **chỉ cột 1 khác** — mọi cột còn lại giống từng byte với bản sao lưu
`R/backups/transfer-npc-20260917T113809Z/SceneAttr.txt`.

**Hai ô dữ liệu — người điều phối đã quyết, cả hai THEO NGUỒN chứ không theo tiền lệ:**

| ô | giá trị | nguồn | hiệu lực |
|---|---|---|---|
| `SceneAttr[1007].安全级别` | **GIỮ 0** | nguồn duy nhất của chính bản đồ này (`SceneAttr` dòng 1335) ghi 0. Ba thành ghi 1 chỉ là tiền lệ của **bản đồ khác** | ngay (server đọc lúc khởi động 18:47:56) |
| `[scene1007] PvpRuler` | **0 → 6** | bản phát hành của **chính bản đồ này** (`[scene490]`) ghi 6 = `镜湖`: PK từ cấp 10, cho đấu tay đôi và PK tự do | **chờ RESTART KẾ** — `scenecore.lua:113/128` đọc `conf.PvpRuler` lúc nạp cảnh, mà tôi đổi lúc 18:48 tức **sau** restart 18:47:56 |

Hai dữ kiện khớp nhau: `安全级别 = 0` và `PvpRuler = 6` cùng nói đây là bản đồ **dã ngoại**, không phải
thành an toàn — dù tên có chữ "Thành". Hệ quả đo được của `安全级别 = 0`: `scene.lua:117` gắn
`SpecificImpact 54` cho người chơi khi vào cảnh.

> **BẪY CÔNG CỤ, ai dùng `scene_install.py set` phải biết.** `set_key` so sánh
> `line.split('=')[0].strip().lower() != key`, tức là **vế trái đã `lower()` còn `key` thì không**.
> Gọi `set --key PvpRuler` (viết hoa như trong file) ⇒ **không khớp dòng nào** ⇒ nó **CHÈN THÊM** một
> dòng `PvpRuler=6` ở đầu section, để lại `[scene1007]` có **HAI** dòng `PvpRuler` (6 rồi 0) và
> `inireader` lấy dòng sau. Lệnh còn báo `"cu": null, "moi": null` chứ không báo lỗi.
> Đã dọn bằng `Build/Logs/…/scripts/fix_pvpruler_1007.py` (giữ `flock` của chính `scene_install`,
> xoá dòng thừa, đặt dòng gốc = 6, in `difflib` toàn file để chứng minh **chỉ 2 dòng trong
> `[scene1007]` đổi`) — kết quả ở `fix-pvpruler-1007.txt`. **Cách dùng đúng: `--key pvpruler`.**
> Nên sửa `scene_install.py` cho `key` cũng `.lower()` — việc của người giữ file đó.

### 7b.6 鬼谷 Quỷ Cốc — bật lại NPC cổng 杨渐, **không** bật 唐昱

`maps-cy4` vào được 2221/2222/2223 nhưng phải **dời nhân vật bằng Mongo** để vào 鬼谷: NPC cổng
vẫn tắt. Hai NPC cổng đó nằm trong **Đại Lý** (`dali_new_320_monster.ini`), không phải trong bản đồ
CY4:

| mục | NPC | type | vị trí (Đại Lý) | script | đích của hub |
|---|---|---|---|---|---|
| `[monster213_off]` | 杨渐 鬼谷接引使 | 56007 | (154, 139.5) | 980007 `cy4_guigu_hub` | **2221** (86,147) |
| `[monster212_off]` | 唐昱 唐门接引使 | 56003 | (166, 137.5) | 980003 `cy4_tangmen_hub` | **2220** (129,71) |

**Đã bật 杨渐** — kiểm đủ bốn điều trước khi bật [DK]: (1) type 56007 có trong
`MonsterAttrExTable` (杨渐, base_ai 3, 阵营 8, 可交互 1); (2) script 980007 có trong `scripts.lua`;
(3) đích `destination_scene = 2221` đang `active=1` **và** có dòng trong DBC client (`Quỷ Cốc` 192×192
`guigu.Scene`); (4) đích **(86,147) đi được** trên `cy4_guigu.path` (vùng 1) và chỗ NPC đứng
**(154, 139.5) đi được** trên `dali_new_320.path` (vùng 5).

> **BẪY**: `Game_2/Scene/` có **hai** file nav cho 鬼谷 — `guigu.path` (bản 0x1000 đời cũ, parser
> giải sai, **không cảnh nào dùng**) và `cy4_guigu.path` (0x2000, 192×192) — `cy4_guigu.scn` khai
> **`cy4_guigu.path`**. Phải đo đúng file mà `.scn` khai, không đo file trùng tên.

**CỐ Ý KHÔNG bật 唐昱**, ba lý do cộng lại [DK]: `cy4_tangmen_hub` trỏ `destination_scene = 2220`;
**2220 đang `active=0`**; **2220 không có dòng trong DBC client** (lý do người điều phối chọn 495 cho
唐门). Và đổi 2220 → 495 cũng **sai**: 2220 dùng bản đồ `cy4_tangmen.scn` còn 495 dùng `tangmen.scn`
— **hai bản đồ khác nhau**, nên toạ độ (129,71) thuộc hệ khác. Người chơi **đã có** đường tới
唐家堡 qua 驿站 (mục menu 1022, đã đo `d7`/`d8`), nên không mất gì. Muốn bật 唐昱 thì phải sửa
`cy4_tangmen_hub.lua` — file của `maps-cy4`.

Cách bật (trong `transfer_npc.py`, có bằng chứng byte): bỏ hậu tố `_off` của section và bỏ dấu `;`
của `pos_x`. Kết quả (`apply-7-guigu.json`): file **4.485 dòng**, **đúng 2 dòng đổi** —
`dòng 4421 "[monster213_off]" → "[monster213]"` và `dòng 4426 "pos_x=;154.0000" → "pos_x=154.0000"`.
**Chờ RESTART KẾ** mới thấy NPC (quái/NPC đọc lúc nạp cảnh).

---

---

## 8. 汴京 Biện Kinh — trạng thái sau đợt bổ sung [DK]

Lúc 18:45 ngày 17/09, trên `R`:

- `[scene755]` `汴京 active=1 clientres=1074 file=bianjing.scn type=0` (ID 755 khớp DBC client);
  `[scene4511]` đã tắt (DBC client không có dòng 4511).
- `bianjing.path` 4.820.256 B, **1024×1024** (lưới 128×128, cell 8), 44.999 đỉnh, 89.986 tam giác —
  khớp `SceneDefineEx` dòng 1074 `汴京 1024 1024 bianjing.Scene`.
- `bianjing.scn` nay khai `navmapname=` **và** `monsterfile=` (dòng thứ hai do tôi thêm, mục 7b.2).
- `bianjing_monster.ini` do tôi tạo: 1 NPC 唐松 (530,937) script 990010 (mục 7b.2).
- `SceneAttr` dòng 755 nay là `汴京`, `安全级别 = 1` — `map-bianjing` đã sửa, tôi không đụng.
- `g_Cities` index **1020** → cảnh **755**, đích **(530,937)**, ẩn với NPC tên `唐松`.

Còn thiếu (của `map-bianjing`, không phải của tôi): 汴京 chưa có quái/NPC nào khác, chưa có
`_area.ini` / `_platform.ini` / `_patrolpoint.ini` / `_growpoint*`, và chưa có cổng đi bộ.
Nếu họ viết lại `bianjing.scn` thì **phải giữ dòng `monsterfile=`**, nếu không NPC 唐松 biến mất —
`transfer_npc.py verify` sẽ báo.

---

## 9. Việc còn lại / rủi ro đã thấy

1. **`SceneAttr.txt` có dòng nhưng SAI TÊN** [DK — tôi đã đoán nhầm là "thiếu dòng", đo lại thì có].
   Server chỉ đọc 3 cột `ID / Name$1$ / 安全级别` (`cfghelper.lua:736`), rồi dùng ở
   `script_base.lua:1536` (`LuaFnGetSceneSafeLevel`), `:1546` (tên cảnh) và hai bản
   `LuaFnIsActivityMonster` (`:10214`, `:11510`). Bảng hiện có:

   | dòng | tên trong `SceneAttr` | 安全级别 |
   |---|---|---|
   | **1007** | **武当山洞天** (sai — đây là Bất Dạ Thành) | 0 |
   | **755** | **测试8** (sai — đây là Biện Kinh) | 0 |
   | 1335 | 冰雪不夜城 (tên đúng, nhưng ID đời GL, không cảnh nào dùng) | 0 |
   | 490 | 擂台 | 0 |
   | 0 / 1 / 2 | 洛阳 / 苏州 / 大理 | 1 |

   ⇒ **không có nil-index**, chỉ là tên hiện sai trong game và Bất Dạ Thành sẽ **không phải vùng an
   toàn** (安全级别 0 như bãi quái, khác 1 của ba thành). Sửa = **đè ô của dòng đang có**, trái luật
   "chỉ thêm dòng" ⇒ **tôi không tự sửa**, xin người điều phối quyết (cùng lượt với 755 của
   `map-bianjing`).
2. **`TransportDefine.txt` chết** (mục 3.3): 1.036 dòng dùng toạ độ bản đồ đời cũ và ID cảnh cũ
   (1335 thay vì 1007). Muốn danh sách dịch chuyển nhanh của client sống lại thì phải **thêm** dòng
   mới theo toạ độ hiện tại (TransId từ 1037). Bot có `--exec 889888,ClientQueryTrans,<id>` nên về lý
   là đo được; để đợt sau.
3. **Cổng đi bộ của 1007 chưa có**: `SnowWorld2024_area.ini` `area_count=0`. Bảng CY
   `ScenePosDefineEx` dòng 2071–2073 cho sẵn cặp 洛阳 (253,253) ↔ 冰雪不夜城 (160,288) / lối về
   (160,290) và (168,185) → 洛阳 (255,253). Thêm cổng sẽ phải sửa `luoyang_new_area.ini` — **file dùng
   chung với cs3a2/maps-***, nên để người điều phối xếp lượt.
4. **无量山 (6) không có 驿站老板**. Nếu muốn nối luôn, cách rẻ nhất là thêm một mục monster giống hệt
   mục 5 vào `wuliang_monster.ini` + một dòng `g_Cities`. Chưa làm vì ngoài phạm vi "5 thành".
5. **Các cảnh phân tuyến 1311 / 1312 / 1320 không có dòng trong DBC client** ⇒ bất kỳ đường nào đưa
   người chơi sang shard đều sẽ ném "Invalid scene ID" ở client. Menu 驿站老板 không gửi tới shard,
   nhưng `chuan_song_system` vẫn còn các nhánh cũ 2001/2006/2007/3001/4001/4006/3011 trỏ tới
   1311/1312/1315/1316/71 — **không nằm trong menu nên không ai gọi được**, song nếu sau này bật lại
   thì phải kiểm DBC trước.
6. Bản Lua mới **chưa được đo live** (chưa restart). Bảo chứng hiện có là `luac -p` + 74 phép kiểm
   ngoại tuyến + 6 cặp đã chạy thật trên bản cũ với **cùng tham số** `TransferFunc`.

## 10. Những gì CHƯA KẾT LUẬN ĐƯỢC

- **Bản Lua có CHIA TRANG chưa đo live.** Nó được chép lên server lúc 18:52, tức **sau** restart
  18:47:56, nên 22 lượt đo ở mục 4/4b là của bản 18:38 (đủ 汴京/唐家堡/恶人谷 987, chưa chia
  trang). Bảo chứng hiện có: `luac -p` + **155/155** phép kiểm ngoại tuyến, trong đó có phép **ép
  tràn thật** (30 thành giả → 3 trang 16+16+10, 30/30 xuất hiện đúng một lần).
- **`[scene1007] PvpRuler = 6` và NPC 杨渐 của 鬼谷 chưa có hiệu lực** — cả hai đọc lúc nạp cảnh,
  đều được đặt sau restart 18:47:56 ⇒ **chờ restart kế**. Đừng đo bây giờ rồi kết luận là hỏng.
- **Tên cảnh 1007 hiện ra sao trong game** — ô tên đã sửa thành `冰雪不夜城` nhưng chưa xem
  tận mắt vì không mở Game.exe trong đợt này.
- **Client vẽ 1007 / 755 / 495 ra sao** — chỉ đo bằng bot (không render).
- **恶人谷 → 987 chưa đo live.** Mục menu của nó nằm trong menu con của `1012`, mà bot chỉ chọn
  được **một** mục mỗi phiên nên không với tới được. Bảo chứng: phép kiểm ngoại tuyến
  "môn phái 1 → cảnh 987" + cảnh 987 đang `active=1` và có dòng DBC client.
- **Trình đọc `.path` bản 0x1000 của `cs3a_scene.py` giải sai** (`tangmen.path` ra `cell`
  2.097.160, thế giới 67.109.120×…; `guigu.path` cũng vậy). Mọi bản đồ 0x1000 hiện **không đo
  được nav**. Đây là lỗi công cụ riêng, để lại cho người sau (xem mục 9).
