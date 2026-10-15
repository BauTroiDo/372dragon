# Mở mọi bản đồ `type=0` trên server riêng — agent `maps-all` (17/09/2026)

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng/số). **[SL]** suy luận.
`R` = `/home/ubuntu/cys-test-20260913` (server riêng skynet trong WSL `TLBB`).
**Trạng thái: XONG.** Đã ghi DBC, đã bật 135 cảnh, đã restart (19:31:52) và **đã đo live: 15/15 ĐẠT**.
Bằng chứng: `Build/Logs/2026-09-17-maps-all/`. Công cụ: `Tools/server/scene_install.py`,
`Tools/server/maps_all_live.ps1` (mới), `Build/Logs/2026-09-17-maps-cy4/scripts/70-client-scenedef-rows.py`
(đã mở rộng — xem mục 4), `Build/Logs/2026-09-17-maps-all/scripts/*`.
Tài khoản đo: `test11` (GUID 200012); `test12`/`test13` (200013/200014) chưa dùng.

---

## 1. Kết quả một dòng

| | trước | sau |
|---|---|---|
| Cảnh `type=0` **đang bật** | **60** | **195** (+135) |
| Quái đặt sẵn trong các cảnh `type=0` đang bật | **8.394** | **26.119** (+17.725) |
| Cảnh `type=0` đang bật mà DBC client `THIEU`/`SAI` | 0 | **0** ← bất biến số 1, giữ đúng |
| Dòng DBC client `SceneDefineEx.txt` | 692 | **746** (+54 dòng THÊM, 74 dòng SỬA) |
| Cảnh `type=0` còn tắt | 187 | **52** (240 quái) |

`scene_install.py verify --scenes <135 ID>` → **`ok: true`, `loi: []`** (`81-verify-135.json`). [DK]
`scene_install.py survey --all` lần cuối: `type=0` bật 195, **0 cảnh `THIEU`/`SAI`** (`80-survey-cuoi.json`). [DK]

**ĐÃ ĐO LIVE sau restart 19:31:52 — 15/15 cảnh mẫu ĐẠT** (mục 7), và server nạp đủ **195 cảnh**
(`scene startup done, total = 195`) với **`SCENE_LOAD_FAIL`/`SCENE_INIT_FAIL`/`SCENE_CREATE_FAIL`/
`traceback` đều = 0**, `MONSTER_CFG_FAIL` **đúng 5 mục cũ, 0 mục mới**. Khởi động tới khi cổng
15733/15734 LISTEN: **40 giây**. RAM thêm **+1,2…1,6 GB** (mục 6.4). [DK]

---

## 2. 187 cảnh `type=0` đang tắt chia thế nào [DK]

Khảo sát đầu (`01-survey-all.json`, `scene_install.py survey --all`) + đối chiếu DBC client
(`10-recon-all.py` → `10-plan.json`):

| nhóm | cảnh | quái | xử lý |
|---|---|---|---|
| DBC đã có dòng **đúng** bản đồ | 7 | 5 | chỉ cần `enable` |
| DBC **thiếu hẳn dòng** ở ID đó | 55 | 8.450 | **THÊM** dòng mới |
| DBC có dòng nhưng **trỏ sai bản đồ** | 76 | 9.319 | **SỬA** dòng đó |
| **Không có dòng DBC nào mang bản đồ này** | 49 | 191 | **không mở được** — xem mục 8 |
| | **187** | **17.965** | |

Số của người điều phối (88 THIẾU / 92 SAI / 125 cảnh có quái / 17.959 quái) lệch nhẹ vì đo ở thời
điểm khác và vì tôi tách riêng nhóm "không có dòng CY nào" khỏi hai nhóm kia. [SL]

Trừ tiếp 3 cảnh (mục 8.2) → **135 cảnh, 17.725 quái** được bật trong đợt này.

---

## 3. Vì sao SỬA một dòng DBC có sẵn là đúng, và bằng chứng đã đúng

DBC `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt` đánh khoá theo **ID CẢNH SERVER ở cột 0**
(`Src/Engine/Interface/TDDBC_Struct.h:985` `SCENE_SERVER_ID_COLUMN = 0`), client tra bằng
`packet.sceneid` (`Src/Client/WXClient/Network/CysModernHandlers.cpp:211` →
`Src/Client/WXClient/World/WorldManager.cpp:96-110` `Search_First_Column_Equ`). Nên **dòng ở ID N chỉ
phục vụ đúng cảnh N của server ta**; một dòng trỏ tới bản đồ khác là rác của nhánh khác. [DK]

Bằng chứng nó là rác chứ không phải dữ liệu hợp lệ: tên hiển thị của dòng cũ và tên cảnh trên server
**không liên quan gì nhau**, còn dòng nguồn thì khớp từng chữ (bảng DBC đã dịch sang tiếng Việt nên
so theo âm Hán-Việt). [DK: `11-dbc-dump.txt`]

| cảnh server | server `.scn` | DBC dòng đó **trước** | dòng nguồn được chép | tên dòng nguồn |
|---|---|---|---|---|
| 179 雪狼湖 | `xuelanghu.scn` | `emei_1.scene` (Nga My sơn) | 222 | Tuyết Lang Hồ |
| 173 黄龙洞 | `huanglongdong.scn` | `shaolin_1.scene` (Thiếu Lâm Tự) | 216 | Hoàng Long Động |
| 177 桃花源 | `taohuayuan.scn` | `tianlong_1.scene` (Thiên Long tự) | 220 | Đào Hoa Nguyên |
| 156 大军草料场 | `caoliao.scn` | `leitai_1.scene` (Lôi Đài) | 199 | Thảo Liệu Trường |
| 538 秦皇地宫四层 | `qinhuanggong_4.scn` | `辽地 3.Scene` | 292 | Tầng bốn Địa cung Tần Hoàng |

**Cách chọn dòng nguồn:** tra theo **tên tệp `.Scene`** (bỏ tiền tố `cy4_`, không phân biệt hoa thường).
124/128 bản đồ chỉ có **đúng một** dòng ứng viên, nên gần như không có chỗ để chọn sai. Khi có nhiều
ứng viên thì ưu tiên dòng **không nằm trong danh sách sắp bị ghi** rồi mới đến ID nhỏ nhất
(`30-make-pairs.py`). [DK]

### 3.1 Chứng minh chỉ đụng đúng những dòng đã nêu [DK]

`70-client-scenedef-rows.py verify` ở chế độ tổng quát dùng **bất biến mạnh nhất phát biểu được**:

> **bản sao lưu + đúng kế hoạch này = file hiện tại, từng ô.**

Nó bao trùm cả hai bất biến cũ (dòng mới giống dòng nguồn; mọi dòng khác giữ nguyên) và bắt được cả
trường hợp một dòng bị sửa ngoài ý muốn. Kết quả trên file thật (`52-verify.json`): **`ok: true`, `loi: []`**.

Kiểm độc lập bằng `71-dbc-dupe-check.py` của `maps-cy4` (`53-dupe-check.json`):

| | trước | sau |
|---|---|---|
| sha256 | `08a29576bfc105c8…` | `233e6315e3e10ce1…` (146.955 B) |
| số dòng | 692 | **746** |
| **số ID trùng** | 0 | **0** |
| cột 0 tăng dần | có | **có** |
| `stage-fps-daiviet` cùng sha256 | — | **true** (junction, `Tools/game/stage_game.py:1271`) |

"0 ID trùng" là bắt buộc, không phải làm đẹp: `DBCFile::CreateIndex`
(`Src/Shared/Common/DataBase/TLBB_DBC.cpp:490-514`) **ném `"[…]Multi index at line N(SAME:value=…)"`**
khi gặp ID lặp. [DK]

Hoàn tác: chép đè bằng `Build/Logs/2026-09-17-maps-all/backup-client/SceneDefineEx.txt.truoc-maps-cy4-20260917T115825Z`.

### 3.2 Hai điều về 13 dòng của `maps-cy4` và `maps-sect` [DK]

1. **Cả 13 dòng còn nguyên và đúng bản đồ** sau lượt ghi của tôi — đo trực tiếp trên file:
   2221 `guigu.Scene`, 2222 `taohuadao.Scene`, 2223 `congren.Scene`, 495 `tangmen.Scene`,
   1358 `gusu.scene`, 1311/1315/1316 `luoyang_new.Scene`, 1312 `suzhou_new.scene`,
   1320/1321 `dali_new_320.Scene`, 1500/2218 `siwang.scene`.
2. **`verify` của `maps-sect` nay báo `ok: false` — đúng như thiết kế, KHÔNG phải hỏng.** Bất biến của
   họ là "bỏ 10 dòng của mình ra thì phần còn lại giống bản sao lưu 682 dòng"; file nay 746 dòng và có
   74 dòng bị sửa, nên nó nói `"so dong lech: sao luu 682 + 10 != 746"`. Bằng chứng đúng đắn hiện nay là
   `verify` của `maps-all` (bản sao lưu 692 dòng) cộng `71-dbc-dupe-check.py` cộng
   `90-audit-cuoi.py`.
3. **10 dòng của `maps-sect` vẫn giữ toạ độ world map của dòng nguồn** (1311/1315/1316 đều `810,397`
   như dòng 0 洛阳; 1320/1321 đều `649,658` như dòng 2 大理) ⇒ bản đồ thế giới sẽ vẽ **ba biểu tượng
   Lạc Dương chồng khít** và **ba Đại Lý**. Không sửa vì không thuộc phạm vi của tôi; chữa chỉ là chạy
   lại lượt của họ kèm `--zero-wmap`. [DK]

---

## 4. Mở rộng `70-client-scenedef-rows.py` (giữ nguyên hành vi cũ)

Bản cũ chỉ biết **THÊM**. Đã mở rộng ngay trong file đó theo yêu cầu, và **mọi lệnh đã ghi trong
`maps-menpai_vi.md` mục A.4/A.4b/B.5 vẫn chạy y hệt** vì các cờ mới mặc định tắt. [DK]

```powershell
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py plan|apply|verify `
    --pairs-file Build\Logs\2026-09-17-maps-all\30-pairs.json `
    --zero-wmap --bak Build\Logs\2026-09-17-maps-all\backup-client
```

| cờ mới | làm gì |
|---|---|
| `--pairs-fix "179:222,…"` | SỬA dòng đã có: chép 24 ô sau của dòng nguồn sang dòng ở ID đó |
| `--pairs-file <json>` | `{"them": {...}, "sua": {...}, "dich": {...}}` — dùng khi nhiều cặp (ở đây 128) |
| `--zero-wmap` | đặt cột 11..14 = 0 trên dòng vừa ghi |

### 4.1 Vì sao có `--zero-wmap` [DK]

`Worldmap::InitWorldMap` (`Src/Client/CEGUISystem/UILuaControl.cpp:2144-2156`) **duyệt MỌI dòng** và
đặt biểu tượng thành phố theo `nServerID` nếu cột 11 **và** 12 đều khác 0. 54/128 dòng nguồn có toạ độ
world map; chép nguyên văn sang ID khác sẽ vẽ **hai biểu tượng chồng khít lên nhau**.
Đặt 0 chính là quy ước của CY cho dòng trùng bản đồ (`erengu`: chỉ dòng 987 có toạ độ, 990/1000/1001/1005
đều 0) — **không phải chế số**. Hệ quả: 135 cảnh mới **không có biểu tượng trên bản đồ thế giới**;
biểu tượng của bản đồ đó vẫn nằm ở dòng CY gốc như trước.

### 4.2 Bẫy đã sập và đã vá: dòng NGUỒN có khi chính là dòng ĐÍCH [DK]

Ví dụ thật: dòng 129 vừa là **nguồn** của cảnh 86 雁南山洞 (`shandong_1`), vừa là **đích** bị đổi thành
`cangjing_2`. Nếu không chụp nội dung nguồn trước khi sửa thì kết quả phụ thuộc thứ tự — một lớp lỗi
rất khó lần. Đã vá hai tầng:

1. `ap_dung()` **chụp toàn bộ dòng nguồn trước khi sửa bất kỳ dòng nào**;
2. kế hoạch mang thêm ô `dich` (tên `.Scene` mà dòng đó **phải** có sau khi ghi) → `apply` **bỏ qua**
   dòng đã đúng ⇒ **idempotent**. Đã đo trên bản sao: chạy `apply` lần hai cho **md5 y hệt**
   (`bf5b6425f71c824cb4914f1028c6816e`) và báo `bo qua 74`. Không có chốt này thì lần chạy thứ hai
   sẽ đặt dòng 86 thành `cangjing_2`.

`verify` cũng phải so dòng đích với **nội dung dòng nguồn trong bản sao lưu**, không phải dòng nguồn
ở file hiện tại (vì nó đã bị đổi).

### 4.3 Thử trên bản sao trước [DK]

Toàn bộ chuỗi `plan → apply → verify → apply lần 2` chạy trên `thu-nghiem/copy.txt` (qua `--dbc`)
trước khi động vào file thật. Kết quả: 692 → 746 dòng, `ok: true`, idempotent.

**Hồi quy hành vi cũ:** `verify` không cờ mới trên bản sao báo lỗi
`"khong ban sao luu nao la tien to cua file hien tai"` — đây là **tình trạng có từ trước**, không do
bản vá: bản sao lưu của `maps-cy4` là file 679 dòng, còn file hiện tại đã có thêm 10 dòng của
`maps-sect` (692 − 3 = 689 ≠ 679). [SL, dựa trên số dòng đã ghi trong `maps-menpai_vi.md` A.4/B.5]

---

## 5. Tiền kiểm phía server: điều tốt nhất trong đợt này [DK]

`20-monster-check.py` + `21-server-preflight.py` (chạy trong WSL) trên 138 cảnh ứng viên:

| kiểm | kết quả |
|---|---|
| Mục NPC/quái **sống** trong `<map>_monster.ini` | **17.915** cho 135 cảnh được bật |
| `type` quái **không có** trong `configs/MonsterAttrExTable.txt` | **0** |
| ⇒ số quái sẽ bị bỏ kèm `MONSTER_CFG_FAIL` | **0** |
| Dải `type` bị đợt `cs3c` đẩy sang `configs/cys_gl_only/` mà đợt này cần | **0** (thư mục đó không có `MonsterAttrExTable.txt`) |
| Thiếu `.scn` / `.path` trên server | **1 cảnh** (718, đã loại — mục 8.2) |
| Thiếu dòng `configs/SceneAttr.txt` | **0** |
| Toạ độ NPC/quái ngoài biên W×H | **0** |

Đây là khác biệt lớn so với `maps-cy4` (80 ID quái thiếu, phải nạp lại 90 dòng): nội dung của 135
bản đồ này là nội dung **gốc của server**, không phải nhánh CY mới, nên bảng quái đã phủ đủ.

**Vẫn còn một khiếm khuyết về chất lượng, không phải lỗi chặn:** **71/135 cảnh có `script_id` chưa
đăng ký** trong `R/Game_2/Script/scripts/scripts.lua` (176 ID khác nhau, vd 39001, 41500–41506, 502000).
`scriptenginer:try_load` (`R/GameServer/lualib/scriptenginer.lua:117-134`) tra `dat[id]`, không có thì
**trả nil và im lặng** — NPC vẫn đứng đó nhưng bấm vào không ra gì. Không traceback, không chặn vào cảnh. [DK]

### 5.1 Bẫy: WSL phân biệt hoa thường, tên tệp cảnh KHÔNG được hạ chữ [DK]

Tệp thật trên server là `FengYun_lingyunku.path`, `DHXYcuiyunshan.path`, `Songliao_Xiuxi.path`.
Lượt đo đầu của tôi hạ tên bản đồ về chữ thường để so với DBC, rồi lỡ dùng luôn tên đó để mở tệp
server ⇒ **8 bản đồ đọc ra 0 quái / 0 navmesh mà không báo lỗi gì**. Đã tách hai trường: `map`
(chữ thường, chỉ để so khớp DBC) và `map_goc` (giữ nguyên hoa thường, để mở tệp server).

### 5.2 `.path` của server là danh sách ĐA GIÁC, không phải lưới ô [DK]

`R/GameServer/lualib/pathparser.lua`: u16 version (`0x1000` v1 có u16 số đa giác, `0x2000` v2 có u32
offset) rồi từng đa giác 5 điểm × 2 float. Lưới ô `BLK1` của `blockmap.lua` là thứ **riêng** do dự án
sinh ra và **hiện không có tệp `.blk` nào** ⇒ tuỳ chọn. Vì vậy điểm vào để đo live lấy từ **vị trí một
NPC/quái đặt sẵn**, không tự dò navmesh.

---

## 6. Chi phí khởi động và RAM — ĐÃ ĐO, có số [DK]

Không restart được (người dùng giữ độc quyền), nên đo **tách riêng** và đo **lịch sử log**.

### 6.1 Mốc trước (server đang chạy, restart 18:47:20, 60 cảnh `type=0`)

`scripts/45-startup-time.sh`, `scripts/47-scene-count.sh`, `scripts/48-scene-window.sh`:

| | 15:27:40 | 15:58:39 | **18:47:20 (mốc)** |
|---|---|---|---|
| Cảnh được tạo (`LAUNCH snlua scene …`) | 17 | 17 | **65** |
| Cửa sổ tạo cảnh (`…` → `[SceneManager] scene startup done`) | 31 s | 31 s | **20 s** |
| Giây mỗi cảnh | 1,82 | 1,82 | **0,31** |
| Tổng khởi động (dòng đầu → người vào được) | 77 s | 216 s | **126 s** |
| `MONSTER_CFG_FAIL` | 0 | 0 | 5 (đúng 5 ID đã biết 49285–49289) |
| `traceback` | 0 | 0 | 0 |

Hai điều rút ra:

1. **Tổng thời gian khởi động dao động rất mạnh mà không liên quan số cảnh.** Đo 22 lần restart
   trong hai ngày ở mức 17 cảnh: từ **63 s đến 616 s** (`47-scene-count.txt`). Đừng suy diễn xu hướng
   từ hai điểm.
2. **Riêng cửa sổ tạo cảnh thì ổn định và đã rẻ hẳn đi**: 1,82 s/cảnh trước, **0,31 s/cảnh** ở lần
   18:47. [SL] Nguyên nhân gần như chắc chắn là bản vá `iostream.lua readfloat` (O(n²) → O(n)) mà
   người dùng vừa làm.

`createScenes` còn có `if created % 3 == 0 then skynet.sleep(1) end` — 195 cảnh ⇒ 65 lần ngủ ≈ 0,65 s,
không đáng kể. [DK]

### 6.2 Đo tách riêng chi phí navmesh

`scripts/40-nav-cost.lua` nạp `.path` của đúng 135 bản đồ mới bằng **chính `pathparser` + `lnavmesh`
của server**, giữ lại `PathFinder` như server làm:

> **135 bản đồ: 8,91 giây, RSS tăng 65,6 MB.** (`40-nav-cost.tsv`)

Kể cả 6 bản `bianjing` 4,8 MB — mỗi bản 0,08–0,11 s đọc + 0,39–0,51 s dựng. Navmesh **không** phải nút thắt.

### 6.3 Đo RAM mỗi cảnh trên server đang chạy (chỉ đọc)

`scripts/49-mem-probe.sh` gọi lệnh `mem` của `debug_console 16002`; `scripts/52-mem-model.py` ghép với
số quái từ khảo sát:

- 65 dịch vụ `scene`, **931 MB bộ nhớ Lua**, trung bình **14,3 MB/cảnh**, nhỏ nhất 7,4 MB, lớn nhất 29,9 MB (大理).
- Hồi quy trên 60 cảnh ghép được: **KB = 10.130 + 33,9 × số_quái** ⇒ **nền ≈ 9,9 MB mỗi cảnh** (mỗi
  cảnh là một dịch vụ skynet = một Lua state riêng) **+ 33,9 KB mỗi quái**.

### 6.4 SỐ THẬT sau restart 19:31:52 — **KHÔNG phải dự báo nữa** [DK]

Server riêng đã restart lúc **19:31:52** với 195 cảnh `type=0`. Đo lại
(`95-sau-restart.txt`, `48-scene-window.txt`, `49-mem-sau.txt`):

| | trước (60 cảnh, restart 18:47) | **sau (195 cảnh, restart 19:31)** | dự báo cũ của tôi |
|---|---|---|---|
| Cảnh thực sự được tạo (`LAUNCH snlua scene`) | 65 | **195** (`scene startup done, total = 195`) | — |
| Cửa sổ tạo cảnh | 20 s | **42 s** (0,22 s/cảnh — *rẻ hơn* trên mỗi cảnh) | ≈ 60 s |
| Cảnh xong (dòng đầu log → `scene startup done`) | — | **59 s** (19:31:12 → 19:32:11) | — |
| **Cổng 15733/15734 LISTEN** | — | **40 s** (người điều phối đo) | ~165 s ❌ |
| Bộ nhớ Lua của các dịch vụ cảnh | 931 MB / 65 cảnh | **2.258 MB / 195 cảnh** (+1.327 MB, tb 11,6 MB/cảnh) | +1.922 MB (thừa 45 %) |
| RSS `Game_tlbb_2` | 1,45 GB | **3,01 GB** (+1,56 GB) | ≈ 3,4 GB |
| RAM hệ thống WSL | — | **dùng 4,60 GB / 16,0 GB, rảnh 11,1 GB** (điều phối đo +1,2 GB: 3.123 → 4.365 MB trước khi bot vào) | — |
| `SCENE_LOAD_FAIL` / `SCENE_INIT_FAIL` / `SCENE_CREATE_FAIL` | — | **0 / 0 / 0** | — |
| `traceback` | 0 | **0** | — |
| `MONSTER_CFG_FAIL` | 5 | **5** — đúng 5 ID cũ 49285/49286/49287/49288/49289, **0 mục mới** | "0 mục mới" ✅ |

**Dự báo ~165 s của tôi sai gấp 4 lần theo hướng tốt.** Hai lý do, cả hai đều phải ghi lại:

1. **Người dùng vá nốt 6 hàm O(n²) còn lại của `iostream.lua` SAU khi tôi lấy mốc.** `map-bianjing`
   đo đúng cấu hình khởi động thật: **228,05 s → 1,52 s (150×)**, kiểm tương đương bằng checksum toạ độ
   của **488 tệp `.path`** (325.837 đa giác) — giống hệt trước/sau. Navmesh gần như biến mất khỏi chi phí
   khởi động. [DK, do `map-bianjing` đo]
2. **Mốc "126 s" của tôi đo sai thứ.** `45-startup-time.sh` lấy `t2` = dòng `CLIENT_HEARTBEAT`/
   `AUTO_ROUTE_ENTER` đầu tiên, tức là **lúc có người kết nối**, không phải lúc server sẵn sàng. Lần này
   nó ra 147 s chỉ vì tôi chạy bot lúc 19:33:35. **Mốc đúng để so là "cổng LISTEN" (40 s) hoặc
   `scene startup done` (59 s)**; mốc ổn định để so giữa các lần là **cửa sổ tạo cảnh** (20 s → 42 s).
   Ai đọc `45-startup-time.sh` sau này phải biết dòng `DEN LUC CO NGUOI VAO` là **chặn trên**, không
   phải thời gian khởi động.

⇒ **Không có chuyện phải chờ 3 phút.** Không cần lùi mức nào. Phần dưới giữ lại chỉ để phòng khi
sau này bật thêm nhiều cảnh nữa:

Nếu về sau khởi động vượt 3 phút hoặc RAM căng, **lùi theo mức** — tắt các cảnh phân tuyến trùng bản đồ
trước (chúng thêm rất ít nội dung mà vẫn tốn đủ phần nền mỗi cảnh):

```powershell
# 汴京 2..6 tuyến (5 cảnh, 1 quái mỗi cảnh), rồi 通天塔/秦皇/敦煌 bản trùng
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py disable `
    --scenes 775,776,779,780,785
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py disable `
    --scenes 764,765,766,767,768,1303,1314,1317,1318,1319
```

Tắt toàn bộ đợt này (hoàn tác hẳn) — danh sách 135 ID nằm ở `Build/Logs/2026-09-17-maps-all/60-scenes.txt`:

```powershell
$sc = Get-Content C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-all\60-scenes.txt
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py disable --scenes $sc
```

---

## 7. ĐO LIVE — **15/15 cảnh ĐẠT** [DK]

Chạy 19:33:35–19:44:06 sau restart 19:31:52. Bằng chứng: `live-1/results.tsv`, `live-1/run.log`,
và mỗi cảnh một thư mục `live-1/s<ID>-<giờ>/` (`result.json`, `report.tsv`) + `live-1/s<ID>-serverlog.txt`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\maps_all_live.ps1 `
    -OutRoot Build\Logs\2026-09-17-maps-all\live-1
```

| cảnh | tên | nhóm | quái đặt sẵn | DBC | `final_scene` | `GCNewMonster` | traceback / error | kết quả |
|---|---|---|---|---|---|---|---|---|
| 581 | 通天塔地宫 | THÊM dòng | 1.176 | OK | **581** | **29** | 0 / 0 | **ĐẠT** |
| 764 | 通天塔地宫 | THÊM dòng | 1.176 | OK | **764** | **29** | 0 / 0 | **ĐẠT** |
| 1303 | 秦皇地宫四层-2 | THÊM dòng | 317 | OK | **1303** | **9** | 0 / 0 | **ĐẠT** |
| 433 | 昆仑山 | THÊM dòng | 325 | OK | **433** | **7** | 0 / 0 | **ĐẠT** |
| 401 | 秦皇地宫二层 | THÊM dòng | 303 | OK | **401** | **2** | 0 / 0 | **ĐẠT** |
| 1322 | 嵩山2 | THÊM dòng | 288 | OK | **1322** | **6** | 0 / 0 | **ĐẠT** |
| 1313 | 敦煌-2 | THÊM dòng | 286 | OK | **1313** | **4** | 0 / 0 | **ĐẠT** |
| 179 | 雪狼湖 | SỬA dòng | 538 | OK | **179** | **9** | 0 / 0 | **ĐẠT** |
| 173 | 黄龙洞 | SỬA dòng | 494 | OK | **173** | **5** | 0 / 0 | **ĐẠT** |
| 177 | 桃花源 | SỬA dòng | 438 | OK | **177** | **7** | 0 / 0 | **ĐẠT** |
| 156 | 大军草料场 | SỬA dòng | 412 | OK | **156** | **7** | 0 / 0 | **ĐẠT** |
| 157 | 苗人洞 | SỬA dòng | 372 | OK | **157** | **5** | 0 / 0 | **ĐẠT** |
| 174 | 水晶湖 | SỬA dòng | 351 | OK | **174** | **9** | 0 / 0 | **ĐẠT** |
| 188 | 银皑雪原 | SỬA dòng | 331 | OK | **188** | **4** | 0 / 0 | **ĐẠT** |
| 775 | 汴京2线 | đã đúng sẵn | 1 | OK | **775** | **1** | 0 / 0 | **ĐẠT** |

**Không cảnh nào hỏng.** Mỗi cảnh: bot vào **đúng ID cảnh đích** (không rơi về Đại Lý như lúc chưa
restart) và **thấy `GCNewMonster` > 0**. 15 cảnh trải đều: 7 nhóm THÊM-dòng, 7 nhóm SỬA-dòng, 1 nhóm
đã đúng sẵn, gồm cả hai cảnh lớn nhất (581 và 764, mỗi cảnh 1.176 quái) và cả bản đồ lớn nhất
(775 汴京, 1024×1024).

**Vì sao `GCNewMonster` chỉ 2–29 chứ không phải hàng trăm:** AOI của server chỉ gửi `GCNewMonster`
cho mục **trong tầm nhìn** tại điểm bot đứng, còn bot đứng yên 20 s (`--walk 0`). Bằng chứng "đủ quái"
là **`MONSTER_CFG_FAIL` đúng 5 mục cũ và 0 mục mới** trong log khởi động (mục 6.4), cộng với
`SCENE_LOAD_FAIL = SCENE_INIT_FAIL = SCENE_CREATE_FAIL = 0`. Cảnh 401 ra 2 là vì điểm vào nằm ở góc
bản đồ ít quái, không phải vì cảnh thiếu quái.

Các cảnh này **không có cổng vào** (không nằm trong `g_mpInfo` của `chuan_song_system.lua`), nên đặt
thẳng vị trí bằng `char_menpai.py set --scene S --pos-x X --pos-z Z`; toạ độ lấy từ **vị trí một
NPC/quái đặt sẵn**. Đạt khi: `final_scene == S` **và** `GCNewMonster > 0` **và** `traceback=0 error=0`
**và** `dbc=OK`.

### 7.1 Hai phép kiểm TRƯỚC restart (giữ lại vì là bằng chứng đối chứng) [DK]

| phép | lệnh | kết quả |
|---|---|---|
| Bộ đo chạy đúng | `-Scenes 6 -Table 70-mau-truoc.json` | `final_scene=6`, `GCNewMonster=9`, `traceback=0 error=0` → ĐẠT (`live-truoc/`) |
| Cảnh mới CHƯA vào được khi chưa restart | `-Scenes 581` | `dbc=OK active=1` nhưng **`final_scene=2`** (rơi về Đại Lý), `traceback=0 error=0` (`live-truoc-581/`) |

So với bảng 7 ở trên (`581 → final_scene=581, GCNewMonster=29` sau restart), phép thứ hai là **cặp
đối chứng sạch**: cùng một lệnh, cùng một cảnh, chỉ khác restart. Nó chứng minh hai điều: **bắt buộc
phải restart**, và cảnh chưa được tạo thì server **rơi về cảnh 2 một cách êm**, không crash.

---

## 8. Cái KHÔNG làm được, và cái cố tình không làm

### 8.1 49 cảnh không mở được: client CY không có tệp nghệ thuật [DK]

Không có dòng DBC nào mang bản đồ đó, **và** `Assets/CanonicalCY/Data/SceneFolder` (+ `Scene2Folder`,
11.719 tệp, 512 tệp `.Scene`) **không có** tệp `.Scene` tương ứng. Tổng 191 quái. Nhóm lớn:
`zijincheng`/`zijinnei`/`zijinwai1..4` (Tử Cấm Thành), `longta_0..3`, `yaotashui/mu/huo_1..4`,
`shenjing_shui/mu/huo`, `fenghuang_war`, `wuyixiang6v6`, `kunwu`, `kunwu_kaiwu`, `chiji_xiuxishi`,
`buyecheng`, `huashan` (37 quái), `mantuoshanzhuang` (31), `fengmingzhen` (108), `sr_rift`.

Đã kiểm: `huashan.Scene`, `mantuoshanzhuang.*`, `zijincheng.*`, `sr_rift.*` **có** trong
`Assets/Canonical/Data/SceneFolder` (nhánh **GL**), nhưng **không** có trong nhánh CY. [DK]
⇒ Muốn mở phải **nhập tài nguyên cảnh từ GL sang bộ dữ liệu CY** — việc riêng, trái với chốt
14/09 "mọi thứ như CY", nên không tự làm. `fengmingzhen` không có ở cả hai nhánh.

### 8.2 3 cảnh loại có chủ đích

| cảnh | quái | vì sao |
|---|---|---|
| **718** 画意洞天 | 0 | server **thiếu cả `HJ_xianshoutan.scn` lẫn `.path`** — không phải chuyện DBC |
| **1063** 恶人谷 | 25 | `maps-sect` hôm nay chuyển 恶人谷 sang ID **987** và đặt 1063 `active=0` (mục B.3). Nay **sửa được** dòng DBC 1063 cho đúng `erengu`, và làm thế sẽ chữa luôn 8 chỗ script còn trỏ 1063 (mục B.7) — nhưng sẽ có **hai cảnh 恶人谷 cùng lúc** và đảo ngược quyết định của họ. **Để người điều phối quyết.** |
| **2220** 唐门 | 24 | người điều phối đã chốt "cảnh 2220 giữ `active=0`", dùng ID 495 cho 唐家堡 (mục A.8.2). Nay **thêm được** dòng DBC 2220 (chép từ 495) và các script `cy4_*_hub.lua` vốn ghi cứng `destination_scene=2220`, nhưng **không tự bật lại**. |

Bật thêm 1063 và 2220 nếu được đồng ý, đúng hai lệnh:

```powershell
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply `
    --pairs "2220:495" --pairs-fix "1063:987" --zero-wmap `
    --bak Build\Logs\2026-09-17-maps-all\backup-client
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py enable --scenes 1063,2220
```

### 8.3 `type=1` và `type=4` — ngoài phạm vi, chỉ ghi số [DK]

| loại | tổng | đang bật | quái (cảnh đang bật) | trong số đang bật: DBC `OK` / `THIEU` / `SAI` |
|---|---|---|---|---|
| `type=1` (phó bản) | 330 | 86 | 1.299 | **3** / 40 / 43 |
| `type=4` (chiến thành) | 221 | 221 | 320 | **0** / 55 / 166 |

⇒ **304 cảnh đang bật sẽ làm client ném `Invalid scene ID` hoặc vẽ nhầm bản đồ** nếu người chơi vào được.
Đây là chuyện có từ trước (maps-sect đã ghi ở B.8.6), không phải do đợt này, nhưng nay đã có công cụ
sửa hàng loạt: chạy lại `10-recon-all.py` bỏ bộ lọc `type == '0'` là ra kế hoạch cho cả hai nhóm.

---

## 9. Việc còn lại / chưa kết luận được

1. ~~Chưa đo live~~ — **XONG**: 15/15 cảnh ĐẠT sau restart 19:31:52 (mục 7).
2. ~~Chưa đo thời gian khởi động và RAM~~ — **XONG**: 40 s tới khi cổng LISTEN, 42 s cửa sổ tạo
   195 cảnh, +1,33 GB bộ nhớ Lua cảnh, RSS 1,45 → 3,01 GB (mục 6.4). Dự báo cũ của tôi sai gấp 4 lần
   **theo hướng tốt**; lý do và cách đo đúng đã ghi ở 6.4.
3. **135 cảnh mới không có cổng vào**: không nằm trong `configs/TransportDefine.txt` hay `g_mpInfo`.
   Người chơi chỉ tới được bằng GM tool hoặc bằng lối đi có sẵn trong `_area.ini` của bản đồ lân cận.
   **Chưa rà** `_area.ini` xem bao nhiêu cảnh đã có lối vào tự nhiên — việc của `transfer-npc`.
4. **71/135 cảnh có NPC mang `script_id` chưa đăng ký** (mục 5) — NPC câm. Cần đối chiếu với
   `Game_2/Script/scripts/` xem tệp script có sẵn mà chỉ thiếu dòng đăng ký hay thiếu hẳn.
5. **135 cảnh mới không có biểu tượng trên bản đồ thế giới** (mục 4.1). Có chủ đích. Nếu muốn hiện,
   phải cấp toạ độ world map thật cho từng cảnh — dữ liệu chưa có, **không được chế số**.
6. **Số dòng DBC dễ mất nay là 128 + 13 cũ**: chạy lại `Tools/pipeline/build_canonical_cy.py` sẽ xoá
   sạch. Áp lại đủ ba lệnh (`maps-cy4`, `maps-sect`, `maps-all`) — cả ba đều idempotent. Xem mục 10.
7. **Chưa kết luận được** Game.exe CY 3.71 thật tra bằng `sceneid` hay `client_res`; ở đây chỉ khẳng
   định phần **mã client CY-Source** (giống kết luận của `maps-cy4` A.4 và `maps-sect` B.2).

---

## 10. Áp lại sau khi dựng lại canonical (bắt buộc, theo thứ tự)

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply
python -X utf8 Build\Logs\2026-09-17-maps-sect\scripts\70-client-scenedef-rows.py apply
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply `
    --pairs-file Build\Logs\2026-09-17-maps-all\30-pairs.json --zero-wmap `
    --bak Build\Logs\2026-09-17-maps-all\backup-client
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\71-dbc-dupe-check.py   # phải: SO_ID_TRUNG = 0
```

Kỳ vọng số dòng cuối: **746**. `maps-sect` giữ **bản sao riêng** của script với hằng số
`CHEP = {495: 615, 1311: 0, 1312: 1, 1315: 0, 1316: 0, 1320: 2, 1321: 2, 1358: 284, 1500: 77, 2218: 77}`
ghi thẳng trong file (`Build/Logs/2026-09-17-maps-sect/scripts/70-client-scenedef-rows.py:45`), nên
lệnh của họ không cần tham số. Bản sao đó **không** có phần mở rộng SỬA/`--zero-wmap`; dùng bản
`maps-cy4` cho mọi việc mới. [DK]
