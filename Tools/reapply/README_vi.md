# `Tools/reapply` — công thức khôi phục dữ liệu, bản ĐƯỢC GIT THEO DÕI

## Vì sao thư mục này tồn tại

`.gitignore` loại **cả `/Assets/*` lẫn `/Build/*`**. Điều đó đúng — dữ liệu game 22 GB và kết quả
dựng không nên vào git. Nhưng nó tạo một lỗ hổng thật:

- Kết quả sửa dữ liệu nằm trong `Assets/CanonicalCY` ⇒ **git không giữ**.
- **Công thức khôi phục** lại nằm trong `Build/Logs/...` ⇒ **git cũng không giữ**.

⇒ Nếu ai đó dọn `Build/` (đã từng xảy ra: 302 GB → 98 GB ngày 17/09) **hoặc** chạy lại
`build_canonical_cy.py`, thì vừa mất kết quả vừa mất cách làm lại. Thư mục này giữ **bản sao công
thức** để điều đó không xảy ra.

**Bản gốc vẫn ở `Build/Logs/…` và vẫn là bản đang dùng hằng ngày.** Đây là bản sao bền, chỉ dùng khi
bản gốc không còn. Sửa bản gốc thì **nhớ chép lại sang đây**.

---

## ⚠️ ĐỌC TRƯỚC KHI CHẠY BẤT KỲ CÔNG THỨC NÀO

**1. Bằng chứng khôi phục đúng là `verify` + `71-dbc-dupe-check` + so từng ô — KHÔNG PHẢI sha256.**
Bản dựng lại **sẽ khác sha256** với file trên đĩa mà vẫn đúng: thứ tự các **chuỗi mới trong string pool** phụ
thuộc vào việc nối làm mấy đợt (file thật thường nối hai đợt vì có bước thử một dòng; bản khôi phục nối một đợt).
Đã đo 18/09: khôi phục ra `d2a33463…` trong khi đĩa là `b960ca2c…`, nhưng **799/799 dòng giống nhau từng ô**,
cùng tập ID, cùng pool 73.382 byte, 72.239 byte đầu của pool giống hệt. Thấy sha256 lệch **đừng chạy lại hay ép
ghi đè** — chạy `verify`.

**2. Số dòng kỳ vọng phụ thuộc chạy tới bước mấy:** 4 bước đầu → **792**; + Bước 5 (`scenes-lo2`) → **799**;
+ Bước 6 (`maps-kho48`) → **802**; + Bước 7 (`tangmen`) → **803**.
Dừng ở 792 là mất 19 dòng của 17 bản đồ nhập từ GL.

**3. Bất biến kiểm cuối cùng** (`Tools\server\scene_install.py verify` / `survey --all`): **không cảnh `type=0`
đang bật nào báo `THIEU`/`SAI`** — chuẩn 18/09 là **197/197 OK**; `doc-truth` đo lại 19/09 vẫn **197/197, 0 vi phạm**;
sau khi `tangmen` bật cảnh 2220 (20/09) là **198/198 OK, 0 vi phạm**.

**4. `71-dbc-dupe-check.py` KHÔNG phải phép kiểm tồn tại.** Nó chỉ biết "0 ID trùng + cột 0 tăng dần", nên
**xoá sạch 242 dòng vẫn ra `SO_ID_TRUNG = 0`** (đã đo 19/09, nhánh `reapply-guard`: xoá đúng 12 dòng `client_res`
⇒ `71` báo `SO_ID_TRUNG: 0, cot0_tang_dan: True`). Phép kiểm biết trượt là
**`72-dbc-pool-rows.py verify`** (19 dòng của `scenes-lo2`) và **`73-scenedef-242.py verify`** (cả 242 dòng).

---

## `scenedef/` — 242 dòng DBC cảnh + 32 thay đổi phía server

`build_canonical_cy.py` dựng lại `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt` sẽ **xoá
sạch** các dòng đã nối thêm và **trả các dòng đã sửa về bản CY gốc**:

| đợt | số lượt ghi | trong đó |
|---|---|---|
| `maps-cy4` | 3 | thêm (2221–2223) |
| `maps-sect` | 10 | thêm |
| `maps-all` | 128 | 54 thêm + 74 sửa |
| `maps-instance` | 82 | 34 thêm + 36 sửa + **12 dòng `client_res`** |
| `scenes-lo2` (Bước 5) | 19 | 7 thêm + 12 sửa |
| `maps-kho48` (Bước 6) | 3 | thêm (3079 `client_res`, 1350, 2300 tạm) |
| `tangmen` (Bước 7) | 1 | thêm (2220) |
| **TỔNG** | **246** | 679 + **124 dòng thêm** = **803** trên đĩa 20/09 |

Bảng kê `73-scenedef-manifest.py` đếm **245** (nó không giữ dòng tạm 2300, xem Bước 6).
Con số **242** ở bản README trước là trạng thái 19/09 sáng, trước Bước 6 và Bước 7.

Cộng 1 dòng chỉ đổi toạ độ bản đồ thế giới (dòng 39 — `maps-instance.wmap_tu`, cùng ID đã có trong 74 dòng
`sua` của `maps-all`, nên không đếm thành lượt riêng).

Đo 19/09 (`reapply-guard`): **242 lượt ghi = 242 ID khác nhau, 0 ID bị hai đợt ghi.**
Con số **211** ở `Timeline/MOC-17-09_vi.md` mục 2 là **đếm thiếu** (bỏ 12 dòng `client_res` + 19 dòng
`scenes-lo2`); MOC đã có khối đính chính.

### ⚠️ 12 dòng `client_res` — khoản đơn lẻ đắt nhất

ID **3170, 3173–3181, 3703, 3800** (= `g_ClientRes` cũ + 3000, xem `66-move-clientres.py:32`).
Phó bản được cấp `sceneid` **10001..10020** (`define.lua` `COPY_SCENE_BEGIN = 10000`) — dải mà
`SceneDefineEx` không bao giờ có dòng — nên `client_res` là **đường tra duy nhất còn lại**:

```
Src/Client/WXClient/World/WorldManager.cpp:110-131
    pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID);
    if(!pSceneDef && nResID > 0 && nResID != nSceneID)                        // CYS-SCENERES
        pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nResID);
    if(!pSceneDef) TDThrow("(CWorldManager::EnterScene) Invalid scene ID(%d,%d,res=%d)");
```

Mất 12 dòng đó ⇒ cả hai lần tra đều trượt ⇒ `TDThrow` ⇒ **mọi phó bản đứng**. `73-scenedef-242.py verify`
có mục `CLIENT_RES` riêng và in cảnh báo này khi thiếu.

### Áp lại — ĐÚNG THỨ TỰ NÀY

Thứ tự bắt buộc vì **dòng 39 là đích của cả `maps-all` lẫn `maps-instance`**; chạy sai thứ tự thì
dòng sau đè dòng trước. Cả bốn bước **idempotent** (đã đo lần hai cho md5 y hệt).

```powershell
cd C:\TLBB\085\CY-Source
$R = 'Tools\reapply\scenedef'

python -X utf8 $R\70-client-scenedef-rows.py apply --bak Build\reapply-bak
python -X utf8 $R\70-sect-scenedef-rows.py   apply --bak Build\reapply-bak
python -X utf8 $R\70-client-scenedef-rows.py apply `
    --pairs-file $R\data\maps-all-30-pairs.json --zero-wmap --bak Build\reapply-bak
python -X utf8 $R\70-client-scenedef-rows.py apply `
    --pairs-file $R\data\maps-instance-62-pairs-all.json `
    --ref-dbc    $R\data\maps-instance-ref-dbc-692.txt --bak Build\reapply-bak

python -X utf8 $R\71-dbc-dupe-check.py      # phai ra: SO_ID_TRUNG = 0
```

**Kỳ vọng sau khi chạy BỐN bước trên: `SceneDefineEx.txt` = 792 dòng × 25 cột, 0 ID trùng, cột 0 tăng dần.**
⚠️ **792 CHƯA PHẢI số cuối.** Đĩa hiện là **799 dòng** vì còn **Bước 5 (`scenes-lo2`)** ở dưới; dừng ở 792 là
**mất 7 dòng + 12 dòng đã sửa** của 17 bản đồ nhập từ GL (cảnh 48/49/125/404/405/410/539… mất bản đồ).
Chạy tiếp Bước 5 rồi mới kiểm bất biến.

Ba điều về `--bak`, đã kiểm trong mã:
- thư mục **tự tạo** (`os.makedirs(..., exist_ok=True)`), không cần tạo tay;
- bản sao lưu đặt tên có dấu thời gian nên **chạy lại nhiều lần không đè lên nhau**;
- `verify` **quét bản sao lưu trong chính `--bak`** ⇒ nếu `apply` dùng `--bak` nào thì `verify` phải
  dùng đúng cái đó, nếu không nó sẽ không thấy gì để so. Vì vậy bốn lệnh trên cố ý dùng chung một
  giá trị. Phép kiểm cuối (`71-dbc-dupe-check.py`) độc lập với `--bak` nên luôn dùng được.

Kiểm bằng bất biến thật, không chỉ bằng số dòng:

```powershell
python Tools\server\scene_install.py verify
```

⇒ **không cảnh `type=0` nào đang bật được báo `THIEU` hoặc `SAI`** (chuẩn 17/09: 195/195 OK;
**chuẩn 18/09 sau `scenes-lo2`: 197/197** — thêm 125 `huashan` và 410 `shengsileitai`).
Chạy phép kiểm này **sau Bước 5**, không phải sau bước 4.

### Bước 5 — `scenes-lo2` (18/09): 19 dòng cho 17 bản đồ nhập từ GL, CÓ NỐI STRING POOL

Chạy **SAU** bốn bước trên (nó SỬA 12 dòng 113–120/125/189/190/539 và THÊM 7 dòng
48/49/404/405/410/3080/3081). Khác ba công cụ trên ở một điểm: pool string được
**nối thêm** (72.239 → 73.382 byte) vì 17 bản đồ này chưa từng có chuỗi `<map>.Scene` trong pool.

```powershell
cd C:\TLBB\085\CY-Source
$R = 'Tools\reapply\scenedef'
python -X utf8 $R\72-make-rows-lo2.py                         # sinh lai data\scenes-lo2-rows.json tu bang GL (tuy chon)
python -X utf8 $R\72-dbc-pool-rows.py apply  --rows $R\data\scenes-lo2-rows.json --bak Build\reapply-bak\scenes-lo2
python -X utf8 $R\72-dbc-pool-rows.py verify --rows $R\data\scenes-lo2-rows.json
python -X utf8 $R\71-dbc-dupe-check.py      # phai ra: SO_ID_TRUNG = 0
```

**Kỳ vọng sau bước này: 799 dòng × 25 cột, pool 73.382 byte, 0 ID trùng.** Idempotent (lần hai
báo `da_du`, md5 y hệt).
⚠️ **799 CŨNG CHƯA PHẢI số cuối** kể từ 19/09 — còn **Bước 6 (`maps-kho48`)** ở mục `material/`
cuối file, đưa lên **800**. Dừng ở 799 là mất dòng `client_res` **3079** (`songliao`).

`72-dbc-pool-rows.py` còn **`undo`** (thêm 19/09, cho đủ khuôn `plan/apply/verify/undo` của `host-2/`):

```powershell
python -X utf8 $R\72-dbc-pool-rows.py undo --rows $R\data\scenes-lo2-rows.json --bak Build\reapply-bak\scenes-lo2
```

Nó **chỉ** trả lại bản sao lưu nào thoả `bản sao lưu + kế hoạch = file hiện tại TỪNG BYTE`; không bản nào
thoả thì **từ chối, không ghi gì** (file đã bị đợt khác ghi tiếp ⇒ đè bản cũ lên là xoá việc của họ).
Đã đo 19/09 trên bản sao: đúng đường ⇒ 799 → 792 (`11ab72b8…`, `verify` sau đó **ok:false đúng như
thiết kế**); đường bị đợt khác ghi ⇒ `ok:false, da_ghi:false`, file không bị đụng.

⚠️ **ĐỪNG so sha256 bản khôi phục với file thật — sẽ khác, và khác là ĐÚNG.** Đã kiểm thật (18/09,
`94-khoiphuc-apply.json`): dựng lại từ bản sao 792 dòng (`11ab72b8…`) ra `d2a33463…` trong khi đĩa là
`b960ca2c…`; nhưng hai bảng **giống nhau từng ô ở cả 799 dòng** (`0 dòng lệch`, cùng tập ID, cùng pool
73.382 byte, 72.239 byte đầu của pool giống hệt). Khác biệt duy nhất là **thứ tự các chuỗi mới trong pool**:
file thật nối làm hai đợt (thử 1 dòng trước, rồi 18 dòng), bản khôi phục nối một đợt. Bằng chứng đúng đắn là
`72-dbc-pool-rows.py verify` (`ok: true`) + `71-dbc-dupe-check.py` + `scene_install.py verify`, **không phải**
sha256. `apply` tự đọc lại từ đĩa và kiểm 6 điều (từng ô của 19 dòng, mọi dòng
khác giữ nguyên, pool cũ là tiền tố pool mới, cột 0 tăng dần, pool kết thúc NUL, `dbc_inventory`
đọc lại được); sai một điều là tự trả bản sao lưu. Tài nguyên cảnh đi kèm (273 tệp GL → CY, kể cả ô
minimap) áp lại bằng `Tools\game\scene_import_gl.py apply --that --maps <17 bản đồ>` (xem
`Registry\batches\2026-09-17-scene-import-gl.yaml`). Đặc tả: `Docs\specs\server\scenes-lo2_vi.md`.

### ✅ Phép kiểm ĐỨNG MÃI — `73-scenedef-manifest.py verify` (reapply-guard 19/09)

Mọi `verify` ở trên là **của một đợt**: nó đối chiếu với bản sao lưu sinh ra ngay trước lần `apply` của
chính đợt đó, nên sau khi đợt sau ghi tiếp thì nó hết hiệu lực (xem "Hai điều dễ hiểu nhầm" mục 1).
Hệ quả: **trước 19/09 không có phép kiểm nào trả lời được "243 dòng còn đủ không?"**.

`73-scenedef-manifest.py` giữ **bảng kê `data/scenedef-rows-manifest.json`** — đủ **25 ô đã giải mã**
của từng dòng, nhóm theo đợt — và trả lời câu đó trên **bất kỳ** file DBC nào, không cần bản sao lưu,
không phụ thuộc thứ tự đợt:

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\reapply\scenedef\73-scenedef-manifest.py verify     # phai ra: ok=true, MAT=0, LECH=0
```

| kết quả | nghĩa |
|---|---|
| `MAT` | ID có trong bảng kê nhưng **không có dòng nào** trên đĩa ⇒ **mất dữ liệu**, luôn là hỏng |
| `LECH` | có dòng nhưng ô khác bảng kê ⇒ đợt sau ghi đè, hoặc dòng đã bị trả về bản CY gốc |
| `CLIENT_RES` | mục riêng cho **15 dòng `client_res`**, in thẳng hậu quả `TDThrow` khi thiếu |

- `--dbc F` chạy trên **bản sao** (dùng cho diễn tập, xem dưới).
- **`LECH` là HỎNG, đó là mặc định và giữ nguyên** (chốt 19/09). `--chi-mat` là cờ **chọn vào**, chỉ dùng khi
  một nhánh **cố ý** sửa lại một dòng đã có bảng kê — khi ấy phải chạy `build` lại và nói rõ trong handoff.
  Đừng biến nó thành mặc định cho "đỡ ồn": một `verify` im lặng trước ô bị đổi chính là căn bệnh mục này
  chữa. `verify` ồn lên nghĩa là **dữ liệu đang trôi**, không phải nghĩa là chuẩn quá cao.
- **Bảng kê giữ ĐỦ 25 ô mỗi dòng (~133 KB), không rút xuống sha256 từng dòng** (chốt 19/09). Bản sha256 chỉ
  nói "có gì đó khác"; bảng kê đầy đủ nói **dòng nào, cột nào, đợt nào phải áp lại** — đúng thứ người đọc cần
  đúng lúc `verify` bắt được lỗi thật.

#### ⚙️ Đã tự động — `build_canonical_cy.py` tự gọi phép kiểm này và **báo ĐỎ**

Chốt 19/09: một công thức phải nhớ chạy tay sẽ **không** được chạy đúng vào lần người ta quên — tức đúng lần
nó cần thiết. Nên `Tools\pipeline\build_canonical_cy.py` (thẻ `CYS-REAPPLY-GUARD`) tự chạy
`73-scenedef-manifest.py verify` ở **hai** chỗ và **trả mã thoát khác 0** nếu thiếu dòng:

- ngay sau khi `--apply` ghi xong cây `Data` (lúc này 243 dòng gần như chắc chắn vừa bị xoá);
- ở cuối `--verify` — vì `--verify` chỉ so với `_manifest\files.tsv`, mà `files.tsv` là **ảnh chụp lúc dựng**
  nên nó **không biết** 243 dòng reapply: không nối thêm thì `--verify` vẫn xanh trên một cây đã mất sạch
  dòng `client_res`.

Khi thiếu, nó in khối `CYS-REAPPLY-GUARD` liệt kê `MAT`/`LECH` theo từng đợt, cảnh báo `client_res` kèm tên
đợt phải áp lại, và đường dẫn `_manifest\reapply-guard.json` có chi tiết từng dòng. Cờ `--skip-reapply-check`
để bỏ qua **có ý**; nếu không tìm thấy script kiểm thì nó cũng **đỏ**, không im lặng bỏ qua.
- **Thêm một đợt mới = thêm ĐÚNG MỘT DÒNG vào bảng `NGUON`** trong script rồi chạy `build` trên file đã
  đủ mọi bước. Không chép tay ID: `build` đọc thẳng các tệp kế hoạch của từng đợt.
- `diff --dbc A --dbc2 B` so hai DBC **theo từng ô đã giải mã** (đúng cách so bản khôi phục với file thật,
  vì sha256 sẽ khác mà vẫn đúng).

### 🔁 DIỄN TẬP TỪ BẢN SAO — làm được mà không đụng dữ liệu sống

`build_canonical_cy.py` sinh ra **679 dòng**. Bản 679 dòng đó nằm sẵn ở
`Assets\CanonicalCY\_generated\gui-cy\ConfigFolder\SceneDefineEx.txt` (sha `a90640b1…`, 140.255 byte) ⇒
**không phải chạy builder để diễn tập**. Mọi công cụ đều nhận `--dbc` và `--bak`, nên chạy trọn công thức
trên một bản sao là an toàn tuyệt đối:

```powershell
$T = "$env:TEMP\reapply-thu"; mkdir $T\dbc, $T\bak -Force | Out-Null
copy Assets\CanonicalCY\_generated\gui-cy\ConfigFolder\SceneDefineEx.txt $T\dbc\SceneDefineEx.txt
# ... chay 6 buoc y het o tren, chi them  --dbc $T\dbc\SceneDefineEx.txt --bak $T\bak  vao moi lenh ...
python -X utf8 Tools\reapply\scenedef\73-scenedef-manifest.py verify --dbc $T\dbc\SceneDefineEx.txt
python -X utf8 Tools\reapply\scenedef\73-scenedef-manifest.py diff `
       --dbc $T\dbc\SceneDefineEx.txt --dbc2 Assets\CanonicalCY\Data\ConfigFolder\SceneDefineEx.txt
```

**Đã chạy thật 19/09** (`Build\Logs\2026-09-19-reapply-guard\`): 679 → 682 → 692 → 746 → 792 → 799 → **800**;
bước 1–4 ra **đúng byte** `11ab72b8…` như phép đo 18/09 của `review-red`; `diff` với file sống ra
**`cung_tap_ID: true`, `SO_DONG_LECH_TUNG_O: 0`, 72.239 byte đầu của pool giống hệt** (sha256 khác —
`3de5c64c…` vs `07205688…` — và **khác là đúng**).

### 🔴 PHÉP KIỂM PHẢI BIẾT TRƯỢT — bằng chứng đo 19/09

Một `verify` chỉ biết nói OK thì không bảo vệ được gì. Bốn phép thử dưới đây **cố tình phá bản sao** rồi
xem công cụ có bắt không (kết quả JSON ở `Build\Logs\2026-09-19-reapply-guard\ket-qua\`):

| thử | phá cái gì | `71-dbc-dupe-check` | `72-dbc-pool-rows verify` | `73-scenedef-manifest verify` |
|---|---|---|---|---|
| N1 | dùng thẳng bản builder 679 dòng | `SO_ID_TRUNG = 0` ✅ **mù** | rc=1 | **rc=1 · MAT 121 · LECH 122** (= 243) · `CLIENT_RES MAT 15/15` |
| N2 | xoá đúng **15 dòng `client_res`** | `SO_ID_TRUNG = 0`, `cot0_tang_dan = True` ✅ **mù** | rc=1 (chỉ thấy 3080/3081) | **rc=1 · MAT 15**, liệt kê đủ 15 ID + tệp `.scene` |
| N3 | xoá 1 dòng `scenes-lo2` (410) | — | rc=1 `thieu dong 410` | rc=1 · MAT 1 |
| N4 | đổi **1 ô** (dòng 125 cột 4) | — | rc=1, in `trên đĩa` vs `kế hoạch` | rc=1 · LECH 1, chỉ đúng cột `szWXObjectName` |

**N2 là ca đắt nhất và là lý do tồn tại của `73-`**: mất 15 dòng `client_res` ⇒ mọi phó bản `TDThrow`,
mà phép kiểm cũ vẫn báo sạch tuyệt đối.

### Phía server

`R` = `/home/ubuntu/cys-test-20260913` trong WSL distro `TLBB`. Có **32 thay đổi dễ mất nếu ai đó
khôi phục `R` từ bản sao lưu cũ**: 16 hằng `g_ClientRes` và 16 dòng `configs/SceneDefineEx.txt`.

```powershell
wsl.exe -d TLBB -u root -- python3 -B <duong-dan-wsl>/66-move-clientres.py apply --out-dir <thu-muc-bang-chung>
```

Idempotent: đã dời rồi thì bỏ qua. Nhớ **server chỉ nạp bảng lúc khởi động** ⇒ phải restart.

---

## `ui-fit/` — bản dịch đã rút ngắn cho vừa khung giao diện

`build_canonical_cy.py` dựng lại `Assets/CanonicalCY/Data/InterfaceFolder` từ `Interface.axp` của CY
⇒ **xoá mọi chuỗi đã rút ngắn**. Công thức nằm ở đây.

**Luật của mảng này:** cách sửa chữ tràn khung là **RÚT NGẮN BẢN DỊCH**, **không nới container theo
tỷ lệ** (2.381 ô lưới phụ thuộc nhau; dự án đã phá vỡ giao diện vì việc đó). Vì vậy mọi bản vá trong
`data/ui-fit-patches.json` chỉ được phép: đổi một chuỗi hiển thị trong `*.lua` thành chuỗi ngắn hơn,
hoặc thêm một thuộc tính **không chạm hình học** (ví dụ `Tooltip`) vào `*.layout.xml`. Không đổi
`UnifiedSize` / `UnifiedPosition` / `AbsoluteSize` / `AbsolutePosition`.

Độc lập với `scenedef/` (khác file hoàn toàn) ⇒ chạy trước hay sau đều được.

### `ui-fit/81-ui-fit-2-strdict.py` — 3.426 chuỗi `StrDictionary` đã rút ngắn (ui-fit-2, 18/09)

Khác `80-`: lớp này **không** sửa file trong `Assets`, nó sửa **nguồn** `Registry/i18n/cy_vi_override.tsv`
(file **nằm trong git**). `build_canonical_cy.py --apply --gui cy` đọc đúng file đó ⇒ dựng lại cây Assets là
**tự có lại** bản rút ngắn, không mất. Script chỉ để áp nhanh và để **kiểm**:

```powershell
python -X utf8 Tools\reapply\ui-fit\81-ui-fit-2-strdict.py apply    # goi Tools\pipeline\cy_i18n_apply.py apply
python -X utf8 Tools\reapply\ui-fit\81-ui-fit-2-strdict.py verify   # phai ra: hong=0
```

`verify` đọc lại từ đĩa và kiểm **ba** thứ: đủ 3.426 khoá trong override · từng khoá khớp đúng giá trị trong
`StrDictionary.txt` đang chạy · **0 dòng còn dấu tiếng Việt dạng tổ hợp NFD** (nguồn ô vuông thứ hai).

Thứ tự so với `80-`: **độc lập** (khác file hoàn toàn), chạy trước hay sau đều được. Dữ liệu nguồn của lớp
này là `Tools/ui-fit/data/{short_vi,abbr_vi,nfd_fix}.tsv`.

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\reapply\ui-fit\80-ui-fit-strings.py plan
python -X utf8 Tools\reapply\ui-fit\80-ui-fit-strings.py apply --bak Build\reapply-bak
python -X utf8 Tools\reapply\ui-fit\80-ui-fit-strings.py verify     # phai ra: hong=0
```

`apply` idempotent (lần hai báo `da-co`, không ghi lại). Bản gốc được chép vào
`Build\reapply-bak\ui-fit\<đường dẫn tương đối>` trước lần ghi đầu tiên.
`verify` đọc **lại từ đĩa** và kiểm cả hai chiều: chuỗi cũ đã biến mất **và** chuỗi mới có mặt đủ số lần.

**Bẫy:** `.layout.xml` của CY dùng **CRLF**, `.lua` dùng **LF**. Script tự đổi ký tự xuống dòng của bản vá
theo từng file; nếu tự viết tay công cụ khác thì phải làm điều đó, không thì không khớp chuỗi nào.

Đo lại sau khi áp (phải ra đúng số của mốc):

```powershell
python Tools\ui-fit\measure_ui_text.py --out <thu-muc> `
       --cy-dict <thu-muc>\cy_strdict.tsv --dyn-digits 7
```

Cách dùng bộ đo và giới hạn của nó: `Tools\ui-fit\README_vi.md` và `Docs\specs\client\ui-fit_vi.md`.

---

## `pet/` — 180 trứng trân thú CY nở đúng con (server riêng, `300027.lua`)

Nhánh `pet-gc512` 18/09. Vấn đề: `R/configs/CommonItem.txt` là bảng **CY** nhưng `R/Game_2/Script` là cây **0.85**;
cột 13 đưa 490/499 trứng CY tới `scripts/obj/commonitem/300027.lua`, mà `g_petList` trong đó viết cho vật phẩm 0.85
cùng ID. Đo theo **tên** (không theo ID): 281 nở đúng, 17 nở ra con khác, 192 bị từ chối "Đạo cụ chưa mở".
Con số "169/517 lệch script" của 17/09 đo theo FILE là phép đo sai (đếm cả 珍兽笼 và sách kỹ năng 840005).

Công thức (script sống ở `Tools/server/pet_egg_map.py`, chạy trong WSL TLBB):

```bash
python3 /mnt/c/TLBB/085/CY-Source/Tools/server/pet_egg_map.py plan      # bảng đổi, không ghi
python3 /mnt/c/TLBB/085/CY-Source/Tools/server/pet_egg_map.py apply     # sao lưu R/backups/pet-eggmap-<UTC>/ rồi ghi (GBK, luac -p, idempotent)
python3 /mnt/c/TLBB/085/CY-Source/Tools/server/pet_egg_map.py verify    # PASS = 434 keep / 0 add / 0 replace / 56 skip
# server chỉ nạp script lúc khởi động hoặc `reload` (scenemanager reload_scripts qua debug console 16002)
```

Quy tắc: `珍兽蛋：X` cấp L → dòng `PetAttrTable` tên `X宝宝` có cột 3 (可携带等级) == L; `变异珍兽蛋：X` → `变异X`.
Hiệu chuẩn bằng 281 trứng đang đúng (270/274 có cột 3 = cấp trứng). Nhiều dòng cùng cấp / không có tên / tên
`废弃·神秘·雄·雌` thì **không đoán** (56 trứng, liệt kê trong `eggmap-plan-2026-09-18.json`). Mục cũ sai được giữ
dưới dạng chú thích `--CYS-PET egg-map old:`. Thứ tự: sau `pet_data.py` (bảng PetAttr 8 651 dòng), độc lập với
các công thức DBC client. `eggmap-plan-2026-09-18.json` là bảng đổi đã áp; `11-egg-truth-by-name.py` /
`12-egg-calibrate.py` là phép đo (đường dẫn `OUT` trỏ `Build/Logs/2026-09-18-pet-gc512`, đổi khi chạy lại).

## `costumes/` — toàn bộ thời trang CY mua được trên server riêng (costumes-all, 18/09)

Sửa **phía server** `R = /home/ubuntu/cys-test-20260913` (không đụng `Assets/`), nên `build_canonical_cy.py`
không xoá gì; thứ dễ mất là khi ai đó **khôi phục `R` từ bản sao lưu cũ**. Công thức thật là
`Tools/server/costume_data.py` (`survey | plan | apply | verify`, idempotent — chạy lần hai ra
`bo_qua_vi_da_co` đủ và không ghi byte nào); `costumes/90-costumes.ps1` chỉ gọi nó đúng thứ tự. Bốn
thứ nó ghi vào `R`: (1) đặt tên cột 51..200 của header `configs/ShopTable.txt` (server đọc ô hàng theo TÊN
cột nên trước đó mỗi shop chỉ đưa ra 50 ô); (2) 7 shop danh mục **431–437**, mỗi Visual đủ chuỗi ngoại
hình đúng một item (578 item, ≤ 96 ô/shop vì client `MAX_BOOTH_NUMBER = 96`); (3) NPC `万衣` / `时装店` (type 29) ở Đại Lý (257,121) / Lạc Dương (339,272) / Tô Châu (322,188) + script
**990011** `Game_2/Script/scripts/costume_shop.lua` + dòng đăng ký trong `scripts.lua` + mục dịch tại wire
`["万衣"] = "Vạn Y"` trong `GameServer/lualib/wire_names_vi.lua`; (4) `EquipExtraAttr` **không
nhập** (bảng server là đời cũ, ánh xạ cột không khớp 100 % — plan tự từ chối, chỉ báo).

Độc lập với `scenedef/`, `ui-fit/`, `pet/` (khác file). Ghi trong `flock .scene_install.lock` nên chạy song
song với các công cụ server khác vẫn an toàn.

```powershell
cd C:\TLBB\085\CY-Source
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\reapply\costumes\90-costumes.ps1          # plan + apply + verify
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\reapply\costumes\90-costumes.ps1 -Verify  # phai ra: "ok": true (59 phep kiem)
```

**Kỳ vọng sau khi chạy:** `verify` ok (**63 phép kiểm**), `catalog_items = 578`, `visuals_covered = 578/578`, header 200 ô,
ba `*_monster.ini` có `script_id=990011`. Rồi **restart server riêng** (bảng chỉ nạp lúc khởi động — nhắn
người điều phối gộp vào lần restart kế). Lần `plan` đầu mất ~5 phút vì đọc 880 mesh + `all.material`
qua `/mnt/c` để kiểm chuỗi ngoại hình; kết quả được cache ở `/tmp/costumes-chain.json` theo mtime.

**Bẫy:** `ShopTable.txt` CRLF nhưng `EquipExtraAttr.txt` LF, `*_monster.ini` LF GBK, Lua UTF-8 LF — công cụ
giữ đúng từng file; tự viết tay thì phải làm thế. Đặc tả: `Docs/specs/server/costumes-all_vi.md`.
**Lưu ý 18/09:** mua + mặc đã chạy thật (bot, Mongo), nhưng client CY-Source **chưa vẽ ô thời trang**
(`CysInventoryNet.cpp` chỉ áp 5 ô, không nạp `EquipDress.txt`) — xem đặc tả mục 8; đó là việc `Src/Client`, không
phải của công thức này.

## `ride/` — thú cưỡi của server riêng ở TRỤC ID CY (ride-finish 18/09)

Phạm vi: `R/configs/{Exterior_Ride,StandardImpact,CharMount,RideSeries,RideCollection}.txt` + 5 bản vá mã
(`cfghelper.lua`, `script_base.lua`, `scenecore.lua`, `skill_14.lua`, `define.lua`). Đặc tả:
`Docs/specs/server/ride-finish_vi.md`. **Không** đụng `Assets/` (client là điểm cố định), **không** đụng `EquipBase.txt`.

Ba dải ride id: `1..297` = đúng dòng CY · `400 + c` = đúc cho CharMount CY `c` không có ride CY (`551` = 大风)
· `1000 + r` = ride GL không có mesh bên CY, đỗ xe, `模型索引 = 1000 + g`, không item nào tới. Bậc tốc độ: CY có 10
bậc 10/20/40/55/70/75/80/85/95/125 ⇒ thêm cột `速度125` ở CUỐI `Exterior_Ride` (bản vá P1 đọc cột đó).

Độc lập với `scenedef/` và `ui-fit/` (khác file). `R/configs/StandardImpact.txt` dùng chung với `server-data`:
`apply` **trộn từ bảng sống trong `flock`**, chỉ thêm dòng mới (và chỉ xoá đúng 1.472 dòng `坐骑：` mà ride-data
đúc hôm 17/09 ở dải 64100..65571 khi không còn ai trỏ tới).

```powershell
# WSL, root. plan KHÔNG chạm R; apply từ chối nếu bảng sống khác lúc plan (sha256) → chạy plan lại.
wsl -d TLBB -u root -- bash -lc 'cd /mnt/c/TLBB/085/CY-Source &&
  python3 -B Tools/reapply/ride/ride_axis.py plan  --out /tmp/ride-axis &&
  python3 -B Tools/reapply/ride/ride_axis.py apply --staging /tmp/ride-axis &&
  python3 -B Tools/reapply/ride/ride_axis.py verify &&
  python3 -B Tools/reapply/ride/ride_server_patch.py apply &&
  python3 -B Tools/server/ride_data.py verify'
```

Kỳ vọng: `verify` `ok: true` — **364 dòng ride, 297/297 dòng CY đúng ID/model/tên, 0/3276 ô impact chết,
364/364 ride mọi bậc đúng `骑乘ID`, item Type 41 dùng được 1798/1798, CharMount 353 dòng / 53 dòng bay = CY,
0 dòng UTF-8**. `plan` lần hai trên R đã áp ⇒ `new_impacts: 0`, `apply` báo `unchanged` cả 5 bảng (idempotent,
đã đo). **Server chỉ nạp bảng và `services/*.lua` lúc khởi động ⇒ phải restart.** Sau restart tiêm
`Build/Logs/2026-09-18-ride-finish/do-dac/probe_ride2.lua` qua `debug_console` 16002 để đọc bảng trong bộ nhớ.

Hoàn tác dữ liệu: chép ngược `R/backups/ride-finish-<UTC>/*.txt` (thư mục **cũ nhất**) rồi restart;
hoàn tác mã: `ride_server_patch.py revert --backup R/backups/ride-finish-code-<UTC>`.

## Nội dung

| tệp | là gì |
|---|---|
| `ride/ride_axis.py` | trục ID thú cưỡi theo CY: `survey` / `plan` / `apply` / `verify` (đọc CY DBC + `client_GL` + `data/`, ghi 5 bảng R) |
| `ride/ride_server_patch.py` | 5 bản vá mã server đi kèm (`audit` / `apply` / `revert`), có `luac -p`, dấu `CYS-RIDE-FINISH` |
| `ride/trau_den_import.py` | **client** (chạy Windows `python -X utf8`): đưa thú cưỡi người dùng tự làm `Trâu Đen` (越南黑水牛) từ `client_GL` vào `Assets/CanonicalCY` — chép 3 tệp (mesh/skeleton/dds), nối khối `trau_den.obj` vào `all.obj`, nối `material trau_den` vào `all.material`, thêm dòng DBC `CharMount 1220` / `CharModelEx 9994` / `ExteriorRideCamera 1220` (chỉ thêm, nối pool). `plan` / `apply` / `verify` / `undo --bak`; sổ sách `Registry/batches/2026-09-18-trau-den-cy.{tsv,yaml}`. Server không cần đổi: ride 1180 đã trỏ 模型索引 1220 |
| `ride/data/trau_den.obj.block.xml`, `ride/data/trau_den.material.txt` | hai khối byte GBK/ASCII lấy nguyên văn từ `client_GL` để nối |
| `ride/data/server-*-gl-*.txt` | ảnh chụp 4 bảng GL của server TRƯỚC ride-data (198 ride / 201 CharMount / 6 series / 14 collection) — nguồn cho dòng đỗ xe và bảng ánh xạ |
| `costumes/90-costumes.ps1` | gọi `Tools/server/costume_data.py plan → apply → verify` trong WSL (`-Verify` chỉ kiểm, `-Survey` chỉ đo bốn con số) |
| `../server/costume_data.py` | công thức thật của costumes-all: header ShopTable 200 ô, 7 shop 431–437, NPC `万衣` + script 990011 + mục dịch tại wire, kiểm chuỗi mesh/material/texture của 583 Visual |
| (client) `Src/**` thẻ `CYS-DRESS` | bản vá **vẽ** thời trang: DBC 309 `EquipDress.txt`, ô `HEQUIP_DRESS = 16`, `UpdateDress`. Không thuộc `reapply` (git giữ `Src/`), nhưng công thức dữ liệu này vô nghĩa nếu bản vá đó bị hoàn tác — xem `Docs/specs/server/costumes-all_vi.md` mục 8 |
| `ui-fit/80-ui-fit-strings.py` | áp lại các chuỗi đã rút ngắn trong `InterfaceFolder` (`plan` / `apply` / `verify`) |
| `ui-fit/81-ui-fit-2-strdict.py` | áp lại + **kiểm** 3.426 chuỗi `StrDictionary` đã rút ngắn (nguồn: `Registry/i18n/cy_vi_override.tsv`, trong git) |
| `../ui-fit/data/short_vi.tsv` | 2.811 bản rút ngắn viết tay: khoá → chuỗi ngắn + lý do (px, khung) |
| `../ui-fit/data/abbr_vi.tsv` | 79 luật viết tắt dùng chung, chia mức 1/2/3 |
| `../ui-fit/data/nfd_fix.tsv` | 14 sửa tay cho dấu tiếng Việt NFC không ghép được |
| `ui-fit/data/ui-fit-patches.json` | bảng bản vá: `file` / `old` / `new` / `count` / `why` (có ghi số đo px biện minh cho từng chỗ) |
| `scenedef/70-client-scenedef-rows.py` | công cụ chính: nối/sửa dòng DBC cảnh. Mặc định `--dbc` trỏ thẳng `Assets/CanonicalCY`; cặp của cy4 nằm sẵn trong script. Cờ: `--pairs-file` `--ref-dbc` `--zero-wmap` `--giu-wmap` `--wmap-tu` `--bak` |
| `scenedef/70-sect-scenedef-rows.py` | bản riêng cho 15 bản đồ môn phái (khác bản trên, **không thay thế được cho nhau**) |
| `scenedef/71-dbc-dupe-check.py` | kiểm bất biến: 0 ID trùng, cột 0 tăng dần. **KHÔNG biết dòng nào phải có** — xoá sạch 243 dòng nó vẫn báo `SO_ID_TRUNG = 0`. Nhận `--dbc` / `--bak` / `--stage` từ 19/09 |
| `scenedef/73-scenedef-manifest.py` | **phép kiểm đứng mãi**: `build` chụp bảng kê, `verify` báo `MAT`/`LECH` theo từng đợt + mục `CLIENT_RES` riêng, `diff` so hai DBC theo từng ô. Thêm đợt = thêm 1 dòng vào bảng `NGUON` |
| `scenedef/data/scenedef-rows-manifest.json` | bảng kê **243 dòng** × 25 ô đã giải mã, nhóm theo đợt (sinh từ DBC sống 800 dòng `07205688…`, 19/09) |
| `scenedef/66-move-clientres.py` | dời 16 hằng `g_ClientRes` + 16 dòng DBC phía server |
| `scenedef/72-dbc-pool-rows.py` | **nối string pool** + THÊM/SỬA dòng từ giá trị 25 ô khai trong JSON (`plan` / `apply` / `verify` / `undo`); công cụ duy nhất được đổi pool. Dùng chung cho `scenes-lo2` (Bước 5) và `maps-kho48` (Bước 6) — mỗi đợt một tệp `--rows` riêng |
| `scenedef/72-make-rows-lo2.py` | sinh `data/scenes-lo2-rows.json` từ bảng client GL (24 cột, tiếng Việt) + dòng `huashan` dựng tay (không bảng nào có) |
| `scenedef/data/scenes-lo2-rows.json` | 19 dòng của đợt `scenes-lo2` (giá trị đầy đủ 25 ô + nguồn từng dòng) |

**Công cụ kiểm điểm vào (dùng trước mọi lượt đo cảnh):** `Tools\game\point_in_navmesh.py` — đọc `<map>.path`
(v1 `0x1000` / v2 `0x2000`, bố cục đã bẻ từ `PathLib.dll`) và trả lời điểm `(x,z)` nằm trong tam giác `flag=0`
(đi được), `flag=1` (bị chặn) hay ngoài lưới. **Điểm vào của bộ đo phải lấy từ `<map>_monster.ini`**, không tự
tính từ `.path` — đợt `scenes-lo2` mất một lượt client vì điểm (58.23,100.28) của `erengu` rơi vào tam giác 319
`flag=1`.
| `scenedef/data/maps-all-30-pairs.json` | 128 dòng của đợt mở thế giới |
| `scenedef/data/maps-instance-62-pairs-all.json` | 82 dòng của đợt phó bản (70 cảnh + 12 `client_res`) |
| `scenedef/data/maps-instance-ref-dbc-692.txt` | DBC mốc 692 dòng — **nguồn để chép nguyên văn từng ô**, vì các dòng CY gốc đã bị đợt `maps-all` ghi đè nên không lấy lại được từ file hiện tại |

---

## Hai điều dễ hiểu nhầm

1. **`verify` của một đợt CŨ báo `ok:false` là ĐÚNG THIẾT KẾ, không phải hỏng.** Khi đợt sau ghi
   thêm dòng, ảnh chụp sao lưu của đợt trước không còn khớp nữa. Bằng chứng đúng đắn là `verify` của
   **đợt mới nhất** + `71-dbc-dupe-check` + `90-audit-cuoi`.
   ⚠️ **Nhưng đừng dùng câu này để bỏ qua mọi `ok:false`.** Từ 19/09 có
   **`73-scenedef-manifest.py verify`** — nó **không** dựa vào bản sao lưu nên **không bao giờ hết hạn**;
   nó báo `ok:false` thì đó là **mất dữ liệu thật**, phải áp lại, không được giải thích cho qua.
2. **Vá dòng DBC ở ID cảnh `type=1` KHÔNG làm phó bản vào được, và không bao giờ làm được.** Phó bản
   lấy ID từ hồ dựng sẵn: `define.lua:2217` `COPY_SCENE_BEGIN = 10000`, `MAX_COPY_SCENE = 20` ⇒ client
   nhận **10001..10020**, trong khi ID lớn nhất của DBC là 4511. Đo chứng minh: 12/12 cảnh `type=1`
   rơi về cảnh 2, **kể cả cảnh 36 vốn đã có dòng DBC đúng từ trước** — cặp đối chứng sạch. Các dòng
   DBC này có giá trị vì **giữ bất biến** và vì `client_res`, không phải vì mở được phó bản.

---

## `Tools/pipeline/cy_i18n_apply.py` — cột hiển thị dịch Việt của các bảng DBC ConfigFolder (i18n-cy 17/09, i18n-2 18/09)

`build_canonical_cy.py --apply --gui cy` dựng lại `Assets/CanonicalCY/{Data,_generated/gui-cy}/ConfigFolder` từ
`Config.axp` của CY sẽ **xoá sạch** mọi bản dịch của lớp này (nó gọi đúng hai hàm nguồn nên tự sinh lại y hệt —
nhưng nếu ai chạy builder từ một nhánh CHƯA có commit thêm bảng, `DISPLAY`/`TABLES` cũ hơn ⇒ thiếu bảng mới).
Khác mọi mục khác trong file này: **script thật không nằm trong `Tools/reapply/`** mà ở `Tools/pipeline/` (đã được
git theo dõi vì không nằm dưới `/Assets/*` hay `/Build/*`, nên không cần chép thêm bản sao vào đây) — mục này chỉ
là điểm chỉ đường bắt buộc theo quy ước README.

```powershell
$py = 'C:\Program Files\Python313\python.exe'; $env:PYTHONUTF8 = 1
cd C:\TLBB\085\CY-Source
& $py -B Tools\pipeline\cy_i18n_apply.py plan      # xem sẽ đổi gì, không ghi
& $py -B Tools\pipeline\cy_i18n_apply.py apply     # ghi GEN + Data, tự sao lưu Build\Logs\2026-09-17-i18n-cy\backup\<stamp>, rồi verify
& $py -B Tools\pipeline\cy_i18n_apply.py verify    # đọc lại từ đĩa, so với bản dựng lại từ Config.axp + Registry\i18n\*.tsv
```


**Bảng `TABLES` trong `cy_i18n_apply.py` PHẢI liệt kê đúng tên mọi bảng đã thêm vào `DISPLAY` của
`Tools\pipeline\cy_item_text.py`** — có trong `DISPLAY` mà thiếu trong `TABLES` thì `plan/apply/verify` lặng lẽ bỏ
qua bảng đó (bẫy thật đã gặp 18/09, xem `Timeline/handoff/i18n-2.md` mục 5). Tính tới 18/09: `StrDictionary.txt`,
`XiuLianMiJi.txt`, `XiuLianBook.txt` (agent `i18n-cy`), `MonsterPaoPao.txt`, `ImpactSEData_V1.txt`, `CharTitle.txt`,
`Ability.txt`, `ChatMood.txt`, `CharHairGeo.txt`, `CharFaceGeo.txt`, `ScenePosDefine.txt` (agent `i18n-2`).

Bảng phân loại cột đầy đủ (chữ hiển thị dịch được / cột chết không ai đọc / khoá tài nguyên cấm dịch):
`Docs/specs/client/i18n-cy_vi.md` mục 2.

---

## `server-data/` — 329 ô impact vật phẩm + tỉ lệ cường hoá + 3 bảng tông môn (server-data 18/09)

Khác mọi mục trên: đích **không** phải `Assets/` mà là **cây server riêng**
`/home/ubuntu/cys-test-20260913` (WSL `TLBB`), thứ git của repo này không theo dõi. Nếu ai dựng lại
server từ bản gốc, hoặc `git checkout` trong cây R, ba thay đổi dưới đây biến mất mà **không dấu vết
nào trong CY-Source** — đó là lý do có mục này.

```bash
wsl -d TLBB -u root -- bash -lc 'cd /mnt/c/TLBB/085/CY-Source &&
  python3 -B Tools/reapply/server-data/90-server-data.py plan   &&
  python3 -B Tools/reapply/server-data/90-server-data.py apply  &&
  python3 -B Tools/reapply/server-data/90-server-data.py verify'
```

Bốn bước, **không phụ thuộc thứ tự lẫn nhau** (bốn đích khác nhau), cả bốn **idempotent**:

| # | công cụ | đích | kỳ vọng sau `verify` |
|---|---|---|---|
| 1 | `Tools/server/impact_map.py` | **362 ô** mang ID impact trong `Game_2/Script/scripts/**` (ô `g_Impact1/2`, hằng số **và biến** ở ô ID của ba hàm `SendSpecificImpactToUnit` / `CancelSpecificImpact` / `HaveImpactOfSpecificDataIndex`, bỏ qua chú thích) | `con_tro_sai(sua_duoc) = 0`, `luac_hong = []` |
| 2 | `Tools/server/enhance_rate.py` | khối quay của `LuaFnEquipEnhance` | `giai_doan = "fix"`, `luac = true` |
| 3 | `Tools/server/zongmen_tables.py` | thêm 3 file mới vào `configs/` | `ok = true`, `giong_nguon_sau_chuan_hoa = true` ×3 |
| 4 | `impact_map.py copy85` | **+18 dòng** `configs/StandardImpact.txt`, chép nguyên byte từ bảng 0.85 | lần hai báo `khong co gi de lam` |

⚠ Bước 4 **ghi vào `StandardImpact.txt`**, file mà `ride-finish` / `impact-data` cũng ghi. Nó tự chạy
trong `flock` `configs/.scene_install.lock` và **trộn lại từ bảng SỐNG ngay trong lock**, nên chạy
song song an toàn — nhưng đừng viết công cụ khác chép đè file staging lên bảng này.

**`apply` không restart, và cần restart hay không thì TUỲ ĐÍCH:**
- `configs/*.txt` (bước 3, 4) và `lualib/*.lua` (bước 2) — **phải restart**;
- `Game_2/Script/**` (bước 1) — `scriptenginer:try_load` (`lualib/scriptenginer.lua:118`) `require`
  từng script **lần đầu có ai dùng tới**, nên script chưa từng chạm sẽ đọc file mới **ngay, không cần
  restart**; script đã chạm rồi thì giữ chunk cũ tới `reload_scripts` hoặc restart.
  Vẫn nên restart một lần cho đồng nhất, nhưng **đừng kết luận "chưa restart nên chưa có tác dụng"**.

Nguồn thật của bước 1 và 2 là **chính hai bảng `StandardImpact.txt`** (CY ở `R/configs/`, 0.85 ở
`/home/ubuntu/configs/`) — công cụ tự tính lại ánh xạ trên bảng SỐNG mỗi lần chạy và **từ chối** nếu
ánh xạ không còn thoả bốn điều kiện, nên không có file dữ liệu tĩnh nào phải chép theo. Nguồn của
bước 3 là `C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Config\` (bản đổ text của CY, chỉ đọc).

Chi tiết + bẫy: `Docs/specs/server/server-data_vi.md`, `Timeline/handoff/server-data.md`.

## `Tools/server/trap_recollide.py` — 65 bản ghi `SpecialObjData.txt` phía CLIENT (trap-recollide 17/09)

Điểm chỉ đường bắt buộc theo quy ước ở mục "Khi thêm công thức mới vào đây" — **mục này thiếu cho tới
19/09**, nhánh `reapply-guard` rà ra bằng sổ cái của chính builder.

`build_canonical_cy.py` trích `Assets/CanonicalCY/Data/ConfigFolder/SpecialObjData.txt` từ `Config.axp`
⇒ **65 bản ghi ID 3000–3064 mà `trap-recollide` nối thêm sẽ mất**. Đo 19/09: bảng trên đĩa **1.908 bản ghi
× 63 cột, 514.592 byte, sha `9d7deb7c…`**; sổ cái `_manifest/files.tsv` ghi **498.212 byte** (= 1.843 bản ghi)
⇒ lệch **+16.380 byte**, đúng bằng 65 bản ghi. Mất chúng thì bẫy **mất hiệu ứng nhìn thấy** (không crash —
mọi chỗ dùng đều bọc `GetSpecialObjData() != NULL`).

Công thức thật là `Tools/server/trap_recollide.py` (`plan | apply | verify`, đã được git theo dõi vì không
nằm dưới `/Assets/*` hay `/Build/*`). `plan` dựng lại 65 bản ghi từ **dòng CY nguồn** chứ không từ bảng
client hiện tại (`trap_recollide.py:343-347`: `cl_add = [… if n not in cl_ids]` rồi `dbc_append(cl, index,
cy[o], n)`), nên sau khi dựng lại client nó **vẫn đủ dữ liệu để nối lại** — ⚠️ nhưng điều đó **chưa được
diễn tập**: đường dẫn bảng client là hằng số `CLIENT` (`trap_recollide.py:46`), **không có cờ `--client`**,
nên không thể chạy thử trên bản sao như `scenedef/`. Xem mục 4 của `Timeline/handoff/reapply-guard.md`.

Thứ tự: độc lập với `scenedef/`, `ui-fit/`, `material/` (khác tệp hoàn toàn).

```bash
wsl -d TLBB -u root -- bash -lc 'cd /mnt/c/TLBB/085/CY-Source &&
  python3 -B Tools/server/trap_recollide.py plan   --out /tmp/trap-recollide &&
  python3 -B Tools/server/trap_recollide.py apply  --staging /tmp/trap-recollide &&
  python3 -B Tools/server/trap_recollide.py verify'
```

Chi tiết: `Docs/specs/server/trap-data_vi.md` mục 7, `Timeline/handoff/trap-recollide.md`.

---

## Khi thêm công thức mới vào đây

Mỗi nhánh sửa dữ liệu trong `Assets/` hoặc `R/configs/` **phải** để lại ở đây: script `apply`
idempotent, dữ liệu nó cần, và một mục trong README này nói **thứ tự** so với các công thức khác.

Thêm ba điều từ 19/09 (nhánh `reapply-guard`):

1. **Khuôn lệnh là `plan` / `apply` / `verify` / `undo`** (mẫu: `host-2/70-sect-tables.py`). `undo` chỉ được
   hoàn tác khi chứng minh được file hiện tại đúng là thứ `apply` của mình sinh ra; không chứng minh được
   thì **từ chối**, đừng đè bản cũ lên việc của nhánh khác.
2. **Mọi lệnh phải nhận `--dbc` / `--bak`** (hoặc tương đương) để **diễn tập được trên bản sao**. Công thức
   không diễn tập được thì không ai kiểm tra được nó, và nó sẽ hỏng im lặng.
3. **Nếu nhánh thêm/sửa dòng `SceneDefineEx.txt`**: thêm **một dòng** vào bảng `NGUON` của
   `scenedef/73-scenedef-manifest.py`, chạy `build`, và commit `data/scenedef-rows-manifest.json` kèm.
   Thiếu bước này thì dòng của bạn **không có phép kiểm tồn tại** — đúng thứ đã làm mất 12 dòng `client_res`
   khỏi con số 211 của MOC.
Nếu công thức chỉ tồn tại trong `Build/Logs/`, coi như nó chưa tồn tại.

---

## `host-2/` — hai bảng tông môn `SectDesc.txt` / `SectInfo.txt` (server → client, 18/09)

`build_canonical_cy.py` dựng lại sẽ **không** tạo hai tệp này (chúng chỉ có ở server `R/configs`), nên sau mỗi lần dựng
lại phải áp lại. Nguồn đã ghim (GBK, sha256 trong `Registry/batches/2026-09-18-host-2-sect-tables.yaml`) nằm ngay
trong `host-2/data/`, không cần WSL.

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\reapply\host-2\70-sect-tables.py plan
python -X utf8 Tools\reapply\host-2\70-sect-tables.py apply     # chi THEM MOI; tep dich da co ma khac -> tu choi
python -X utf8 Tools\reapply\host-2\70-sect-tables.py verify    # phai ra: OK x2
```

Idempotent (lần hai báo `BO-QUA`). Ô chuỗi giữ nguyên byte GBK như các bảng cùng họ (`TalentInfo.txt`); chuyển UTF-8 /
dịch là việc của `i18n-cy`. Chưa có hàm host nào đọc hai bảng này (xem `Docs/specs/client/host-2_vi.md` mục 3).

---

## `material/` — mục `all.material` + dòng DBC `client_res` cho bản đồ nhóm `kho` (maps-kho48, 19/09)

Hai loại thay đổi, **cả hai đều bị `build_canonical_cy.py` dựng đè** (khác với tệp *nhập thêm* — cảnh,
model, texture — vốn chỉ bị `--verify` báo `extras`):

| tệp | vì sao mất khi dựng lại |
|---|---|
| `Assets/CanonicalCY/Data/MaterialFolder/all.material` | trích từ kho S4 `Material.axp` ⇒ **nằm trong kế hoạch dựng** |
| `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt` | như 4 bước `scenedef/` ở trên |

Texture `.dds` chép kèm thì **không mất** (tệp nhập thêm), nhưng lệnh `apply` bên dưới vẫn tự chép lại
nếu thiếu, nên chạy một lệnh là đủ.

### Áp lại — chạy **SAU** Bước 5 (`scenes-lo2`), kỳ vọng trước: 799 dòng

```powershell
cd C:\TLBB\085\CY-Source
$M = 'Tools\reapply\material'

python -X utf8 $M\80-mat-append.py apply  --rows $M\data\maps-kho48-rows.json `
    --bak Build\reapply-bak\maps-kho48 --that
python -X utf8 $M\80-mat-append.py verify --rows $M\data\maps-kho48-rows.json   # ok: true

python -X utf8 Tools\reapply\scenedef\72-dbc-pool-rows.py apply `
    --rows $M\data\maps-kho48-dbc-rows.json --bak Build\reapply-bak\maps-kho48
python -X utf8 Tools\reapply\scenedef\72-dbc-pool-rows.py verify `
    --rows $M\data\maps-kho48-dbc-rows.json
python -X utf8 Tools\reapply\scenedef\71-dbc-dupe-check.py   # SO_ID_TRUNG = 0, TONG_SO_DONG = 800

python -X utf8 Tools\game\scene_import_gl.py apply  --maps songliao --that
python -X utf8 Tools\game\scene_import_gl.py verify --maps songliao
python -X utf8 Tools\game\scene_import_gl.py registry
```

**Bước 6 làm số dòng DBC kỳ vọng thành 802** (Bước 1–5 ra 799):

| dòng | cho | bắt buộc? |
|---|---|---|
| **3079** | `client_res` của cảnh 47 (phó bản 宋辽边境) — đường chạy THẬT của `songliao` | **có**, giữ vĩnh viễn |
| **1350** | cảnh `type=0` 锁龙古塔一层 `longta_0` | **có**, giữ vĩnh viễn |
| **2300** | cảnh TẠM chỉ để đo `songliao` bằng client thật | **không** — gỡ sau khi đo xong |

Dòng 2300 nằm ở tệp rows **riêng** (`data\maps-kho48-dbc-rows-2300.json`) để `undo` gỡ được một mình nó:

```powershell
python -X utf8 Tools
eapply\scenedef:-dbc-pool-rows.py apply `
    --rows $M\data\maps-kho48-dbc-rows-2300.json --bak Build
eapply-bak\maps-kho48   # -> 802
wsl -d TLBB -u root -- python3 -B Tools/server/scene_install.py add --id 2300 `
    --name songliao-do-2300 --file songliao.scn --clientres 3079 --type 0 --active 1 --threadindex 20
```

**Vì sao phải có cảnh tạm 2300**: cảnh 47 mới là cảnh thật chạy `songliao.scn`, nhưng nó `type=1` và
công thức "tạm đặt `type=0`" của `scenes-lo2` **không áp được** — DBC đã có dòng ở ID 47 trỏ
`murenxiang.scene` nên `WorldManager.cpp:118` không bao giờ lui về `client_res`; và dòng 47 là **dữ liệu
sống** (cảnh 43 木人巷 dùng `clientres=47`). Chi tiết: `Timeline/handoff/maps-kho48.md` mục 5.0b.
**Công thức `scenes-lo2` chỉ đúng cho cảnh `type=1` mà DBC KHÔNG có dòng ở ID cảnh.**

Cả ba lệnh `apply` đều **idempotent** (lần hai báo `so_noi: 0` / `BO-QUA` / `bo_qua_da_co`).

### Vì sao `80-mat-append.py` không phải là thứ đã phá 60.161 vật liệu

Bản làm hỏng năm xưa đọc `all.material` bằng `errors='replace'` rồi **ghi lại cả tệp**. Công cụ này
**chỉ đọc `rb` và nối byte vào cuối** — không khối nào đã có bị chạm, không byte nào được giải mã rồi
mã hoá lại. Sau khi ghi nó đọc lại từ đĩa và kiểm 6 điều (kích thước, **phần đầu nguyên vẹn từng byte**,
số khối, tên mới có mặt, sha256 khối mới khớp GL, không sinh tên trùng); trượt một điều là **tự trả lại
bản sao lưu ngay trong cùng lần chạy**. Sao lưu: `Build/reapply-bak/maps-kho48/`.

Bằng chứng + phép đo bao phủ vật liệu: `Build/Logs/2026-09-19-maps-kho48/`,
`Timeline/handoff/maps-kho48.md`.

---

## `tangmen/` — Bước 7: 1 dòng DBC cho cảnh 2220 唐门 (tangmen, 20/09)

`maps-cy4` (17/09) thêm dòng cho **2221/2222/2223** nhưng **bỏ sót 2220** — bản đồ môn phái CY4 thứ tư.
Thiếu dòng thì `WorldManager.cpp:110` trượt và client lui về `clientres`; trước đợt này `clientres` của
`[scene2220]` là **1053 = `zijinkuafu_spring`**, mà bộ tệp `zijinkuafu_spring.*` **không có trong
`SceneFolder`** ⇒ bật cảnh lên là hỏng cảnh, không phải chỉ "sai bản đồ".

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\reapply\tangmen\90-scene2220-row.py apply   # 802 -> 803 dòng, pool KHÔNG đổi
python -X utf8 Tools\reapply\tangmen\90-scene2220-row.py verify  # ok:true
python -X utf8 Tools\reapply\scenedef\71-dbc-dupe-check.py       # SO_ID_TRUNG = 0, 803 dòng
```

**Bước 7 làm số dòng DBC kỳ vọng thành 803** (Bước 1–6 ra 802). Dòng mới là **bản sao 24 ô sau của dòng
CY 615** (`tangmen.Scene` / `tangmen.path`, `wmapX/Y` 692/520) — cùng khuôn với `maps-cy4`
(2221←678, 2222←731, 2223←824). **String pool không bị chạm một byte.**

Hai thay đổi phía server đi kèm (**cần restart**, xem `Timeline/handoff/tangmen.md`):

```bash
wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py \
    set --scene 2220 --key clientres --value 615
wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/scene_install.py enable --scenes 2220
wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/tangmen/91-dali-door212.py apply
```

`91-dali-door212.py` mở NPC 接引使 của Đường Môn ở Đại Lý (race 56003). **Phải làm HAI việc, thiếu một
là NPC "bật rồi mà không hiện"**: đổi `[monster212_off]` → `[monster212]` (`scenecore.lua:657` chỉ lặp
khoá `monster%d`) **và** bỏ dấu `;` ở `pos_x=;166.0000` (`inireader.lua:31` loại giá trị bắt đầu bằng
`;` ⇒ khoá `pos_x` không bao giờ được đặt ⇒ `world_pos.x = nil`).

`92-scene-res-check.py` (chạy trong WSL) là phép kiểm **tài nguyên đúng bằng sha256, không bằng tên** —
lớp bẫy đã cắn dự án bốn lần. Nó so byte navmesh của server (`<scn>.navmapname`) với navmesh client
(`szRegionFile` của dòng DBC mà client thật sự tra). **Nó có cách để trượt**: trên 197 cảnh `type=0`
đang bật ra **52 ĐẠT / 141 LỆCH_HASH / 4 THIẾU** — byte-giống-hệt là **bằng chứng đủ**, không phải
điều kiện cần; xem `Timeline/handoff/tangmen.md` mục 6.

---

## `npcdata/` — 84 dòng NPC đối thoại trong `MonsterAttrExTable.txt` (npc-data, 19/09)

`build_canonical_cy.py --apply` dựng lại `ConfigFolder` từ kho `Config.axp` của CY ⇒ **xoá sạch 84
dòng này**, và khi ấy **cửa duy nhất vào bản đồ Quỷ Cốc đóng lại** (NPC 接引使 đứng ở Đại Lý không bấm
được nữa). Chi tiết vì sao: `Timeline/handoff/npc-data.md`.

Nguyên nhân gốc: đợt `cs3c-tables` 14/09 gộp **1.015 dòng chỉ-GL** (`cys_gl_only`) vào **bảng server**
nhưng **không** gộp vào **DBC client** ⇒ 84 race mà server khai `是否可以交互 = 1` không có dòng phía
client ⇒ `OnDataChanged_RaceID` tắt `OSF_RAY_QUERY` ⇒ **không bấm được bằng bất kỳ cách nào**.

Cách dựng dòng: **chép nguyên 73 ô của dòng CY CÙNG TÊN** (82/84 ca; 2 ca còn lại chọn tay cùng môn
phái), chỉ ghi đè `[0]` id, `[5]` `是否可以交互`, `[70]` `阵营`. Vì vậy **string pool không đổi một byte**
và ô model chắc chắn hợp lệ. **Đừng** chép dòng 56xxx từ `client_GL`: hai nhánh dữ liệu **không dùng
chung ID** (84/84 khớp theo ID nhưng chỉ 68/83 khớp theo TÊN).

```powershell
cd C:\TLBB\085\CY-Source
python -B Tools\reapply\npcdata\80-monsterattr-rows.py plan
python -B Tools\reapply\npcdata\80-monsterattr-rows.py apply
python -B Tools\reapply\npcdata\80-monsterattr-rows.py verify   # ket_luan: DAT, 0 MAT, 0 LECH
```

Kỳ vọng sau khi áp: **29.052 dòng** (28.968 + 84), **73 cột**, pool **204.983 byte không đổi**,
`server_only` còn 70 và trong đó **NPC đối thoại thiếu = 0**.

`verify` **không** dựa vào bản sao lưu: nó đối chiếu với bảng kê trong git
(`data/npc-data-manifest.json`, 84 dòng × 73 ô) nên **không hết hạn** khi đợt sau ghi đè.
Đối chứng âm đã đo (`Build/Logs/2026-09-19-npc-data/70-negctl.json`): xoá một dòng ⇒ `so_MAT` bắt đúng;
sửa một ô ⇒ `so_LECH` bắt đúng; chạy `apply` hai lần ⇒ trùng **từng byte**.
Sao lưu: `Build/reapply-bak/npc-data/`.

---

## `teleport-dali/` — đích "về Đại Lý" của 4 NPC phái CY4 trên SERVER RIÊNG (teleport-dali, 20/09)

**Mất khi nào:** dựng lại / clone lại server riêng từ server gốc (`/home/ubuntu` → `cys-test-*`). 4 tệp
`Game_2/Script/scripts/obj/cy4/cy4_{congren,guigu,taohuadao,tangmen}_travel.lua` của server gốc ghi
`destination_scene=2,destination_x=241,destination_z=141` — **đúng với bản đồ `dali` CŨ** của cặp `client_GL` + server
gốc, nhưng **ở ta cảnh 2 là `dali_new_320`** và (241,141) rơi vào **bồn hoa có lan can đá** (`dali_new_320.path`
tri 10884, `flag=1`, sâu 2,6 ô) ⇒ người chơi từ **bất kỳ phái nào trong 4 phái mới** về Đại Lý là **đứng im, bấm đâu
cũng không đi** (người dùng báo 20/09: *"kẹt map ở đại lý khi dịch chuyển về"*). Chi tiết: `Timeline/handoff/teleport-dali.md`.

**Vì sao đợt dời 241,141→253,121 của `cs3a-maps` (14/09) bỏ sót:** bộ quét bắt **chữ số tại chỗ gọi** (`…, 2, x, z`);
`cy4_npc.lua:141` truyền **biến** (`c.destination_x`) và con số nằm trong bảng `cfg`. ⇒ **Ai viết bộ quét đích dịch
chuyển mới: phải bắt cả dạng `destination_x=`/bảng, không chỉ chữ số trong lời gọi.**

```powershell
wsl.exe -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/teleport-dali/40-sua-cy4-ve-dali.py kiem
wsl.exe -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/teleport-dali/40-sua-cy4-ve-dali.py apply   # undo = tra ve ban goc
wsl.exe -d TLBB -u root -- lua5.4  /mnt/c/TLBB/085/CY-Source/Tools/reapply/teleport-dali/41-lua-ab.lua /home/ubuntu/cys-test-20260913/Game_2/Script
```

Kỳ vọng: `kiem` in 4 dòng `DA VA (253,121)`; `41-lua-ab.lua` in 4 dòng `… scene=2, x=253, z=121 …` (chạy nó trên
`/home/ubuntu/Game_2/Script` thì ra `x=241, z=141` — đó là **đối chứng âm**). Sửa ở mức byte, cùng độ dài (kích thước tệp
không đổi), idempotent bằng cấu trúc (luôn dựng lại từ bản sao lưu gốc), `luac -p` sau khi ghi.
**Ca thứ hai cùng lớp, cùng bản đồ** — `scripts/event/dali/edali_newquest_016.lua` (NPC 云飘飘, nhiệm vụ "Bắt Trân thú", lối ra
phó bản "Hậu Hoa Viên" → Đại Lý) giữ `g_Back_X = 275` trong **biến**; (275,50) BỊ CHẶN (tri 8659), (276,50) đi được và là
đúng con số `cs3a-maps` đã dùng cho hai script anh em dạng chữ số. Công thức: `42-sua-newquest016.py kiem|apply|undo` (cùng khuôn).

Sao lưu: `/home/ubuntu/cys-test-20260913/backups/teleport-dali-20260920/`. **Script nạp lười rồi CACHE**: sửa khi server
đang chạy thì phải `Tools/server/pet_egg_map.py reload --port 16002`; sửa khi server tắt (như 20/09) thì không cần gì thêm.
