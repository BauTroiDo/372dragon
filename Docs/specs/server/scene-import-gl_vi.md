# Nhập tài nguyên cảnh từ nhánh GL sang bộ dữ liệu CY — agent `scene-import-gl` (17/09/2026)

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng/số). **[SL]** suy luận.
`R` = `/home/ubuntu/cys-test-20260913` (server riêng skynet trong WSL `TLBB`).
Bằng chứng: `Build\Logs\2026-09-17-scene-import-gl\`. Công cụ: `Tools\game\scene_import_gl.py`.
Kê khai nguồn: `Registry\batches\2026-09-17-scene-import-gl.yaml` + `.tsv`.
Không restart server, không sửa `Src\`, không đụng `SceneDefineEx.txt`, không commit.

> **ĐỌC HAI DÒNG NÀY TRƯỚC.**
> 1. Việc chép tài nguyên **chạy được và đã kiểm**: 3 bản đồ, 34 tệp, `verify` đọc lại từ đĩa
>    báo **0 tham chiếu thiếu**. Nhưng **chưa cảnh nào được client thật vẽ**, vì thiếu bước 2.
> 2. **Bước 2 bị chặn bởi một phát hiện kỹ thuật, không phải do thiếu thời gian**: muốn client
>    vẽ bản đồ vừa nhập thì phải có dòng DBC trỏ tới `<map>.Scene`, mà **chuỗi đó không tồn tại
>    trong string pool** của `SceneDefineEx.txt` — của cả 68 bản đồ, ở cả file hiện tại lẫn bản
>    sao lưu 692 dòng. Mọi công cụ hiện có chỉ **chép ô offset** giữa các dòng nên không tạo
>    được chuỗi mới. Mục 6 nói chính xác phải làm gì.

---

## 1. Kết quả một dòng

| | trước | sau |
|---|---|---|
| Bản đồ có `.Scene` bên CY (`SceneFolder` + `Scene2Folder`) | 511 | **514** (+3) |
| Tệp nhập từ GL | 0 | **34** (4.649.551 byte) |
| Bản đồ nhập xong, `verify` 0 tham chiếu thiếu | 0 | **3** |
| Bản đồ **client thật đã vào và vẽ đúng** | 0 | **0** ← xem mục 6 |
| Cảnh `type=0` đang bật `THIEU`/`SAI` (bất biến số 1) | 0 | **0** ← giữ nguyên |
| `SceneDefineEx.txt` (client) | 792 dòng | **792 dòng, sha256 y hệt** — tôi không đụng |

Ba bản đồ: **`huashan`** (cảnh 125 华山绝顶, `type=0`, 37 quái), **`shengsileitai`** (cảnh 410
生死擂台, `type=0`, 1 quái), **`zhulin`** (cảnh 49 竹林, `type=1`, 81 quái).

---

## 2. Đo trước: con số thật khác con số trong đề bài [DK]

Đề bài nói 62 cảnh (13 của `maps-instance` + 49 của `maps-all`). Đo lại trên đĩa
(`scripts\11-recon-full.py` → `11-thieu-scene-full.json`) ra bức tranh rộng hơn và chính xác hơn:

| nhóm | cảnh | bản đồ |
|---|---|---|
| Cảnh (mọi `active`) mà CY **không có** `.Scene` | **299** | **98** |
| … trong đó **GL có** `.Scene` | **70** | **68** |
| … trong đó GL cũng không có | 229 | 30 |

229 cảnh GL-không-có gần như toàn bộ là `type=4` (thành bang hội, 220 cảnh / các bản đồ `PCity*`),
cộng `fengmingzhen`, `cangjingge_xiaochang`, `erengu_1` — **ngoài phạm vi đợt này**. [DK]

70 cảnh GL-có chia theo `(type, active)`: `('0','0')` 50, `('1','1')` 13, `('1','0')` 13,
`('0','1')` 3. [DK]

### 2.1 Trừ ngay 4 bản đồ `cy4_*` — chúng KHÔNG thiếu gì cả [DK]

`cy4_guigu` / `cy4_taohuadao` / `cy4_congren` / `cy4_tangmen` xuất hiện trong danh sách vì tên
`.scn` phía server là `cy4_*`, nhưng dòng DBC của chúng trỏ `guigu.Scene` / `taohuadao.Scene` /
`congren.Scene` / `tangmen.Scene` — **và bốn tệp đó CÓ ở CY**, với **0 tham chiếu thiếu**
(mục 3.1). Bản `cy4_*.Scene` bên GL là dòng dõi khác, chép sang chỉ tạo rác. **Loại.**

⇒ Còn **64 bản đồ** thực sự đáng nhập.

### 2.2 Trừ tiếp 8 bản đồ server không dựng được [DK]

`scripts\17-server-files.sh` kiểm `R/Game_2/Scene/<map>.{scn,path,_monster.ini}`:

| bản đồ | cảnh | thiếu phía server |
|---|---|---|
| `zijincheng` `zijinnei` `zijinwai1..4` | 742, 745–749 | **không có `.scn`, không có `.path`** |
| `_pingpan_1` | 42 | **không có `.scn`** |
| `petislandhj` | 41 | **không có `.path`** |

Chép nghệ thuật cho chúng là vô nghĩa lúc chạy: server không tạo nổi cảnh. **Loại khỏi kế hoạch
nhập, ghi lại để khỏi ai đo lại.** [DK]

---

## 3. Phép đo quyết định: một cảnh "đủ tài nguyên" nghĩa là gì

Chỉ có `.Scene` là **chưa đủ**. `.Scene` là XML tham chiếu tiếp:

| tham chiếu | thuộc tính trong `.Scene` | giải ra đâu |
|---|---|---|
| mesh | `<Property name="mesh name" …>` | `Model*Folder` (8 thư mục, **cùng một nhóm tài nguyên `General`**) |
| model | `<Property name="model name" …>` | như trên |
| hệ hạt | `<Property name="particle system name" …>` | `EffectFolder\all.particle` |
| vật liệu | `<Property name="material" …>` | `MaterialFolder\all.material` |
| texture địa hình | `<texture filename="…">` trong `<map>.Terrain` | `BrushesFolder` (**có thư mục con**) |

Nhóm tài nguyên lấy từ `Build\world-gui\stage-fps-daiviet\Bin64\WXResources.cfg`: `[General]` gồm
mọi `Model*Folder` + `Material*Folder`, `[Scene]` = `SceneFolder` + `Scene2Folder`,
`[Brushes]` = `BrushesFolder`. Nên đặt mesh mới vào `ModelFolder` hay `Model5Folder` đều tra được;
công cụ **soi gương GL** cho dễ đối chiếu về sau. [DK]

### 3.1 Đối chứng — ngưỡng "0 thiếu" là đúng, không phải khắt khe quá [DK]

`scripts\16-deps.py` chạy đúng phép đo đó trên các cảnh **CY đang vẽ đúng**:

| bản đồ đang chạy | mesh | model | hạt | vật liệu | texture | **thiếu** |
|---|---|---|---|---|---|---|
| `luoyang_new` | 0/421 | 0/15 | 0/16 | 0/1 | 0/35 | **0** |
| `dali_new_320` | 0/288 | 0/5 | 0/14 | 0/2 | 0/41 | **0** |
| `suzhou_new` | 0/500 | 0/12 | 0/16 | 0/2 | 0/35 | **0** |
| `songshan` | 0/131 | 0/2 | 0/6 | 0/3 | 0/18 | **0** |
| `bianjing` | 0/824 | 0/29 | 0/3 | **1**/3 | 0/20 | 1 |
| `guigu` | 0/206 | 0/9 | 0/16 | **1**/3 | 0/11 | 1 |

**mesh/model/hạt/texture: 0 thiếu ở mọi cảnh đang chạy.** Chỉ cột `material` (thuộc tính `material`
của `.Scene`, thường là nước/dung nham) có 1 mục thiếu ở hai cảnh vẫn chạy tốt ⇒ trục đó **dung
thứ được**, các trục kia thì không. Vì vậy công cụ lấy **0 thiếu** làm điều kiện nhập. [DK]

### 3.2 BẪY đã sập và đã gỡ: tên tệp trên đĩa là **byte GBK đọc nhầm thành cp1252** [DK]

Lần đo đầu báo 8.916/9.033 mesh "thiếu" — sai hoàn toàn. Nguyên nhân: `.Scene` ghi tên bằng
**UTF-8** (`0树木/将军柏.mesh`) còn tên trên đĩa là `0Ê÷Ä¾\½«¾ü°Ø.mesh`, tức
`'0树木'.encode('gbk').decode('cp1252')`. Phải đổi mã **cả từng đoạn thư mục lẫn tên tệp** rồi mới
so. Sau khi sửa: 3.264/9.033 — và đối chứng ở 3.1 về 0.

```python
ten_that = lambda n: n.encode('cp1252').decode('gbk')   # dia  -> that
ten_dia  = lambda t: t.encode('gbk').decode('cp1252')   # that -> dia
```

Hai hàm này nằm trong `Tools\game\scene_import_gl.py`. **Ai đo tài nguyên client mà không đổi mã
tên tệp thì mọi con số đều sai.** [DK]

### 3.3 Phân nhóm 68 bản đồ theo chi phí thật [DK]

`scene_import_gl.py list` (→ `20-plan-all.json`):

| nhóm | nghĩa | số bản đồ |
|---|---|---|
| **`sach`** | chép thư mục cảnh là xong: 0 mesh/model/texture/hạt/vật liệu thiếu | **13** |
| **`themep`** | thêm vài tệp mesh/model/texture, **vẫn 0 mục phải thêm vào `all.*`** | **7** |
| **`kho`** | còn phải thêm mục vào `all.material` / `all.particle` | **48** |

- `sach` (13): `bianguan_1..4`, `dumuchang`, `huomuchang`, `jiaofei`, `yanziwu`, `shengsileitai`,
  `yewai`, `zhulin`, `zijinnei`, `zijinwai2`.
- `themep` (7): `huashan` (1 mesh), `zijinwai1` (1), `PhoenixMaze` (4 texture),
  `huanjing_1..4` (5 model mỗi cảnh).
- `kho` (48): từ `songliao` (3 vật liệu) tới `cy4_congren` (187). `wedding_*`, `longta_*`,
  `yaota*`, `shenjing_*`, `changchungu_*`, `kunwu`, `sr_rift`, `mantuoshanzhuang*`…

**Ranh giới `kho` là có chủ đích, không phải lười.** `all.material` là **GBK**; bài học cũ:
đọc `errors='replace'` rồi ghi đè đã phá **60.161 vật liệu**. `all.effect`/`all.particle` thì một
dòng chú thích làm parser chết im lặng. Đợt này **không chạm một byte nào** vào ba tệp đó —
công cụ chỉ chép **tệp mới**, và tự loại mọi bản đồ cần sửa chúng. [DK]

---

## 4. Đã làm gì — lô 1

`Tools\game\scene_import_gl.py apply --maps huashan,shengsileitai,zhulin --that`

| bản đồ | cảnh | type | quái | tệp chép | byte |
|---|---|---|---|---|---|
| `huashan` | 125 华山绝顶 | 0 | 37 | 12 (11 tệp cảnh + 1 mesh) | 2.774.594 |
| `shengsileitai` | 410 生死擂台 | 0 | 1 | 11 | 1.092.469 |
| `zhulin` | 49 竹林 | 1 | 81 | 11 | 782.488 |
| | | | | **34** | **4.649.551** |

Mesh duy nhất phải thêm: `华山/白石亭子.mesh` (32.165 B) — GL để ở `ModelFolder`, 110 mesh anh em
của `huashan` bên CY cũng ở `ModelFolder`, nên đích là `ModelFolder\»ªÉ½\°×Ê¯Í¤×Ó.mesh`. [DK]

`scene_import_gl.py verify` (đọc lại từ đĩa, không tin biến trong bộ nhớ):

```
ok: True  dat: 3  hong: 0
  huashan       tep=11  loi=[]   thieu {mesh:0, model:0, texture:0, particle:0}
  shengsileitai tep=11  loi=[]   thieu {mesh:0, model:0, texture:0, particle:0}
  zhulin        tep=11  loi=[]   thieu {mesh:0, model:0, texture:0, particle:0}
```

`verify` còn đối chiếu **sha256 từng tệp với bản kê khai** — lệch là báo lỗi. [DK]

### 4.1 Kê khai nguồn — điều kiện người dùng đặt ra [DK]

Mỗi tệp một dòng, trả lời được "tệp này từ đâu ra":

| nơi | nội dung |
|---|---|
| `Build\Logs\2026-09-17-scene-import-gl\manifest.jsonl` | 34 dòng JSON: `dich_CY`, `nguon_GL`, `sha256`, `kich_thuoc`, `ngay`, `canh_dung` (ID/tên/type/active), `the` = `"NGUON=GL (Assets/Canonical) - CHO BAN CY THAT"` |
| `Registry\batches\2026-09-17-scene-import-gl.yaml` | sổ sách người đọc: tổng, theo bản đồ, lệnh hoàn tác, lệnh áp lại |
| `Registry\batches\2026-09-17-scene-import-gl.tsv` | bảng tra từng tệp, có cột `ten_that` (tên đã giải mã GBK) |

Cả hai tệp `Registry` **sinh lại được** bằng `scene_import_gl.py registry`, nên không bao giờ lệch
với `manifest.jsonl`. Hoàn tác: `scene_import_gl.py undo --maps <ds> --that` (xoá đúng các tệp đã
kê khai, không đụng tệp CY gốc).

### 4.2 Bất biến sau khi làm [DK]

`scene_install.py survey --all` (`30-survey-cuoi.json`): `type=0` đang bật **195, OK 195,
THIEU 0, SAI 0**. `type=1` 73 OK / 13 chưa; `type=4` 221 chưa — cả hai **y như trước đợt này**.
`SceneDefineEx.txt` client: **792 dòng, sha256 `11ab72b8…`, 151.555 byte** — trùng khít con số
`maps-instance` ghi lúc họ dừng ⇒ **không ai đụng tệp đó, kể cả tôi**.

---

## 5. Vì sao chép an toàn — ba luật của công cụ [DK]

1. **`Assets\Canonical` (GL) chỉ đọc.** Công cụ không có đường ghi vào đó.
2. **Không bao giờ ghi đè một tệp CY đã có.** Trùng tên ⇒ `bo_qua_da_co`, ghi log. Nhờ vậy
   `apply` idempotent và không thể phá dữ liệu CY đang chạy. Lô 1: `bo_qua_da_co = 0`.
3. **Không chạm `all.material` / `all.effect` / `all.particle`.** Bản đồ nào cần là vào nhóm `kho`.

Thêm: `apply` giữ khoá tệp (`.scene_import_gl.lock`) nên chạy song song với agent khác vẫn an toàn;
mọi tệp chép bằng `shutil.copy2` (giữ mtime, dễ nhận ra tệp nhập).

### 5.1 Ba khác biệt định dạng GL↔CY đã kiểm, **không** phải sửa [DK]

| khác biệt | kết luận |
|---|---|
| GL không có `.Region` (8/546), CY có (424/466) | `grep -rn "\.Region" Src/` → **0 kết quả**: client CY-Source **không đọc** `.Region`. Bỏ qua được. |
| GL dùng `.newhdrbloom` + `.hdr-new`, CY dùng `.hdr` | `CYSSceneFiles.cpp:167-187` đọc **cả hai**, và cả hai đều tuỳ chọn (`.hfog` có mặc định khi vắng). |
| Tên tệp cảnh phân biệt hoa/thường | Chỉ mục của công cụ dùng chữ thường, chép giữ nguyên tên gốc GL. |

---

## 6. **CÁI CHẶN: không có dòng DBC nào tạo được cho 68 bản đồ này** [DK]

Đây là phát hiện quan trọng nhất của đợt, và nó quyết định bước tiếp theo.

### 6.1 Chuỗi bằng chứng

1. Client tra bản đồ bằng **ID cảnh SERVER ở cột 0** của `SceneDefineEx.txt`
   (`TDDBC_Struct.h:996`, `WorldManager.cpp:96-110`). Dòng đó mang tên tệp `.Scene` ở **cột 4**
   và `.path` ở **cột 5**, cả hai là **STRING**.
2. DBC nhị phân `00CCBBDD` không lưu chuỗi trong ô; ô chỉ chứa **offset vào string pool**
   (`TLBB_DBC.cpp:229-243`). Muốn một dòng mang `huashan.Scene` thì **pool phải có sẵn chuỗi đó**.
3. `scripts\15-pool.py` quét toàn bộ pool (72.239 byte, 3.011 chuỗi riêng biệt):
   **0/68 bản đồ có chuỗi `<map>.Scene`.** Kiểm lại bằng tìm byte thô trên cả
   `SceneDefineEx.txt` hiện tại **và** `ref-dbc-692.txt` (bản sao lưu trước lượt ghi của
   `maps-all`): vẫn **0/68**. Vài lần "trúng" là chuỗi con của bản đồ khác
   (`shuhe_yewai01.Scene`, `QNYH_yewai.Scene`, `new_yanziwu.scene`), không dùng được.
4. Công cụ hiện có `70-client-scenedef-rows.py` **chỉ chép ô** giữa dòng nguồn và dòng đích, và
   tự chốt `assert d['pool'] == d['pool_goc']` — **thiết kế của nó là không bao giờ đổi pool**.

⇒ **Không có đường nào tạo dòng DBC cho 68 bản đồ này bằng công cụ hiện có.** Đây là lý do
`maps-all` viết "không có dòng DBC nào mang bản đồ này" cho 49 cảnh: không phải họ chưa tìm kỹ,
mà chuỗi thật sự không tồn tại.

### 6.2 Cách chữa, đã kiểm tính khả thi trên mã đọc DBC [SL, dựa trên [DK] mục 6.1]

Nối thêm chuỗi vào **cuối pool** rồi cập nhật `m_nStringBlockSize` trong header. An toàn vì
`OpenFromMemoryImpl_Binary` (`TLBB_DBC.cpp:148-250`):

- đọc `m_nStringBlockSize` **từ header**, cấp phát đúng bấy nhiêu rồi `memcpy` — không có hằng số
  kích thước nào ở nơi khác;
- **chặn biên offset**: `pString = m_pStringBuf + (nOffset < m_nStringBufSize ? nOffset : 0)`;
- ép `m_pStringBuf[m_nStringBufSize-1] = 0`, nên pool **phải kết thúc bằng NUL** (chuỗi vốn đã vậy);
- kiểm tổng kích thước tệp ở đầu hàm cũng tính theo header.

Không chỗ nào đánh chỉ mục pool theo **số chuỗi**, nên nối thêm không xê dịch offset cũ. [DK cho
từng dòng mã; [SL] cho kết luận "làm được", vì **chưa chạy thật**.]

Ngoài chuỗi, dòng mới cần 25 cột. Nguồn độc lập đã có sẵn: **bảng `SceneDefineEx.txt` phía SERVER**
(`R/configs`, 24 cột, dòng dõi GL, GBK) có dòng đầy đủ cho các bản đồ này — W×H, `.Scene`, `.path`,
`.wCollision`, minimap, far/near clip, imageset tên thành. Ví dụ `zhulin` (dòng 55):

```
81  竹林  128  128  zhulin.scene  zhulin.path  zhulin.wCollision  zhulin.jpg
120  60000  zhulinscene  0 0 0 0  15000  10  Sign1  MiniMap_Icon  YiPinTang_Normal
MiniMap_Icon  YipinTang_Hover  竹林  0.2;0.2
```

Dựng dòng client = chép cột 0..23 của dòng server, **thay cột 0 bằng ID cảnh của server ta**
(49, không phải 81), **đặt cột 11..14 = 0** (toạ độ bản đồ thế giới — luật `--zero-wmap` của
`maps-all`, tránh vẽ hai biểu tượng chồng nhau), **thêm cột 24 = 0** (CY 3.71 có thêm một cột;
phân bố hiện tại 762 số 0 / 25 số 1 / 5 số 4). Đọc bảng server bằng
`scripts\24-server-sde.py`. [DK]

---

## 7. Việc chưa làm và vì sao

| việc | trạng thái |
|---|---|
| Nhập 17 bản đồ `sach`/`themep` còn lại (~200 tệp) | **chưa** — dừng theo yêu cầu chốt mốc, không mở lô mới |
| Dòng DBC cho bản đồ đã nhập | **chưa** — mục 6, cần công cụ nối pool |
| Bật cảnh + restart server + đo bằng client thật | **chưa** — phụ thuộc dòng DBC |
| 48 bản đồ nhóm `kho` | **chưa** — cần sửa `all.material`/`all.particle`, rủi ro cao, nên làm sau khi mục 6 xong và đã có một cảnh chứng minh được |
| 8 bản đồ server không dựng được (mục 2.2) | **không làm** — chép cũng vô ích |
| 4 bản đồ `cy4_*` | **không làm** — không thiếu gì (mục 2.1) |

**Chưa chứng minh được bằng client thật rằng bộ tài nguyên nhập từ GL vẽ đúng trong client CY.**
Mọi khẳng định ở trên là về **tính đầy đủ của tham chiếu**, đo bằng đúng phép đo mà các cảnh CY
đang chạy đều vượt qua (mục 3.1) — mạnh, nhưng không thay được một khung hình. [SL]

---

## 8. Bẫy ghi lại cho người sau

1. **Tên tệp trên đĩa là GBK-đọc-nhầm-cp1252** (mục 3.2). Sai chỗ này thì mọi số liệu tài nguyên
   đều vô nghĩa. Đã có hai hàm đổi mã trong công cụ.
2. **`BrushesFolder` có thư mục con.** Quét một cấp ra "35/35 texture thiếu" ở cả cảnh đang chạy —
   dấu hiệu rõ ràng là phép đo sai chứ không phải dữ liệu thiếu. **Luôn chạy đối chứng trên cảnh
   đang chạy trước khi tin một con số "thiếu".**
3. **`build_canonical_cy.py` KHÔNG xoá tệp nhập, nhưng `--verify` sẽ báo chúng là `extras` và
   thoát mã 1.** Đọc `Tools\pipeline\build_canonical_cy.py` dòng 21 ("nothing else is removed") và
   664-678. Khác hẳn `SceneDefineEx.txt` — tệp đó **nằm trong kế hoạch** nên bị dựng lại đè.
4. **Bộ đọc tên vật liệu trong `.mesh` là heuristic.** `scene_import_gl.py` duyệt chunk Ogre
   `M_SUBMESH` (0x4000); gặp header hỏng thì trượt 1 byte, nên có thể ra rác
   (`silindao` báo 34.943 vật liệu "thiếu"). Chỉ dùng để **phân nhóm thận trọng** (rác ⇒ đẩy vào
   `kho`), **đừng** dùng con số đó làm kết luận.
5. **Đường dẫn Windows có `\` trong chuỗi Python bị hiểu thành escape** — đã làm hỏng một script
   khi viết bằng heredoc. Dùng công cụ Edit/Write hoặc `BS = chr(92)`.
6. **Đừng tin cột `map` của `SceneInfo.ini` là tên tệp `.Scene` của client.** Bốn cảnh `cy4_*`
   chứng minh: `.scn` server tên `cy4_guigu`, `.Scene` client tên `guigu`.

---

## 9. Lệnh áp lại sau khi dựng lại dữ liệu chuẩn

`build_canonical_cy.py --apply` **không xoá** tệp nhập (mục 8.3), nên bình thường không cần làm gì.
Nếu `Assets\CanonicalCY\Data` bị dựng lại từ đầu (xoá thư mục rồi extract):

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\game\scene_import_gl.py apply  --maps huashan,shengsileitai,zhulin --that
python -X utf8 Tools\game\scene_import_gl.py verify --maps huashan,shengsileitai,zhulin
python -X utf8 Tools\game\scene_import_gl.py registry
```

`apply` idempotent (tệp đã có ⇒ `bo_qua_da_co`), nên chạy thừa vô hại.

**Dòng DBC của các đợt trước vẫn phải áp lại theo đúng thứ tự cũ** — 4 lệnh ở mục 9 của
`Docs\specs\server\maps-instance_vi.md` (maps-all **trước**, maps-instance **sau**), kỳ vọng 792 dòng.
Đợt này không thêm dòng nào nên không chèn thêm bước.
