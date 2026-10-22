# Bóng đổ — khép khác biệt còn lại so với CY 3.71 (shadow-finish, 17/09/2026)

Tiếp nối `shadow-cy_vi.md` (đặc tả CY) và `d3d9-parity_vi.md` §L1. Chuẩn duy nhất là CY 3.71
(`Tools\DATA NEW\CY Game`). Ký hiệu: **FACT** = có bằng chứng (offset/hàm/trace/số đo), **INF** = suy luận.


---

## 1. Cách đo

| Việc | Lệnh |
|---|---|
| Dựng cây riêng | `cmd /c "Build\Logs\2026-09-17-shadow-finish\build_shadow.cmd <log> [targets]"` (cây `Build\cmake\shadow-x64`, parallel 4) |
| Chụp khung dự án ở camera CY | `powershell -File Build\Logs\2026-09-17-shadow-finish\viewer_shadow.ps1 -Tag <tên> -Cases w09,w28,w42,login [-Env 'K=V;K2=V2']` |
| Tập caster của một capture | `python caster_set.py <capture> [--dump x.tsv]` |
| Hằng số nhận bóng + hộp ortho | `python shadow_consts.py <nhãn>=<capture> ...` |
| Ma trận chiếu + hash chương trình caster | `python shadow_proj.py <nhãn>=<capture> ...` |
| Số lệnh vẽ theo pass / RT của pass | `python pass_counts.py`, `python pass_rt.py` |
| Độ sáng vùng bóng trên nền | `python shadow_metrics.py CY=<png> PROJ=<png>` |
| Hai bản đồ bóng R32F cạnh nhau | `python dds_shadow.py <a.dds> <b.dds> <out.png>` |
| Caster dự án có nằm trong hộp bóng của CY không | `python inside_cy_box.py <cy capture> <proj capture>` |
| Bàn thử CSM | `Build\cmake\shadow-x64\bin\CysShadowTest.exe --level 2 --size 4096 --out <dir> --timing 60 --stability 30` |

Công tắc A/B mới: **`CYS_SHADOW_BASIS=z`** trả trục cơ sở ánh sáng về bản cũ (neo theo trục Z thế giới).

---

## 2. Bảng khác biệt đo được TRƯỚC khi sửa (camera CY `w09`, Đại Lý, 1280×720)

Nguồn: `cy-world-1-trace\f002960_w09-idle` (CY) so với `viewer-base\w09-trace\f000230_frame` (main `c2ca6001`).

| # | Hạng mục | CY 3.71 | CY-Source | Kết luận |
|---|---|---|---|---|
| 1 | Bản đồ bóng | 1 × 4096² R32F, DS 4096² D24S8, vp toàn map | **giống hệt** | đạt |
| 2 | Chương trình caster (hash VS/PS) | `1d8605c4`/`a38170c2` tĩnh, `fe9b84b7` skin, `9beba414`/`c46a8a36` địa hình, `83c098ab`+`c0dcc9a8`/`2d5580e0` alpha | **giống hệt 5/5 cặp** | đạt |
| 3 | Trạng thái pass bóng | CULLMODE 2 (CW), ZFUNC 4, ALPHATEST 0, DEPTHBIAS 0, COLORWRITE 15 | **giống hệt** | đạt |
| 4 | Hằng nhận bóng | `shadow_param` (1,1,4096,0), `shadow_csm_param` (1,1,0.005,8000), `isystem_userdata` (8,0,0,20) | **giống hệt** | đạt |
| 5 | Hướng đèn | (−0,3710, −0,6392, −0,6736) | **giống hệt** | đạt |
| 6 | RT các pass | bóng → `rt1`; cảnh → `rt2` + DS **INTZ** 1280×720 | **giống hệt** | đạt |
| 7 | Độ sáng dưới bóng lá cọ (tỉ lệ bóng/sáng) | 0,6672 và 0,4355 | 0,6621 và 0,4348 | lệch ≤ 0,8 % |
| 8 | **Trục cơ sở ánh sáng** (`shadow_view_matrix` hàng 0) | (0,8759, **0,0000**, −0,4824) — neo theo **+Y** | (−0,8649, 0,5020, **0,0000**) — neo theo **+Z** | **LỆCH** |
| 9 | **Hộp ortho của bản đồ bóng** | **9422 × 7555**, sâu 17215 | **9701 × 7684**, sâu 17216 | **+3,0 % / +1,7 %** |
| 10 | **Số ô địa hình trong bản đồ bóng** | **40** | **48** | **+20 %** |
| 11 | Số caster (thực thể + địa hình) | 306 | 1057 | xem mục 3 |

---

## 3. Bác bỏ giả thiết "CY có luật chọn caster mà dự án thiếu" (L1)

`d3d9-parity_vi.md` §L1 ghi "CY 306 caster ở w09, dự án 2.757 ⇒ CY có luật chọn caster chưa biết". Đo lại:


| Khung CY (cùng cảnh Đại Lý) | Thời điểm | Caster | Tĩnh | Alpha | Skin | Địa hình | Khoảng cách xa nhất tới mắt |
|---|---|---|---|---|---|---|---|
| `w09-idle` | 14:19:20 | 306 | 181 | 76 | 9 | 40 | 5.953 |
| `w28-tp1` | 14:19:39 | 709 | 484 | 143 | 38 | 44 | 7.720 |
| `w42-tp2` | 14:19:53 | 703 | 480 | 160 | 21 | 42 | 9.075 |
| đăng nhập `at84s` | — | 728 | 423 | 178 | 101 | 26 | 23.320 |

Trong **cùng một lượt chạy, cùng một cảnh**, số caster CY tăng 306 → 709 sau ~19 giây đồng hồ (`trace.log`
14:19:20 → 14:19:39, đã tính cả ~6 giây dừng để proxy đổ render target), và khoảng cách xa nhất tăng
5.953 → 7.720 → 9.075. Cảnh đăng nhập, nhỏ hơn nhiều nên dựng xong, cho 23.320. Vậy "trần ~6.000" ở `w09` là
**trạng thái dựng dần**, không phải luật lọc; `perf-cy_vi.md` (bẫy 6) cũng ghi "w09 CY mới ~330 vật".

**Hai phép kiểm khép hẳn giả thiết này:**

1. **Cảnh đăng nhập `erengu_DL` (1.078 vật — cả hai bên đều dựng xong).** Tập caster của dự án **trùng
   từng con số với CY**: 728 caster = 423 tĩnh + 178 alpha + 101 skin + 26 địa hình, **919.379 tam giác**, cùng
   phân bố khoảng cách (p25 5.041 / p50 7.881 / p99 19.603 / max 23.320). Không thừa, không thiếu một lệnh vẽ nào.
   Bản đồ bóng 4096² của hai bên gần như cùng một ảnh: `shadowmap_login_cy_vs_proj.png` (0 texel 17,16 % CY vs
   17,07 % dự án, biên độ sâu 9.808 vs 9.819 đơn vị).
2. **Game.exe (world replay `world-7`, 15/09) có cùng bộ dựng dần + camdiscull như CY:** 253 / 303 / 258 caster
   (36 / 40 / 35 ô địa hình) — nằm trong khoảng của CY (306…709, 40…44 ô), khoảng cách xa nhất 3.628…6.407 so với
   CY 5.953…9.075.

Chênh 1057 vs 306 chỉ xuất hiện ở **TlbbViewer**, vì viewer dựng toàn bộ cảnh ngay
(`setDisableIncrementalBuildScene`) trong khi CY mới dựng ~330 vật ở khung đó. `camdiscull` vẫn chạy trong viewer
(log `CYS-PERF camdiscull: created=5662 hidden=443`) nhưng chỉ ẩn 7,8 % vì luật CY là
`dist² ≤ max(depth², (bán kính × 14)²)` với depth 4000.

**Kết luận:** không có luật chọn caster nào còn thiếu. Mục L1 "luật chọn caster như CY" **đóng**; phần còn lại của
L1 (hộp ortho / số ô địa hình) được sửa ở mục 5.

---

## 4. FACT mới từ Render.dll của CY — nút render ShadowMap


**Ánh xạ sang CY-Source (INF).** Hàng đợi của WX 0.85 khác CY: ô địa hình và StaticEntity nhận bóng ở queue 25,
StaticEntity còn lại ở 50, `LogicModel` ở 60, nước ở 75/77, hạt ở 80. Dải 25…70 của
`CYSShadowCasters` phủ **đúng cùng nhóm đối tượng** mà CY phủ bằng 40…50 + 68…70 (địa hình + vật tĩnh + model động,
loại nước/hạt/trời/overlay). Chép nguyên con số của CY sẽ **sai**, vì nó sẽ loại địa hình (25) và model (60) của
dự án. Giữ 25…70.


---

## 5. Sửa: trục cơ sở ánh sáng theo CY — `CYSShadowFitting.cpp::lightBasis`

**Nguyên nhân.** `Ogre::Camera` giữ trục yaw cố định +Y, nên `Camera::setDirection` cho
`x = chuẩn hoá(Y × z)`, `y = z × x`, `z = −dir`. Kiểm bằng số trên khung CY `w09`: với
`dir = (−0,3710, −0,6392, −0,6736)` công thức đó cho hàng 0 = (0,8759, 0, −0,4824) và hàng 1 =
(−0,3084, 0,7690, −0,5599) — **trùng từng chữ số với `shadow_view_matrix` của CY**. Dự án neo trục x theo Z thế
giới, tức là cùng hướng nhìn nhưng **xoay quanh trục đèn**; vì fit `tight` là AABB *trong hệ đó*, hộp ortho ra to hơn.

**Thay đổi** (`Src\Engine\WXCore\CYS\Shadow\CYSShadowFitting.cpp`, thẻ `CYS-SHADOW-FINISH`): dùng luật của CY khi
|dir.y| < 0,999 (gần thẳng đứng thì giữ luật cũ để không suy biến). `CYS_SHADOW_BASIS=z` trả về bản cũ.

**Số đo A/B cùng một binary, camera CY `w09`** (`viewer-basisA` = `CYS_SHADOW_BASIS=z`, `viewer-basisB` = mặc định):

| Chỉ số | Trước (trục Z) | Sau (trục Y = CY) | CY 3.71 |
|---|---|---|---|
| `shadow_view_matrix` hàng 0 | (−0,8649, 0,5020, 0,0000) | **(0,8759, 0,0000, −0,4824)** | (0,8759, 0,0000, −0,4824) |
| Hộp ortho | 9701 × 7684 | **9425 × 7557** | 9422 × 7555 |
| Lệch so với CY | +3,0 % / +1,7 % | **+0,03 % / +0,03 %** | — |
| Cạnh texel (đơn vị thế giới) | 2,368 | **2,301** | 2,300 |
| Ô địa hình trong bản đồ bóng | 48 | **40** | **40** |
| Lệnh vẽ pass bóng (viewer, dựng hết cảnh) | 1057 | 978 | (CY chưa dựng xong, xem mục 3) |
| Tam giác pass bóng | 307.048 | **278.598** (−9,3 %) | — |
| CPU cập nhật atlas (trung bình 5 s) | 6,447 ms | **5,163 ms** (−19,9 %) | — |
| Tỉ lệ bóng/sáng dưới lá cọ | 0,6621 / 0,4348 | 0,6629 / **0,4367** | 0,6672 / 0,4355 |
| Sai khác trung bình với khung CY ở vùng lá cọ | 1,318 | **1,291** | 0 |

**Số ô địa hình trong bản đồ bóng, cả ba camera CY của Đại Lý** (`viewer-camsB`, hộp ortho 9425 × 7557 ở cả ba):

| Camera | CY 3.71 | CY-Source sau khi sửa |
|---|---|---|
| `w09` | 40 | **40** |
| `w28` | 44 | **44** |
| `w42` | 42 | **42** |

(Trước khi sửa `w09` là 48.) CPU cập nhật atlas ở ba camera: 5,163 / 5,718 / 4,799 ms (viewer dựng hết cảnh).

Ảnh: `w09_palm_cy_vs_before_after.png` (CY / trước / sau), `diff_basisA_basisB.png` (0,578 % điểm ảnh lệch > 12 —
chỉ là viền bóng dịch dưới một texel), `login_frame_cy_vs_proj.png`, `shadowmap_login_cy_vs_proj.png`.

Bàn thử `CysShadowTest --level 2 --size 4096` chạy lại sau khi sửa: rc 0, cả hai kiểu fit còn dùng được, nháy
(30 khung, camera fit rung ±37/23 đơn vị) `stable` 0,0003 vs `tight` 0,0291 |dRGB|/điểm/khung — dự án giữ `tight`
như CY (`bench-cy\`).

---
