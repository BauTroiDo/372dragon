# ride-finish — thú cưỡi (坐骑) của server riêng ở TRỤC ID CY, hoàn tất hệ thống

> Cập nhật 24/09/2026: các phép đo “bay” ở tài liệu này là model/hover sát đất. Bay cao bằng Ctrl + chuột trái, điều kiện CharMount cột19 và gói2242 được bổ sung tại [mount-high-flight-20260924_vi.md](mount-high-flight-20260924_vi.md).

Ngày: **18/09/2026** (tiếp nối `ride-data_vi.md` 17/09). Server riêng `R = /home/ubuntu/cys-test-20260913`
(WSL `TLBB`, cổng 15733/15734). Công cụ: `Tools/reapply/ride/ride_axis.py`, `ride_server_patch.py`
(git theo dõi). Bằng chứng: `Build/Logs/2026-09-18-ride-finish/`.

---

## 0. Trả lời ngắn

| việc trong đề bài | trạng thái |
|---|---|
| 1. Đổi trục ID server theo CY, cập nhật mọi bảng/script trỏ tới, giữ đúng dòng bay | **ĐÃ GHI XONG trên đĩa, kiểm `verify` ok** — 364 ride: **297 đúng dòng CY (297/297 đúng ID/model/tên)**, 17 đúc, 50 GL đỗ xe; 0/3276 ô impact chết; 364/364 ride đúng `骑乘ID` **ở mọi bậc**; item dùng được **1798/1798**; CharMount 353 dòng, **53 dòng bay = CY**; RideSeries/RideCollection = 8 dòng CY; `define.lua` 174→264 |
| 2. 15 con CY còn thiếu (ưu tiên 151 大风) | **17 dòng đúc** (14 CharMount không có ride + 3 dòng 附件 mà item trỏ tới); `551 = 大风`, 10 item `飞龙：大风` nay có ride |
| 3. Restart + đo ack / xuống thú / BAY + ảnh | **XONG**: restart 2 (03:51:27 → LISTEN 03:52:49) + restart 3 (08:27:48), cả hai log sạch. Ack **0 → 1** (3 547 ms, hết "no reply"); **xuống thú 7/7**; 3 thú bay lên đúng model (94/162/151, cột bay 5.0/3.0/2.0); **ẢNH nhân vật lơ lửng: `live-fly-96/cys-live-198549906-cam-sky-low.png`** (mục 7c (e)) |
| 4. Chọn thú chưa sở hữu thất bại im lặng | **ĐÃ VÁ VÀ ĐÃ ĐO** (P3b/P3d/P4/P3e): `SELECT_ABORT` + `notify_tips` tới client (gói `GCScriptCommand`), riêng hồi chiêu trả `OR_COOL_DOWNING` (`last_or = −6`). Đo TRƯỚC: `bot-truoc-96` — `RIDE_TIMEOUT`, không một chữ tới người chơi |
| 5. RideSeries/RideCollection + bậc 125 | **ĐÃ NHẬP** 8 series / 8 collection CY; **bậc 125 là thật** (CY có 10 bậc 10/20/40/55/70/75/80/85/95/125) ⇒ thêm cột `速度125` + P1, không ép về 90 nữa |
| 6. Tự phản biện: 4 con số ≥ trước; thú đi bộ/bay đúng | 4 con số: **301/303 · 364/364 · 0 · 1798/1798** (trước 287/302 · 335/335 · 0 · 1788/1798; mẫu số 303 vì Trâu Đen thêm một dòng `CharMount` vào bản CY). Cưỡi thử **3 đi bộ + 3 bay: 6/6 đúng model, 7/7 xuống đúng** |

---

## 1. Quyết định và ba dải ID

**Server đổi theo CY** (MOC-17-09 mục 7). Đo lại trước khi làm: Mongo 16 nhân vật — chỉ `test09` sở hữu ride 1
(陆行雕, cùng ID cùng mesh ở cả hai nhánh ⇒ không cần migration); `attrib.ride` của `test15` = 1 (đã chọn, chưa sở hữu).

`Exterior_Ride.txt` mới = **364 dòng × 27 cột**:

| dải | số dòng | nghĩa |
|---|---|---|
| `1..297` | 297 | **đúng dòng CY** (DBC `Assets/CanonicalCY/.../Exterior_Ride.txt`): ID, `模型索引`, `门派`, tên/icon/mô tả (byte GBK từ string pool), `速度索引`, cột 12/13/14 giữ nguyên CY |
| `400 + c` | 17 | **đúc** cho CharMount CY `c` mà CY không phát hành ride: 14 dòng thú (22 走白雕, 23 象, 25 双人雕, **151 大风**, 170 替模骑乘, 193 神马浮云, 240 芙玉飞花, 256 桃舟, 258 花灯, 259 花舟, 281/282 从刃滑翔翼, 401 玉霄云龙, 403 归墟神龙) + 3 dòng `附件` có item trỏ tới (95 金翅附件, 97 烟雨清荷附件, 152 大风附件). Nội dung: nhân bản ride CY cùng tên (551←44, 801←285, 803←286, 495←96, 497←89, 552←551), còn lại mẫu chung (icon của ride 1, `#G`, 门派 −1, bậc 80). Model bay ⇒ bậc ≥ 80 (mọi ride CY có model bay đều 80/85) |
| `1000 + r` | 50 | **đỗ xe**: ride GL `r` mà mesh **không có** bên CY (`绝地`, `六合舆`, `渡情`, `凌霄`, `羊驼`, `昆仑雪猿`, `扶摇万里`, `墨玉麒麟`, `昭华金乌`, `天乌骓·…`, `大风·震/离/坎/乾`, `幻神翼·…`, **`越南黑水牛` (Trâu Đen 06/09)** …). Giữ nguyên nội dung GL nhưng `模型索引 = 1000 + g` để **không** trùng chỉ số CharMount CY; client CY không vẽ được (như 31 ghost trước), không item nào trỏ tới |

**148 ride GL còn lại bị BỎ**: cùng mesh với một CharMount CY mà CY đã phát hành ride ⇒ dòng CY ở đúng ID CY thay
thế (ánh xạ cũ→mới: `plan-2/axis-map.tsv`, ví dụ GL 174 飒露紫 → CY 264, GL 44 大风(đất) → CY 44, GL 129 曙光荧翼 → CY 261).

Đối chiếu theo **MESH** (`CharMount → CharModelEx → all.obj`), tie-break khi nhiều dòng CY dùng chung mesh
(附件, biến thể màu): bỏ 附件 → CharMount CY cùng tên với **ride** GL → cùng tên CharMount → cùng id → id nhỏ nhất.
Nhờ luật "cùng tên ride" mà 龙骧 → 338 (không phải 308 兵马俑马), 惊流云 → 383, 金辉领主 → 387, 幽夜 → 300.

Vì sao đỗ xe phải đổi cả `模型索引`: `LuaFnGetExteriorRideIDByVisual` quét bằng `pairs()`; nếu ride GL 绝地
vẫn mang `模型索引 = 84` thì item CY Visual 84 (幻火赤麟兽) có thể nhận ride 绝地 và client vẽ con khác tên.

## 2. Bậc tốc độ — CY có 10 bậc, không phải 8

`ImpactSEData_V1.txt` của CY có **3 119 dòng SE thú cưỡi** (`分类 99`, `52200`), mỗi dòng mô tả
`坐骑：X。您已激活的坐骑中最高移动速度+N%` (một phần đã dịch: `Tọa kỵ: Lục Hành Điêu … +95%`). N đo được:
**10, 20, 40, 55, 70, 75, 80, 85, 95, 125** — mỗi bậc đúng 207 dòng liên tiếp (4978 + k·207), và 10 cột impact
[18..27] của `Exterior_Ride` CY cũng bước 207 ⇒ đó là 10 bậc theo thứ tự. Server đọc 8 cột `速度10..速度90`
(GL có 90, CY không có 90/nhưng có 55/95).

Xử lý: thêm cột **`速度125` ở CUỐI** (an toàn với `txtreader`; `cfghelper` đọc theo tên — bản vá P1 thêm
`[125] = conf["速度125"]`). Hai ride CY bậc 125 (`201 照夜白`, `202 香鬃乌`) giữ đúng 125 — không ép về 90 như
ride-data đã làm. **Mọi** ride đều có đủ 9 bậc (10/20/40/70/75/80/85/90/125) vì `get_riders_max_speed_up` lấy bậc
lớn nhất trong **các ride sở hữu** rồi tra `impacts[bậc]` của ride **đang chọn**. Không thêm 55/95: không ride nào có
`速度索引` 55/95 nên không bao giờ được tra. Giữ cột `速度90` cho 12 ride GL đỗ xe bậc 90.

## 3. Impact — đúc lại với SE của CY

Mỗi (`模型索引`, bậc) cần một dòng `StandardImpact` logic 14 với `骑乘ID == 模型索引` và `移动速度修正% == bậc`.
Đúc **3 163 dòng mới** (id **48310..51923**, luôn < 65 536, tránh 63000–64099 của server-impact), dùng lại 8 dòng
0.85 gốc; **xoá đúng 1 472 dòng** `坐骑：…` ride-data đúc hôm 17/09 (64100..65571, có 36 dòng ≥ 65536) vì không còn
ai trỏ tới. 1 097 dòng 0.85 gốc (đã "repair" từ server gốc, `骑乘ID` trục GL) **giữ nguyên** — mồ côi, vô hại.

SE (`瞬发效果ID`) của dòng đúc = **dòng SE CY cùng (icon, bậc)** trong khối hiện đại 4978..7047 ⇒ biểu tượng
buff và dòng chữ "+N%" **đúng như CY** (ride 1 陆行雕: 10→4978, 80→6220, 85→6427, 125→6841). Bậc 90 (CY không có)
và 3 ride không có SE theo icon (蹑景 236/237, 龙骧 260) ⇒ SE −1. `是否需要装备支持 = 0`, `装备的ItemIndex = 0`
(không nơi nào ép; không chép item của mẫu vào dòng của thú khác).

## 4. Bảng khác

| bảng | kết quả |
|---|---|
| `CharMount.txt` (server, **bảng chết**) | 353 dòng CY chiếu về 15 cột GL: `[0..11] = CY[0..11]`, `[12] = CY[16]`, `[13] = CY[17]`, `[14] = CY[22]` (độ cao bay). Đối chiếu dòng 0 (虎) khớp từng ô với client_GL trừ 6/7 (ActionSet CY 839/1435 ≠ GL 282/549). **53 dòng bay = đúng 53 dòng CY** (28 thú + 25 附件); GL chỉ có 12, MOC ghi "15" là phép so theo ID |
| `RideSeries.txt` | 8 dòng CY, 21 cột (`id, tên, số, loại, ngưỡng, 16 ride`). **Bỏ cột thứ 6 của CY** (giá trị 1/1/1/1/1/5/5/30, chưa rõ nghĩa): `ride_huayu_bonus.load_series` đọc theo **vị trí** (`ints[5..]` = ride id) nên giữ cột đó là đọc ra ride 1/5/30. GL DBC (15 cột) cũng không có cột này. Giá trị đã bỏ: `plan.json → dropped_series_col` |
| `RideCollection.txt` | 8 dòng CY (47 紫电 + 7 series). 14 dòng GL cũ (紫电 47, 黑天马 86, 红熊王 97, 昆仑雪猿 108, 扶摇万里 116, 赤兔 125, 墨玉麒麟 150, 昭华金乌 168 + 6 series GL) **thay hẳn** — 5/8 ride đó mesh không có bên CY |
| `EquipBase.txt` | không chạm (đã là CY). Sau đổi trục, 3 Visual `附件` (95/97/152) lộ ra là mồ côi (trước đó "dùng được" nhờ trỏ nhầm sang ride GL 凌霄/红熊王) ⇒ đúc 3 ride 495/497/552 ⇒ **1798/1798** |
| `define.lua` `ADD_EQUIP_BUFF[HEQUIP_RIDER]` | `MINID/MAXID 174 → 264` (GL 飒露紫 → CY 264, cùng mesh), BUFFID 63000 giữ |

## 5. Năm bản vá mã (`ride_server_patch.py`, dấu `CYS-RIDE-FINISH`, `luac5.4 -p` rc 0, sao lưu `R/backups/ride-finish-code-20260917T202926Z/`)

| | file | nội dung |
|---|---|---|
| P1 | `lualib/cfghelper.lua` (CRLF) | `read_exterior_ride` đọc thêm `[125] = conf["速度125"]` |
| P2 | `lualib/script_base.lua` | `LuaFnGetExteriorRideIDByVisual`: 10 `模型索引` CY dùng chung cho 2–3 ride (紫电 47/232, 玄天狐 173/仿 175, 大象 22/36 …) — `pairs()` trả ngẫu nhiên ⇒ chọn **xác định**: ưu tiên `门派 == -1`, rồi id nhỏ nhất (47 nằm trong RideCollection, 232 thì không). **Có bản thứ hai của hàm này ở `Game_2/Script/xxx_script_base.lua:1292` — MÃ CHẾT**: 0 tham chiếu `require`, và `Game_2/Script` không có file tên `script_base.lua` nên `require "script_base"` không thể trỏ vào. Chứng minh động trên chính module vật phẩm (`do-dac/probe_itempath.lua`): `require "scripts.obj.commonitem.999801"` → `:LuaFnGetExteriorRideIDByVisual(43)` ra **47 cả 12/12 lần** |
| P3a | `services/scene/scenecore.lua` `char_auto_ride` | **đang cưỡi mà bấm lại = XUỐNG THÚ**: gỡ thẳng impact lớp 99 (`impact_get_first_impact_of_specific_class_id(define.RIDE_IMPACT_ID)` → `on_impact_fade_out` → `remove_impact` → `send_refresh_attrib`, y hệt `human:reverse_ride` và `skill_14:start_charging`; nếu không thấy impact thì đẩy kỹ năng 21 như 0.85), đợi `ride_model == −1` (tối đa 2 s) rồi mới ack `GCCharAutoRide`. Client CY gọi cùng một hàm host cho cả 召唤(1) lẫn 收回(0) (`Ride.lua:425`); trước đây nhánh này chỉ ack. (v1 03:29 đi qua kỹ năng 21, v2 03:40 gỡ trực tiếp — `P3a_v1to2` nâng file đã vá v1) |
| P3b | như trên | chưa chọn ⇒ tip `#{WGTJ_201222_106}`; **chưa sở hữu** (`have_this_ride`) ⇒ tip `#{ZQGZ_110512_25}` + log `RIDE_ABORT ly do=KHONG SO HUU`; không có impact cho bậc ⇒ tip `#{ZQGZ_110512_20}` |
| P3c | như trên | log timeout in đúng số lần + tip |
| P3d | `char_exterior_request` cat 3 | chỉ cho **chọn** thú đã sở hữu (hoặc −1 = bỏ chọn); không thì tip + `SELECT_ABORT` |
| P4 | `skill/human/skill_14.lua` | chặn nil khi ride id không còn trong bảng; không có impact ⇒ log `SKILL21_NO_IMPACT` + tip |
| P5 | `lualib/define.lua` | 174 → 264 (2 env) |

Chỉ có hiệu lực **sau restart** (services/lualib nạp lúc khởi động).

## 6. Số đo trước / sau (đọc từ đĩa — `survey-truoc.json`, `verify-sau.json`)

| | TRƯỚC (17/09 sau ride-data) | SAU (18/09) |
|---|---|---|
| thú cưỡi CY hiện được (CharMount không 附件 có ride + mesh) | 287/302 | **301/303** (mẫu số +1 vì Trâu Đen; còn thiếu 20 vô danh và 241 霜瑟飞花 — cả hai do dữ liệu CY thủng, xem bàn giao mục 7) |
| ride đúng model (`骑乘ID == 模型索引`) | 335/335 (chỉ bậc đang dùng) | **364/364 ở MỌI bậc** (0/3276 ô sai bậc/logic; trước có 146 ô cột 速度90 mang tham số 85) |
| ô impact trỏ hụt | 0/2680 | **0/3276** |
| item thú cưỡi dùng được | 1788/1798 | **1798/1798** |
| dòng ride ≤ 297 trùng nghĩa với CY cùng ID (model + tên) | 177/297 | **297/297** |
| dòng có `模型索引` ngoài CharMount CY (model < 1000) | 155 (GL) | **0** |
| ride có bậc 125 | 0 | 364 |
| impact id ≥ 65536 đang dùng | 36 | **0** |
| CharMount server: dòng / dòng bay | 201 (GL) / 12 | **353 / 53 = CY** |
| RideSeries / RideCollection | 6 / 14 (id GL) | **8 / 8 = CY**, mọi id có thật |
| GBK + CRLF + 0 dòng UTF-8 (5 bảng) | ok | **ok** (`fix_server_utf8_rows.py check` trên R: `files: 0`) |
| `ride_data.py verify` | FAIL (95/97/152 mồ côi sau đổi trục) | **ok: true** |

Đo **chạy thật TRƯỚC** (server đang chạy bảng cũ, `bot-truoc-96`, test15 sở hữu 6 ride, chọn 96 = 金翼龙兽 CY):
`RIDE_REQ … ride_da_chon= 96` → `RIDE_TIMEOUT … sau 15 lan cho` sau 5 s, `ride_replies=0`, `ride_model=-1`,
**không một chữ nào tới người chơi** — đúng lớp lỗi "bấm không có gì xảy ra".

## 7. Bẫy đã trả giá

1. **`ImpactSEData_V1` của CanonicalCY đã bị dịch một phần** (mô tả UTF-8 tiếng Việt lẫn GBK Trung) ⇒ không so
   theo TÊN, chỉ theo icon `RideHeaderX_Y` + "+N%" đọc ở mức byte. Cùng icon có dòng cũ (258/299 "雕") lẫn dòng
   hiện đại (4978+) ⇒ phải ưu tiên khối 4978..7047.
2. **`cfghelper.lua` dùng CRLF**, 4 file kia LF — bản vá khớp từng byte phải mang đúng EOL.
3. **Chuỗi GBK tình cờ hợp lệ UTF-8**: 犀牛 → `Ϭţ`, 驯鹿 → `ѱ¹`. Bộ lọc "chữ thật" phải loại Hy Lạp/Kirin, không thì
   báo 24 dòng UTF-8 giả.
4. **Ảnh chụp GL 198 dòng còn mô tả GB18030 4 byte** (ride 180 越南黑水牛, tiếng Việt 06/09) — txtreader chỉ GBK;
   công cụ đổi về ASCII như ride-data đã làm và **từ chối** mọi dòng không GBK khác.
5. **Item CY trỏ tới dòng `附件`** (Visual 95/97/152) mà CY không phát hành ride ⇒ sau khi bỏ ride GL trỏ nhầm,
   chúng lộ ra mồ côi. Đúc theo ride của con chính (cùng `ModelID`).
6. **Cột `速度90` của bảng 0.85 gốc lặp giá trị cột 85** (146 ô) — trước đây "đúng model" vì chỉ kiểm bậc đang dùng.
7. Trong `bash -lc '…'` của công cụ Bash, **biến gán trong shell trong** ra rỗng (`$L`) — viết script ra file rồi
   gọi, đừng chuỗi một dòng.
8. **`--out` của bot là đường tương đối từ repo** và phải là thư mục mới; bot có `--select-ride` chỉ ở
   `Build/cmake/ride-core-x64/bin` (và các cây build sau 22:09) — đã chép về `Build/bot-ride-finish/`.

## 7b. Trâu Đen (越南黑水牛) — thú cưỡi người dùng tự làm, đưa vào CanonicalCY (quyết định điều phối 18/09)

Không được để đỗ xe. `Tools/reapply/ride/trau_den_import.py` (chạy Windows, `plan|apply|verify|undo`) đưa từ `client_GL`
vào `Assets/CanonicalCY` theo ngoại lệ đã duyệt cho tài nguyên GL — **chỉ thêm, không đè**, sổ sách
`Registry/batches/2026-09-18-trau-den-cy.{tsv,yaml}` (nguồn + sha256 từng tệp), sao lưu `Build/reapply-bak/trau-den/<UTC>/`:

| việc | chi tiết |
|---|---|
| 3 tệp thêm mới | `Model3Folder/trau_den.mesh` (242 577 B, sha `e71b27cc…`), `trau_den.skeleton` (362 062 B, JX3 64 xương, 7 animation tên như ActionSet 白牦牛), `Material5Folder/tga_trau_den.dds` (174 904 B) — cùng sha với GL |
| `all.obj` | nối khối `<Object name="trau_den.obj">` (3 997 byte GBK, 11 locator kể cả `attach1` trên `Bip001_Spine1`, hiệu ứng 06/09) trước `</AllObjects>` |
| `all.material` | nối `material trau_den : Mtl_Character_PSLit` (template có trong `MaterialTemplates.zip` của CY; CY hiện dùng `Mtl_Character_Lit` cho 8 957 vật liệu — nếu ảnh ra sai tông thì đổi sang `Lit` theo mẫu `骑乘金翅100728`) |
| DBC (nối dòng cuối + nối pool) | `CharMount 1220` = bản sao dòng 17 白牦牛 CY (con vật gốc của Trâu Đen): ModelID 9994, AddHeight 0.6, col 5 = 461 (CY 白牦牛 cũng 461 — cột này **không** phải ActionSetFile id, CY/GL cùng số dù bảng ActionSetFile khác nhau), rider 829/1425 (`女/男主角_白牦牛.txt`, đúng tên tệp GL 273/540), không bay · `CharModelEx 9994` = bản sao 1006 白牦牛.obj, linked id họ 牦牛 3166..3176, ActionSet 1481 (`白牦牛.txt` = tên tệp GL 582) · `ExteriorRideCamera 1220` = bản sao dòng 17 |
| kiểm | `verify` ok: 354/7617 dòng, cột 0 tăng dần, pool NUL, `dbc_inventory.Table` đọc lại 354; `plan` lần 2 = 0 việc |

Server: ride **1180** (dải đỗ xe) đã trỏ `模型索引 1220` và 9 impact `骑乘ID 1220` ⇒ không đổi gì ở `configs/`; `ride_axis.py`
bỏ qua CharMount 1220 khi tìm chỗ trống (không đúc dòng thứ hai). Tên trong bảng: `越南黑水牛` GBK (GL ghi "Trâu Đen" UTF-8;
client CY chưa hiện tên ride vì `LuaFnGetExteriorRideInfo` còn stub). test15 đã được cấp ride 1180. Đo sau restart:
`10-bot-ride.ps1 -SelectRide 1180` (mong `ride_model=1220`) + `20-live-ride.ps1 -RideProbe 1180` (ảnh).

## 7c. ĐO SAU RESTART LẦN 2 (18/09, server 03:51:27 → LISTEN 03:52:49, ~82 s; log nạp sạch: `SCENE_LOAD_FAIL 0`, `MONSTER_CFG_FAIL 5`, `traceback 0` = baseline)

**(a) Bảng TRONG BỘ NHỚ** (tiêm `probe_ride2.lua` chỉ-đọc vào service cảnh 2 `:00000351` qua `debug_console` 16002):

```
[PROBE_RIDE2] exterior_ride dang nap = 364 | CY(<=297) = 297 | lap cho(400..) = 17 | do xe(1000+) = 50
              | co bac 125 = 364 | o impact = 3276 | chet = 0 | moi bac dung 骑乘ID+toc do = 364 | sai = 0
[PROBE_RIDE2] ride 201 照夜白 model=265 speed_up=125 imp[125]=50416 logic=14 骑乘ID=265 speed%=125   ← bậc 125 CHẠY
[PROBE_RIDE2] ride 551 大风  model=151 speed_up=80  imp=51795 骑乘ID=151   ← con đúc, 10 item nay dùng được
[PROBE_RIDE2] ride 1180 越南黑水牛 model=1220 speed_up=70 imp=51748 骑乘ID=1220   ← Trâu Đen
[PROBE_RIDE2] visual 43 -> 47 | 24 -> 22 | 26 -> 25 | 230 -> 175 | 308 -> 236 | 94 -> 96 | 151 -> 551 | 95 -> 495
```

Dòng cuối là **P2 chạy thật**: 8 `模型索引` dùng chung nhiều ride nay trả **một** ride xác định (trước đây `pairs()` trả ngẫu nhiên).

**(b) Ack quay lại** — `bot-sau-96` (test15 chọn ride 96, gửi `CGCharAutoRide`): `ride_replies` **0 → 1**.
Bản vá `wait_ride_ready 15→45` có hiệu lực (log lần thử hỏng sau đó in `sau 46 lan cho`, tức trần mới là 45).
Con thú **dính vào nhân vật**: phiên bot kế tiếp đăng nhập đọc ngay `ride_model=94`, `ride_model_changes=1`.
*(Trường `ride_model` trong `result.json` của phiên ĐANG cưỡi vẫn −1: bot chỉ đọc `ride_model` từ ảnh chụp thuộc tính
lúc vào thế giới, không theo dõi cập nhật refix — hạn chế của bot, không phải của server.)*

**(c) Không còn thất bại IM LẶNG** — `bot-sau-chon2-xuong` (chọn ride 2 虎, không sở hữu):

```
[DIAG_RIDE_PK] SELECT_ABORT ly do=KHONG SO HUU ride= 2     ← lựa chọn GIỮ NGUYÊN 96, người chơi nhận tip
[DIAG_RIDE_PK] RIDE_REQ ... RIDE_DISMOUNT ride_model= 94   ← bấm lại khi đang cưỡi = XUỐNG THÚ (trước chỉ ack)
```
Gói `GCScriptCommand` 23 byte trong `world-events.tsv` của phiên đó = `notify_tips` thật sự tới client.

**(d) 3 đi bộ + 3 bay, lên/xuống/đổi** — `ride_test2.lua`, 04:00:30–04:01:31, **6/6 đúng model, 7/7 xuống đúng**:

| ride | tên | model mong đợi | `ride_model` | bay (CharMount) | ms |
|---|---|---|---|---|---|
| 1 | 陆行雕 | 21 | **21** | 0 | 3 500 |
| 264 | 飒露紫 | 346 | **346** | 0 | 3 500 |
| 47 | 紫电 | 43 | **43** | 0 | 3 500 |
| 96 | 金翼龙兽 | 94 | **94** | **5.0** | 3 510 |
| 109 | 绝云焱龙 | 162 | **162** | **3.0** | 3 500 |
| 551 | 大风 (đúc) | 151 | **151** | **2.0** | 3 500 |

Mỗi lần "XUONG thu" đều ra `ride_model = -1`. Không thú đi bộ nào nhận model bay và ngược lại (cột `fly` lấy từ
`CharMount` CY mà client vẽ). **Độ cao thật là việc của client** ⇒ phép đo (e).

**Bẫy tìm ra ở lượt (d) đầu tiên (03:56)**: kỹ năng 21 có `冷却时间 = 3000 ms`. Lên thú ngay 1 giây sau khi xuống ⇒
`push_command_use_skill` trả `OR_COOL_DOWNING (-6)` nhưng `char_auto_ride` vẫn chờ hết 4,6 s rồi báo `#{ZQGZ_110512_20}`
("chưa học kỵ thuật") — **sai nghĩa**. Bản vá **P3e** kiểm hồi chiêu trước và trả `OR_COOL_DOWNING` ngay.
Kịch bản (d) nay chờ 6,5 s giữa hai lần triệu hồi, đúng như người chơi thật.

### (f) Sau RESTART 3 (08:27:48, log sạch: `SCENE_LOAD_FAIL 0`, `MONSTER_CFG_FAIL 5`, `traceback 0`) — kiểm P3e

Bảng vẫn nguyên: probe 08:34:03 in lại **`dang nap = 364 | CY = 297 | lap cho = 17 | do xe = 50 | co bac 125 = 364 |
o impact = 3276 | chet = 0 | sai = 0`**. Con thú **sống qua restart**: nhân vật test đăng nhập lại vẫn đang cưỡi
`ride_model = 94`.

`ride_cooldown.lua` (08:32:24–08:32:34):

```
[RIDE_CD] 1. LEN ride 1 -> ride_model= 21 | ms= 3500
[RIDE_CD] 2. XUONG -> ride_model= -1
[DIAG_RIDE_PK] RIDE_ABORT ly do=KY NANG 21 CON HOI (3000 ms)          ← P3e
[RIDE_CD] 3. LEN NGAY khi con hoi -> ride_model= -1 | ms= 2000
[RIDE_CD] 4. doi het hoi roi LEN -> ride_model= 21 | ms= 3610 | DUNG= true
```

Bot của lượt đó: `operate_results=1 last_or=-6` ⇒ **mã `OR_COOL_DOWNING` thật sự tới client** (trước P3e: 0 gói,
người chơi chờ 4,6 s rồi nhận câu báo sai). Đợi hết hồi thì lên bình thường ⇒ bản vá không chặn nhầm.

### (e) ẢNH BAY — người chơi thật lơ lửng [DK]

`20-live-ride.ps1 -Label live-fly-96 -RideProbe 96` (stage riêng, test15, 08:39). `WXClient.log`:

```
[08:39:15] CYS ride: CGCharAutoRide flag=1 sent (mount=-1)
[08:39:18] CYS ride: mount -1 -> 94, fly height 5.0 (FLYING)
[08:39:18] CYS ride: GCCharAutoRide flag=1 after 3547 ms (mount=94 fly=5.0)
```

**Dòng `got no reply in 6000 ms` của 17/09 đã BIẾN MẤT**, thay bằng ack thật sau **3 547 ms** — bản vá
`wait_ride_ready 15→45` chứng minh xong ở tầng client. Ảnh (`live-fly-96/`):

| ảnh | nội dung |
|---|---|
| `cys-live-198549906-world-1.png` | CYTest15 còn **đang niệm** kỹ năng 21 (tư thế dang tay) — đúng 3 000 ms trước khi thú hiện |
| `cys-live-198549906-cam-yaw90.png` | CYTest15 **đã trên thú**, camera xoay 90° nhìn lên cánh vàng |
| **`cys-live-198549906-cam-sky-low.png`** | **ảnh chốt: CYTest15 cưỡi 金翼龙兽 LƠ LỬNG giữa trời**, cao hẳn trên nền gạch; nhãn tên vẽ ở mặt đất bên dưới (nhãn neo theo điểm đi bộ), còn người + thú được nâng đúng `m_fFlyHeight = 5.0`. Đối chứng ngay trong khung: CYTest13 của nhánh khác cưỡi thú **đi bộ** đứng sát đất |

Ba ảnh này cũng là cặp đối chứng "thú bay ≠ thú đi bộ" mà mục 0 yêu cầu, chụp **cùng một khung hình**.

**Lượt Trâu Đen — hai lần chưa ra ảnh, cả hai đều vì lý do NGOÀI dữ liệu thú, mỗi lần lại chứng minh thêm một điều:**

1. `live-traudien-1180` (08:40): hỏng ở **đăng nhập** — chạy ngay sau lượt trước nên `login_flag = 8`
   (tài khoản còn online + cooldown 20 s). Bài học: nghỉ ≥ 60 s giữa hai phiên GUI.
2. `live-traudien-1180b` (09:27): **PASS cả 20 cổng kiểm** của runner, nhưng nhân vật **đăng nhập trong trạng
   thái ĐANG CƯỠI** con 94 của phiên trước — buff cưỡi được lưu vào DB (`impact_list`) nên sống qua cả đăng xuất:

   ```
   CYS ride: mount -1 -> 94, fly height 5.0 (FLYING)      ← vào game là đã ở trên thú bay
   CYS ride: CGCharAutoRide flag=1 sent (mount=94)
   CYS ride: mount 94 -> -1, fly height 0.0               ← P3a: đang cưỡi mà bấm = XUỐNG
   CYS ride: GCCharAutoRide flag=1 after 361 ms (mount=-1 fly=0.0)
   ```

   Đầu dò chỉ gửi **một** gói auto-ride nên gói đó bị dùng để xuống thú. **Thu hoạch phụ, đáng giá hơn ảnh:**
   đây là **P3a chạy trong client thật** (ack **361 ms** vì xuống thú không phải niệm 3 000 ms), và là bằng chứng
   **thú cưỡi sống qua đăng xuất/đăng nhập** — `impact_data:init_from_db_data` phục hồi buff lớp 99.

   Sau lượt đó Mongo xác nhận trạng thái sạch: `attrib.ride = 1180`, `ride_model = -1`, **0** impact logic 14 ⇒
   lượt kế tiếp (`live-traudien-1180c`) sẽ lên Trâu Đen ngay. Đang xếp hàng.

⇒ **Quy tắc cho người chụp ảnh thú cưỡi sau này**: kiểm `ride_model` + `impact_list` của nhân vật **trước** khi chạy
(`do-dac`-style: `mount_state.py`); nếu đang cưỡi thì gói auto-ride đầu tiên sẽ là lệnh XUỐNG, không phải lệnh lên.

## 7d. Phân định số liệu với `review-red`: `335/335` hay `329/335`?

`review-red` đo độc lập và báo **6 ô sai nguy hiểm** — ride 173 bậc 10 trúng *độc*, ride 169/170/171 bậc 90 trúng
*biến hình*. Kết luận: **họ đúng, nhưng về bảng CŨ** (trước lượt đổi trục của tôi); và **họ đếm THIẾU**.

Phép phân định (đọc **tên + `逻辑ID`** của chính 6 ô đó trên hai bảng — script
`Build/Logs/2026-09-18-ride-finish/do-dac/six_cells.py`, chạy lại được):

| ô | bảng TRƯỚC khi đổi trục (ride-data 17/09) | bảng SỐNG hôm nay (trục CY) |
|---|---|---|
| ride 173 bậc 10 | impact 53108 `一日丧命散效果` **logic 102** (độc) | impact 50165 `坐骑：玄天狐` **logic 14**, `骑乘ID 230`, tốc độ 10 |
| ride 169 bậc 90 | impact 47700 `瑶山豹` **logic 97** (biến hình) | impact 50136 `坐骑：地火离炎兽` logic 14, `骑乘ID 225`, tốc độ 90 |
| ride 170 bậc 90 | impact 47751 `白雕` **logic 97** | impact 50145 `坐骑：布丁甜心` logic 14, `骑乘ID 226`, tốc độ 90 |
| ride 171 bậc 90 | impact 47759 `木牛流马` **logic 97** | impact 50154 `坐骑：灵狐` logic 14, `骑乘ID 228`, tốc độ 90 |
| **quét toàn bảng** | **146/2 680 ô sai nghĩa** | **0/3 276 ô sai nghĩa** |

**`review-red` đếm thiếu một nửa lớp nguy hiểm.** Quét toàn bảng cũ theo đúng luật của họ (logic ≠ 14) ra
**12 ô**, không phải 6 — họ bỏ sót ride 173 bậc **20/40** (cùng `一日丧命散效果`), ride 173 bậc **75/80/85/90**
(`黄泉咒印` logic 169, một lời nguyền) và ride **176** bậc 10/20 (`缚影截脉` logic 179, trói chân). Phân loại đầy đủ
146 ô sai của bảng cũ: **125 ô lệch bậc tốc độ** (cột `速度90` chép lại dòng của bậc 85), **9 ô lệch `骑乘ID`**,
**12 ô sai hẳn họ impact**. Script: `do-dac/old_breakdown.py`.

Mức nguy hiểm thật của bảng cũ, nói cho đúng: `skill_14` dùng `impacts[max_speed_up]` với `max_speed_up` = bậc lớn
nhất trong **các ride SỞ HỮU**, còn dòng lấy là của ride **đang chọn**. Người chỉ sở hữu đúng ride 173 sẽ chạm ô
bậc 75 của nó; sở hữu thêm một con bậc cao hơn thì chạm ô bậc 80/85/90 — **cả bốn ô đó đều là `黄泉咒印`**. Nên
"lên thú bị dính lời nguyền/độc" là **có thật** với ride 173 ở mọi cấu hình sở hữu, chứ không phải trường hợp hiếm.

⇒ **Không cần sửa gì, không cần restart 4 vì việc này.** Lượt đổi trục đã xoá sạch lớp lỗi đó: mọi ô của cả 364
ride nay đều là dòng `坐骑：<tên>` logic 14 do chính công cụ đúc, `骑乘ID == 模型索引`, tốc độ == bậc của cột.
Kiểm lại lần cuối 08:5x: `ride_axis.py verify` `ok: true`, `0/3276 ô sai`.

**ĐỊNH NGHĨA BỘ KIỂM — luật mà mọi con số "ô impact" trong đặc tả này tuân theo.** Một ô của `Exterior_Ride` là
**ĐÚNG** khi thoả **cả bốn**:

1. ID đó **có dòng thật** trong `StandardImpact`;
2. dòng đó có **`逻辑ID == 14`** (`StdImpact014` — họ impact thú cưỡi; điều kiện này loại độc/biến hình/nguyền);
3. tham số **`骑乘ID(-1为无效) == 模型索引`** của chính ride đó (cưỡi ra **đúng con**);
4. tham số **`移动速度修正% ==` bậc của cột** chứa ô (cột `速度85` phải mang 85, không phải 90).

Kiểm trên **cả 9 bậc** của **mọi** ride, không chỉ bậc đang dùng. Ba phép đếm đã tồn tại trên cùng dữ liệu:

| phép đếm | xét gì | bảng cũ | bảng nay |
|---|---|---|---|
| `ride-data` 17/09 | (1)+(3), chỉ **một** bậc đang dùng | `335/335` sạch | — |
| `review-red` 18/09 | (2), một phần bảng | 6 ô sai | (lỗi thời) |
| **bộ kiểm này** | (1)+(2)+(3)+(4), **9 bậc × mọi ride** | **146 ô sai** (12 trong đó sai họ impact) | **0/3 276** |

⇒ Trước khi đối chất số với ai, **đối chiếu luật trước**. Ba con số trên đều "đúng" theo luật của chúng.

## 8. Sau restart lần 2 — kịch bản đo (lệnh chạy được)

```powershell
Set-Location C:\TLBB\085\CY-Source
# (a) bảng TRONG BỘ NHỚ: tiêm probe chỉ-đọc, mong đợi "dang nap = 364 | CY = 297 | co bac 125 = 364 | chet = 0 | sai = 0"
wsl -d TLBB -u root -- bash -lc 'cp /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-18-ride-finish/do-dac/probe_ride2.lua /tmp/ && cp /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-18-ride-finish/do-dac/ride_test2.lua /tmp/'
#     debug_console 16002:  inject :<scene-service cua canh 2, lay tu dong AUTO_ROUTE_ENTER> /tmp/probe_ride2.lua
# (b) bot thuần (không cần khe Game.exe): chọn 96 rồi cưỡi -> ride_replies=1, ride_model=94 (金翅), chạy lại lần 2 -> xuống thú
powershell -NoProfile -ExecutionPolicy Bypass -File Build\Logs\2026-09-18-ride-finish\10-bot-ride.ps1 -Account test15 -Guid 200016 -SelectRide 96 -RideFlag 1 -Label bot-sau-96
powershell -NoProfile -ExecutionPolicy Bypass -File Build\Logs\2026-09-18-ride-finish\10-bot-ride.ps1 -Account test15 -Guid 200016 -RideFlag 1 -Label bot-sau-xuong
# (c) chọn thú KHÔNG sở hữu (ride 2 虎) -> SELECT_ABORT + tip; cưỡi -> không
powershell -NoProfile -ExecutionPolicy Bypass -File Build\Logs\2026-09-18-ride-finish\10-bot-ride.ps1 -Account test15 -Guid 200016 -SelectRide 2 -RideFlag 1 -Label bot-sau-khong-so-huu
# (d) 3 thú đi bộ + 3 thú bay, lên/xuống/đổi, trong một phiên bot dwell dài rồi tiêm ride_test2.lua (đọc RIDE_TEST2 trong log)
# (e) ẢNH bay: khe Game.exe, stage riêng, test15, probe chọn 96 (金翅, bay 5.0) -> dòng "mount -1 -> 94, fly height 5.0 (FLYING)" + PNG world-1
powershell -NoProfile -ExecutionPolicy Bypass -File Build\Logs\2026-09-18-ride-finish\20-live-ride.ps1 -Label live-fly-96 -Account test15 -RideProbe 96 -Seconds 120
```
