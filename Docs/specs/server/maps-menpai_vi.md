# Bản đồ môn phái trên server riêng

Mỗi agent viết MỘT mục riêng và **nối vào cuối file**, không viết đè mục của agent khác.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng/số). **[SL]** suy luận.
`R` = `/home/ubuntu/cys-test-20260913` (server riêng skynet trong WSL `TLBB`).

---

## Mục A — `maps-cy4`: 鬼谷 2221, 桃花岛 2222, 绝情谷 2223 (17/09/2026)

Bằng chứng: `Build/Logs/2026-09-17-maps-cy4/`. Công cụ: `Tools/server/scene_install.py` +
`Build/Logs/2026-09-17-maps-cy4/scripts/*`.

### A.1 Kết quả

| Việc | Trạng thái |
|---|---|
| 3 cảnh có mục, `active=1`, `scene_install.py verify` | **ok: true** (`07-verify.json`) |
| 90 dòng `MonsterAttrExTable` của NPC/quái 4 phái CY | **đã nạp lại** (28.968 → 29.058 dòng, `05-monster-verify.json`) |
| 3 dòng `SceneDefineEx` phía client cho 3 cảnh | **đã thêm** (679 → 682 dòng, `09-client-rows-verify.json`) |
| Đo live (bot), sau restart 18:47:56 | **ĐẠT 3/3** — xem A.7b |
| Cổng vào từ Đại Lý | 2/3 cổng đang bật; cổng 鬼谷 **đang tắt** — xem A.6, việc của `transfer-npc` |

### A.2 Sửa lại khảo sát ban đầu: ba cảnh **đã có sẵn mục**, không cần `add` [DK]

Giao việc nói `SceneInfo.ini` không có mục nào cho `taohuadao`/`congren` và `guigu` chỉ có cảnh 198.
Đo lại thì **sai**: nội dung 4 phái CY nằm dưới tiền tố `cy4_`, nên tìm theo tên trần không thấy.

```
scene  ten     act type file               cres  cres_ten  khop  nav      quai
2220   唐门     0   0    cy4_tangmen.scn    1053  唐门        OK    305709   24
2221   鬼谷     0→1 0    cy4_guigu.scn      1054  鬼谷        OK    164611   34
2222   桃花岛   0→1 0    cy4_taohuadao.scn  1055  桃花岛      OK    512994   27
2223   绝情谷   0→1 0    cy4_congren.scn    1056  绝情谷      OK    712804   19
```

- Bốn mục này có sẵn trong **bản sao gốc 13/09** (`git log -- configs/SceneInfo.ini`: lần sửa cuối là
  `c7e7865` CS3a2 tắt 183 cảnh); cả bốn nằm trong danh sách bật lại `configs/cys_scene_off.json`. [DK]
- Nội dung cảnh (`.scn`, `.path`, `_monster.ini`, `_area.ini`, `_patrolpoint.ini`) có từ 09/09–10/09,
  do đợt "4 phái CY" của server gốc nhập. [DK: mtime + `git log`]
- **Vì vậy không dùng `add` mà dùng `enable`.** Chọn ID mới sẽ tách rời khỏi wiring đang có: script
  `cy4_*_hub.lua` ghi cứng `destination_scene=2220/2221/2222/2223`, và `configs/SceneAttr.txt` đã có
  dòng 2220–2223 với đúng toạ độ đó (2221 → 86,147; 2222 → 252,167; 2223 → 244,252). [DK]

`cy4_*.path` trên server **trùng sha256** với `.path` của CY trong `Assets/CanonicalCY/Data/SceneFolder`
(`41-name-proof.sh`): `guigu` `8e724c04…`, `taohuadao` `cfcdc723…`, `congren` `3d2f3750…`,
`tangmen` `23976721…`. Tức là navmesh CY **nguyên byte**, chỉ đổi tên file. [DK]

### A.3 Lỗ hổng thật: 80 ID quái/NPC không có trong bảng đang nạp [DK]

Mọi mục trong `cy4_*_monster.ini` dùng `type` 56000–56167. Bảng `configs/MonsterAttrExTable.txt`
sau đợt `cs3c-tables` (chuyển theo ID CY) **không còn một ID nào** trong dải 56000–56200 → nếu bật cảnh
mà không vá thì **100% NPC/quái của cả ba bản đồ** rơi vào
`[MONSTER_CFG_FAIL] … 怪物 type=… 在 monster_attr_ex 中找不到配置，跳过该怪物`
(`R/GameServer/services/scene/scenecore.lua:705`).

90 dòng đó bị `cs3c` đẩy sang `R/configs/cys_gl_only/MonsterAttrExTable.txt` (không nạp), nội dung
**byte-identical** với `/home/ubuntu/configs/MonsterAttrExTable.txt` của server gốc. [DK: `22-plan-monster-rows.py`]

**Cách chữa đã chọn: nạp lại nguyên văn 90 dòng đó** (`scripts/60-install-monster-rows.py apply`).

- 80/80 type mà ba cảnh cần đều có trong khối này; 0 ID trùng với bảng đang nạp; cùng 71 cột; GBK + CRLF;
  chèn **đúng thứ tự tăng dần** (bảng vốn đã sắp xếp, min 0 max 65047). [DK]
- Vì sao **không** đổi `type` sang ID CY thật (đúng chữ của luật "chỉ dùng dòng có thật từ bảng CY"):
  đối chiếu theo **tên dòng** thì chỉ 71/90 khớp 1–1, 19 dòng còn lại tên chung hoặc nhiều ứng viên; đối chiếu
  theo tên hiển thị trong ini thì 59 rõ / 19 nhiều ứng viên / 26 không khớp — tức là phải **đoán 19–45 chỗ**.
  Trong khi 90 dòng kia là **dòng có thật**, chính là bản sao dòng CY cùng tên (khác đúng cột 44 và 61),
  và đã chạy thật trên server gốc. [DK: `51-name-match-cy.py`, `52-retype-plan.py`, `53-row-equal.py`]
- Hoàn tác: `configs/MonsterAttrExTable.txt` trong `R/backups/maps-cy4-20260917T*/`.

### A.4 Bảng cảnh phía client: **ID cảnh server**, không phải `clientres` [DK]

Đây là phát hiện quan trọng nhất, ảnh hưởng cả các cảnh của agent khác.

1. Client CY-Source tra `SceneDefineEx` bằng **`packet.sceneid`** (ID cảnh SERVER), **bỏ qua `client_res`**:
   - `Src/Client/WXClient/Network/CysModernHandlers.cpp:211` `SetSceneID((INT)packet.sceneid, …)`;
     dòng 212 chỉ *ghi log* `client_res`.
   - `Src/Client/WXClient/World/WorldManager.cpp:108` `Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID)`.
   - `Src/Engine/Interface/TDDBC_Struct.h:985` `SCENE_SERVER_ID_COLUMN = 0`.
   - Không có ca hồi quy nào bắt được khác biệt: `Src/Client/NetCore/ReplayStream.cpp:437` đặt
     `p.sceneid = p.client_res = sc.sceneId`.
2. `R/configs/SceneDefineEx.txt` (547 dòng / 24 cột, max ID 1056) **không phải bảng CY**: đó là bảng dòng
   dõi GL, chỉ dòng 0/1/2 được CS3a/CS3a2 viết lại. Dòng 1053–1056 = 4 bản đồ `cy4_*` do đợt 4 phái thêm.
3. Bảng client thật (`Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt`, DBC `00CCBBDD`,
   **679 dòng / 25 cột, ID 0…1079**) là bảng CY. Ở đó **1054/1055/1056 là cảnh khác hẳn**
   (`FengYun_lingyunku` / `FengYun_tianxiahui` / `FengYun_jianchi`), còn 4 phái nằm ở
   **678 `guigu.Scene` 192×192**, **731 `taohuadao.Scene` 320×320**, **824 `congren.Scene` 512×512**,
   **615 `tangmen.Scene` 192×192** — tên file **không có tiền tố `cy4_`**, và bộ file đúng tên đó
   **có thật** trong `SceneFolder` (11–15 file mỗi bản đồ). [DK: `40-client-scenedef.py`]
4. Hệ quả: với `sceneid` 2221–2223 client không tìm được dòng nào → `CWorldManager::EnterScene` ném
   `TDThrow("Invalid scene ID")`. Với giả thuyết ngược (client dùng `client_res`) thì nó vẽ nhầm cảnh 风云.
   **Cả hai đường đều hỏng** nếu không thêm dòng.

**Đã làm:** nối thêm 3 dòng vào DBC client — ID 2221/2222/2223, nội dung **sao chép nguyên văn** dòng CY
678/731/824 (chỉ đổi cột 0). An toàn vì 2221 > 1079 nên cột 0 vẫn tăng dần (ràng buộc `curIndex < lastIndex`
của DBC), và string pool **không đổi một byte** (kiểm bằng cách so với bản sao lưu).
`Assets/CanonicalCY/Data` là đích của symlink `Build/world-gui/stage-fps-daiviet/Data`, nên bản đang chơi
dùng chung file này. [DK: `70-client-scenedef-rows.py plan|apply|verify`]

**Kiểm TRÙNG ID (người điều phối hỏi lại 17/09)** — `11-dbc-dupe-check.json`, `scripts/71-dbc-dupe-check.py`.
`Search_First_Column_Equ` lấy **dòng đầu tiên** khớp, nên một ID trùng sẽ làm kết quả phụ thuộc thứ tự dòng.
Đo trên chính file đã ghi: [DK]

| | trước | sau |
|---|---|---|
| File | `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt` | (cùng file) |
| Số dòng | **679** | **682** |
| sha256 | `a90640b1…` | `3972d134…` (140.555 B) |
| Số ID trùng trên cả bảng | 0 | **0** |
| Dòng mang ID 2221 / 2222 / 2223 | không có | đúng **một** dòng mỗi ID, ở hàng 679 / 680 / 681 |
| Cột 0 tăng dần | có | **có** (…1078, 1079, 2221, 2222, 2223) |

Thêm hai bằng chứng cho "không chạm dòng cũ": mảng `cells` của bản 679 dòng là **tiền tố đúng** của bản
682 dòng, và string pool **giống nhau từng byte**. `stage-fps-daiviet` có cùng sha256 (symlink).
Tức là ba dòng mà người điều phối đọc thấy **chính là ba dòng này** (679 + 3 = 682), không phải bản sẵn có,
và **không cần hoàn tác**.

**Cảnh báo độ bền:** ba dòng này nằm trong dữ liệu **đã dựng** (`Assets/CanonicalCY/Data`). Trong cây còn
hai bản `SceneDefineEx.txt` khác — `Assets/Canonical/…` (bản GL, 152.527 B, binary CY không dùng) và
`Assets/CanonicalCY/_generated/gui-cy/ConfigFolder/…` (140.255 B = **đúng bản 679 dòng trước khi vá**).
Bản `_generated` không phải nguồn của SceneDefineEx (`build_canonical_cy.py:77` `GUI_CONFIG` chỉ gồm
`InterfaceEx/StrDictionary/StrFilter`), nhưng **chạy lại `build_canonical_cy.py` sẽ dựng lại `Data` từ
nguồn CY và xoá ba dòng này**. Áp lại chỉ một lệnh, và lệnh đó idempotent (tự bỏ qua ID đã có): [DK]

```powershell
python Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply
```

### A.4b Dùng lại công cụ cho cảnh khác (maps-sect: 495, 1358)

Người điều phối chuyển `70-client-scenedef-rows.py` / `71-dbc-dupe-check.py` cho `maps-sect`. Đã sửa để
dùng chung được, **mặc định không đổi** nên mọi lệnh đã ghi ở trên vẫn chạy y hệt: [DK]

```powershell
python …\70-client-scenedef-rows.py plan   --pairs "1358:236,495:615" --bak <thu-muc-bang-chung-cua-ban>
python …\70-client-scenedef-rows.py apply  --pairs "1358:236,495:615" --bak <…>
python …\70-client-scenedef-rows.py verify --pairs "1358:236,495:615" --bak <…>
```

Ba điều phải biết trước khi chạy:

1. **ID thấp hơn ID lớn nhất là bình thường, nhưng KHÔNG được nối đuôi.** Sau khi maps-cy4 thêm 2221–2223,
   ID lớn nhất là 2223; 495 và 1358 nhỏ hơn, nên bản cũ (chỉ biết nối đuôi) **từ chối ghi**. Nay `apply`
   **chèn đúng chỗ** để cột 0 vẫn tăng dần (DBC assert `curIndex < lastIndex`, và
   `Search_First_Column_Equ` tìm trên cột đã sắp xếp), và tự huỷ trước khi ghi nếu kết quả mất thứ tự
   hoặc sinh ID trùng. Đã thử thật trên **bản sao**: 495 rơi vào giữa 306 và 501, 1358 giữa 1079 và 2221,
   684 dòng, tăng dần, 0 ID trùng. Có `--dbc <file>` để tự thử trên bản sao trước khi động vào bản thật.
2. **Mỗi agent trỏ `--bak` vào thư mục bằng chứng của MÌNH.** `verify` đối chiếu string pool và các dòng cũ
   với bản sao lưu trong thư mục đó; trộn bản sao lưu của hai agent vào một chỗ sẽ ra kết luận sai.
3. `verify` nay kiểm bất biến đúng cho cả chèn giữa: **bỏ các dòng mình thêm ra thì phần còn lại phải
   giống hệt bản sao lưu** (trước đây chỉ kiểm "tiền tố", chỉ đúng khi nối đuôi).

Sau khi `maps-sect` thêm 2 dòng, trong cây sẽ có **5 dòng DBC dễ mất** nếu ai chạy lại `build_canonical_cy.py`.

- Hoàn tác: chép đè bằng `Build/Logs/2026-09-17-maps-cy4/backup-client/SceneDefineEx.txt.truoc-maps-cy4-*`.
- **Chưa kết luận được**: Game.exe CY 3.71 thật dùng `sceneid` hay `client_res`. Ở đây chỉ khẳng định
  **mã client CY-Source** dùng `sceneid`. Thêm dòng 2221–2223 là vô hại với cả hai giả thuyết.
- **Luật rút ra cho mọi cảnh khác:** với client CY-Source, cảnh nào có `sceneid` không nằm trong bảng CY,
  hoặc nằm nhưng trỏ tới bản đồ khác, thì client **không vẽ đúng**. Đo thử trên 324 cảnh đang bật:
  chỉ **12** cảnh có dòng CY cùng số **và** cùng tên file `.Scene`; 221 cảnh có dòng nhưng
  **lệch bản đồ**; 103 cảnh không có dòng nào. Đây là việc chung của CS1/CS2, không phải của riêng đợt này.
  [DK: `44-sceneid-vs-cy.py`]

### A.5 Tiền kiểm trước restart (đều PASS) [DK]

`scripts/62-preflight2.py`, `scripts/61-preflight.sh`, `cs3a_scene.py query`:

| Kiểm | 鬼谷 2221 | 桃花岛 2222 | 绝情谷 2223 |
|---|---|---|---|
| Mục NPC/quái sống | 34 | 27 | 19 |
| `script_id` chưa đăng ký trong `scripts.lua` | 0 | 0 | 0 |
| `patrol_id` / `base_ai` | −1 / 3 | −1 / 3 | −1 / 3 |
| Toạ độ ngoài biên bản đồ | 0 | 0 | 0 |
| Điểm vào đứng được trên navmesh | (86,147) ô 1300, flag 0 | (252,167) ô 7248, flag 0 | (244,252) ô 7207, flag 0 |
| Dòng `SceneAttr.txt` | có, 86/147 | có, 252/167 | có, 244/252 |

`threadindex=0` vô hại: không một dòng nào trong `R/GameServer` đọc khoá đó.
`_area.ini` của cả ba đều `area_count=0` → **không có cổng nội bộ**, chỉ vào/ra bằng NPC.

### A.6 Cổng vào — **thiếu 1/3, KHÔNG tự sửa** (việc của `transfer-npc`) [DK]

NPC đưa người chơi vào nằm ở Đại Lý, `R/Game_2/Scene/dali_new_320_monster.ini`:

| Phái | script_id | NPC | mục | trạng thái |
|---|---|---|---|---|
| 唐门 2220 | 980003 | Đường Dục | `[monster212_off]` `pos_x=;166.0` | **TẮT** (type 56003) |
| 鬼谷 **2221** | 980007 | Dương Tiệm | `[monster213_off]` `pos_x=;154.0` | **TẮT** (type 56007) |
| 桃花岛 **2222** | 980011 | Hoàng Thời Vũ | `[monster214]` (166,140) | BẬT, type 17033 |
| 绝情谷 **2223** | 980015 | Cảnh Ngôn | `[monster215]` (154,143) | BẬT, type 17340 |

Type 56003 và 56007 **nay đã có trong bảng** (nằm trong 90 dòng vừa nạp), nên bật lại hai NPC này chỉ còn là
bỏ hậu tố `_off` và bỏ dấu `;` ở `pos_x`. Không tự làm vì luật giao việc cấm agent này thêm NPC.
Đường về Đại Lý thì đủ cho cả ba (`cy4_*_travel.lua`, `destination_scene=2`, 241,141).

### A.7 Cách đo live sau khi restart

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-cy4\scripts\90-live.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-cy4\scripts\92-restore.ps1
```

CYTest03 (GUID 200004) **đã được dời sẵn** vào cảnh 2221 (86,147); bản gốc lưu ở `char/00-goc-200004.json`
(cảnh 2, 160/150). Script tự dời tiếp sang 2222 rồi 2223, mỗi lượt cho bot vào 45 s, rồi đọc
`result.json` (`core.final_scene`, `world.objects`, `world.created`) và chạy `91-logcheck.sh`.
Mốc so sánh trước restart: `10-logcheck-truoc-restart.txt` — `traceback=0 error=0`,
`MONSTER_CFG_FAIL=0`, log `Game2_20260917_155839.log`.

Lưu ý khi đọc số quái: AOI của server chỉ gửi `GCNewMonster` cho mục **trong tầm**, nên
`world.objects` của một lượt **luôn nhỏ hơn** tổng số NPC trong cảnh — xem cách chứng minh ở A.7b.

### A.7b Kết quả đo live — **ĐẠT 3/3** (17/09, sau restart 18:47:56) [DK]

Bot `Build/bot-unknownid/CysNetBot.exe`, tài khoản test03 / CYTest03 (GUID 200004), log
`90-live.log`, `91-logcheck.txt`, `live/*/bot/result.json`.

| Cảnh | `final_scene` | `in_world` | đối tượng thấy | rc | kết thúc |
|---|---|---|---|---|---|
| 鬼谷 **2221** | **2221** | true | 4 | 0 | `quit_complete`, `unknown_packets=0` |
| 桃花岛 **2222** | **2222** | true | 1 | 0 | `quit_complete`, `unknown_packets=0` |
| 绝情谷 **2223** | **2223** | true | 1 | 0 | `quit_complete`, `unknown_packets=0` |

Log server xác nhận vào đúng cảnh và `client_res` đúng dòng đã đặt:

```
[18:50:56] [AUTO_ROUTE_ENTER] guid=200004 obj=36 scene=2221 x=86.0 y=147.0 client_res=1054 first_login=true
[18:51:46] [AUTO_ROUTE_ENTER] guid=200004 obj=29 scene=2222 x=252.0 y=167.0 client_res=1055 first_login=true
[18:52:35] [AUTO_ROUTE_ENTER] guid=200004 obj=21 scene=2223 x=244.0 y=252.0 client_res=1056 first_login=true
```

Sức khoẻ: `SCENE_LOAD_FAIL` **0**, `SCENE_INIT_FAIL` **0**, `SCENE_CREATE_FAIL` **0**,
`traceback` **0**, `error` **0**. `MONSTER_CFG_FAIL` toàn cục **5**, và **0 dòng nào thuộc cảnh
2220–2223** — 5 dòng đó là type 49285–49289 của cảnh 9/13/15 (少林/天龙/峨嵋), đã biết từ trước.
Tức là **không một type 56000–56167 nào bị từ chối**: bản vá 90 dòng đã ăn.

**Chứng minh "đủ 34 NPC" ở 鬼谷** (`12-aoi-probe.json`, `scripts/93-aoi-probe.ps1`,
`scripts/64-best-spot.py`). Một lượt bot không bao giờ thấy đủ 34 vì AOI; nên thay vì đếm,
**tính trước** số NPC trong bán kính 20 quanh mỗi chỗ đứng từ `cy4_guigu_monster.ini` rồi so với số
đối tượng bot thật sự nhận:

| Chỗ đứng | Dự đoán | Bot thấy | |
|---|---:|---:|---|
| (86,147) điểm vào | 4 | **4** | KHỚP |
| (99,56) | 7 | **7** | KHỚP |
| (146,60) | 6 | **6** | KHỚP |
| (48,61) | 5 | **5** | KHỚP |

**4/4 khớp tuyệt đối, sai lệch 0.** Bốn chỗ này phủ 22 NPC khác nhau. Dự đoán khớp ở mọi chỗ với bốn
giá trị khác nhau, cộng với 0 `MONSTER_CFG_FAIL` cho cảnh 2221 ⇒ **cả 34 mục đã được tạo thật trong
cảnh**; con số nhỏ ở bảng trên chỉ là hệ quả của AOI, không phải thiếu quái. [DK]

`92-restore.ps1` đã trả CYTest03 và CYTest04 về cảnh 2 (160,150) — kiểm lại bằng `inspect`.

### A.8 Việc còn lại / chưa kết luận

1. **Chưa đo live** — chờ restart (người điều phối gộp một lần cho cả 4 agent).
2. **唐门 — ĐÃ CHỐT, không phải việc của mục này.** Người điều phối quyết dùng **ID 615** (DBC client:
   615 = Đường Gia Bảo `tangmen.Scene`); **cả 495 lẫn 2220 đều KHÔNG có dòng trong DBC client** nên đều
   làm client ném "Invalid scene ID". `maps-sect` chuyển sang 615. Cảnh 2220 giữ `active=0`.
   90 dòng quái đã nạp vẫn phủ đủ type của 唐门 nếu sau này cần.
3. **Chưa kết luận được** Game.exe CY 3.71 thật dùng `sceneid` hay `client_res` (A.4). Đã khẳng định chắc
   chắn phần **mã client CY-Source**; người điều phối đã kiểm chứng độc lập và xác nhận cùng kết luận.
4. Khối 56000–56200 hiện có 90 dòng, ba cảnh này chỉ dùng 80; 10 dòng còn lại thuộc 唐门 và các NPC cổng.
5. Bản "thuần CY" hơn (đổi `type` sang ID CY thật, bỏ hẳn dải 56xxx) — **người điều phối quyết KHÔNG làm
   đợt này**: phải đoán 19–45 chỗ không khớp tên, trái luật "không chế số". Kế hoạch giữ nguyên ở
   `02-retype-plan.json`, **chờ người dùng quyết**.
6. `scene_install.py` cột `khop`/`LECH` đang đo **sai trục**: nó so `.scn` với bảng `SceneDefineEx` của
   **server**, trong khi thứ quyết định client vẽ gì là dòng **`sceneid`** trong DBC của **client**.
   Vì vậy `ok: true` của nó là điều kiện cần, không phải điều kiện đủ. Người điều phối sẽ sửa công cụ.

---

## Mục B — `maps-sect`: 12 bản đồ môn phái sẵn nội dung (17/09/2026)

Bằng chứng: `Build/Logs/2026-09-17-maps-sect/`. Công cụ: `Tools/server/scene_install.py`,
`Tools/server/maps_sect_live.ps1` (mới), `Build/Logs/2026-09-17-maps-sect/scripts/70-client-scenedef-rows.py`.
Tài khoản đo: `test01` (GUID 200002) và `test02` (GUID 200003).

### B.1 Kết quả

| Cảnh | Tên | file `.scn` | active | dòng DBC client tại ID đó | quái đặt sẵn | cổng vào |
|---|---|---|---|---|---|---|
| 9 | 少林寺 | shaolin.scn | 1 | `shaolin.Scene` OK | 31 | có |
| 10 | 丐帮总舵 | gaibang.scn | 1 | `gaibang.scene` OK | 28 | có |
| 11 | 光明殿 | mingjiao.scn | 1 | `mingjiao.scene` OK | 38 | có |
| 12 | 武当山 | wudang.scn | 1 | `wudang.scene` OK | 29 | có |
| 13 | 天龙寺 | tianlong.scn | 1 | `tianlong.scene` OK | 32 | có |
| 14 | 淩波洞 | xiaoyao.scn | 1 | `xiaoyao.scene` OK | 25 | có |
| 15 | 峨嵋山 | emei.scn | 1 | `emei.scene` OK | 36 | có |
| 16 | 星宿海 | xingxiu.scn | 1 | `xingxiu.scene` OK | 29 | có |
| 17 | 天山 | tianshan.scn | 1 | `tianshan.scene` OK | 40 | có |
| **495** | 唐家堡 | tangmen.scn | 1 | `tangmen.Scene` OK (**dòng MỚI**) | 23 | **KHÔNG có** |
| **987** | 恶人谷 | erengu.scn | 1 | `erengu.Scene` OK | 25 | **HỎNG** (script còn trỏ 1063) |
| **1358** | 慕容山庄 | gusu.scn | 1 | `gusu.scene` OK (**dòng MỚI**) | 8 | có |

`scene_install.py verify --scenes 9,10,11,12,13,14,15,16,17,495,987,1358` → **`ok: true`**
(`24-verify-12canh.json`). Toàn bộ cảnh `type=0` đang bật nay đều có dòng DBC đúng bản đồ:
**0 cảnh `THIEU`/`SAI`** (`28-survey-toanbo-cuoi.json`, đo 18:35 khi có 60 cảnh `type=0` bật; số cảnh
còn tăng vì agent khác đang bật thêm — điều kiện phải giữ là "0 cảnh không OK").

### B.1b Đo live sau restart 18:47:56 — **12/12 ĐẠT** [DK]

`Build/Logs/2026-09-17-maps-sect/live-1/` (`results.tsv`, `30-quai-theo-generation.json`,
`s<ID>-serverlog.txt`). Mọi phiên đều `quest.transferred = true`, tức bot **đi qua cổng thật trong game**
(NPC 驿站老板 崔逢九 ở Đại Lý), không đặt toạ độ.

| cảnh | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 495 | 987 | 1358 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `final_scene` | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 495 | 987 | 1358 |
| mục menu | 1000 | 1000 | 1000 | 1000 | 1000 | 1000 | 1000 | 1000 | 1000 | **1022** | 1000 | 1000 |
| `GCNewMonster` cả phiên | 19 | 25 | 19 | 18 | 20 | 22 | 19 | 19 | 19 | 20 | 20 | 17 |
| — **trong cảnh đích** (`generation = 2`) | **3** | **9** | **3** | **2** | **4** | **6** | **3** | **3** | **3** | **4** | **2** | **1** |
| `traceback` / `error` | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |

Số "trong cảnh đích" nhỏ vì AOI chỉ gửi mục **trong tầm** và bot đứng yên (`--walk 0`) ở điểm đến; nó
chứng minh "cảnh sống và có quái/NPC", **không** phải "đủ quái cả bản đồ". Bằng chứng đủ quái là log
khởi động: 65 cảnh tạo xong, `SCENE_LOAD_FAIL`/`SCENE_INIT_FAIL`/`SCENE_CREATE_FAIL`/`traceback` đều **0**,
`MONSTER_CFG_FAIL` **5** và đúng 5 ID đã lường trước (`31-khoi-dong.json`).

### B.2 Trục đúng: client tra bản đồ bằng `sceneid`, không phải `clientres` [DK]

Khảo sát giao việc nói `clientres` phải tra trong `R/configs/SceneDefineEx.txt`. Đo lại thì **sai trục**:

- `Src/Client/WXClient/Network/CysModernHandlers.cpp:211` — `SetSceneID((INT)packet.sceneid, …)`;
  `packet.client_res` chỉ vào chuỗi log ở dòng 213, không dùng để tra bảng.
- `Src/Client/WXClient/World/WorldManager.cpp:96-110` —
  `Search_First_Column_Equ(_DBC_SCENE_DEFINE::SCENE_SERVER_ID_COLUMN, nSceneID)`, nhánh còn lại so
  `pTempSceneDef->nServerID == nSceneID`. Không tìm thấy dòng ⇒ `TDThrow("(CWorldManager::EnterScene)
  Invalid scene ID(%d,%d)")`.
- `Src/Engine/Interface/TDDBC_Struct.h:985` — `SCENE_SERVER_ID_COLUMN = 0`, `INT nServerID; // [0] scene id`.
- Gói `GCEnterScene` mang CẢ HAI trường: `services/game/packet_domains/movement.lua:147-148`
  (`sceneid` rồi `client_res`, đều `u16`).

`R/configs/SceneDefineEx.txt` (548 dòng, 24 cột) là **bản gương phía server, dòng dõi GL**, không phải
bảng client dùng để vẽ: 163/426 ID chung giữa nó và DBC client trỏ **khác** file `.Scene`; dòng 1052 của
nó vẫn là `Summoner Rift sr_rift.Scene` (bản vá riêng của dự án 085). Server chỉ đọc nó ở
`lualib/cfghelper.lua:4452-4465` `read_scene_define_ex` để lấy **tên cảnh copy**, mà hai dòng đầu file đều
là dòng KIỂU (`INT STRING …`) nên `conf["Index"]` luôn `nil` ⇒ bảng phía server **rỗng lúc chạy**
(`copyscenecore.lua:32-35` rơi về `"未知场景"`). [DK]

⇒ Cột `khop/LECH` cũ của `survey` đo theo bảng đó nên nói ngược: 495 bị báo `LECH` trong khi client vẽ
đúng, còn 1063/1358 được báo `OK` trong khi client vẽ sai/không vẽ được. Người điều phối đã sửa công cụ
(nay có cột `client ve duoc?` = `OK` / `THIEU` / `SAI:<bản đồ>`).

### B.3 恶人谷: đổi ID cảnh server 1063 → **987** [DK]

DBC client dòng 1063 là **Lăng Vân Quật `FengYun_lingyunku.scene`** — vào cảnh 1063 thì client vẽ nhầm
bản đồ. Các ID mà DBC có đúng `erengu.Scene` là 987 / 990 / 1000 / 1001 / 1005; **cả năm đều chưa có
section** trong `SceneInfo.ini`. Chọn **987** vì đó là dòng mang tên "Ác Nhân Cốc" và có toạ độ biểu
tượng bản đồ lớn thật (cột 11–14 = 514,532,511,560), bốn dòng kia để 0.

- Thêm mục mới: `scene_install.py add --id 987 --name 恶人谷 --file erengu.scn --clientres 703 --type 0
  --threadindex 50` (`09-enable-987.json`). `clientres=703` = dòng 恶人谷 của **bảng gương server**
  (client không dùng ô này); để `verify` cũ vẫn khớp.
- Cảnh 1063 đặt lại `active=0` (`10-disable-cu.json`) để không ai lạc vào bản đồ vẽ sai.
- `ScriptGlobal.FUBEN_TADI = 987` **không xung đột**: đó là *loại phó bản* (`g_CopySceneType`), khác hẳn
  không gian ID cảnh. [DK: `ScriptGlobal.lua:830-858`, `edali_newquest_021.lua:33`]

### B.4 唐家堡 495 và 慕容山庄 1358: thêm dòng DBC, GIỮ ID cảnh server [DK]

Không đổi được ID cảnh vì **mọi ID có dòng DBC đúng bản đồ đều đã bị chiếm**:

| bản đồ | ID có dòng DBC đúng | section phía server |
|---|---|---|
| `tangmen.Scene` | 615 | 雁南正南 `PCityyannanzhengnan.scn` type=4 đang bật |
| | 628 | 黄龙府西北 `PCityhuanglongfuxibei…` type=4 đang bật |
| `gusu.scene` | 284 | 辽西西北 `PCityliaoxixibei.scn` type=4 đang bật |
| | 561 | 罗浮城 `luofucheng.scn` type=0 |
| | 593 | 擂台 `leitai_1.scn` type=1 |

⇒ Cách đúng là **nối thêm dòng vào DBC client**, giữ nguyên ID cảnh server (script, `TransportDefine`,
bản ghi nhân vật trong Mongo đều đang dùng ID cũ):

- DBC **495** ← chép nguyên văn 24 ô sau của dòng **615** (`tangmen.Scene`, 192×192).
- DBC **1358** ← chép nguyên văn 24 ô sau của dòng **284** (`gusu.scene`, 192×192).
  **Không** dùng dòng 236: 236 là 燕子坞 `new_yanziwu.scene`, không phải 慕容山庄. [DK]

### B.5 Cộng thêm: 8 cảnh phân tuyến đang bật mà DBC thiếu dòng (lỗi có từ 14/09) [DK]

Người điều phối phát hiện khi quét bằng cột kiểm mới. Tám cảnh do đợt `cs3a2` tự đặt ID, **đang bật**,
người chơi bị bộ phân tuyến đẩy sang là client ném `Invalid scene ID`:

| cảnh | tên | file | chép từ dòng DBC |
|---|---|---|---|
| 1311 / 1315 / 1316 | 洛阳-2/3/4 | `luoyang_new.scn` | 0 `luoyang_new.Scene` |
| 1312 | 苏州-2 | `suzhou_new.scn` | 1 `suzhou_new.scene` |
| 1320 / 1321 | 大理4/5 | `dali_new_320.scn` | 2 `dali_new_320.Scene` |
| 1500 / 2218 | 地府-2/3 | `siwang.scn` | 77 `siwang.scene` |

Cơ chế phân tuyến CÓ chạy thật (`team-live` 17/09 đo được cổng Đại Lý→Vô Lượng chọn ngẫu nhiên
{6, 73, 74}), nên đây là lỗi người chơi gặp được, không phải lý thuyết.

Tất cả **10 dòng** (2 của B.4 + 8 của B.5) thêm trong **một lượt `apply`**:

```powershell
python -X utf8 Build\Logs\2026-09-17-maps-sect\scripts\70-client-scenedef-rows.py plan|apply|verify --out <F>
```

Kết quả `22-dbc-verify.json`: **682 → 692 dòng**, cột 0 **vẫn tăng dần**, **0 ID trùng**, string pool
**giống bản sao lưu từng byte**, và bất biến mạnh: **bỏ đúng 10 hàng vừa chèn thì mảng `cells` còn lại
giống hệt bản sao lưu, từng ô**. `71-dbc-dupe-check.py` của `maps-cy4`: `SO_ID_TRUNG = 0`,
`cot0_tang_dan = true`, `TONG_SO_DONG = 692`.

Ba điểm phải biết:

1. **Chèn giữa, không nối đuôi.** 495/1358/1311… đều nhỏ hơn ID lớn nhất 2223, nên phải chèn đúng chỗ để
   cột 0 tăng dần (`Search_First_Column_Equ` lấy dòng ĐẦU khớp; DBC assert `curIndex < lastIndex`).
2. `cells_la_tien_to_cua_ban_moi` trong `71-dbc-dupe-check.py` nay trả **false** — **đúng như vậy**, vì
   bất biến "tiền tố" chỉ hợp với nối đuôi. Bất biến đúng cho chèn giữa là bất biến "bỏ hàng mới ra"
   ở trên; đừng đọc `false` đó là hỏng.
3. **Bản đang chơi dùng CHUNG file**: `Build/world-gui/stage-fps-daiviet/Data` là **junction** tới
   `Assets/CanonicalCY/Data` (`Tools/game/stage_game.py:1271` `mklink /J`); đo được cùng **inode**
   `1407374884195207` và cùng sha256 `08a29576bfc1…` sau khi ghi. Stage mới cũng sẽ mang theo. [DK]

### B.6 Cách đo live (CHƯA chạy — cần restart trước)

`scenemanager_core:createScenes` (`lualib/scenemanager_core.lua:176-203`) chỉ tạo cảnh `active=1 and
type=0` **lúc khởi động**; `rebuild_scene` chỉ dùng `scene_info_cache` nạp lúc khởi động. Vì vậy bật
`active` chưa đủ, **phải restart**.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\maps_sect_live.ps1 `
    -OutRoot Build\Logs\2026-09-17-maps-sect\live-1
```

Mỗi cảnh một phiên bot: `char_menpai.py restore` → `set --menpai M` → bot → `logcheck.sh`. Hai đường vào:

- **Qua cổng thật** (9–17, 1358): bot `--talk 253,121 --talk-option 1000` — NPC 驿站老板 崔逢九 ở Đại Lý,
  mục "Trở về Môn phái" của `chuan_song_system.lua:80`, tra `g_mpInfo` theo `attrib.menpai` rồi gọi
  `TransferFunc`. **Đã kiểm thật trước restart**: cùng lệnh với `--talk-option 1001` cho
  `transfer scene 2->0`, `traceback=0 error=0` (`live-truoc/talk-opt1001`).
- **Đặt thẳng vị trí** (495, 987 — chưa có cổng): `char_menpai.py set --scene S --pos-x X --pos-z Z`
  (ba tham số mới, `maps-sect` thêm vào `Tools/server/menpai_audit/char_menpai.py`). **Đã kiểm thật**:
  đặt cảnh 6 (40,150) → bot vào đúng `scene=6`, `GCNewMonster=9`, `traceback=0 error=0`
  (`live-truoc/place-scene6b`).

Bằng chứng mỗi cảnh: `result.json` (`core.final_scene`, `quest.transferred`), `report.tsv`
(`GCNewMonster`), `s<ID>-serverlog.txt` (`traceback=`/`error=`).

### B.7 Cổng vào — thiếu 2, KHÔNG tự sửa (việc của `transfer-npc`) [DK]

Nguồn cổng: `configs/TransportDefine.txt` (NPC 驿站) và `Game_2/Script/scripts/chuan_song_system.lua`
bảng `g_mpInfo` (mục 1000 "Trở về Môn phái" + mục 1012 "Đưa ta đến Môn phái khác" → chỉ số 1..12).
Server **không có** `ScenePosDefineEx.txt`.

| cảnh | tình trạng cổng |
|---|---|
| 9–17 | **ĐỦ**: mỗi cảnh 22 dòng `TransportDefine` (nguồn 洛阳/苏州/大理 + 9 phái), NPC nguồn đều có mặt trong `*_monster.ini`; thêm 9 NPC dẫn đường riêng ở Đại Lý (慧易/简宁/石宝/张获/破贪/澹台子羽/路三娘/海风子/程青霜) đều **CÓ** trong `dali_new_320_monster.ini` |
| 1358 | **ĐỦ**: 42 dòng `TransportDefine` + `g_mpInfo` mục 3. (NPC riêng 慕容传 ở Đại Lý **thiếu** — chỉ là lối tắt) |
| **987 恶人谷** | **ĐÃ SỬA** (`transfer-npc`, 17/09): `chuan_song_system.lua:13` `g_mpInfo` nay trỏ **987**; đo thật `final_scene=987`. **Còn 7 chỗ vẫn ghi 1063** (`26-tham-chieu-1063.txt`): `obj/dali/odali_shanfeng.lua:46`, `obj/petisland/opetisland_guijia.lua:17`, `obj/commonitem/340001.lua:25`, `YYC/KuaiJCS.lua:31`, `event/huodong/eTouximenpai_Generate.lua:200,629,733` → sẽ đưa người chơi về cảnh 1063 đang tắt ⇒ rơi về Đại Lý. `TransportDefine` **0 dòng** cho cả 1063 lẫn 987. |
| **495 唐家堡** | **ĐÃ THÊM** (`transfer-npc`, 17/09): mục riêng **index 1022** "Thành thị - Đường Gia Bảo" trên chính NPC 驿站 (`chuan_song_system.lua:78`), chiều về dùng NPC 唐予诚 "唐门传送人" (126,68) có sẵn trong `tangmen_monster.ini`; đo thật `final_scene=495`. **Chưa kết luận được** 495 (bản đồ 唐家堡 cũ) và **2220** `cy4_tangmen.scn` (bản đồ 唐门 bộ 4 phái CY, `active=0`) nên tồn tại song song hay không. |

### B.8 Việc còn lại / chưa kết luận

1. ~~Chưa đo live~~ — **XONG 18:57, 12/12 đạt** (mục B.1b).
2. **Còn 7 chỗ script trỏ cảnh 1063 đã tắt** (mục B.7) — việc của `transfer-npc`. Cổng chính đã xong.
3. **5 ID quái không có trong `MonsterAttrExTable`** đã bị bỏ qua kèm `MONSTER_CFG_FAIL` khi nạp
   (đo thật, `31-khoi-dong.json`): 49285/49286 (cảnh 9), 49287/49288 (cảnh 13), 49289 (cảnh 15).
   Chín cảnh còn lại 0 mục thiếu. [DK: `02-tien-kiem.json`, `31-khoi-dong.json`]
4. **Bảng gương `R/configs/SceneDefineEx.txt` đang lệch thật với DBC client** (163/426 ID chung khác file).
   Nó gần như không được server đọc (B.2) nhưng vẫn là nguồn gây hiểu nhầm; việc dọn thuộc CS1/CS2.
5. **12 dòng DBC dễ mất** nếu ai chạy lại `Tools/pipeline/build_canonical_cy.py`: 3 của `maps-cy4`
   (2221–2223) + 10 của `maps-sect`. Phải chạy lại `apply` của **cả hai** script sau mỗi lần dựng lại
   canonical. Bản chưa vá còn nằm ở `Assets/CanonicalCY/_generated/gui-cy/ConfigFolder/SceneDefineEx.txt`
   (679 dòng) — **không** phải nguồn của `Data/ConfigFolder` (`build_canonical_cy.py:77` chỉ lấy
   `InterfaceEx`/`StrDictionary`/`StrFilter` từ đó), nhưng dễ bị chép nhầm.
6. **304 cảnh `type=1`/`type=4` đang bật cũng báo `THIEU`/`SAI`** — chuyện có từ trước, ngoài phạm vi đợt
   này, chỉ ghi lại.
7. **Chưa kết luận được** Game.exe CY 3.71 thật dùng `sceneid` hay `client_res`; ở đây chỉ khẳng định
   phần **mã client CY-Source**.
