# 86 cảnh `type=1` (phó bản) — agent `maps-instance` (17/09/2026)

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng/số). **[SL]** suy luận.
`R` = `/home/ubuntu/cys-test-20260913` (server riêng skynet trong WSL `TLBB`).
Bằng chứng: `Build/Logs/2026-09-17-maps-instance/`. Không restart server, không commit.
**Trạng thái: XONG phần dữ liệu + mã; BỊ CHẶN đúng một phép đo cuối** (mục 7.5 / 11.1 — hệ thống
quyền từ chối ghi `R/configs/SceneInfo.ini`). Bàn giao: `Timeline/handoff/maps-instance.md`.

> **ĐỌC DÒNG NÀY TRƯỚC.** Việc DBC đã làm xong và đã kiểm (73/86 cảnh `type=1` đang bật nay
> `client = OK`, 13 cảnh còn lại thiếu tệp `.Scene` bên CY). **Nhưng nó KHÔNG làm phó bản vào được**,
> và điều đó không phải vì làm sai: **ID cảnh mà server gửi cho client khi vào phó bản nằm trong dải
> 10001..10020, không phải ID `[sceneN]` của `SceneInfo.ini`.** Chứng minh ở mục 3, đo live ở mục 6.
> Cặp đối chứng sạch: **cảnh 36 có dòng DBC đúng từ TRƯỚC đợt này mà vẫn rơi về cảnh 2**.
> Đường đúng là `client_res`, và **đã làm xong ở mục 7**: `client_res` từ **1/16 → 12/16**, client
> đã vá (`CYS-SCENERES`), dựng lại **1356/1356 rc=0**, và chạy thật **20/20 phép kiểm PASS**
> với bảng 792 dòng (mục 7.6).

---

## 1. Kết quả một dòng

| | trước | sau |
|---|---|---|
| Cảnh `type=1` **đang bật** mà DBC client `OK` | **3** | **73** (+70) |
| … `THIEU` (không có dòng nào ở ID đó) | 40 | **6** |
| … `SAI` (dòng ở ID đó trỏ bản đồ khác) | 43 | **7** |
| Dòng DBC `SceneDefineEx.txt` | 746 | **792** (+46 THÊM, 36 SỬA, 1 dòng chỉ đổi toạ độ world map) |
| Cảnh `type=0` đang bật `THIEU`/`SAI` | 0 | **0** ← bất biến số 1 của `maps-all`, giữ nguyên |
| Quái đặt sẵn trong 70 cảnh đã sửa | — | **1.021** |
| **`client_res` của kịch bản phó bản trỏ đúng bản đồ** | **1/16** | **12/16** (mục 7) |

`70-client-scenedef-rows.py verify` → **`ok: true`, `loi: []`** (`52-verify.json`). [DK]
`71-dbc-dupe-check.py` → **780 dòng, cột 0 tăng dần, 0 ID trùng**, `stage-fps-daiviet` cùng sha256
(`53-dupe-check.json`). [DK]
**Client thật đã nạp bảng mới:** `DBC: SceneDefineEx.txt OK columns=25 records=780 record=160`
(`gui-1/WXClient.log`, đo lúc bảng đang là 780 dòng — đợt 2 sau đó nâng lên 792), vào thế giới,
dựng navmesh, di chuyển được, 0 dump, 19/20 phép kiểm PASS (mục 6.2). [DK]

---

## 2. 86 cảnh chia thế nào, và nguồn lấy từ đâu [DK]

Khảo sát `01-survey-all.json` + `20-find-sources.py` → `20-sources.json` / `21-plan-detail.txt`:

| nhóm | cảnh | quái | xử lý |
|---|---|---|---|
| DBC đã đúng sẵn | 3 | 92 | không đụng |
| DBC **thiếu hẳn dòng** ở ID đó | 34 | 462 | **THÊM** dòng mới |
| DBC có dòng nhưng **trỏ sai bản đồ** | 36 | 559 | **SỬA** dòng đó |
| **Client CY không có tệp `.Scene`** | 13 | 186 | **không mở được** — mục 5 |
| | **86** | **1.299** | |

### 2.1 Chỗ khác `maps-all`: dòng nguồn nằm trong BẢN SAO LƯU, không nằm trong file hiện tại [DK]

`maps-all` đã SỬA 74 dòng theo luật vàng (dòng ở ID N phục vụ cảnh N của server ta). Nhiều dòng bị
ghi đè tình cờ **lại chính là dòng CY thật của các bản đồ phó bản** mà tôi cần làm nguồn:

| dòng DBC | nội dung CY gốc | nội dung sau `maps-all` | vì sao bị ghi đè |
|---|---|---|---|
| 61 | `zhenlong.scene` 珍珑棋局 | `newbie_1.scene` | server 61 = 小木人巷 |
| 126 | `muchang.scene` 牧场 | `baozang_2.scene` | server 126 = 宝藏洞二层 |
| 139 | `wushendong_1.scene` | `shaolin_2.scene` | server 139 = 少林寺2 |
| 151 | `shiji_1.scene` | `prison.scene` | server 151 = 监狱 |
| 167 | `kaochang.scene` 考场 | (dòng khác) | server 167 |
| 173 | `shaolin_1.scene` | `huanglongdong.scene` | server 173 = 黄龙洞 |
| 181 | `tianshan_1.scene` | `qianzhuang.scene` | server 181 = 钱庄 |

**Các CHUỖI đó vẫn còn nguyên trong string pool** — pool là 72.239 byte y hệt ở cả bốn phiên bản
(679/682/692/746 dòng), chỉ là không còn ô nào trỏ tới. [DK: `41-clientres.txt`, và chính công cụ
khẳng định `assert d['pool'] == d['pool_goc']`] ⇒ chép nguyên văn một dòng từ bản sao lưu sang file
hiện tại là hợp lệ **từng ô**: mọi offset chuỗi của dòng cũ vẫn trỏ đúng chuỗi cũ.

Vì vậy `20-find-sources.py` tìm nguồn theo thứ tự **bản sao lưu 692 dòng trước, file hiện tại sau**.

**Bẫy đã tránh nhờ thứ tự đó:** `leitai_1.scene` ở file hiện tại có 5 dòng, 4 dòng (315/317/492/597)
mang tên **"KVK Đại Địa Đồ"** vì `maps-all` chép từ dòng 597; chỉ 599 còn tên "Lôi Đài". Trong bản
sao lưu có 10 dòng "Lôi Đài" (82, 156–163, 599). Ba cảnh 擂台 192/195/196 lấy nguồn là dòng **82**
(Lôi Đài) chứ không phải 315. Nếu tìm nguồn ở file hiện tại trước thì ba phó bản 擂台 sẽ mang tên
"KVK Đại Địa Đồ". [DK]

### 2.2 Bằng chứng độc lập: bảng `SceneDefineEx.txt` của chính server [DK]

`R/configs/SceneDefineEx.txt` (547 dòng, dòng dõi GL) có dòng cho **mọi** bản đồ phó bản này, với
`.Scene` / `.path` / `.wCollision` / `.jpg` và **W×H**. Đối chiếu từng cảnh (`21-plan-detail.txt`,
cột `sv_sde`): **70/70 khớp kích thước** với dòng nguồn CY tôi chép. Ví dụ:

| cảnh server | `.scn` | dòng nguồn CY | bảng server SDE | W×H |
|---|---|---|---|---|
| 130 少林寺 | `shaolin_1.scn` | 173 `shaolin_1.scene` Thiếu Lâm Tự | 173 `shaolin_1.scene` | 192×192 ✓ |
| 133 武当山 | `wudang_1.scn` | 176 `wudang_1.scene` Võ Đang sơn | 176 | 144×224 ✓ |
| 96 五神洞 | `wushendong_1.scn` | 139 `wushendong_1.scene` | 139 | 64×64 ✓ |
| 65 牧场 | `muchang.scn` | 126 `muchang.scene` Mục Tràng | 126 | 128×128 ✓ |
| 1328 慕容山庄 | `gusu_1.scn` | 288 `gusu_1.scene` Mộ Dung Sơn Trang | 800 | 192×192 ✓ |

Và **70/70 tên hiển thị của dòng nguồn khớp âm Hán-Việt với tên cảnh phía server** (木人巷 = Mộc
Nhân Hạng, 珍珑棋局 = Trân Lung Kỳ Cuộc, 缥缈峰 = Phiêu Miễu Phong…). Bảng đầy đủ ở
`21-plan-detail.txt`. Không phải chế số. [DK]

### 2.3 Ba trường hợp toạ độ bản đồ thế giới (cột 11..14) [DK]

`Worldmap::InitWorldMap` (`Src/Client/CEGUISystem/UILuaControl.cpp:2144-2156`) duyệt MỌI dòng và
đặt biểu tượng theo `nServerID` khi cột 11 **và** 12 khác 0. `30-make-pairs.py` **dựng lại toàn bộ
bảng sau khi ghi rồi mới quyết định**, nên không có chỗ đoán:

1. **ZERO (68/70 dòng)** — mặc định, giống `maps-all`.
2. **GIỮ (2 dòng: 44 và 45)** — dòng nguồn có toạ độ mà **sau khi ghi không dòng nào khác mang toạ
   độ đó**, nên biểu tượng **di chuyển** về đúng cảnh chứ không nhân đôi:
   - cảnh **45 水牢** giữ `990,428` (dòng nguồn 66 chính là dòng bị ghi đè trong cùng lượt này);
   - cảnh **44 珍珑棋局** giữ `875,477` (dòng 61 đã bị `maps-all` ghi đè kèm `--zero-wmap`, tức là
     biểu tượng 珍珑棋局 **đã mất từ lượt đó**; nay nó trở lại đúng dòng 44).
3. **CHUYỂN (`wmap_tu`, 1 dòng)** — dòng 112 là rác (server 112 = 衙门) nhưng đang giữ **biểu tượng
   duy nhất** của 玄武岛 `1190,466`. Ghi đè nó là mất biểu tượng, nên 4 ô 11..14 được chép sang
   **dòng 39**, tức là cảnh 玄武岛 **thật** của server ta (`petisland.scn`, `type=0`, đang bật, DBC
   `OK`, 259 quái). 20 ô còn lại của dòng 39 không bị đụng. Kết quả: biểu tượng vẫn có, và bấm vào
   nó là tới đúng cảnh.

`verify` kiểm luôn "không hai dòng nào trong số dòng lượt này đụng tới cùng toạ độ": `[]`. [DK]

---

## 3. **PHÁT HIỆN CHÍNH: phó bản không dùng ID `[sceneN]`** [DK]

Đây là điều quan trọng nhất của đợt này, và nó phủ định giả định trong đề bài.

### 3.1 Chuỗi bằng chứng trong mã

| bước | nơi | nội dung |
|---|---|---|
| 1 | `R/GameServer/lualib/scenemanager_core.lua:177-204` | `createScenes` **chỉ tạo `active==1 AND type==0`**; `scene_info_cache[id]` cũng chỉ được điền trong nhánh đó |
| 2 | `R/GameServer/lualib/copyscenemanager_core.lua:27-33, 199-220` | phó bản lấy từ **một hồ dựng sẵn**: `register(index + define.COPY_SCENE_BEGIN)` rồi `select()` trả `id + COPY_SCENE_BEGIN` |
| 3 | `R/GameServer/lualib/define.lua:2217-2218` | `COPY_SCENE_BEGIN = 10000`, `SPAN_COPY_SCENE_BEGIN = 20000` |
| 4 | `R/confs/publish_yu/server_conf.lua:7-9` | `MAX_COPY_SCENE=20`, `MAX_SPAN_COPY_SCENE=5`, `PREWARM_COPY_SCENE=3` ⇒ dải thật là **10001..10020** |
| 5 | `R/GameServer/services/scene/copyscenecore.lua:92-121` | `load(conf)` đặt `client_res`, `navmapname`, `monsterfile` từ **kịch bản**, **không** đặt lại `self.id` |
| 6 | `R/GameServer/services/scene/scenecore.lua:2032` | `ret.sceneid = self.id` — thứ gửi cho client |
| 7 | `Src/Client/WXClient/Network/CysModernHandlers.cpp:211-212` | `SetSceneID((INT)packet.sceneid, …)` |
| 8 | `Src/Client/WXClient/World/WorldManager.cpp:105-115` | `Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID)`; không có dòng ⇒ `TDThrow("(CWorldManager::EnterScene) Invalid scene ID(%d,%d)")` |

⇒ Khi vào phó bản, client nhận `sceneid ∈ 10001..10020`. DBC có **ID lớn nhất 4511**, nên **không
dòng nào khớp**, bất kể dòng ở ID 43/45/130/… đúng hay sai.

### 3.2 Đo trên server đang chạy [DK]

`40-list-services.sh` (debug console skynet 16002, chỉ đọc) — `40-services.txt`:

```
195 snlua scene        <- đúng 195 cảnh type=0
  3 snlua copyscene    <- hồ phó bản: .SCENE_10001, .SCENE_10002, .SCENE_10003
  0 snlua dynamicscene <- chưa thành bang hội nào
```

**Không có dịch vụ nào mang ID của 86 cảnh `type=1`.**

### 3.3 Toàn bộ lịch sử log 158 tệp: chưa ai từng vào phó bản [DK]

`42-log-copyscene.sh` trên `R/log/202609`: `[AUTO_ROUTE_ENTER] … scene=` chỉ có các giá trị
6/2/74/0/1/73/1007/495/755/2221/62/2218/1500/987/9/775/764/581/433/401 — **không giá trị nào ≥ 10000
và không giá trị nào là một trong 86 ID `type=1`**. Các dòng chứa chữ `copyscene` đều là
`[MEM_OPT] copyscene prewarm/runtime init`, không phải lượt vào.

### 3.4 `client_res` mới là khoá mà giao thức định dùng — và nó đã hỏng 10/16 (ĐÃ SỬA ở mục 7) [DK]

Kịch bản phó bản truyền thẳng số: `eTouximenpai_NPC_shaolin.lua:16` `g_ClientRes = 173`, rồi
`:400 config.client_res = self.g_ClientRes` và `:246/:678/:691 NewWorld(..., self.g_ClientRes)`.
Server gửi số đó trong `GCEnterScene.client_res` (`scenecore.lua:2031`) và
`GCNotifyChangeScene.client_res` (`scenecore.lua:9254`).

16 giá trị `g_ClientRes` (`43-clientres-map.json`) tra vào DBC (`43-clientres-pho-ban.txt`):

| | số dòng mang ĐÚNG bản đồ |
|---|---|
| DBC CY **gốc** (trước `maps-all`) | **10/16** (170, 173–181) |
| DBC lúc phát hiện (sau `maps-all`) | **1/16** (chỉ còn 180) |
| **DBC sau khi sửa ở mục 7** | **12/16** |

Ví dụ: `client_res=173` → CY gốc `shaolin_1.scene` ✓, sau `maps-all` `huanglongdong.scene` ✗.
[SL] Đây là **hệ quả không tránh được** của luật "dòng ở ID N phục vụ cảnh N": ID 173 không thể
vừa phục vụ cảnh 173 (黄龙洞 của server ta) vừa phục vụ `client_res 173` (少林寺 phó bản). Hai cách
đánh khoá **xung đột trực tiếp**. Không phải lỗi của `maps-all`; là một quyết định còn thiếu — và
quyết định đó nay đã có: **dời `client_res` sang khối ID riêng `+3000`** (mục 7.1).

---

## 4. Mở rộng `70-client-scenedef-rows.py` (giữ nguyên hành vi cũ) [DK]

Thêm vào chính file `Build/Logs/2026-09-17-maps-cy4/scripts/70-client-scenedef-rows.py`. **Mọi lệnh
đã ghi trong `maps-cy4`/`maps-sect`/`maps-all` vẫn chạy y hệt** — đã kiểm hồi quy (mục 4.2).

| cờ / khoá mới | làm gì |
|---|---|
| `--ref-dbc <file>` | đọc **dòng nguồn** từ file DBC khác (phải cùng string pool từng byte, script tự kiểm và từ chối nếu khác) |
| `"giu_wmap": [44,45]` | miễn trừ `zero_wmap` cho đúng các dòng đó |
| `"wmap_tu": {"39": 112}` | **chỉ** chép cột 11..14 từ dòng nguồn sang dòng đích, 20 ô còn lại giữ nguyên |
| `"zero_wmap": true` | tương đương cờ `--zero-wmap`, để khai báo được trong `--pairs-file` |

`verify` được mở rộng tương ứng: so dòng đích với dòng nguồn **trong `--ref-dbc`** (không phải trong
bản sao lưu — nội dung nguồn không nằm ở đó, đó chính là lý do phải có `--ref-dbc`), bỏ qua cột
11..14 đúng theo `giu_wmap`/`wmap_tu`, và thêm phép kiểm "không hai dòng nào của lượt này dùng chung
toạ độ world map".

### 4.1 Lệnh đã chạy

```powershell
cd C:\TLBB\085\CY-Source
$L='Build\Logs\2026-09-17-maps-instance'
$REF='Build\Logs\2026-09-17-maps-all\backup-client\SceneDefineEx.txt.truoc-maps-cy4-20260917T115825Z'
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply `
    --pairs-file "$L\30-pairs.json" --ref-dbc $REF --bak "$L\backup-client"
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py verify `
    --pairs-file "$L\30-pairs.json" --ref-dbc $REF --bak "$L\backup-client"
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\71-dbc-dupe-check.py
```

Bản sao `--ref-dbc` đã được chép vào thư mục bằng chứng của tôi (`ref-dbc-692.txt`, md5
`1b30f908c93e7cb323f238906cabfbb9`, giống hệt bản của `maps-all`) để lệnh trên tự đủ.

Hoàn tác: chép đè bằng
`Build/Logs/2026-09-17-maps-instance/backup-client/SceneDefineEx.txt.truoc-maps-cy4-20260917T143101Z`
(746 dòng, sha256 `233e6315e3e10ce1…`). Sau khi ghi: sha256 `5f9676d3f4482ebd…`, 150.355 byte.

### 4.2 Thử trên bản sao trước, và hồi quy hành vi cũ [DK]

Toàn bộ `plan → apply → verify → apply lần 2` chạy trên `thu-nghiem/copy.txt` (`--dbc`) trước khi
động vào file thật: 746 → 780 dòng, `ok: true`, **idempotent** (md5 `6EC7143217E4B674…` ở cả hai lần,
lần hai báo `BO-QUA 36`). Ba phép hồi quy trên bản sao `thu-nghiem/hoiquy.txt`:

| phép | kết quả |
|---|---|
| `plan` không cờ mới (maps-cy4) | như cũ, chỉ thêm dòng thông tin `nguon_doc_tu` |
| `verify` không cờ mới | vẫn báo đúng lỗi **có từ trước** mà `maps-all` đã ghi ở mục 4.3 của họ |
| `verify --pairs-file` của `maps-all` + `--zero-wmap` (chạy TRÊN BẢN SAO, trước khi ghi) | **`ok: true`** |

### 4.3 Kiểm độc lập sau khi ghi — `90-audit-cuoi.py`, không dựa vào `verify` của ai [DK]

```
1.  dòng của maps-all còn đúng:                    128/128
2.  dòng của maps-cy4/maps-sect còn đúng:           13/13
3a. dòng của maps-instance trỏ đúng .Scene:         70/70
3b. dòng NGOÀI mọi kế hoạch giống bản sao lưu từng ô: 709   (709 + 70 + 1 = 780 ✓)
4.  biểu tượng world map: 111 → 112 dòng; cặp toạ độ TRÙNG: 8 → 8, TRÙNG MỚI: không có
    dòng MỚI có biểu tượng: [39, 44, 45]      dòng MẤT biểu tượng: [66, 112]
=> DAT (0 lỗi)
```

8 cặp toạ độ trùng đều **có từ trước** (3 cặp Lạc Dương/Tô Châu/Đại Lý của `maps-sect`, 3 cặp của
`maps-cy4`, `tangmen`, `gusu` — đúng những cặp `maps-all` đã ghi ở mục 3.2.3 của họ). Đợt này
**không tạo thêm cặp trùng nào** và trả lại biểu tượng cho 3 dòng đúng chủ.

### 4.4 `verify` của `maps-all` nay báo `ok: false` — ĐÚNG THIẾT KẾ, không phải hỏng [DK]

Giống hệt điều đã xảy ra với `maps-sect` (mục 3.2.2 của `maps-all`). Chạy lại trên file thật sau
lượt của tôi (`91-verify-mapsall.json`) báo đúng hai điều, cả hai đều là **thay đổi có chủ đích của
tôi**:

1. `"KHONG ban sao luu nao + ke hoach = file hien tai"` — 70 dòng của tôi được ghi **sau** bản sao
   lưu của họ;
2. `"dong 39 con toa do world map khac 0"` — chính là phép chuyển biểu tượng 玄武岛 ở mục 2.3.

Bằng chứng đúng đắn hiện nay là `verify` của **maps-instance** (`ok: true`) cộng
`71-dbc-dupe-check.py` cộng `90-audit-cuoi.py`.

---

## 5. 13 cảnh không mở được: client CY không có tệp nghệ thuật [DK]

Cùng lớp với 49 cảnh của `maps-all`. Không dòng DBC nào (kể cả trong bản sao lưu) mang bản đồ đó,
**và** `Assets/CanonicalCY/Data/SceneFolder` + `Scene2Folder` **không có** tệp `.Scene` tương ứng.

| cảnh | bản đồ | quái | có ở nhánh GL? |
|---|---|---|---|
| 49 竹林 | `zhulin` | 81 | có |
| 47 宋辽边境 | `songliao` | 51 | có |
| 155 / 154 / 153 礼堂 | `wedding_3/2/1` | 27 / 16 / 9 | có |
| 189 镜湖匪寨 | `jiaofei` | 1 | có |
| 316 预留 | `cangjingge_xiaochang` | 1 | **không có ở cả hai nhánh** |
| 42 叛军营地 | `_pingpan_1` | 0 | có |
| 48 野外匪寨 | `yewai` | 0 | có |
| 190 燕子坞 | `yanziwu` | 0 | có |
| 539 凤凰陵墓 | `PhoenixMaze` | 0 | có |
| 1326 恶人谷 | `erengu_1` | 0 | **không có ở cả hai nhánh** (chỉ có `erengu`) |
| 1327 曼陀山庄 | `mantuoshanzhuang_1` | 0 | có |
| | | **186** | |

11/13 có tệp ở `Assets/Canonical/Data/SceneFolder` (nhánh **GL**). Mở được chúng đòi **nhập tài
nguyên cảnh từ GL sang bộ dữ liệu CY** — việc riêng, trái với chốt 14/09 "mọi thứ như CY", nên
không tự làm. **Không đề nghị tắt** 13 cảnh này: tắt không lợi gì (chúng vốn không có dịch vụ nào
lúc chạy, mục 3.2) mà có thể làm hỏng `scenecore:get_specifi_scene_client_res` — hàm này đọc
`clientres` của chính section `[sceneN]` đó.

---

### 6.1 Bot: 13 cảnh mẫu, tài khoản `test03` (GUID 200004) [DK]

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\maps_all_live.ps1 `
    -OutRoot 'Build\Logs\2026-09-17-maps-instance\live-1' -Account test03 -Guid 200004 `
    -Owner maps-instance -Orig 'Build\Logs\2026-09-17-maps-instance\char\goc-200004.json' `
    -Table 'Build\Logs\2026-09-17-maps-instance\70-mau-live.json' `
    -Scenes '6,36,1328,43,130,137,65,96,85,44,108,45,49'
```

| cảnh | tên | type | nhóm | quái | DBC | `final_scene` | `GCNewMonster` | tb/err | kết quả |
|---|---|---|---|---|---|---|---|---|---|
| **6** | 无量山 | **0** | đối chứng | 339 | OK | **6** | 22 | 0/0 | **ĐẠT** |
| 36 | 聚贤庄 | 1 | **đã đúng sẵn TỪ TRƯỚC** | 47 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 1328 | 慕容山庄 | 1 | THÊM dòng | 110 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 43 | 木人巷 | 1 | SỬA dòng | 89 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 130 | 少林寺 | 1 | SỬA dòng | 30 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 137 | 星宿海 | 1 | SỬA dòng | 30 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 65 | 牧场 | 1 | THÊM dòng | 17 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 96 | 五神洞 | 1 | THÊM dòng | 12 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 85 | 擂鼓山 | 1 | THÊM dòng | 27 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 44 | 珍珑棋局 | 1 | SỬA + giữ wmap | 1 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 108 | 市集 | 1 | SỬA dòng | 10 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 45 | 水牢 | 1 | SỬA + giữ wmap | 12 | OK | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |
| 49 | 竹林 | 1 | **không sửa được** | 81 | THIEU | **2** | 10 | 0/0 | KHÔNG VÀO ĐƯỢC |

**Nói thẳng: 12/12 cảnh `type=1` KHÔNG vào được, kể cả cảnh 36 vốn đã có dòng DBC đúng từ trước
đợt này.** Đó chính là cặp đối chứng sạch: cảnh 36 chứng minh việc không vào được **không liên quan
gì tới DBC**. Cảnh 6 (`type=0`) vào đúng ID với 22 `GCNewMonster`, nên bộ đo chạy đúng.

Log server nói rõ server đặt nhân vật ở đâu (`51-route-log.sh`):

```
[AUTO_ROUTE_ENTER] guid= 200004 obj= 378 scene= 6   x= 74.41 y= 158.32 client_res= 6  first_login= true
[AUTO_ROUTE_ENTER] guid= 200004 obj= 198 scene= 2   x= 160   y= 150    client_res= 2  first_login= true   <- 130
[AUTO_ROUTE_ENTER] guid= 200004 obj= 199 scene= 2   x= 160   y= 150    client_res= 2  first_login= true   <- 137
… (mọi cảnh type=1 đều ra scene 2, đúng toạ độ mặc định)
```

Đường rơi: `R/GameServer/services/msgagent.lua:974-993` — `.SCENE_130` không PING được →
`Dynamicscenemanager:ensure_city_scene` trả khác → `SceneManager:ensure_scene(130)` trả **false** vì
`scene_info_cache` chỉ có `type=0` (`scenemanager_core.lua:270-292`) → rơi về
`define.DEFAULT_SCENEID_AND_WORLD_POS` = cảnh 2. Không crash, không traceback. [DK]

### 6.2 Client thật (`Game.exe`) — `gui-1/` [DK]

Đặt CYTest04 (GUID 200005) vào **cảnh 130 少林寺** rồi chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\game\run_world_gui_live.ps1 `
    -Stage C:\TLBB\085\CY-Source\Build\world-gui\stage-fps-daiviet `
    -OutDir C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-instance\gui-1 -Account test04
```

| bằng chứng từ `gui-1/WXClient.log` | ý nghĩa |
|---|---|
| `DBC: SceneDefineEx.txt OK columns=25 records=780 record=160` | **bảng 780 dòng của tôi được client thật nạp**, không ném `Multi index at line N` |
| `DBC: SceneDefineEx scene 2 resolved name=Đại Lý scene=dali_new_320.Scene path=dali_new_320.path size=320x320 (EnterScene can find it)` | tra cứu vẫn đúng |
| `CYS world: GCConnect generation=1 scene=2` / `GCEnterScene scene=2 res=2 obj=212 city=0` | **nhân vật ở cảnh 130 lại vào cảnh 2** — đúng như bot, trên client thật |
| `CYS: navmesh dali_new_320.path … invariant_violations=0` | navmesh nạp sạch |
| 3 lượt bấm đất `navmesh=1 reachable=1`, `position … delta 1.87,-0.02` | di chuyển được |
| 16 ảnh PNG, `no_dump PASS`, `no_handler_errors PASS` | không crash |

**19/20 phép kiểm PASS.** Phép duy nhất FAIL là `position_changed`: ngưỡng của bộ đo là
`|dx|+|dy| ≥ 2.0` (`run_world_gui_live.ps1:174`) mà lượt này ra **1,89** — vì kịch bản ba lượt bấm
đi rồi quay lại gần chỗ cũ (154,54 → 162,54 → 159,48 → 156,42). Các dòng `ground click` cho thấy cả
ba lượt đều `reachable=1` và nhân vật thật sự đi 8 đơn vị ở lượt đầu. **Đây là đặc tính của kịch bản
replay tại điểm hồi sinh đó, không phải hồi quy do bảng DBC.** [SL]

Cả hai nhân vật test đã được trả về bản gốc (`char/restore-200005.json`, `char/inspect-200004-cuoi.json`).


---

## 7. SỬA HỒI QUY `client_res` — ĐÃ LÀM (đợt 2, 22:00–22:30)

Người điều phối chốt: hồi quy 10/16 → 1/16 là **do chính đợt làm này gây ra**, nên phải trả. Ba
việc dưới đây đã làm xong; kết quả: **`client_res` đúng 12/16** (mục 7.4).

### 7.1 Việc 1 — dời 16 hằng `g_ClientRes` sang dải ID trống `+3000` [DK]

`client_res` dùng chung dải ID với "ID cảnh server", nên 173 không thể vừa là 黄龙洞 (cảnh 173 của
server ta) vừa là 少林寺 phó bản. Đã dời sang **`mới = cũ + 3000`** — dải **2224..4510 của DBC
hoàn toàn trống** (đếm trên bảng 780 dòng; **10001..20100 cũng trống**), và phép cộng 3000 giúp
kiểm lại bằng mắt.

| việc | số lượng | công cụ |
|---|---|---|
| Hằng `g_ClientRes` trong `R/Game_2/Script/scripts/event/**` | **16 tệp** | `66-move-clientres.py apply` |
| Dòng mới trong DBC client ở `3170, 3173–3181, 3703, 3800` | **12** | `70-client-scenedef-rows.py --pairs-file 62-pairs-all.json --ref-dbc` |
| Dòng mới trong bảng `R/configs/SceneDefineEx.txt` **của server** | **16** (`3079…3800`) | `66-move-clientres.py apply` |

Kiểm 12 dòng mới bằng `68-check-3xxx.py` (đọc lại từ file thật, không tin kế hoạch):
**12/12 giống nguyên văn dòng CY nguồn** ở cả 24 ô, trừ cột 0 và cột 11..14 đã đặt 0 có chủ đích
(`68-check-3xxx.txt`). [DK]

Bốn giá trị `3079` (`songliao`), `3080` (`yewai`), `3081` (`zhulin`), `3596` (`mantuoshanzhuang_1`)
**không có dòng DBC** vì client CY không có tệp `.Scene` — đúng 4 bản đồ đã liệt kê ở mục 5. Vẫn dời
hằng số cho cả 16 **có chủ đích**: để 4 cảnh đó **hỏng thành thật** (không tìm ra dòng) thay vì rơi
vào dòng cũ và vẽ **nhầm bản đồ** (81 → `newbie_1.scene`, 596 → `kuafuzongjuesai.scene`).

Vì sao phải thêm dòng vào bảng SERVER: `copyscenecore:get_name`
(`R/GameServer/services/scene/copyscenecore.lua:31-36`) tra `scene_define_ex[client_res].name`, và
tên đó **hiện ra cho người chơi** (thông báo rơi đồ thay `&S` bằng `scene:get_name()` —
`services/scene/obj/itembox.lua:237`; thông báo hạ boss toàn server —
`Game_2/Script/scripts/event/allwar/all_boss_die.lua:227`). Không thêm thì thành "未知场景".

**Bẫy GBK đã tránh:** `txtreader` đổi cả dòng bằng `gbk.toutf8` vô điều kiện, một ô UTF-8 lẻ byte
sẽ nuốt tab và lệch cột IM LẶNG. Nên công cụ **chép nguyên byte** dòng nguồn và chỉ thay ô đầu
(chữ số ASCII). Kiểm sau khi ghi: file giải mã **sạch bằng GBK**, **không** giải mã được bằng UTF-8
(đúng như mong đợi), **mọi dòng đúng 24 cột**, `Index` tăng dần, 548 → **564 dòng**. [DK]

### 7.2 Việc 2 — sửa client: tra định nghĩa bằng `client_res`, giữ danh tính bằng `sceneid` [DK]

Thẻ `CYS-SCENERES`, 6 tệp, thay đổi tối thiểu. **Luật then chốt: chỉ tra `client_res` khi
`Search_First_Column_Equ(0, sceneid)` KHÔNG ra gì** ⇒ 195 cảnh `type=0` không bao giờ chạy tới
nhánh mới ⇒ 0 thay đổi hành vi.

| tệp | thay đổi |
|---|---|
| `Src/Engine/Interface/TDWorldSystem.h:54` | `EnterScene(INT, INT, INT nResID = -1)` |
| `Src/Client/WXClient/World/WorldManager.h` | cùng chữ ký + ô mới `m_nActiveServerSceneID` |
| `Src/Client/WXClient/World/WorldManager.cpp` | `GetActiveSceneID()` trả ID cảnh **phía server**; nhánh dự phòng `client_res` + dòng log `CYS-SCENERES:`; phép so "cùng cảnh" đổi sang `nSceneID`; `CheckIsFriend` so bằng `GetActiveSceneID()` |
| `Src/Client/WXClient/Procedure/GamePro_Enter.h/.cpp` | `SetSceneID(…, nResID = -1)`, ô `m_nResID`, khởi tạo ba ô trong hàm dựng (trước đây **không được khởi tạo**) |
| `Src/Client/WXClient/Network/CysModernHandlers.cpp` | truyền `packet.client_res`; `GCDelObject` và `GCNotifyChangeScene` so bằng `GetActiveSceneID()` thay vì `GetSceneDefine()->nServerID` |

Vì sao phải tách danh tính khỏi định nghĩa: `GCNotifyChangeScene.scene_from = self.id`
(`scenecore.lua:9250`) là **ID chạy** (10001…), còn định nghĩa lúc đó là dòng 3173. Nếu so bằng
`nServerID` của dòng định nghĩa thì **lượt dịch chuyển RA khỏi phó bản bị bỏ qua** — người chơi kẹt
trong phó bản. Tương tự với `GCDelObject.m_idScene` và `m_SceneID` của thành viên tổ đội.

**Không đụng** `Src/Client/WXClient/Network/PacketHandler/*` (lớp gói 0.85 cũ, không nằm trên đường
chạy hiện tại) — ghi lại ở mục 11.

Build: `Build/cmake/maps-instance-x64` (cây riêng), `cys_wxclient` → **`[1147/1148] Linking CXX
executable bin\Game.exe`, 0 lỗi** (`70-build.log`).

### 7.3 Việc 3 — đo [một phần ĐẠT, một phần BỊ CHẶN]

| phép | trạng thái |
|---|---|
| Chấm điểm `client_res` (tĩnh, đối chiếu bảng server ↔ DBC client) | **ĐẠT — 12/16**, mục 7.4 |
| `verify` DBC + `71-dbc-dupe-check` + `90-audit-cuoi` sau khi thêm 12 dòng | **ĐẠT** (792 dòng, 0 ID trùng) |
| Dựng lại **toàn bộ** cây client sau khi đổi interface | **ĐẠT** — 1356/1356, **rc=0, 0 lỗi** (`74-build-all.log`); mọi target đều link, kể cả `Render.dll`, `UI_CEGUI.dll`, `TlbbViewer`, `CysUiViewer`, `OgreSmoke`, 4 bộ test |
| **Client ĐÃ VÁ chạy thật, không hồi quy** | **ĐẠT — 20/20 phép kiểm PASS** (mục 7.6) |
| Client thật vẽ đúng bản đồ **phó bản** từ dòng vừa ghi (mục 11.1) | **BỊ CHẶN** — xem mục 7.5 |

### 7.4 Điểm `client_res`: **1/16 → 12/16** [DK]

`67-clientres-score.py` hỏi đúng một câu cho từng giá trị `g_ClientRes` đang có trong kịch bản:
*dòng DBC client ở ID đó có mang đúng bản đồ mà bảng `SceneDefineEx.txt` của server nói ID đó là
không?*

| | trước đợt này | sau đợt 1 (`maps-all` + 70 dòng của tôi) | **sau đợt 2** |
|---|---|---|---|
| đúng | 10/16 (bảng CY gốc) | **1/16** | **12/16** |

12 giá trị đúng: `3170 zeiying`, `3173 shaolin_1`, `3174 gaibang_1`, `3175 mingjiao_1`,
`3176 wudang_1`, `3177 tianlong_1`, `3178 xiaoyao_1`, `3179 emei_1`, `3180 xingxiu_1`,
`3181 tianshan_1`, `3703 erengu`, `3800 gusu_1`.
4 giá trị còn lại (`3079/3080/3081/3596`) **chờ tài nguyên `.Scene` của CY** — cùng quyết định với
13 cảnh ở mục 5 và 49 cảnh của `maps-all`. **Cao hơn cả bảng CY gốc (10/16)**, vì `3703` và `3800`
trước đây cũng sai.

### 7.5 Phép đo cuối còn nợ, và lý do CHÍNH XÁC [DK]

Kịch bản đã dựng sẵn ở mục 11.1: tạm đặt `type=0` cho cảnh 130 (chứng minh đường **sceneid**) và
cảnh 1326 với `clientres=3703` (chứng minh đường **client_res** — cảnh 1326 `erengu_1` không có
dòng DBC ở ID 1326, nên client buộc phải rơi sang `client_res`). Điểm vào của `erengu_1` đã đo:
`(58.23, 100.28)`, trọng tâm một đa giác navmesh (944 đa giác, biên 2..254).

**Không chạy được vì hệ thống quyền của Claude Code từ chối lệnh ghi vào cấu hình server dùng
chung**: `scene_install.py set --scene 130 --key type --value 0` bị chặn với lý do
*"Modify Shared Resources"*. Đây là hàng rào của công cụ, **không phải luật của dự án** — người
điều phối đã cho phép, nhưng chỉ người dùng mới mở được quyền này. Tôi không tìm cách đi vòng.
Cần người dùng cho phép `wsl … scene_install.py set` (và một lần restart) thì phép đo chạy được
ngay, mất khoảng 15 phút.

**70 + 12 dòng DBC của đợt này đều cần giữ.**

### 7.6 Client ĐÃ VÁ chạy thật: **20/20 phép kiểm PASS** — `gui-3/` [DK]

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\game\run_world_gui_live.ps1 `
    -Stage C:\TLBB\085\CY-Source\Build\world-gui\stage-maps-instance `
    -OutDir C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-instance\gui-3 -Account test04
```

| bằng chứng từ `gui-3/WXClient.log` | ý nghĩa |
|---|---|
| `DBC: SceneDefineEx.txt OK columns=25 records=792 record=160` | **client ĐÃ VÁ nạp đúng bảng 792 dòng** |
| `DBC: SceneDefineEx scene 2 resolved name=Đại Lý … (EnterScene can find it)` | tra bằng `sceneid` vẫn ra ở bước 1 ⇒ **nhánh `client_res` không hề chạy cho cảnh thường** |
| `GCConnect generation=1 scene=2` / `GCEnterScene scene=2 res=2 obj=204 city=0` | vào thế giới bình thường |
| `navmesh dali_new_320.path … invariant_violations=0` | navmesh sạch |
| `position before clicks 160.00,150.00 after 159.29,151.70 (delta -0.71,1.70)` | di chuyển được; `position_changed` **PASS** (2,41 ≥ 2,0) |
| `PASS world GUI live`, 16 ảnh PNG, `no_dump`, `no_handler_errors` | **20/20** |

Đây là phép kiểm hồi quy mạnh nhất có thể làm mà không đụng cấu hình server: cùng một bộ đo, cùng
một tài khoản, chỉ khác `Game.exe` đã vá và bảng DBC đã thêm 82 dòng. So với `gui-1` (client cũ,
bảng 780 dòng, 19/20) thì **nay hơn một phép** — phép `position_changed` trượt ở `gui-1` là do điểm
hồi sinh, không phải hồi quy (mục 6.2).

Stage dùng cho lượt này: `Build/world-gui/stage-maps-instance` (18 nhị phân, profile `cys-server`,
`Data` là junction tới **cùng** `Assets/CanonicalCY/Data`). **Không đụng stage của agent khác.**

**Lượt `gui-2` trước đó thất bại là do stage, không do mã**: cây build riêng lúc ấy mới chỉ có
`cys_wxclient` nên stage thiếu `Render.dll` và `Game.exe` chết ngay với
`TDThrow: Load plugin dll(WXRender.dll) failed!`. Dựng đủ 18 nhị phân là hết. [DK]

---

## 8. `type=4` (221 cảnh PCity) — chỉ khảo sát, KHÔNG sửa [DK]

Khảo sát riêng (agent phụ), bằng chứng đi kèm ở mục này:

1. **Nội dung**: chỉ **4/221** cảnh có navmesh (`1297, 1299, 1300, 1301`), **3** cảnh có quái.
   216 cảnh dùng chung **18 tệp `PCity*.scn`**, mỗi tệp đúng 12 lần (18 × 12 = 216) — [SL] 18 vị trí
   địa lý × 6 cấp thành hoặc tương tự.
2. **Tạo động lúc chạy — ĐÚNG, nhưng khác copyscene**: `dynamicscenecore` kế thừa `scenecore` và
   **không** override `load`, nên `self.id = conf.id` (`R/GameServer/services/scene/scenecore.lua:126`)
   với `info.id = id` đặt ở `dynamicscenemanager_core.lua:601` = **đúng ID `[sceneN]`**. Không có dải
   riêng. Nhưng `info.clientres` bị **ghi đè lúc chạy** bởi
   `get_scene_city_client_res` (`dynamicscenemanager_core.lua:281-296`), trả giá trị cột
   `"<N>级城市"` của `configs/CityInfo.txt` theo **cấp thành**, và `run_city_scene` **huỷ tạo cảnh
   nếu giá trị đó nil** (`:606`).
3. **Người chơi vào được không — hiện KHÔNG**: lối vào duy nhất là
   `guildoperation.lua:66 → CityMoveTo → check_city_running → run_city_scene`, và dữ liệu nguồn là
   collection `city` trong MongoDB (`dynamicscenemanager_core.lua:177`). Kiểm MongoDB (chỉ đọc):
   DB game chỉ có `account, activity, character, flower_top, jingpai, limit_shops, mingdong_top,
   ranking_chaos_brawl_players` — **không có `city`, không có `guild`**. Khớp với đo: **0 dịch vụ
   `dynamicscene`**. ⇒ **Chưa cảnh `type=4` nào từng được tạo.**
4. **Tài nguyên client**: chỉ **1/221** bản đồ có tệp `.Scene` trong CanonicalCY (scene 1299
   `qinhuanggong_4`). 18 tệp `PCity*` **không có** tài nguyên client.
5. **Rủi ro nếu sửa**: trùng ID trực tiếp = **0**. Nhưng 166 dòng DBC đang bị coi là "SAI" ở các ID
   đó thật ra **đang mô tả bản đồ thật**, và **72 cảnh đang bật (`type=0`/`type=1`) đặt `clientres`
   trỏ vào 70 trong số các ID đó**. Ghi đè chúng là phá dữ liệu sống.

⇒ **Khuyến nghị: KHÔNG sửa DBC cho 221 cảnh `type=4`.** Chi phí cao (ghi đè 166 dòng sống), lợi ích
bằng 0 (chưa bao giờ tạo được, 220/221 thiếu tài nguyên, đường `client_res` của chúng vốn đã hợp lệ).
Nếu sau này có bang hội thật, việc cần làm là kiểm `configs/CityInfo.txt` cột `N级城市` và các dòng
536/605/611/617/618/632, **không phải** sửa 221 dòng theo ID cảnh.

---

## 9. Bất biến cuối đợt, và số dòng DBC dễ mất

`scene_install.py survey --all` lần cuối (`61-survey-sau.json`): [DK]

| type | đang bật | OK | THIEU | SAI |
|---|---|---|---|---|
| 0 | 195 | **195** | 0 | 0 |
| 1 | 86 | **73** | 6 | 7 |
| 4 | 221 | 0 | 55 | 166 |

- Bất biến của `maps-all` (`type=0` sạch) **giữ nguyên**.
- `type=1` còn **13 cảnh** — tất cả vì client CY thiếu tệp `.Scene` (mục 5), không phải vì thiếu
  công cụ hay thiếu nguồn.
- `type=4` để nguyên có chủ đích (mục 8).

**Dòng DBC dễ mất khi dựng lại canonical: 13 (cy4 + sect) + 128 (maps-all) + 82 (maps-instance:
70 dòng cảnh + 12 dòng `client_res`) = 223 dòng**, cộng 1 dòng chỉ đổi toạ độ world map (dòng 39).
Áp lại **theo đúng thứ tự** — bước của tôi phải **sau** `maps-all` vì dòng 39 là đích của cả hai:

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply
python -X utf8 Build\Logs\2026-09-17-maps-sect\scripts\70-client-scenedef-rows.py apply
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply `
    --pairs-file Build\Logs\2026-09-17-maps-all\30-pairs.json --zero-wmap `
    --bak Build\Logs\2026-09-17-maps-all\backup-client
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\70-client-scenedef-rows.py apply `
    --pairs-file Build\Logs\2026-09-17-maps-instance\62-pairs-all.json `
    --ref-dbc Build\Logs\2026-09-17-maps-instance\ref-dbc-692.txt `
    --bak Build\Logs\2026-09-17-maps-instance\backup-client
python -X utf8 Build\Logs\2026-09-17-maps-cy4\scripts\71-dbc-dupe-check.py   # phải: SO_ID_TRUNG = 0
```

Kỳ vọng số dòng cuối: **792**. Cả bốn bước đều idempotent (đã đo lần hai cho md5 y hệt).
`62-pairs-all.json` = `30-pairs.json` (70 dòng cảnh) **gộp** `60-clientres-pairs.json` (12 dòng
`client_res`); dùng nó là đủ, không cần chạy hai lần.

**Phía server cũng có 32 thay đổi dễ mất nếu ai đó khôi phục `R` từ bản sao lưu cũ**: 16 hằng
`g_ClientRes` và 16 dòng `configs/SceneDefineEx.txt`. Áp lại bằng
`wsl … 66-move-clientres.py apply --out-dir <thư mục bằng chứng>` (idempotent: đã dời rồi thì bỏ qua).

---

## 10. Sửa vào công cụ / mã dùng chung (mặc định không đổi hành vi) [DK]

1. `Tools/server/maps_all_live.ps1`: thêm tham số `-Orig` (để trống = đường dẫn cũ của `maps-all`).
   Trước đó đường dẫn bản gốc nhân vật bị ghi cứng vào thư mục bằng chứng của `maps-all`.
2. `Tools/game/run_world_gui_live.ps1`: thêm `-Role`, và **truyền `CYS_BOT_ACCOUNT` / `CYS_BOT_ROLE`
   cho tiến trình con**. Đây là một lỗi im lặng có từ trước: tham số `-Account` đã tồn tại nhưng
   tên tài khoản **không** được truyền vào `Game.exe`, mà `CysGlLoginSmoke.h:47-58` mặc định
   `test00`/`CYTest00`. Hệ quả: một lượt `-Account testNN` (NN ≠ 00) sẽ gửi **mật khẩu của testNN
   dưới tên tài khoản test00** ⇒ một lần sai mật khẩu, mà server đếm số lần sai theo MAC.
   Tôi phát hiện trước khi chạy nên chưa lượt nào của tôi sai; **chưa kiểm** liệu lượt nào trước đây
   đã sập bẫy này chưa. Nay `-Account test04` ⇒ `CYS_BOT_ACCOUNT=test04`, `CYS_BOT_ROLE=CYTest04`;
   mặc định `test00` giữ nguyên hành vi cũ.
3. `Tools/server/scene_install.py`: thêm khối chú thích "cột `client` chỉ có nghĩa với `type=0`"
   kèm dẫn chứng. **Không đổi một dòng mã nào**, nên mọi lệnh và JSON đầu ra giữ nguyên.
4. `Build/Logs/2026-09-17-maps-cy4/scripts/70-client-scenedef-rows.py`: `--ref-dbc`, `giu_wmap`,
   `wmap_tu`, `zero_wmap` (mục 4).
5. **Mã client, thẻ `CYS-SCENERES`** (mục 7.2): `TDWorldSystem.h`, `WorldManager.h/.cpp`,
   `GamePro_Enter.h/.cpp`, `CysModernHandlers.cpp`. Tất cả tham số mới đều có giá trị mặc định
   giữ nguyên hành vi cũ, và nhánh mới **chỉ chạy khi không có dòng nào ở `sceneid`**.
   Ba agent khác đang ở trong `Src/Client/` (`ride-core`, `move-parity` ở `WXClient/`,
   `host-*` ở `LuaApiGen/`); tôi đọc lại từng tệp ngay trước khi sửa và không chạm tệp của họ.

---

## 11. Việc còn lại / chưa kết luận được

1. **CẦN NGƯỜI DÙNG MỞ QUYỀN — phép đo cuối cùng.** Chưa chứng minh được bằng client rằng một dòng
   DBC vừa ghi vẽ đúng bản đồ, vì không cảnh `type=1` nào vào được (mục 3). Kịch bản đã dựng sẵn,
   chạy mất ~15 phút:

   ```powershell
   # 1) tam bien 2 canh thanh type=0 de server tao luc khoi dong
   #    130  = 少林寺 shaolin_1  -> chung minh duong SCENEID  (DBC dong 130 la dong toi vua ghi)
   #    1326 = 恶人谷 erengu_1   -> chung minh duong CLIENT_RES (DBC KHONG co dong 1326,
   #                               nen client buoc phai roi sang client_res 3703 = erengu.Scene)
   wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py `
       set --scene 130 --key type --value 0
   wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py `
       set --scene 1326 --key type --value 0
   wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py `
       set --scene 1326 --key clientres --value 3703
   # 2) restart, cho `scene startup done, total = 197`
   # 3) dat CYTest04 vao canh 130 (92.43, 83.93) roi 1326 (58.23, 100.28); moi canh mot luot
   #    run_world_gui_live.ps1 -Stage Build\world-gui\stage-maps-instance -Account test04
   #    ky vong canh 130 : `CYS world: GCEnterScene scene=130` + Scene_Load shaolin_1.Scene
   #    ky vong canh 1326: `CYS-SCENERES: scene 1326 has no SceneDefineEx row;
   #                        resolved by client_res 3703 -> erengu.Scene`
   # 4) TRA VE type=1 cho ca hai + clientres=703 cho 1326, roi restart lai
   ```

   Tiền kiểm đã làm [DK]: `shaolin_1.scn/.path/_monster.ini` và `erengu_1.scn/.path` đều có trên
   server; điểm vào của `erengu_1` là trọng tâm một đa giác navmesh (`71-nav-erengu_1.txt`, 944 đa
   giác, biên x 2..254 / z 0,7..254).

   **Vì sao chưa chạy: hệ thống quyền của Claude Code từ chối** `scene_install.py set` với lý do
   *"Modify Shared Resources"* (`R/configs/SceneInfo.ini` dùng chung với agent khác). Đây là hàng
   rào của công cụ, không phải luật dự án; chỉ người dùng mở được. Tôi không đi vòng.
2. **13 cảnh thiếu tệp `.Scene` bên CY** (và 4 giá trị `client_res` `3079/3080/3081/3596` cùng lý
   do) — cần quyết định có nhập tài nguyên cảnh từ nhánh GL không (chung một quyết định với 49 cảnh
   của `maps-all`).
3. ~~`client_res` hỏng 10/16~~ — **ĐÃ SỬA, nay 12/16** (mục 7). Bốn giá trị còn lại nằm ở mục 2 trên.
4. **`spancopyscenemanager_core:init` lặp `for i = 1, define.MAX_SCENE`** nhưng `define.MAX_SCENE`
   không tồn tại trong `R/GameServer/lualib/define.lua`. Hiện không có dịch vụ `spancopyscene` nào
   chạy, khớp với việc dịch vụ đó không được khởi động trong cấu hình này. **Chưa kết luận được**
   đây là mã chết hay một lỗi sẽ nổ khi bật liên server. [DK cho số liệu, [SL] cho kết luận]
5. **Chưa kết luận được** Game.exe CY 3.71 thật tra bằng `sceneid` hay `client_res`; ở đây chỉ khẳng
   định phần **mã client CY-Source** (giống kết luận của `maps-cy4`, `maps-sect`, `maps-all`). Dữ
   liệu thì nghiêng về `client_res`: 10/16 `g_ClientRes` của kịch bản phó bản trỏ đúng bản đồ trong
   bảng CY gốc, còn dải 10001+ thì bảng CY gốc **không có dòng nào**. Cách sửa ở mục 7.2 **không
   phụ thuộc vào câu trả lời này**: nó chỉ dùng `client_res` khi `sceneid` không tra ra gì.
6. **`Src/Client/WXClient/Network/PacketHandler/*` (lớp gói 0.85) chưa được sửa theo `CYS-SCENERES`**
   — `GCDelObjectHandler.cpp:24` và `GCNotifyChangeSceneHandler.cpp:15` vẫn so bằng
   `GetSceneDefine()->nServerID`. Chúng không nằm trên đường chạy hiện tại (mọi gói đi qua
   `CysModernHandlers`), nhưng nếu ai đó bật lại lớp cũ thì phải sửa cùng kiểu.
7. ~~Lượt client `gui-2` thất bại~~ — **ĐÃ GIẢI QUYẾT**: nguyên nhân là stage thiếu DLL, không phải
   mã. Dựng đủ 18 nhị phân rồi chạy lại (`gui-3`) cho **20/20 PASS** (mục 7.6). Bài học giữ lại:
   **stage cần 18 nhị phân**, nên phải dựng TOÀN BỘ thành phần (`build.cmd … Release` không truyền
   target), không chỉ `cys_wxclient`.
