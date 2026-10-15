# Cảnh lô 2 + công cụ nối string pool + phép đo client thật — agent `scenes-lo2` (17–18/09/2026)

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/dòng/số). **[SL]** suy luận.
`R` = `/home/ubuntu/cys-test-20260913` (server riêng skynet trong WSL `TLBB`).
Bằng chứng: `Build/Logs/2026-09-17-scenes-lo2/`. Công cụ mới: `Tools/reapply/scenedef/72-dbc-pool-rows.py`,
`72-make-rows-lo2.py`, `data/scenes-lo2-rows.json`; mở rộng `Tools/game/scene_import_gl.py` (ô minimap).
Bàn giao: `Timeline/handoff/scenes-lo2.md`. Không commit.

> **ĐỌC BA DÒNG NÀY TRƯỚC.**
> 1. Cái chặn của `scene-import-gl` (không tạo được dòng DBC vì pool thiếu chuỗi) **đã gỡ**: công cụ
>    `72-dbc-pool-rows.py` nối chuỗi vào cuối pool, đã chạy thật, client thật nạp bảng mới (mục 4).
> 2. **Bẫy `clientres` lặp lại lần thứ ba, ở `huashan`**: cảnh 125 华山绝顶 có `clientres=168` trỏ
>    `huashan_10.scene`, nhưng navmesh của server `huashan.path` **bằng từng byte** với GL `huashan.path`
>    và **khác** `huashan_10.path` (mục 3.1). Ai làm theo `clientres` sẽ vẽ nhầm bản đồ.
> 3. Số "đã nhập" và số "đã vào bằng client thật, vẽ đúng" **để riêng** ở mục 5 — đừng gộp.

---

## 1. Kết quả một dòng

| | trước đợt | sau đợt |
|---|---|---|
| Bản đồ GL → CY nhập trọn bộ (`verify` 0 tham chiếu thiếu) | 3 | **17** |
| Tệp nhập từ GL (có kê khai nguồn + sha256 từng tệp) | 34 | **273** (185 tệp cảnh/mesh/texture + 88 ô minimap) |
| DBC `SceneDefineEx.txt` (client) | 792 dòng, pool 72.239 B | **799 dòng, pool 73.382 B** (7 THÊM, 12 SỬA, 0 ID trùng) |
| Bản đồ nhập từ GL có dòng DBC trỏ tới | 0 | **17** (19 dòng, kể cả `client_res` 3080/3081) |
| Cảnh `type=0` đang bật `THIEU`/`SAI` (bất biến số 1) | 0/195 | **0/197** (bật thêm 125, 410) |
| Cảnh lô 2 đang bật | 0 | **12/12** (125, 410 `type=0`; 113–120, 404, 405 `type=1`) |
| Cảnh nhập từ GL **client thật đã vào và vẽ đúng** | 0 | **2** (`huashan`, `shengsileitai`, có ảnh) |
| Phép đo cuối `maps-instance` (130 `sceneid`, 1326 `client_res`) | bị chặn quyền | **cả hai đường 20/20 PASS** (mục 5.3, 5.4b) |
| `client_res` kịch bản phó bản trỏ đúng | 12/16 | **14/16** |
| RAM server khi bật thêm (199 cảnh lúc đo) | 3,01 GB RSS @195 | **2,94 GB** — ≈ 0 GB, dưới ngưỡng 0,5 GB |

---

## 2. Lô 2 — 14 bản đồ, rủi ro 0, xong [DK]

`Tools/game/scene_import_gl.py apply --that --maps bianguan_1,bianguan_2,bianguan_3,bianguan_4,dumuchang,
huomuchang,jiaofei,yanziwu,yewai,PhoenixMaze,huanjing_1,huanjing_2,huanjing_3,huanjing_4`
(`10-lo2-apply.json`): **151 tệp ghi, 15 bỏ qua vì đã có, 0 tệp CY bị ghi đè**; `zijinnei/zijinwai1/
zijinwai2` **bỏ theo quyết định đã chốt** (server không có `.scn`). `verify` 17/17 bản đồ (3 lô 1 + 14 lô 2):
đủ `.Scene/.Terrain/.Heightmap/.GridInfo/.WCollision/.path`, **0 mesh / 0 model / 0 texture / 0 hệ hạt thiếu**,
sha256 từng tệp khớp kê khai (`11-lo2-verify.json`, `16-verify-17.json`).

### 2.1 Mở rộng: ô minimap [DK]

`FalagardSceneMap::createTiledBackground` (`Src/Client/CEGUIFalagardEx/FalagardSceneMap.cpp:431,470`) tìm
`jpg_<cột 10 szSceneMap><''|_SJ|_QX>_<x>_<y>.dds` trong nhóm `General` (CY để ở `Scene2Folder`). GL có
sẵn các ô này trong `SceneFolder` nhưng công cụ lô 1 chưa chép ⇒ minimap tròn sẽ trống. Đã thêm loại tệp
`minimap` vào `scene_import_gl.py` (tiền tố = cột 10 của bảng GL cho bản đồ đó ∪ tên bản đồ, vì `huashan`
không có dòng bảng nào): **88 ô** chép sang `Scene2Folder` (`15-minimap-apply.json`), ví dụ `huashan` 16 ô
(256×256 = 4×4), `yewai` 4 ô (`yewaiscene`), `shengsileitai` 1 ô. `verify` in thêm `minimap_o` (thông tin,
không phải lỗi). Đối chứng trên cảnh đang chạy: `luoyang_new` 192 ô, `bianjing` 256, `suzhou_new` 192
(`33-verify-thamchieu-CY.json`).

### 2.2 Kê khai nguồn — điều kiện người dùng đặt [DK]

`Build/Logs/2026-09-17-scene-import-gl/manifest.jsonl` **273 dòng** (mỗi tệp: `dich_CY`, `nguon_GL`, `sha256`,
`kich_thuoc`, `ngay`, `canh_dung`, thẻ `NGUON=GL (Assets/Canonical) - CHO BAN CY THAT`);
`Registry/batches/2026-09-17-scene-import-gl.{yaml,tsv}` sinh lại bằng `scene_import_gl.py registry`
(17 bản đồ / 273 tệp). Hoàn tác: `scene_import_gl.py undo --maps <ds> --that`.

---

## 3. Dòng DBC — nguồn 24 cột và ba bẫy [DK]

### 3.1 `huashan` (cảnh 125): không bảng nào có dòng, và `clientres` trỏ nhầm hình học

| bảng | dòng `huashan.scene`? | dòng 168 (= `clientres` của cảnh 125) |
|---|---|---|
| bảng client GL `Assets/Canonical/.../SceneDefineEx.txt` (547 dòng) | **không** | `huashan_10.scene` "Tuyệt đỉnh Hoa Sơn" 256×256 |
| bảng server `R/configs/SceneDefineEx.txt` (564 dòng) | **không** | `huashan_10.scene` 华山绝顶 256×256 |
| DBC CY (792 dòng, và bản 692) | **không** | (692) `huashan_10.scene`; (792) `chuanwu.scene` |

Navmesh (`13-server-facts.json`): server `Game_2/Scene/huashan.path` sha256 `a065941e…` 267.241 B **=** GL
`huashan.path`; CY `huashan_10.path` `92e88862…` 290.657 B, GL `huashan_10.path` `842b3988…` 334.804 B —
**khác**. `.Heightmap` GL `huashan` ≠ CY `huashan_10` (cùng 264.212 B, sha khác). ⇒ hình học server = GL
`huashan`, **không phải** `huashan_10`. Dòng 125 dựng tay từ mẫu 168 (cùng tên 华山绝顶, cùng 256×256:
`nBackSound 140`, `nCol9 20000`, `Sign14`, `MiniMap_Icon3/HuaShanZhiDian_Normal`), thay 4 ô tệp bằng
`huashan.*`, tên `Tuyệt đỉnh Hoa Sơn` (tên CY gốc của dòng 168 trong `ref-dbc-692`), hiển thị `Đỉnh Hoa Sơn`.

### 3.2 16 dòng còn lại: bảng client GL = bảng server, chỉ khác ngôn ngữ

`13-server-facts.json` đối chiếu 19 dòng nguồn (80, 81, 156–163, 168, 173, 230, 236, 266, 267, 281, 546,
703) giữa bảng client GL (text, 24 cột, **tiếng Việt**) và bảng server (GBK, 24 cột, tiếng Trung):
**0 ô khác nhau ngoài cột [1]/[22]**. Nên lấy bảng GL (đã dịch) làm nguồn là đúng y "24 cột từ bảng
server" mà không phải dịch tên. Cột 0 = ID cảnh server ta; cột 11..14 = 0 (`--zero-wmap`); cột 24 = 0.

| ID | bản đồ | việc | nguồn GL |
|---|---|---|---|
| 125 | huashan | SỬA (`kuangchang` → `huashan.Scene`) | dựng tay, mục 3.1 |
| 410 | shengsileitai | THÊM | 546 |
| 48 / 3080 | yewai | THÊM / THÊM (`client_res`) | 80 |
| 49 / 3081 | zhulin | THÊM / THÊM (`client_res`) | 81 |
| 189, 190, 539 | jiaofei, yanziwu, PhoenixMaze | SỬA (`xingxiu_2`, `tianshan_2`, `辽地 4` → đúng) | 230, 236, 281 |
| 113–116 | huanjing_1..4 | SỬA (`juxian_1`, `yanzi_1`, `yipin_1`, `leigu` → đúng) | 156–159 |
| 117–120 | bianguan_1..4 | SỬA (`leigu_1`, `wanjie`, `wanjie_1`, `cangmang` → đúng) | 160–163 |
| 404, 405 | dumuchang, huomuchang | THÊM | 266, 267 |

### 3.3 Sửa 12 dòng đang có — có ai dùng chúng qua `clientres` không? [DK]

`SceneInfo.ini` có 11 cảnh đặt `clientres` vào một ID tôi ghi: 64 (→125), 68/69/70/78/79/80/84/85
(→113..120), 146/147 (→189/190). Đọc mã: `scenecore.lua:112,127` `self.client_res = conf.clientres`,
`:2031` gửi trong `GCEnterScene`, `:9228` `get_specifi_scene_client_res` đọc `scene_info[dest].clientres`
cho `GCNotifyChangeScene`/`NewWorld` (`script_base.lua:4863`); `copyscenecore.lua:113` **ghi đè** bằng
`conf.client_res` của kịch bản. Client (`CYS-SCENERES`) chỉ tra `client_res` khi **không có dòng ở
`sceneid`**. ⇒ 146/147 là `type=0` đang bật, có dòng ở đúng ID ⇒ `client_res` không bao giờ được tra;
9 cảnh kia là `type=1` — vào được thì `sceneid` là 1000x và `client_res` là **`g_ClientRes` của kịch bản**
(đã dời sang 3xxx), không phải `clientres` của section. **Không đường chạy nào tới 12 dòng cũ** ⇒ sửa
theo luật vàng (dòng ở ID N phục vụ cảnh N) là an toàn.

### 3.4 Công cụ `72-dbc-pool-rows.py` — nối pool, 6 phép kiểm sau khi ghi [DK]

Khác `70-client-scenedef-rows.py` (chỉ chép offset, `assert pool == pool_goc`): nhận **giá trị 25 ô** từ JSON,
mã hoá chuỗi (cột chữ [1]/[22] UTF-8; cột khoá tài nguyên ASCII, nếu có chữ Hán thì GBK — đúng quy ước
đo được của pool: 35 ô tài nguyên có chữ Hán đều là byte GBK, vd `\xc8\xfb\xcd\xe2 1.Scene` = `塞外 1.Scene`),
**tìm chuỗi đã có** (chỉ mục mọi đoạn kết thúc NUL) hoặc **nối vào cuối pool**, rồi THÊM/SỬA dòng giữ cột 0
tăng dần. An toàn theo `TLBB_DBC.cpp OpenFromMemoryImpl_Binary` (poolSize đọc từ header, offset chặn biên,
byte cuối ép NUL, không chỗ nào đánh chỉ mục theo số chuỗi). Sau khi ghi, **đọc lại từ đĩa** và kiểm: từng ô
19 dòng; mọi dòng khác giữ nguyên từng ô; pool cũ là tiền tố pool mới; cột 0 tăng dần + 0 trùng; pool
kết thúc NUL; `Tools/game/dbc_inventory.Table` đọc lại được. Sai một điều là tự trả bản sao lưu.

Thử trên bản sao trước (`20-plan-copy.json`, `21-apply-copy.json`, `22-verify-copy.json`): 792 → 799 dòng,
pool 72.239 → 73.382 B, chạy lần hai `da_du` với md5 y hệt (`b4ca245a…`). Chuỗi có sẵn (`qiongzhou.jpg`,
`Sign1`, `MiniMap_Icon`, `0.2;0.2`, `Thương Mang Sơn`…) được **dùng lại**, chỉ 70 chuỗi mới nối vào.

---

## 4. Đúng thứ tự đề bài: 1 dòng → client nạp → hàng loạt [DK]

| bước | kết quả | bằng chứng |
|---|---|---|
| Thêm **1 dòng** (410 `shengsileitai`) vào file thật | 792 → 793 dòng, pool 72.239 → 72.356 B (6 chuỗi mới), sha `1ef80c02…` | `24-apply-1dong.json` |
| `71-dbc-dupe-check` | 793 dòng, **0 ID trùng**, cột 0 tăng dần, stage `stage-fps-daiviet` cùng sha256 | `25-dupe-1dong.json` |
| **Client thật nạp bảng 793 dòng** | `DBC: SceneDefineEx.txt OK columns=25 records=793 record=160`; `scene 2 resolved … (EnterScene can find it)`; `GCEnterScene scene=2`; navmesh `invariant_violations=0`; 3 lượt bấm đất `reachable=1`; 16 ảnh; **0 dump**; không có `Multi index` | `gui-t1-dbc793-load/WXClient.log:40,66,288-291`, `run.json` |
| Áp **hàng loạt** 19 dòng | 793 → **799 dòng**, pool → **73.382 B** (62 chuỗi mới; 1 dòng BO-QUA vì đã đúng), sha `3ac52912…`, 153.398 byte | `26-apply-hangloat.json`, `27-verify-hangloat.json` |
| `71-dbc-dupe-check` | **799 dòng, 0 ID trùng**, stage cùng sha256 | `28-dupe-hangloat.json` |
| `67-clientres-score.py` của `maps-instance` | **12/16 → 14/16** (`3080 yewai`, `3081 zhulin` nay ĐÚNG; còn 3079 `songliao`, 3596 `mantuoshanzhuang_1` thuộc nhóm `kho`) | in ra màn hình, mục 4 |
| `scene_install.py survey --all` sau DBC | `type=0` đang bật: **198 OK + 1 THIEU** — THIEU duy nhất là **1326** đang tạm `type=0` **có chủ đích** cho phép đo `client_res` (mục 5), sẽ trả về `type=1`; `type=1` đang bật: 73 → **77 OK** (48/49/189/190/539) | `34-survey-sau-dbc.json` |

Lượt client `t1` chạy trên `stage-fps-daiviet` (bản chơi) cho thấy một bẫy phụ: `Game.exe` dựng 13:17 của
stage đó **không đọc `CYS_BOT_ACCOUNT`** nên `-Account test05` vẫn đăng nhập `test00/CYTest00`
(`character_selected FAIL`, mọi phép còn lại PASS 19/20). Từ lượt sau dùng stage riêng
`Build/world-gui/stage-scenes-lo2` (dựng từ `Build/cmake/maps-instance-x64`, 18 nhị phân, có `CYS-SCENERES`)
và tài khoản riêng `test12/CYTest12` (GUID 200013, bản gốc `char/goc-200013.json`).

---

## 5. Phép đo bằng client thật [DK]

Bộ đo: `scripts/40-scene-gui.ps1` (đặt `sceneid`/`world_pos` của CYTest12 bằng `char_menpai.py set`, chạy
`run_world_gui_live.ps1` trên stage riêng `stage-scenes-lo2`, rút dòng log, trả nhân vật về gốc), gọi tuần tự
bởi `scripts/50-run-4-scenes.sh` (lượt `b`, 03:27–). Mỗi lượt 20 phép kiểm của runner + ảnh PNG.

### 5.1 Cảnh 125 `huashan` (type=0, 37 quái) — **VẼ ĐÚNG** — `gui-s125-huashan-b/` (20/20 PASS)

| bằng chứng | dòng log / ảnh |
|---|---|
| bảng mới được nạp | `DBC: SceneDefineEx.txt OK columns=25 records=799 record=160` |
| vào đúng cảnh theo `sceneid` | `CYS world: GCConnect generation=1 scene=125` / `GCEnterScene scene=125 res=168 obj=39 city=0` (server vẫn gửi `client_res=168` = `huashan_10`, client **không** dùng vì dòng 125 có sẵn — đúng thiết kế `CYS-SCENERES`) |
| navmesh của bản đồ nhập từ GL | `CYS: navmesh huashan.path points=2391 tris=4771 blocked=2187 edges=2389 regions=18 cell=8 grid=32x32 bounds=[0.0,0.0]-[256.0,256.0] invariant_violations=0` |
| di chuyển được | 3 lượt bấm đất `navmesh=1 reachable=1 limit_move=0`, quãng đường **24,03** đơn vị (`path_length`), `position … delta -0.72,1.74` |
| 0 dump, 0 lỗi handler | `no_dump PASS`, `handler_errors=0`, `invalid_pos=0` |
| **ảnh** | `cys-live-180103875-world-1.png` (sân đấu đá, cờ 武当, hoa đỏ, cỏ), `cam-zoom-far.png` (địa hình xa, sương), `cam-sky-low.png` (cờ 天龙/峨嵋/武当, bầu trời + núi skysphere), `move-after.png` (nhân vật đứng cạnh NPC **Ngô Minh** = quái 吴铭 đặt ở (138.28,130.88) trong `huashan_monster.ini`) |
| minimap | ô tròn góc phải có địa hình (16 ô `jpg_huashan_*` chép ở mục 2.1), tên cảnh "Tuyệt đỉnh Hoa Sơn" hiện trên thanh tiêu đề (bị cắt đầu vì dài hơn khung CY — xem 5.5) |

Điểm nhìn tận mắt: tô bóng, cỏ, hoa, cờ vải, sương khoảng cách và skysphere đều vẽ; không mesh trắng/đen,
không "ô vuông" texture, không lỗ trên địa hình quanh nhân vật. Đây là **cảnh nhập từ GL đầu tiên được client
CY vẽ đúng** — mắt xích biến "đã chép" thành "vẽ đúng".

### 5.2 Cảnh 410 `shengsileitai` (type=0, 1 NPC) — **VẼ ĐÚNG** — `gui-s410-shengsileitai-b/` (20/20 PASS)

Cặp đối chứng của `huashan` (0 tệp thêm ngoài thư mục cảnh). `DBC … records=799`; `GCConnect scene=410` /
`GCEnterScene scene=410 res=546`; `CYS: navmesh shengsileitai.path points=239 tris=467 … bounds=[0.0,0.0]-[63.9,64.0]
invariant_violations=0` (tệp v2 của GL, server dùng bản v1 240 đa giác — cùng lưới, mục 8.4); 3 lượt bấm
`reachable=1`, quãng đường 24,0; 0 dump. Ảnh `world-1.png` / `cam-zoom-far.png` / `move-after.png`: sàn đá
lát rêu, cờ lồng đèn đỏ, cổng gỗ, sương tím, NPC **Đại sư Khô Vinh** (枯荣大师 ở (12,33)) đứng cạnh nhân vật.
**Minimap tròn tối** ở cảnh này: ô `jpg_shengsileitai_0_0.dds` **có được nạp** (`WXRender.log: Loading 2D
Texture 'jpg_shengsileitai_0_0.dds'`, `UISystem.log: Creating Imageset`), và bản thân ô là ảnh tối (giải mã DXT1
→ `tile-jpg_shengsileitai_0_0.png`: độ sáng trung bình 41/255, sàn đấu ban đêm có chữ 出口) — minimap tối là
**trung thành với dữ liệu GL**, không phải lỗi chép. Đối chứng: ô `huashan` (độ sáng 70) hiện rõ ở 5.1.

### 5.3 Cảnh 130 `shaolin_1` — phép đo cuối của `maps-instance`, đường **`sceneid`** — **ĐẠT** — `gui-s130-shaolin1-b/` (20/20 PASS)

Cảnh 130 tạm `type=0` để server tạo dịch vụ `.SCENE_130` lúc khởi động (mục 6). Client: `DBC … records=799`;
`GCConnect generation=1 scene=130` / `GCEnterScene scene=130 res=173 obj=33` — client nhận đúng `sceneid=130`,
tra **dòng 130 do `maps-instance` ghi** (`shaolin_1.scene`, `.path` = `shaolin.path`) và vẽ **Thiếu Lâm Tự**:
`CYS: navmesh shaolin.path points=1266 tris=2522 … bounds=[0.0,0.1]-[192.0,192.0] invariant_violations=0`;
**không có dòng `CYS-SCENERES`** (nhánh `client_res` không chạy — đúng thiết kế: có dòng ở `sceneid` thì không
tra `client_res`); `objects=15 created=16` — 15 quái "Lâu La" (喽啰) trong tầm nhìn; 3 lượt bấm `reachable=1`,
quãng đường 23,98; 0 dump. Ảnh `world-1.png` / `cam-zoom-far.png`: sân đá, lan can, tượng sư tử, cầu thang, quái
cầm đao đứng gác, minimap có ô với nhãn 大雄宝殿 và tên "Thiếu Lâm Tự" trên tiêu đề. Tông màu xanh lục phủ
toàn cảnh (kể cả da nhân vật) là màu sương/HDR của chính tệp cảnh CY `shaolin_1` — dữ liệu CY gốc, không thuộc
đợt nhập GL. ⇒ **Một dòng DBC do `maps-instance` vừa ghi đã vẽ ra đúng bản đồ** — phép đo họ còn nợ ở 11.1.

### 5.4 Cảnh 1326 `erengu_1` — phép đo cuối của `maps-instance`, đường **`client_res`** — **BẢN ĐỒ ĐÚNG, phiên không trọn** — `gui-s1326-erengu1-b/` (13/20)

Cảnh 1326 tạm `type=0` + `clientres=3703` (DBC **không có** dòng 1326 ⇒ client buộc phải rơi sang `client_res`).
Client: `DBC … records=799`; `GCConnect scene=1326` / `GCEnterScene scene=1326 res=3703 obj=28`;
**`CYS-SCENERES: scene 1326 has no SceneDefineEx row; resolved by client_res 3703 -> erengu.Scene`**;
`CYS: navmesh erengu.path points=4724 tris=9434 … bounds=[2.0,0.7]-[254.8,254.1] invariant_violations=0`;
`CYS-NAV: wcollision erengu.WCollision … parsed=131036/131036`; `CYS audio: scene 3703 env sounds erengu.esd`,
nhạc nền `music\erengu.mp3`. Ảnh `cys-live-180670656-world-1.png`: hang Ác Nhân Cốc xanh thẫm, nấm phát sáng,
đá, minimap có ô và tiêu đề "Ác Nhân Cốc". ⇒ **Dòng 3703 do `maps-instance` ghi được client tra qua
`client_res` và vẽ đúng bản đồ** — điều họ cần chứng minh ở 11.1.

**Phần không đạt (7/20 FAIL):** sau `GCDetailAttrib obj=28 self=1`, bộ đếm giữ `objects=0 created=0 moves=0`
suốt 80 s, `CysWorldReplay` không phát 3 lượt bấm đất, không thoát qua menu ⇒ runner kill ở 150 s. So với 130
(cùng phiên, 4 phút trước): `created=16`, bấm đất lúc +19 s.

**Phía server KHÔNG lỗi** (`15-erengu1-login.txt`): `AUTO_ROUTE_ENTER guid= 200013 obj= 28 scene= 1326 x= 58.23
y= 100.28 client_res= 3703`, rồi `CLIENT_HEARTBEAT guid= 200013 scene= .SCENE_1326 obj= 28` mỗi 15 s suốt phiên,
không traceback. `erengu_1.scn` khai `navmapname=erengu.path`, `monsterfile=erengu_monster.ini` (25 quái),
`eventfile=erengu_area.ini` — tức là dùng nguyên bộ tệp của bản đồ 恶人谷 987; `erengu_1.path` ≡ `erengu.path`
(sha `011fdef2…`, 493.812 B).

### 5.4b Đo lại tại (111,120) — **ĐẠT 20/20**, giả thuyết được xác nhận — `gui-s1326-erengu1-c/`

Cùng cảnh, cùng tài khoản, **chỉ đổi điểm vào** sang vị trí quái 山流儿 (111,120) — điểm mà
`point_in_navmesh.py` báo `flag=0` (tam giác 3479, vùng 2):

| | lượt `b` — (58.23, 100.28) `flag=1` | lượt `c` — (111, 120) `flag=0` |
|---|---|---|
| `CYS-SCENERES … 3703 -> erengu.Scene` | có | **có** |
| navmesh `erengu.path` | `invariant_violations=0` | **`invariant_violations=0`** |
| `created` / `objects` | **0 / 0** | **2 / 2** (hai NPC 山流儿 `Sơn Lưu Nhi`, 山曜 `Sơn Diệu`) |
| 3 lượt bấm đất | không phát được | **3/3 `reachable=1`**, quãng đường **24,02** |
| phép kiểm | 13/20, bị kill ở 150 s | **20/20 PASS**, 0 dump |

⇒ **Nguyên nhân là điểm vào nằm trong tam giác bị chặn, không phải lỗi cảnh, không phải lỗi `client_res`.**
Ảnh `cys-live-201559859-{world-1,move-after}.png`: nhà gỗ mái ngói, lồng đèn cam, chum vại, cây khô, hai NPC áo
trắng đứng cạnh nhân vật — Ác Nhân Cốc vẽ đầy đủ. Đây cũng là **lần thứ hai** một dòng DBC của `maps-instance`
được chứng minh bằng mắt, lần này qua đường `client_res`.

**Nguyên nhân — chứng minh trực tiếp [DK]** (`scripts/16-point-in-navmesh.py`, đọc `.path` v2 theo bố cục đã bẻ từ
`PathLib.dll`: u16 version, u32 pointCount, điểm {f32 x,z}, u32 triCount, tam giác 29 byte {v0,v1,v2,n0,n1,n2,
u8 flag (bit0 = BỊ CHẶN), u32 vùng}; kiểm point-in-triangle trên **9.434 tam giác** của `erengu.path`):

| điểm | bản đồ | kết quả |
|---|---|---|
| **(58.23, 100.28)** — điểm vào 1326 do `maps-instance` tính | `erengu` | **BỊ CHẶN** — tam giác 319, `flag=1` |
| (111, 120) quái 山流儿 · (133, 122) 印祖 · (50, 141) 齐小环 | `erengu` | đi được, flag 0, vùng 2 |
| (138.28, 130.88) · (12, 33) · (92.43, 83.93) — ba điểm vào đã dùng | `huashan` / `shengsileitai` / `shaolin` | đi được, flag 0 |
| (160, 150) hồi sinh mặc định · (253, 121) · (235, 322) · (204, 256) · (530, 937) · (160, 290) — 5 đích NPC dịch chuyển 17/09 | `dali_new_320` / `luoyang_new` / `suzhou_new` / `bianjing` / `SnowWorld2024` | **đi được, flag 0 — 0 điểm dữ liệu game bị lây** |

Điểm (58.23,100.28) là "trọng tâm một đa giác" mà `maps-instance` tính bằng cách đọc `erengu_1.path` theo kiểu
5 điểm/đa giác của `pathparser.lua` (`erengu_1.path` ≡ `erengu.path`), trong khi tệp v2 là **lưới tam giác** — "đa
giác" đó là 5 đỉnh liên tiếp bất kỳ nên trọng tâm rơi vào tam giác bị chặn. Hệ quả đúng như đo được: nhân vật
**có** tồn tại (nhãn tên `CYTest12` trong ảnh; `GCDetailAttrib self=1`; server heartbeat), nhưng `CysWorldReplay`
không phát được lượt bấm đất nào (bộ tìm đường không xuất phát từ tam giác bị chặn) nên không thoát qua menu và
bị kill; `objects=0` chỉ vì không có quái trong tầm AOI (quái gần nhất cách 41 đơn vị) — **không phải server bỏ AOI**
(`scenecore.lua:1048 pcall(AOI.enter, AOI, obj)` không có điều kiện vị trí; `invalid_pos=0` nên client cũng không
bỏ gói). Cách đo lại (gộp restart 3/4): tạm `type=0` cho 1326, điểm vào **(111,120)**, khe client qua
`Build/game-slot-queue.txt`, rồi trả `type=1`. **Bài học:** điểm vào của bộ đo lấy từ vị trí quái/NPC trong
`<map>_monster.ini`, hoặc kiểm `16-point-in-navmesh.py` trước; đừng tính từ `.path` bằng `pathparser.lua`.

**Hệ quả cần biết:** phiên bị kill ⇒ server lưu nhân vật **sau** lệnh `restore` của bộ đo, nên CYTest12 còn
`sceneid=1326, menpai=0` khi kiểm lại; đã `restore` lần hai (`char/restore-200013-cuoi.json`,
`inspect-200013-cuoi2.json`: 0 ô khác bản gốc). **Bẫy cho bộ đo:** khi client bị kill, phải chờ server lưu xong
(~vài giây) rồi mới `restore`.

### 5.5 Tên cảnh trên minimap

Tiêu đề minimap CY cắt "Tuyệt đỉnh Hoa Sơn" thành "yệt đỉnh Hoa S" (ảnh 5.1). Đã đổi cột [1] của dòng 125 thành
**"Đỉnh Hoa Sơn"** (bằng cột [22]; `29-apply-ten125.json`: 1 SỬA, 0 chuỗi mới vì chuỗi đã có trong pool) — DBC cuối:
799 dòng, sha256 `b960ca2c0fe6003a4b3c5f4776ae3f17e3c035dbffab6d15cf3a67f3f398a576`, 153.398 byte
(`29-verify-ten125.json`, `29-dupe-ten125.json`: 0 ID trùng). Ba lượt client ở trên chạy với bản sha `3ac52912…`
(chỉ khác đúng chuỗi tên này).

### 5.6 Hai con số, đừng gộp

| | số |
|---|---|
| Bản đồ GL → CY **đã nhập**, `verify` 0 tham chiếu thiếu, có kê khai nguồn | **17** (273 tệp) |
| Bản đồ nhập từ GL **client thật đã vào và vẽ đúng** (có ảnh) | **2** — `huashan` (125), `shengsileitai` (410) |
| Dòng DBC của `maps-instance` **client thật đã vẽ đúng** | **2/2** đường: `sceneid` (130 → `shaolin_1.scene`) và `client_res` (1326 → 3703 → `erengu.Scene`) |
| Cảnh đi trọn phiên (vào + navmesh + đi được + thoát sạch) | **4/4 — 125, 410, 130, 1326 đều 20/20 PASS** (1326 ở lượt `c`, sau khi đổi điểm vào; lượt `b` 13/20 vì điểm vào bị chặn) |

---

## 6. Chính sách bật + chi phí RAM / khởi động [DK]

**Chính sách v1 (đặt ra đầu đợt, theo đề bài):** chỉ bật cảnh **có nội dung chơi** (quái/NPC trong `SceneInfo.ini`
hoặc NPC dịch chuyển trỏ tới) **và** đã chứng minh vẽ đúng; đo RAM + thời gian khởi động trước/sau mỗi lô; lô nào
làm RAM tăng > 0,5 GB thì dừng và báo.

**Chính sách v2 (điều phối nới ra 18/09, sau bốn phép đo):** vì **thêm cảnh ≈ 0 GB** (bảng dưới), không còn lý do
RAM để giữ cảnh tắt ⇒ **bật mọi cảnh đã có dòng DBC và `survey` OK**, kể cả cảnh chỉ trang trí — "người chơi đi lạc
vào đó còn hơn gặp tường vô hình". Thứ tự đã làm: lô A (có nội dung) bật ở restart 3 — 117–120 `bianguan_1..4`
(11 quái mỗi cảnh) + 404 `dumuchang`; lô B (trang trí) 113–116 `huanjing_1..4` + 405 `huomuchang` ghi sẵn cho
restart 4. Hai cảnh `type=0` đã vẽ đúng (125, 410) bật từ restart 1. Lưu ý: cảnh `type=1` **không** tạo dịch vụ lúc
khởi động (`scenemanager_core` chỉ tạo `type=0`) nên "bật" chúng gần như miễn phí về RAM; giá trị thật là
`get_specifi_scene_client_res` và các đường dẫn kịch bản đọc `clientres` của chính section đó.

**Lô bật này = 2 cảnh `type=0`:** 125 `huashan` (37 quái, `PvpRuler=3`) và 410 `shengsileitai` (1 NPC 枯荣大师,
kịch bản `scripts.obj.shengsi.shengsileitai` 892009). Kèm 130 + 1326 tạm `type=0` cho phép đo maps-instance
11.1 (trả về `type=1` sau khi đo) ⇒ lần restart đo có **199** cảnh.

| mốc (cách đo của `maps-all_vi.md` 6.4) | maps-all 19:31 (195 cảnh) | **scenes-lo2 00:09:11 (199 cảnh)** |
|---|---|---|
| cổng 15733/15734 LISTEN | 40 s (từ lúc start Game) | 81,6 s (từ lúc gọi `cys_server.sh restart`, gồm mongo/mqtt/manager/datacenter/tool rồi Game) |
| cửa sổ tạo cảnh (`LAUNCH snlua scene` đầu → `scene startup done`) | 42 s (0,22 s/cảnh) | **56 s** (0,28 s/cảnh) |
| dòng đầu log → `scene startup done` | 59 s | **76 s** |
| cảnh tạo (`total = N`) | 195 | **199** |
| RSS `Game_tlbb_2` sau khi xong | 3,01 GB | **2,94 GB (+30 s) / 2,93 GB (+60 s)** |
| RAM hệ thống WSL `used` | 4,60 GB | **4,61 GB (+30 s) / 4,51 GB (+60 s)** |
| `traceback` / `SCENE_x_FAIL` / `MONSTER_CFG_FAIL` | 0 / 0 / 5 | **0 / 0 / 5** (đúng 5 ID cũ 49285–49289) |

**Bốn lần restart đã đo** (mỗi lần cùng một cách, `30-restart-measure.sh` hoặc monitor cổng + `31-server-health.sh`):

| lần | cảnh `type=0` tạo | cổng LISTEN | cửa sổ tạo cảnh | dòng đầu → done | RSS `Game_tlbb_2` | used | traceback / `SCENE_x_FAIL` / `MONSTER_CFG_FAIL` |
|---|---|---|---|---|---|---|---|
| `maps-all` 19:31 (17/09) | 195 | 40 s¹ | 42 s | 59 s | **3,01 GB** | 4,60 GB | 0 / 0 / 5 |
| scenes-lo2 00:09:11 | 199 | 81,6 s² | 56 s | 76 s | **2,94 GB** | 4,61 GB | 0 / 0 / 5 |
| điều phối 03:51:28 | 197 | 92,3 s³ | 46 s | 79 s | **2,95 GB** | 4,45 GB | 0 / 0 / 5 |
| scenes-lo2 08:27:43 (lần 3) | 198 | 68,0 s² | 44 s | 63 s | 2,96 GB | 4,44 GB | 0 / 0 / 5 |
| scenes-lo2 09:34:59 (lần 4) | **197** | **67,1 s²** | **42 s** | **61 s** | **2,94 GB** | 4,55 GB | **0 / 0 / 5** |

¹ tính từ lúc Game khởi động · ² từ lúc gọi `cys_server.sh restart` (gồm stop + mongo/mqtt/manager/datacenter/tool)
· ³ từ lúc cổng xuống. Bằng chứng: `restart-A1-199canh.json`, `38-health-sau-restart-dieu-phoi.txt`,
`restart-A3-197canh.json`, `39-health-sau-restart-3.txt`.

**RSS tăng theo thời gian chạy — nhưng BÃO HOÀ, không tuyến tính (giả thuyết "rò bộ nhớ" bị phản bác) [DK]**

| đo ngay trước khi stop | uptime | RSS `Game_tlbb_2` | lượt `AUTO_ROUTE_ENTER` |
|---|---|---|---|
| trước restart 2 | 3 h 42 m | 3,48 GB | — |
| trước restart 3 | 4 h 36 m | 3,53 GB | — |
| **trước restart 4** | **1 h 07 m** | **3,45 GB** | **29** |

Mốc "vừa khởi động xong" luôn là **2,90–2,96 GB**. ⇒ **+0,54 GB trong hơn một giờ đầu, rồi chỉ +0,08 GB trong
3,5 giờ tiếp theo** — đường cong bão hoà. Rò bộ nhớ theo giờ sẽ cho đường thẳng; đây thì không. Giải thích hợp lý
hơn: **nạp lười** — bảng/dữ liệu cảnh/AOI chỉ nạp khi có người vào và giữ lại, mà mốc "sau restart" đo ở +30…60 s
khi chưa ai đăng nhập. ⇒ **Không đáng đào tiếp**; phép đo rẻ để đóng hồ sơ: một lần chạy 8–12 giờ rồi đọc RSS —
vẫn ~3,5 GB là xong. `30-restart-measure.sh` nay tự ghi `uptime_s` + `luot_vao` trước mỗi lần stop nên mỗi restart
sau cho thêm một điểm miễn phí.

⇒ **+2…4 cảnh ≈ 0 GB RAM** (RSS dao động 2,94–3,01 GB không theo số cảnh), dưới ngưỡng 0,5 GB rất xa;
cửa sổ tạo cảnh +14 s là dao động giữa các lần restart (`maps-all` đo 22 lần: 63–616 s tổng), không tuyến tính
theo 4 cảnh. Bằng chứng: `restart-A1-199canh.json`, `restart-A1-199canh.log`, `31-server-health.sh`. Sau 3,25 h
chạy: RSS 3,48 GB, used 4,9 GB, 0 traceback (log `Game2_20260918_000911.log`), có dòng `May overload, message
queue length = 2049` ở dịch vụ `:0000018d` — cùng loại cảnh báo đã có trong log 00:00 trước đợt này (`= 1042`),
không phải do cảnh mới.

**Sự cố restart chồng nhau (ghi thật):** script của tôi chờ "0 `Game.exe` + 0 kết nối" rồi gọi restart lúc
00:09:06 — đúng lúc nhánh `server-data` vừa start (log `Game2_20260918_000845.log` 103 dòng, dừng 00:08:48 ở
`LAUNCH snlua service_cell sharetable`, chưa tạo cảnh nào). `provision stop` của tôi báo **không có tiến trình
nào** đang chạy, `start` 00:09:11 lên đủ. Đã báo điều phối; từ đó **không tự restart nữa** — lần trả 130/1326 gộp
vào lượt restart của điều phối. Bài học: "0 kết nối + 0 `Game.exe`" **không** đủ để kết luận server rảnh khi có
nhánh khác cũng được phép restart; phải qua một người điều phối (luật 16/09 vẫn đúng hơn luật 17/09 ở điểm này).

---

## 7. Bất biến sau đợt, và lệnh áp lại [DK]

`scene_install.py survey --all` sau khi trả 130/1326 về `type=1` (`37-survey-cuoi.json`):

| type | đang bật | OK | THIEU | SAI |
|---|---|---|---|---|
| 0 | **197** (195 + 125 + 410) | **197** | 0 | 0 |
| 1 | 86 | **78** (73 + 48/49/189/190/539) | 4 | 4 |
| 4 | 221 | 0 | 55 | 166 (không đụng, quyết định cũ) |

DBC: **799 dòng × 25 cột**, pool 73.382 B, **0 ID trùng**, cột 0 tăng dần, sha256 `b960ca2c…`; `71-dbc-dupe-check`
xác nhận stage `stage-fps-daiviet` cùng sha256 (junction). `72-dbc-pool-rows.py verify` ok. Phép đo tham chiếu trên
3 cảnh CY đang chạy (`luoyang_new`, `bianjing`, `suzhou_new`): 0 thiếu ở mọi trục (`33-verify-thamchieu-CY.json`) ⇒
bộ đo không tự hỏng. `SceneInfo.ini`: 130/1326 đã trả (`60-set-*.json`, sao lưu
`R/backups/scene-install-20260917T204307Z-set`), có hiệu lực ở lần restart gộp của điều phối (lần 2: `ride-finish`
+ `server-data` + scenes-lo2) — số đo sau lần đó: `38-health-sau-restart-dieu-phoi.txt` (nếu có).
`client_res` của kịch bản phó bản: **14/16** (`67-clientres-score.py`).

Lệnh áp lại: `Tools/reapply/README_vi.md` "Bước 5 — scenes-lo2" (sau 4 bước cũ), kỳ vọng 799 dòng / 73.382 B /
0 trùng; tài nguyên: `scene_import_gl.py apply --that --maps <17 bản đồ>` (idempotent, 273 tệp, kể cả 88 ô minimap).

---

## 8. Bẫy ghi lại cho người sau

1. **`clientres` trỏ nhầm hình học — lần thứ ba** (sau 1063/495/1007 của maps-all và `client_res` của
   maps-instance): cảnh 125 `clientres=168` = `huashan_10`, nhưng navmesh server = GL `huashan`. Tiêu chí
   đúng là **so sha256 `.path` của server với `.path` của client** — đó là phép đo rẻ nhất chứng minh hai bên
   nhìn cùng một mặt đất.
2. **Bảng client GL (`Assets/Canonical/.../SceneDefineEx.txt`) là bản tiếng Việt của bảng server** — cùng
   dòng dõi, 0 ô khác nhau ngoài chữ. Lấy tên ở đó thay vì dịch lại.
3. **`huanjing_2..4` và `bianguan_2..4` dùng chung `.path`/`.wCollision`/ô minimap của `_1`** ngay trong bảng
   gốc (cột 5/6/10) — đó là thiết kế của GL, không phải lỗi chép; đừng "sửa" cho khớp tên.
4. **`.path` server là v1 (`0x1000`) ở 4 bản đồ (shengsileitai/zhulin/yewai/yanziwu) trong khi GL là v2
   (`0x2000`)** — cùng số đa giác (240/496/1253/2887 ↔ offset 239/495/1253/2887), chỉ khác cách gói; sha khác
   không có nghĩa là hình học khác. Với `pathparser.lua` v2 `polygon_count = floor(offset*8/40)` — số này
   nhỏ hơn v1 nhiều lần (47 vs 240), là chuyện của server, ghi lại để ai đo navmesh server biết.
5. **Đường UNC `\\wsl.localhost\TLBB\...` / `\\wsl$\TLBB\...` không mở được từ Python Windows trong phiên
   này** — đọc tệp server bằng `python3` trong WSL rồi ghi JSON ra `/mnt/c`.
6. Git Bash đổi `/mnt/c/...` thành `C:/Program Files/Git/mnt/c/...` khi gọi `wsl.exe` — đặt
   `MSYS_NO_PATHCONV=1`.
7. `grep -c` trên log Game2 vài nghìn dòng chạy nhanh, nhưng `grep -rn` trên `Game_2/Script/scripts` và
   `find` trên `client_GL` mất >2 phút — luôn giới hạn thư mục.
8. **`Game.exe` của `stage-fps-daiviet` (dựng 13:17) không đọc `CYS_BOT_ACCOUNT`** ⇒ `-Account test05` vẫn đăng
   nhập `test00/CYTest00` (lượt `t1`). Muốn dùng tài khoản riêng phải stage từ bản dựng mới (`maps-instance-x64`).
9. **`static-menpai.json` không có khoá `"9"`** (không phái) ⇒ `char_menpai.py set --menpai 9` ném `KeyError`, và
   PowerShell 5.1 với `$ErrorActionPreference='Stop'` nuốt cả traceback thành `NativeCommandError` — hạ xuống
   `Continue` quanh lệnh `wsl.exe` để đọc được lỗi thật. Dùng `--menpai 0` rồi `restore` như `maps_all_live`.
10. **Client bị kill ⇒ server lưu nhân vật SAU lệnh `restore`** của bộ đo ⇒ nhân vật "trả về gốc" mà vẫn còn
    `sceneid`/`menpai` của phiên. Luôn `inspect` lại sau lượt bị kill; nếu lệch thì `restore` lần hai.
11. `Get-Process Game` không thấy tiến trình nào trả mã thoát ≠ 0 trong PowerShell ⇒ `cmd && cmd` trong Git Bash
    dừng chuỗi im lặng (lượt `b` lần đầu "không chạy gì"). Đừng nối lệnh đo-khe bằng `&&`.
12. **Restart chồng nhau**: "0 `Game.exe` + 0 kết nối" không đủ để kết luận server rảnh khi nhánh khác cũng được
    quyền restart — phải qua điều phối (mục 6).

---

## 9. Lệnh áp lại sau khi dựng lại dữ liệu chuẩn

Xem `Tools/reapply/README_vi.md` mục "Bước 5 — scenes-lo2": chạy **sau** 4 bước cũ (maps-cy4 → sect →
maps-all → maps-instance), kỳ vọng **799 dòng, pool 73.382 B, 0 ID trùng**; tài nguyên cảnh áp lại bằng
`scene_import_gl.py apply --that --maps <17 bản đồ>` (idempotent).
