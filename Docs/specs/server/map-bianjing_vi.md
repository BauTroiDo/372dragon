# Bản đồ 汴京 (Biện Kinh) trên server riêng — cảnh 755

Ngày: 17/09/2026. Agent `map-bianjing`. Bằng chứng: `Build/Logs/2026-09-17-map-bianjing/`.
Tiếp nối `cs3a-maps_vi.md` (cách server nạp cảnh) và `cs3a2-maps_vi.md` (Lạc Dương / Tô Châu / Vô Lượng Sơn).
Công cụ: `Tools/server/map_bianjing.py` (`plan | apply | verify | navcost | move-char`) + `Tools/server/scene_install.py`.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`.
Nguồn CY: S4 = `Assets/CanonicalCY/Data` (nghệ thuật + DBC client), bảng thô S2 = `Tools/DATA NEW/DataCY31-08-26/Config`.

---

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| Cảnh **755 汴京** (`bianjing.scn`, `active=1`, `type=0`, `PvpRuler=0`, `clientres=1074`) | **Đã cài**, `scene_install.py verify --scenes 755` → `ok: true` |
| Navmesh `R/Game_2/Scene/bianjing.path` | Chép **nguyên byte** từ CY, sha256 `a082f49b5d840326649b49bb1982055a675427ce0025d926e5406835d470b449`, 4.820.256 B |
| `R/Game_2/Scene/bianjing.scn` | Mới (tôi tạo, chỉ `navmapname`); 18:38 **agent khác** thêm `monsterfile=bianjing_monster.ini` — giữ nguyên, xem mục 5.1 |
| Dòng mirror `configs/SceneDefineEx.txt` id **1074** | Mới (THÊM, không đè dòng nào); 23 ô sau copy nguyên từ dòng CY 755 |
| 5 tuyến phụ **775/776/779/780/785** | ✅ **`active=1`**, cả 5 cảnh đều được tạo lúc khởi động 18:47 (mục 6.2) |
| `SceneAttr` dòng 755 (`测试8` → `汴京`, an toàn 0→1, điểm đứng 40,40→512,942) | ✅ đã sửa, **đúng 4 ô của đúng 1 dòng**, chứng minh từng byte (mục 3.1) |
| Client tra được cảnh 755 | **[DK] tĩnh đạt**: DBC client dòng 755 = "Biện Kinh" 1024×1024 `bianjing.Scene`; đường tra mã đã đọc (mục 2). Chưa chạy `Game.exe` thật (mục 7.5) |
| Kích thước bản đồ 1024×1024 (không phải 512×942) | **[DK] đo bằng `.Heightmap`** (mục 3) |
| 22 điểm CY trong 汴京 nằm trên navmesh | **[DK] 21/22 đi được**, cùng vùng liên thông 2; 1 điểm chặn (mục 4) |
| Quái / NPC | **KHÔNG cài** — CY không có nguồn đặt NPC cho 汴京 (mục 5), ghi rõ thay vì bịa |
| Bot vào cảnh + đi lại (DoD 2–3) | ✅ **ĐẠT LIVE 18:54–18:58** — vào đúng (512, 942), đi 383,2 đơn vị / 16 chặng, 0 lỗi (mục 7) |
| Cổng nối | 汴京 **CÓ** nối 洛阳 trong CY (mục 4.2). Không tự thêm NPC — để agent `transfer-npc` |

Không restart, không commit (đúng ràng buộc).

---

## 1. Ba tầng dữ liệu của một bản đồ, và tầng nào là “sự thật”

| Tầng | File | Ai đọc | 汴京 |
|---|---|---|---|
| Danh sách cảnh | `R/configs/SceneInfo.ini` `[sceneN]` | `scenemanager_core:createScenes` (`lualib/scenemanager_core.lua:178-215`) tạo mọi cảnh `active=1 and type=0` lúc khởi động | **đã thêm `[scene755]`** |
| Nội dung cảnh | `R/Game_2/Scene/<file>.scn` + navmesh/ini | `scenecore:load` (`services/scene/scenecore.lua:102-149`) | **đã thêm `bianjing.scn` + `bianjing.path`** |
| Tài nguyên client | **DBC `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt`** | client, tra bằng **ID CẢNH SERVER** | **đã có sẵn dòng 755** |

Bảng `R/configs/SceneDefineEx.txt` (mirror phía server, 24 cột, dòng dõi GL) **không phải** bảng client dùng để vẽ.
`scene_install.py` vẫn bắt `clientres` phải có thật trong bảng mirror và tên file phải khớp — đó là ràng buộc của công cụ, không phải của client.

---

## 2. Vì sao ID cảnh server phải là 755 [DK]

Client CY-Source tra bản đồ bằng `packet.sceneid`, **không** bằng `packet.client_res`:

- `Src/Client/WXClient/Network/CysModernHandlers.cpp:211` — `if (packet.is_city) …SetSceneID((INT)packet.sceneid, 0); else …SetSceneID((INT)packet.sceneid, -1);`
  `packet.client_res` chỉ đi vào `TDU_Log(...)` ở dòng 212–213.
- `Src/Client/WXClient/World/WorldManager.cpp:108-110` — `Search_First_Column_Equ(_DBC_SCENE_DEFINE::SCENE_SERVER_ID_COLUMN, nSceneID)`
  (nhánh `bUserCity` ở `:93-104` cũng so `pTempSceneDef->nServerID == nSceneID`).
- `Src/Engine/Interface/TDDBC_Struct.h:985` — `static const int SCENE_SERVER_ID_COLUMN = 0;` và `INT nServerID; // [0] scene id`.
- `WorldManager.cpp:113-117` — không có dòng khớp ⇒ `TDThrow(_T("(CWorldManager::EnterScene) Invalid scene ID(%d,%d)"), …)`.

DBC client đọc bằng `Tools/game/dbc_inventory.py` — **682 dòng × 25 cột**, và đã có sẵn
(`Build/Logs/2026-09-17-map-bianjing/50-client-dbc.out.txt`):

| cột 0 = ID cảnh server | tên (đã dịch) | kích thước | file |
|---:|---|---|---|
| **755** | Biện Kinh | 1024×1024 | `bianjing.Scene` |
| 775 / 776 / 779 / 780 / 785 | Biện Kinh 2–6 tuyến | 1024×1024 | `bianjing.Scene` |
| 1072 / 1073 | Biên Cảnh Thạch Quật / Doanh Trại | 256×256 | `bianjingshiku.Scene` / `bianjingyingzhai.Scene` (bản đồ **khác**, đừng nhầm) |

### 2.1 Lần thử đầu đã sai trục — ghi lại để không ai lặp
Trước khi có đính chính, tôi chọn scene ID = **4511** vì đó là ID cảnh của **server CY** cho 汴京:
`SceneAttr` CY dòng 4511 = 汴京, `TransportDefine` CY cột 3 = 4511 cho 6 NPC truyền tống 汴京,
`T300SceneIDInfo` dòng 6–11 gom 4511–4516 vào nhóm 4511 [DK]. Lập luận đó đúng **cho server CY**, nhưng
**DBC client của dự án đánh số theo ID cảnh server của DỰ ÁN**, và ở đó 汴京 nằm ở 755 — không có dòng 4511.
`[scene4511]` đã được **`disable`** (`active=0`), không xoá vì `scene_install.py` chưa có lệnh `remove`
(`scene_install.py survey` báo đúng: `4511 … client ve duoc? THIEU`).

### 2.2 `clientres = 1074` — vì sao, và vì sao nó vô hại
`scene_install.py add` từ chối `clientres` không có trong bảng mirror. 汴京 **không có** trong bảng mirror
(547 dòng, ID lớn nhất 1056) [DK `survey/03-sde-compare.json`], nên tôi **THÊM** dòng mới id **1074**:

- 1074 trống ở **cả** bảng mirror (hết 1056) **lẫn** bảng thô DataCY (nhảy 1073 → 1075) → không đụng ai, không chặn lần đồng bộ sau.
- 23 ô sau copy **nguyên** từ dòng CY 755 (bảng CY 25 cột → mirror 24 cột, bỏ ô 25 = `0`).
- Không đè dòng nào: dòng mirror 755 vẫn là 寒雪灵境 (`HJZBS_BaiXiHuGameArea`, ở CY nằm ở dòng 1069) — nó **không được section nào dùng** [DK `survey/03-sde-compare.json` `755_dung_boi_sceneinfo: []`].
- **Client KHÔNG dùng `clientres`** (mục 2) ⇒ giá trị này chỉ để công cụ kiểm tra khớp tên file.

---

## 3. Kích thước bản đồ: 1024×1024, còn “512 / 942” là ĐIỂM ĐỨNG [DK]

`SceneAttr.txt` của CY có header `ID | Name$1$ | 类型 | 安全级别 | 可以站立的位置X | 可以站立的位置Z | …`
(đọc được ở bảng server `R/configs/SceneAttr.txt` dòng 2, bảng CY chỉ có 2 dòng kiểu nên mất tên cột).
Vậy dòng `4511 | 汴京 | 0 | 1 | 512 | 942 | …` nghĩa là **an toàn=1, điểm đứng (512, 942)** — *không phải* 512×942 kích thước.

Đo độc lập bằng file thật (`50-client-dbc.out.txt`): `.Heightmap` = `(W+1)² × 4 byte float + 16 byte đầu`.

| file | byte | suy ra |
|---|---:|---|
| `bianjing.Heightmap` | 4.202.516 | (1024+1)²×4 + 16 → **1024 × 1024** |
| `luoyang_new.Heightmap` | 1.052.692 | (512+1)²×4 + 16 → 512 × 512 ✔ khớp DBC |
| `dali_new_320.Heightmap` | 412.180 | (320+1)²×4 + 16 → 320 × 320 ✔ khớp DBC |

Xác nhận thêm: `bianjing.GridInfo` = 7.340.049 = 1024×1024×7 + 17; `bianjing.path` có `grid 128×128, cell 8` → 128×8 = 1024;
`bbox` = 0,038 … 1023,96. **Không có mâu thuẫn nào** — DBC ghi 1024×1024 là đúng.

## 3.1 `SceneAttr` dòng 755 — đã sửa đúng 4 ô (được người điều phối duyệt) [DK]

`configs/SceneAttr.txt` đánh chỉ số theo **ID cảnh server** (`cfghelper.lua:736-749` đọc bằng khoá `ID`;
dòng 0/1/2/6 = 洛阳/苏州/大理/无量山, dòng 71/72 = 大理, 73/74 = 无量山), và **dày đặc 0…19092 không hở ID**
(19.093 dòng dữ liệu) ⇒ **không thể thêm dòng**, chỉ có thể sửa dòng sẵn có. Dòng 755 là rác của một cảnh thử
(`测试8` = "Thử 8"), chưa cảnh nào dùng trước khi tôi thêm `[scene755]`.

Giá trị mới **lấy nguyên từ dòng CY 4511** (汴京) — cùng tên cột, không tự nghĩ số:

| cột | tên cột (dòng tên của chính bảng server) | trước | sau | nguồn |
|---:|---|---|---|---|
| 1 | `Name$1$` | `测试8` | **`汴京`** | `SceneAttr` CY dòng 4511 cột 1 |
| 3 | `安全级别` | `0` | **`1`** | `SceneAttr` CY dòng 4511 cột 3 |
| 4 | `可以站立的位置X` | `40` | **`512`** | `SceneAttr` CY dòng 4511 cột 4 |
| 5 | `可以站立的位置Z` | `40` | **`942`** | `SceneAttr` CY dòng 4511 cột 5 |

Chứng minh (`73-sceneattr-apply.out.txt`, cả công cụ tự kiểm lẫn `diff` độc lập):

- Sao lưu trước khi ghi: `R/backups/map-bianjing-sceneattr-20260917T113453Z/SceneAttr.txt`.
- **Đúng MỘT dòng khác** giữa bản sao lưu và file mới: chỉ số dòng 757 (dòng 758 khi đếm từ 1) = dòng ID 755.
- **Đúng 4 ô khác** trong dòng đó: `[1, 3, 4, 5]`. Mọi ô còn lại (kể cả `ResId=547` ở cột 23) **giữ nguyên**.
- Số dòng 19.096 → 19.096; số cột 24 → 24; kết thúc dòng vẫn **CRLF**; toàn file **vẫn giải mã GBK sạch**.
- Số byte 1.463.876 → 1.463.877 (đúng bằng −1 cho `测试8`(5 B GBK) → `汴京`(4 B), +1 cho `40`→`512`, +1 cho `40`→`942`).
- Đọc lại bằng chính luật `txtreader` (dòng tên 24 cột ↔ dòng 755 24 cột): `ID=755, Name$1$=汴京, 类型=0, 安全级别=1, X=512, Z=942`.

**Tác dụng thật của `安全级别`, đo được** — không phải "mở PK" như tôi viết vội lần trước:
`cfghelper.lua:745` đưa nó vào `scene_attr[].safe_level`; người đọc duy nhất là
`script_base.lua:1533-1537 LuaFnGetSceneSafeLevel()`, được gọi ở `Game_2/Script/scripts/scene.lua:91`
(lúc vào cảnh) và dùng ở `scene.lua:115-118`:

```lua
-- 玩家进入非安全场景，给个无敌BUFF
if nSafeLevel == 0 then
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 54, 100)
end
```

⇒ với `安全级别 = 0`, mỗi lần vào 汴京 người chơi bị gắn impact 54 ("vô địch" khi vào cảnh **không** an toàn);
với `= 1` (như CY) thì không. Luật PK thật nằm ở `PvpRuler` của `SceneInfo.ini` (đang là 0, giống 洛阳/苏州/大理),
**không** phải cột này. `Name$1$` được `script_base.lua:1546 GetSceneName()` trả về (dùng trong thoại/thông báo).

---

### 4.1 `bianjing.path` [DK]
`cs3a_scene.py path-info` trên file **đã cài**:
`version 0x2000`, **44.999 đỉnh / 89.986 tam giác (41.361 chặn) / 44.997 cạnh**, lưới 128×128 ô 8,
bbox 0,038…1023,96, **28 vùng đi được**, vùng chính **#2 có 48.004 tam giác**, `trailing_bytes: 0`
(đọc hết đúng byte cuối). Chép nguyên byte, sha256 khớp nguồn.

Để so: `dali_new_320.path` 11.669/23.324, `luoyang_new.path` 10.546/21.080 → 汴京 lớn gấp ~4 lần.

### 4.2 Điểm CY đã biết, và chúng có đi được không (`39-points.out.txt`)
Định dạng `(tam giác, cờ, vùng)`, cờ bit0 = bị chặn.

| Điểm CY | x,z | kết quả | nguồn |
|---|---|---|---|
| **Điểm đứng / hồi sinh** | **512, 942** | (57769, **0**, 2) đi được | `SceneAttr` CY dòng 4511 cột 4/5 |
| **Đến từ 洛阳** | **757, 435** | (75978, **0**, 2) đi được | `ScenePosDefineEx`: 洛阳 (195,269) → 汴京 (757,435) |
| NPC 金阅楼 | 752, 435 | 0, vùng 2 | `TransportDefine` #1034 |
| NPC 余繁 | 688, 752 | 0, vùng 2 | `TransportDefine` #1035 |
| NPC 梁民 | 347, 353 | 0, vùng 2 | `TransportDefine` #1036 |
| NPC 许行之 | 360, 724 | 0, vùng 2 | `TransportDefine` #1037 |
| NPC 唐松 | 530, 937 | 0, vùng 2 | `TransportDefine` #1038 |
| NPC 杨中川 | 542, 554 | 0, vùng 2 | `TransportDefine` #1039 |
| NPC 碧落 (三神幻境) | 621, 380 | 0, vùng 2 | `CampaignTable` 558 `_INFOAIM621,380,755` |
| NPC 典卿诗 | 496, 552 | 0, vùng 2 | `StrDictionary` `_INFOAIM` |
| NPC 周万金 | 756, 545 | 0, vùng 2 | `StrDictionary` |
| NPC 周万金 (mục 2) | 135, 448 | **(328, 1, 0) BỊ CHẶN** | `StrDictionary` — điểm duy nhất chặn |
| 4 mốc không tên | 215,302 / 239,828 / 699,795 / 768,497 / 788,789 | đều 0, vùng 2 | `StrDictionary` |

⇒ **21/22 điểm CY đi được và cùng vùng liên thông #2** với điểm đứng. [SL] (135,448) nằm trong nhà/vật cản.

### 4.3 Cổng vào — đính chính giả thiết ban đầu [DK]
Giả thiết của người điều phối (“汴京 không nối với 4 bản đồ ta đang có”) **KHÔNG đúng với dữ liệu CY**:
`ScenePosDefineEx` có **84 dòng nối 汴京 ↔ 洛阳** (và 12 dòng ↔ 凤鸣镇, bản đồ ta không có); 180 dòng còn lại là
chuyển tuyến 汴京 ↔ 汴京N线 (`survey/07-portals.json`).

| Chiều | Điểm đi | Điểm đến |
|---|---|---|
| 洛阳 (cảnh 0) → 汴京 | (195, 269) | **(757, 435)** |
| 汴京 → 洛阳 (cảnh 0) | (752, 435) | (195, 273) |

`AutoSearch.txt` dòng 183 cho biết NPC ở đầu 洛阳: **孟华**, chức danh **汴京使者**, chức năng **传送**, tại **(195, 269)** cảnh 0
(`37-cy-detail.out.txt`). NPC này **chưa có** trong `luoyang_new_monster.ini` của server — `cs3a2-maps_vi.md` mục 3 đã
liệt 孟华 vào 32 NPC CY thiếu.

**Toạ độ điểm đến nên dùng khi nối vào 汴京: `(757, 435)`** (điểm CY thật, đi được, cạnh NPC 金阅楼 752,435).
Điểm hồi sinh / đứng mặc định: **(512, 942)**. Chiều về 洛阳: (195, 273).
Tôi **không** thêm NPC/cổng nào — phần nối 5 thành thuộc agent `transfer-npc`.

### 4.4 Server KHÔNG chặn di chuyển bằng navmesh [DK]
- `scenecore:char_move` (`services/scene/scenecore.lua:2162-2199`) không hề tra `self.map`; khối chú thích 2026-08-26
  ghi rõ đã **bỏ** phần server kéo ngược nhân vật khi vào ô bị chặn, trả việc chặn tường cho client.
- `scenecore:move_blocked` (`:335`) **không được gọi ở đâu cả** (`grep` chỉ ra đúng chỗ định nghĩa).
- Không có `bianjing_block.bin` (cả thư mục chỉ có `sr_rift_block.bin`) ⇒ `blockmap` không bật cho 汴京.
- `findpath` chỉ dùng cho **AI/robot** (`services/scene/ai/character.lua:35,79`, `services/robot/*`).

⇒ Bot/nhân vật sẽ đi được mọi nơi trong 汴京; navmesh chỉ ảnh hưởng AI quái.

### 4.5 `findpath` trả rỗng — hành vi có sẵn, không phải lỗi của 汴京 [DK]
Chạy chính `pathparser` + `lnavmesh.so` của server (`34-navpath.out.txt`):
`GetPath` trả **0 waypoint** cho hầu hết cặp điểm ở **cả** `bianjing.path` **lẫn** `dali_new_320.path`
(bản đồ đang chạy thật). Chỉ cặp rất gần (512,942)→(516,938) trả 2 điểm.
Vậy đây là giới hạn sẵn có của lớp nav hiện tại, **không** phải khiếm khuyết riêng của 汴京. Chưa kết luận
được nguyên nhân (nghi đơn vị: `nav_adapter:findpath` chia kết quả cho 100 nhưng đầu vào không nhân 100 —
`lualib/nav_adapter.lua:83-96`); việc này nằm ngoài phạm vi bản đồ.

---

## 5. Quái / NPC: KHÔNG có nguồn CY — để trống [DK]

Đã tìm hết các nguồn mà cs3a/cs3a2 từng dùng:

| Nguồn | Kết quả cho 汴京 |
|---|---|
| `MissionNPC_HashTable.txt` (CY) — cột 3 = ID cảnh | **0 dòng** cho 755 hoặc 4511 (so: cảnh 2 大理 có 92 dòng) |
| `tlbb15/Public/Scene` | **không có file `bianjing*` nào** |
| `NpcPosLimit.txt`, `ShopTable.txt` (CY) | 0 dòng |
| `_INFOAIM<x>,<z>,755` quét TOÀN BỘ bảng CY | **9 mốc**, chỉ **4 có tên** (碧落, 典卿诗, 周万金 ×2) — so với 4.060 mốc của 洛阳, 2.970 của 大理 |
| `TransportDefine.txt` | 6 NPC truyền tống có **tên + toạ độ**, nhưng **không có `type`** (ID `MonsterAttrExTable`); dò theo tên trong bảng server chỉ khớp **1/6** (唐松 = 49068, trùng tên, chưa xác minh là cùng NPC) |
| `MonsterAttrExTable` CY | 16 dòng *mang chữ* 汴京 trong tên (汴京校尉 117, 汴京使者 49396, 汴京马车/牛车, ghế, 花车, mèo…) nhưng **không có bảng đặt vị trí** |

⇒ Không đủ dữ liệu để dựng `bianjing_monster.ini` mà **không bịa `type`/`script_id`**. `bianjing.scn` vì vậy chỉ khai `navmapname`
(mọi khoá khác của `.scn` là tuỳ chọn — `scenecore:load` kiểm `if self.scn.System.<khoá> then`).
Một thành phố đi lại được nhưng chưa có NPC là kết quả thật; **đây là việc tiếp theo, không phải việc đã làm**.

Có thể làm sau nếu người dùng đồng ý dựng từ nguồn gián tiếp: 6 NPC truyền tống (tên + vị trí CY) + 4 NPC `_INFOAIM`,
dùng `type` của các NPC **cùng tên** trong `MonsterAttrExTable` server, `script_id=-1` (không thoại).
Sẽ phải ghi rõ đó là **[SL]**, không phải bản đặt NPC của CY.

### 5.1 Agent khác đã đặt NPC đầu tiên (17/09 18:38) — không phải việc của tôi, giữ nguyên [DK]
`R/Game_2/Scene/bianjing_monster.ini` (mới, 273 B) có **1 mục**: `type=49068 name=唐松 title=驿站老板
pos_x=530 pos_z=937 dir=27 script_id=990010 base_ai=3`, và `bianjing.scn` được thêm dòng `monsterfile=bianjing_monster.ini`.
Đúng chính là NPC tôi nêu trong handoff (唐松 = 1/6 tên khớp `MonsterAttrExTable` server; vị trí (530,937) từ
`TransportDefine` #1038) — vị trí này **đi được** (tam giác 18129, cờ 0, vùng 2).

**Đã gia cố công cụ để không đè mất việc của họ**: `map_bianjing.py apply` giờ **chỉ tạo `.scn` khi thiếu**;
nếu file đã có và `navmapname` đúng thì **giữ nguyên** (chỉ liệt kê khoá của agent khác); chỉ khi `navmapname` sai
mới sửa **đúng dòng đó** (có sao lưu `.truoc-map-bianjing`). `verify` cũng chỉ đòi `navmapname=bianjing.path`,
không phán các khoá còn lại. (Trước khi gia cố, chạy lại `apply` sẽ **xoá mất** dòng `monsterfile=` của họ.)

---

### 6.1 Nguyên nhân và bản vá
`.path` được đọc bằng `lualib/pathparser.lua` → `lualib/iostream.lua`. Bản gốc:

```
GameServer/lualib/iostream.lua:100-106 (trước vá)
function bistream:readfloat()
    local start = self.pos
    local s = string.sub(self.buffer, start)      <-- COPY TOÀN BỘ phần đuôi buffer, mỗi float một lần
    local n = string.unpack("f", s)
```

⇒ O(n²) theo kích thước file. **Cả 7 hàm đọc đều mắc**: `readfloat`, `readushort`, `readshort`, `readuint`,
`readulong`, `readuint8`, `readchar` (`readint` :57 và `readuchar` :81 vốn đã kẹp đúng).

**Người điều phối đã áp hai đợt vá 17/09**: `readfloat` (sao lưu `backups/iostream-20260917T112813Z/`), rồi 6 hàm
còn lại (`backups/iostream2-20260917T114206Z/`). Tôi đo lại **trên chính thư viện của server**:

| phép đo | trước vá | sau vá | tỉ lệ |
|---|---:|---:|---:|
| `dali_new_320.path` (1,19 MB) parse | 2,23 s | **0,024 s** | 93× |
| `bianjing.path` (4,82 MB) parse | 32,34 s | **0,081 s** | **399×** |
| `bianjing` tổng (parse + dựng polygon + `AddPolygons`) | 32,69 s | **0,464 s** | 70× |
| bộ nhớ Lua khi nạp `bianjing` | 19.636 KB | 10.349 KB | −47% |
| 60 cảnh `type=0 active=1` (chưa bật tuyến phụ) | 65,68 s | 0,71 s | 92× |
| **65 cảnh (đã bật 5 tuyến phụ 汴京) — đúng cấu hình khởi động thật** | **228,05 s** | **1,52 s** | **150×** |
| **488 file `.path` trong `Game_2/Scene`** (325.837 polygon, 1.629.185 điểm) | **101,65 s** | **3,53 s** | 29× |

### 6.1.1 Chứng minh bản vá KHÔNG đổi dữ liệu và KHÔNG đổi hành vi [DK]
Quan trọng vì `iostream` còn nằm trên đường **gói mạng**: `services/game/packet.lua`, `services/login/packet.lua`,
`stallinforeader`, `preloader`, `item.lua`, `pet_detail.lua`, `guildmanager_core.lua`.

1. **Độ rộng kẹp khớp định dạng `string.unpack`** (`90-iostream-audit.out.txt`) — bẫy thật: trong Lua 5.4 `"L"` là
   kích thước **native** (8 byte trên x64), không phải 4:
   `H`→2 (`start+1`), `h`→2, `I4`→4 (`start+3`), `L`→8 (`start+7`), `I8`→8 (`start+7`), `b`→1 (`start+0`), `f`→4 (`start+3`). ✔
2. **Checksum toàn bộ toạ độ** của **488 file `.path`** (`92-navcheck.out.txt`): bản gốc và bản đã vá cho
   `polygon=325837 diem=1629185 checksum1=2922427470 checksum2=739044409` — **giống hệt**.
3. **Tương đương từng kiểu đọc** (`94-equiv.out.txt`): đọc một buffer 4.096 byte ngẫu nhiên có hạt giống cố định,
   9 kiểu × 60 vòng **+ 27 ca BIÊN** (vừa đủ byte / thiếu 1 / thiếu 2 ở cuối buffer). Hai bản cho ra
   **687 dòng giống hệt, cùng sha256 `23d73c0b…2873`**, kể cả **cách ném lỗi khi thiếu byte**.

Script đo lại: `scripts/70-iostream-after.sh`, `71-startup-navcost.sh`, `92-run-navcheck.sh`, `94-run-equiv.sh`
(bản chưa vá chạy từ thư mục sao lưu ở `/tmp`, không đụng server).

### 6.2 5 tuyến phụ — đã bật trước restart
Giá bật thêm sau khi vá **không đáng kể**: 5 cảnh × 0,464 s ≈ **+2,3 s khởi động**. Chưa vá thì là **+161 s**
(5 × 32,3 s) — tức bật tuyến phụ khi chưa vá là không khả thi.

`scene_install.py enable` **SAU** khi restart sẽ không tạo cảnh: `scenemanager_core:createScenes` chỉ chạy lúc khởi
động và `ensure_scene` (`:270-307`) chỉ dùng `scene_info_cache` nạp lúc đó ⇒ bật sau = **phải restart lần nữa**.
Vì vậy quyết định phải ra **trước** cửa sổ restart; người điều phối đã bật cả 5 lúc đó
(`verify --scenes 755,775,776,779,780,785` → `ok: true`), và log 18:47 cho thấy **cả 6 cảnh đều được tạo**.

---

### 7.1 Khởi động: 65 cảnh, 4 giây
Người điều phối restart lúc **18:47:56** sau khi vá cả 7 hàm `iostream` và bật 5 tuyến phụ.
Log `Game2_20260917_184720.log` (`A1-logcheck.out.txt`):

- `LAUNCH snlua scene 汴京` + `汴京2线…汴京6线` — **cả 6 cảnh đều được tạo** (18:47:39 → 18:47:53).
- `[SceneManager] scene startup done, total = 65` lúc **18:47:56**; `15733/15734 LISTEN sau 4 giây`.
- **0** `traceback`, **0** `SCENE_LOAD_FAIL`, **0** `SCENE_INIT_FAIL`, **0** `SCENE_CREATE_FAIL`.
  **5** `MONSTER_CFG_FAIL` — 5 ID đã biết của 少林/天龙/峨嵋, **không** phải của 汴京.

So với giá nạp navmesh đo được cho **đúng 65 cảnh này**: **228,05 s trước vá → 1,52 s sau vá** (mục 6.1).

### 7.2 Dời nhân vật mà KHÔNG restart [DK]
`30-restart-move.sh` được viết cho cửa sổ restart (dừng skynet rồi ghi Mongo). Lúc tôi chạy thì server **đã chạy lại rồi**
và 4 agent khác đang đo ⇒ chạy `30-` sẽ restart lần hai và cắt ngang họ. **Không chạy.** Thay vào đó:

- Đo trước: log của lượt chạy hiện tại **không hề nhắc GUID 200006** (`so_lan_nhac_guid: 0`, `connected/disconnected 0/0`)
  ⇒ test05 chưa từng đăng nhập từ 18:47:20, server không giữ bản ghi nào của nó trong bộ nhớ.
- Thêm cờ `--server-running` cho `move-char`: **thu hẹp** điều kiện từ chối từ "có bất kỳ client nào nối" xuống
  "**chính nhân vật này** đang online" (đếm `[CLIENT_LINK] connected/disconnected guid=` trong log đang chạy),
  và ghi bằng chứng vào kết quả. Mặc định (cửa sổ restart) vẫn là điều kiện cũ, chặt hơn.
- Ghi: `matched 1, modified 1`, (74; 50,170) → **(755; 512, 942)** (`A3-char-move-1.json`).

### 7.3 Hai lượt bot live (tài khoản test05 / GUID 200006, `CYTest05`)

| | lượt 1 `18:54:48` | lượt 2 `18:56:20` |
|---|---|---|
| vào cảnh | `entered scene=755 obj=5 pos=512.0,942.0` | `entered scene=755 obj=6 pos=530.0,937.0` (giữ đúng chỗ lượt 1 rời đi) |
| đi | (512,942) → **(530,937)**, 2 chặng, 18,7 đơn vị | (530,937) → **(542,554)**, **16 chặng, 383,2 đơn vị**, 95,4 s |
| `GCEnterScene` / `GCCharMove` | 1 / 2 | 1 / 2 |
| tới đích | `goto arrived (model) at 530.0,937.0 scene=755` | `goto arrived (model) at 542.0,554.0 scene=755` |
| heartbeats | 0 (phiên 10 s) | **6** |
| `decode_failures` / `unknown_packets` / `dropped_outbound` / `transfers` | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| `exit_code` / `terminal` / `charlogin` / `in_world` | 0 / `quit_complete` / `granted` / true | như lượt 1 |
| review | 6/8 PASS | **7/8 PASS** (`bot_result` PASS) |

Bằng chứng **phía server** (log, `A6-postbot-log.out.txt`) — không chỉ lời của bot:

```
[18:54:49] [AUTO_ROUTE_ENTER] guid= 200006 obj= 5 scene= 755 x= 512.0 y= 942.0 client_res= 1074 first_login= true
[18:56:22] [AUTO_ROUTE_ENTER] guid= 200006 obj= 6 scene= 755 x= 530.0 y= 937.0 client_res= 1074
[18:56:37 … 18:57:52] 6 × [CLIENT_HEARTBEAT] guid= 200006 scene= .SCENE_755 obj= 6
```

161 dòng log mới trong cả hai phiên, **0 dòng lỗi** (`traceback|[E]|error|fail|nil value|attempt to` → rỗng).
Tổng cả log vẫn 0/0/0/0 + 5 `MONSTER_CFG_FAIL` cũ. Mongo sau đó: 200006 ở **cảnh 755 (542, 554)** — server ghi lại đúng.

`world.created=1 → deleted=1` ở lượt 2: NPC 唐松 vào rồi ra khỏi tầm AOI khi bot đi xa ⇒ AOI của cảnh chạy đúng.

### 7.4 Hai mục review FAIL là do khuôn, không phải lỗi cảnh [DK]
`Tests/net/collect_world_snapshot.py:21` ghim cứng `ACCOUNT, GUID = 'test00', 200001`:

- `one_login_record` (FAIL cả hai lượt): đếm `login_flags` của **test00**; tôi chạy test05 nên `changed = {}` → `sum ≠ 1`.
- `position_unchanged` PASS "giả": nó so `scene_pre=2, scene_post=2` của **CYTest00**, không liên quan tôi.
- `bot_result` FAIL ở lượt 1 chỉ vì `heartbeats 0 < --min-heartbeats 3` (mặc định); phiên 10 s chưa tới nhịp 15 s.
  Lượt 2 dài hơn → `heartbeats=6` → **PASS**. Mọi trường `wanted` khác đều khớp ngay từ lượt 1.

### 7.5 Kịch bản để tái lập

```bash
# chỉ khi CÓ cửa sổ restart (dừng skynet, 0 client): dời nhân vật rồi bật lại
wsl -d TLBB -u root -- bash .../scripts/30-restart-move.sh
wsl -d TLBB -u root -- bash .../scripts/31-wait-logcheck.sh 900      # chỉ đọc, chạy lúc nào cũng được
# khi server ĐANG CHẠY và nhân vật này offline:
python3 -B Tools/server/map_bianjing.py move-char --guid 200006 --scene 755 --x 512 --z 942 --server-running --out F
powershell -NoProfile -ExecutionPolicy Bypass -File Build\Logs\2026-09-17-map-bianjing\scripts\32-run-bot.ps1 `
    -Goto "542,554" -Walk 1 -DwellMs 150000
```

`32-run-bot.ps1` là bản sao **có tham số** của `Tests/net/run_core_live.ps1` (bản gốc ghim `test00`/200001 nên không
dùng được; **tôi không sửa file dùng chung**). Mật khẩu đọc từ `.local/test-accounts.txt`, không ghi ra đâu.
`--walk` chỉ nhận **0 hoặc 1** (bot từ chối 6); muốn `bot_result` PASS thì phiên phải đủ dài cho ≥ 3 nhịp 15 s.

**Chưa đo được: log CLIENT.** Tiêu chí "không có `Invalid scene ID`" mới chỉ chứng minh **tĩnh** (mục 2: DBC có dòng 755,
đường tra mã đã đọc). Chạy `Game.exe` thật cần một phiên client riêng, không làm trong lượt này.

---

## 8. Việc đã chạm, và cách hoàn tác

| Thứ | Thao tác | Hoàn tác |
|---|---|---|
| `R/configs/SceneDefineEx.txt` | **thêm 1 dòng** id 1074 ở cuối (547 → 548 dòng dữ liệu; 548 dòng đầu **trùng từng byte** với bản sao lưu) | `cp backups/map-bianjing-20260917T110209Z/SceneDefineEx.txt configs/` |
| `R/configs/SceneInfo.ini` | thêm `[scene755]` (active=1), `[scene775/776/779/780/785]` (active=0), `[scene4511]` (active=0, rác của lần thử đầu) | `scene_install.py disable --scenes 755,775,776,779,780,785`; muốn xoá hẳn section thì cần thêm lệnh `remove` cho `scene_install.py` |
| `R/configs/SceneAttr.txt` | **4 ô của đúng dòng 755** (mục 3.1) | `cp backups/map-bianjing-sceneattr-20260917T113453Z/SceneAttr.txt configs/` |
| `R/Game_2/Scene/bianjing.path` | file MỚI (bị `.gitignore` loại: `/Game_2/Scene/**/*.path` → cần `git add -f` nếu muốn theo dõi) | `rm` |
| `R/Game_2/Scene/bianjing.scn` | file MỚI, chưa `git add` | `rm` |
| Mongo, nhân vật **200006** (`CYTest05`) | `attrib.sceneid` 74 → **755**, `world_pos` (50, 170) → (512, 942); sau hai lượt bot server ghi lại (542, 554) | bản ghi trước khi sửa ở `A3-char-move-1.json`; `move-char --guid 200006 --scene 74 --x 50 --z 170 --server-running` |

Sao lưu đã tạo: `R/backups/map-bianjing-20260917T110209Z/` (tôi), và `R/backups/scene-install-20260917T11*/` (mỗi lệnh ghi một bản).
**Không commit** — `git -C R status` còn nguyên thay đổi của các agent khác (`native_config.lua`, `packet.lua`, `monster.lua`,
`MonsterAttrExTable.txt`, `StandardImpact.txt`…) nên người điều phối phải tách hunk khi commit.
Phần của tôi trong `configs/SceneInfo.ini` là **chỉ** các section 755/775/776/779/780/785/4511; **16 dòng `active=0 → 1` khác
là của agent khác** (9 cảnh môn phái, 冰雪不夜城, 唐家堡, 恶人谷, 慕容山庄, cy4 1054–1056) — đã đối chiếu bằng
`41-attrib-diff.out.txt`. `configs/.scene_install.lock` là file khoá do `scene_install.py` tạo, nên cho vào `.gitignore`.

Bằng chứng flock hoạt động: bản sao lưu của agent khác lúc `20260917T110218Z` **đã chứa** section của tôi, và bản sao lưu
của tôi lúc `110209Z` chưa có sửa đổi 冰雪不夜城 của họ — hai lượt ghi nối tiếp nhau, không ai mất mục
(`42-backup-tail.sh`: 7905 dòng / 790 section → 7915 dòng / 791 section, đúng 10 dòng của một section + 1 dòng trắng).

---

## 9. Chưa kết luận được / rủi ro còn lại

1. **Client thật (`Game.exe`) chưa chạy.** Bot đã đo live xong (mục 7.3), nhưng "không có `Invalid scene ID`"
   mới chỉ chứng minh **tĩnh** bằng DBC + đường tra mã (mục 2). Cần một phiên client để đóng hẳn.
2. ~~`SceneAttr` dòng 755~~ — **ĐÃ XỬ 17/09** (mục 3.1). *Đính chính lần báo trước của tôi:* dòng 755 là **`测试8`**,
   không phải `副本` (`副本` là dòng 4511, tôi đã suy từ dòng sai). Và `安全级别` **không** điều khiển PK —
   nó chỉ quyết định có gắn impact 54 lúc vào cảnh hay không (`scene.lua:115-118`); luật PK là `PvpRuler`.
3. `ResId` của dòng `SceneAttr` 755 vẫn là **547** (giá trị cũ của 测试8). Cột này **không** nằm trong 3 khoá mà
   `cfghelper:read_scene_attr` đọc (`ID`, `Name$1$`, `安全级别`) nên chưa thấy ai dùng; **chưa kết luận được**
   nó có nghĩa gì ở bản server này, nên tôi không đổi (CY để ô tương ứng = 755).
4. **5 cảnh đang `active=1` mà DBC client KHÔNG có dòng** — phát hiện phụ khi đọc DBC, **không phải việc của tôi** nhưng
   nên báo: scene **1311, 1312, 1315, 1316, 1320, 1321, 1500, 2218** (phân tuyến 洛阳/苏州/大理 + 地府) không có dòng nào
   trong DBC client 682 dòng ⇒ người chơi bị đẩy vào đó sẽ ăn `Invalid scene ID`. Kiểm nhanh:
   `scene_install.py survey --all` cột “client ve duoc?”.
5. **`凤鸣镇`** (12 dòng cổng CY nối 汴京) là bản đồ ta không có; nếu sau này nối, cần xem lại `ScenePosDefineEx`.
6. Script CY `\event\bianjing\tempallianceshop.lua` (id 510001) nằm trong `Data/ConfigFolder/Script.dat` **chưa giải nén**;
   chưa đọc, chưa dùng.

---

## 10. Lệnh hay dùng

```bash
# trạng thái / cài lại (idempotent) / kiểm
python3 -B Tools/server/map_bianjing.py plan   --out <json>
python3 -B Tools/server/map_bianjing.py apply  --out <json>
python3 -B Tools/server/map_bianjing.py verify --out <json>
python3 -B Tools/server/map_bianjing.py navcost --out <json>
python3 -B Tools/server/map_bianjing.py sceneattr             # xem trước, KHÔNG ghi
python3 -B Tools/server/map_bianjing.py sceneattr --apply     # ghi 4 ô của đúng dòng 755 + tự chứng minh

# bảng cảnh (mọi thay đổi SceneInfo.ini phải qua đây — có flock)
python3 -B Tools/server/scene_install.py survey --scenes 0,1,2,6,755,775,776,779,780,785,4511
python3 -B Tools/server/scene_install.py verify --scenes 755
python3 -B Tools/server/scene_install.py enable --scenes 775,776,779,780,785   # bật 5 tuyến phụ (mỗi cảnh +32 s khởi động)

# navmesh
python3 -B Tools/server/cs3a_scene.py path-info R/Game_2/Scene/bianjing.path
python3 -B Tools/server/cs3a_scene.py query     R/Game_2/Scene/bianjing.path 512,942 757,435
```
