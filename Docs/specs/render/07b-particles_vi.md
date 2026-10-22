# 07b — Hệ hạt (particle) theo client_GL: đặc tả và bằng chứng

Tài liệu của nhánh **fx-particles** (13/09/2026). Mục tiêu: CY-Source đọc `all.particle` của client_GL ("B") và của CY 3.71
("C") **đúng như B**: mọi khoá, kiểu, mặc định và thuật toán. Tài liệu này là nguồn tham chiếu khi sửa `Src\Engine\ParticleFX2`,
lõi hạt OGRE (`OgreParticle*`, `OgreBillboard*`), plug-in `ParticleFX` và các renderer/affector hạt của WXCore.


## 0. Nguồn và quan hệ B / C

|---|---|
| B `Plugin_ParticleFX.dll` | `f84752770006993583695402bcf5bada3f507f76044c326c166fe0821b1533f9` |
| B `Plugin_ParticleFX2.dll` | `31febfa71aaa1c22ce1a59b4db8542fd9218e968d317b3312919946413235974` |
| B `OgreMain.dll` | `a86de953d14fcd2ee6ef313f5c37507d7c545f11891eddd5f0f0bb0ffd0b0cb3` |
| B `Render.dll` | `49b2ab1f3c72d4b1c957e463bbe474f0ef86f3f085fd8aa8660776f9de1369bb` |
| C `Plugin_ParticleFX.dll` | `ad2f5b1192a76c1982a8a3093fabf62ebf1997160ff4b31aef1ceafe4061bb9b` |
| C `Plugin_ParticleFX2.dll` | `288d1192f2ab9c23872a47b72e3991d40919845afce308a51fed22c91fb37877` |
| C `OgreMain.dll` | `a226c865cf3f45af0669e0bcb88dd0b44ba3c0401e3a5f9ae18796a7ac1ffb87` |
| C `Render.dll` | `e6e67de45489f90207379419c0eb2e9f4fbdbd1d800cc6f46902c1fe5eb0cec7` |


### 1.3 Parser (FACT, `ParticleSystemManager::parseScript` `18012cba0`)

- Dòng cấp hệ chứa `stacks`, `slices` hoặc `repeat_times` **không** phải thuộc tính của hệ: nó được đưa cho affector `SequenceFrame`
  đầu tiên của hệ (tạo mới nếu chưa có). Đây là cách B làm flip-book cho `texcoord_billboard` (Canonical 1.981/1.944/507 dòng, S2 3.699/3.575/682).
  Census của fx-audit so giá trị ở phạm vi hệ nên báo các dòng này là "value-not-applied"; giá trị thật nằm ở affector `SequenceFrame`
  (kiểm trong `pparams.tsv`: `a_y_dali_06 affector SequenceFrame stacks 4, slices 2`).
- Dòng emitter/affector được hạ chữ thường (như 0.85). Thuộc tính hệ: thử hệ, rồi renderer.

### 1.4 Ngẫu nhiên tất định (CYS, chỉ cho kiểm thử — fx-audit D17)

Không phải hành vi B. `ParticleSystem::setCysDeterministicSeed(seed, true)` hoặc biến môi trường `CYS_FX_SEED=<n>` (đọc khi tạo hệ
đầu tiên): trong `_update` mỗi hệ gọi `srand(hash(tên hệ) ^ seed + 0x9E3779B9·số lần cập nhật)`, sau cập nhật đặt lại
`srand(seed + 0x85EBCA6B·tổng số lần cập nhật)`. Kết quả không còn phụ thuộc thứ tự controller (con trỏ). Mặc định tắt (game không đổi).

## 2. `Particle`: ba chiều (FACT, offset B +0x14/+0x18/+0x1c)

Hạt có `width`, `height`, `depth`. `setDimensions(w, h)` lấy `depth` = độ sâu mặc định của hệ; `setDimensions(w, h, d)` đặt cả ba.
Scaler (plug-in ParticleFX) của B gọi `setDimensions(w, h, 0)`.

## 3. `ParticleEmitter` (FACT, ctor `18011c4c0`)

| Tham số | B | 0.85 |
|---|---|---|
| `velocity` (min/max) | **0** | 1 |
| `time_to_live` (min/max) | **1** | 5 |
| `emission_rate` | 10 | 10 |
| `direction` | +X | +X |
| `angle`, `duration`, `repeat_delay`, `start_time` | 0 | 0 |

`genEmission*`, `genConstantEmissionCount`, `initDurationRepeat`: như 0.85.

### 4.1 `AreaEmitter` (FACT, `initDefaults` `180001f40`)

`setDirection(+Y)` và `setSize(1, 1, 1)` (0.85: hướng +Z, up +Y, kích thước 100³). Vì `setDirection` sinh `up = (+Y).perpendicular() = −Z`:

- `width` trải theo **+X**, `height` theo **−Z**, `depth` theo **+Y** (hướng phát) khi không có `direction`.
- `genAreaAxes`, Box (`180002570`), Point (`18000d3d0`), Cylinder, Ring (`18000d680`): cùng công thức 0.85.

### 4.2 `Ring`

`inner_width`/`inner_height` được **lưu nguyên** (0 = đĩa đặc). 0.85 ép giá trị ≤ 0 hoặc ≥ 1 thành 1 → 723 đĩa `inner_width 0` của dữ
liệu thành vòng mảnh. Mặc định 0,5/0,5.

### 4.3 `Ellipsoid` (FACT, ctor `180007d40`, `_initParticle` `1800082c0`, đã kiểm operand trong asm)

Khoá mới: `inner_width`, `inner_height`, `inner_depth` (thực, mặc định 0), `angle_range` (hai số, độ, mặc định `0 360`),
`height_range` (hai số 0..1, mặc định `0 1`). Điểm = `P0 + k.x·XRange + k.y·YRange + k.z·ZRange`, với Z là hướng phát.
Thứ tự rút ngẫu nhiên: `u = RangeRandom(F(z0), F(z1))`, `phi = RangeRandom(angle)`, `W = UnitRandom()` (không rút W khi là mặt cầu).
`z0 = 2·h0 − 1`, `z1 = 2·h1 − 1`.

1. **Đặc** (một inner bất kỳ = 0, so bằng `RealEqual` eps 1,1920929e−7): `F(z) = (3z − z³ + 2)/3`,
   `z = 2·cos(acos(1 − 1,5u)/3 + 4π/3)`, bán kính lát `sqrt(1 − z²)·(1 − W²)`.
   (Phân bố bán kính KHÔNG đều theo thể tích — B dùng `1 − W²`; kiểm thử đo đúng tỷ lệ `1 − √0,5` bên trong nửa bán kính.)
2. **Mặt cầu** (cả ba inner = 1): `z = u`, bán kính `sqrt(1 − z²)`.
3. **Rỗng** (a, b, c): `k = 4abc`, `G0 = (c³ − 3c + 2)/3`, `G1 = (3c − c³ − k + 2)/3`;
   - `u ≤ G0`: như đặc; `u ≥ G1`: `z = 2·cos(acos(1 − 2abc − 1,5u)/3 + 4π/3)`, bán kính như đặc;
   - giữa: giải `(ab − c²)z³/(3c²) + (1 − ab)z + (2 − 2abc)/3 = u` — tuyến tính nếu `ab = c²`; Cardano nếu ∆ ≥ 0; lượng giác nhánh
     `+4π/3` nếu ∆ < 0; điểm = `W²·elip trong (a, b) + (1 − W²)·đường tròn ngoài`.
   - `u` lớn hơn thể tích vỏ `(4 − k)/3`: B không ghi vị trí (lỗi, chỉ gặp do làm tròn); CY-Source kẹp `u`.

`HollowEllipsoid` của B (inner riêng mặc định 0,5) giữ bộ lấy mẫu cổ điển 0.85.

## 5. `PolarEmitter` (B `Plugin_ParticleFX2`, FACT `180007b80`)

| Khoá | Mặc định B |
|---|---|
| `radius_start/step/end`, `theta_start/step/end`, `phi_start/step/end` | 0 |
| `use_polar_step` | **true** (0.85 false; dữ liệu chỉ viết `use_polar_step false`, 601 lần) |
| `flip_yz_axis` | false |
| `reset_radius_count` / `reset_radius` | 0 / false |

- Theo bước: dùng giá trị hiện tại; `x = r·sinθ·cosφ`, không lật: `y = r·sinθ·sinφ`, `z = r·cosθ`; lật: đổi y/z. Sau mỗi hạt
  `θ = fmod(θ + θstep, 360)`, `φ = fmod(φ + φstep, 360)`, `r += rstep` (hoặc về `radius_start` khi `reset_radius` và đếm vượt `reset_radius_count`).
- Ngẫu nhiên: θ, φ, r lấy trong khoảng start–end. Vị trí = `mPosition + (x, y, z)` (không dùng trục của emitter).
- Mọi setter đặt lại giá trị hiện tại về start; `setEnabled` cũng vậy.
- **Không phát hạt nào ở lần cập nhật mà `duration` hết** (0.85 vẫn trả số hạt của lần đó).

### 6.1 `ColourFading` (FACT: ctor `180001450`, `_initParticle` `180002950`, `_affectParticles` `180002670`)

Khoá: `colourN`, `timeN`, `opacityN` (N = 0..5), `repeat_times`, `opacity`, `fade_in_time`, `fade_out_time`.

| Tham số | B | 0.85 |
|---|---|---|
| `colourN` | đen (0,0,0,1) | xám (0,5,0,5,0,5,0) |
| `timeN` | `time0 = 0`, còn lại 1 | tất cả 1 (kể cả time0!) |
| `opacityN` | 1 | (không có: 17.572 dòng Canonical bị từ chối) |
| `repeat_times`, `opacity`, `fade_in_time`, `fade_out_time` | 1, 1, 0, 1 | như B nhưng không có bảo vệ chia 0 |

- Hạt sinh ra: màu **đen** (màu emitter bị bỏ).
- Mỗi cập nhật, `t = 1 − ttl/tổng`, `rt = repeat ≠ 1 ? fmodf(t·repeat, 1) : t`:
  - `!(time0 < rt)` → RGB = colour0, alpha = opacity0;
  - `rt < time5` → đoạn đầu tiên `[time_i, time_i+1)` chứa `rt`: nội suy RGB và **alpha từ opacity** (alpha của colourN bị bỏ);
  - còn lại → stage đầu tiên có `time ≥ 1` (hoặc stage 5).
- Bao opacity theo tuổi thật `t`: `op = opacity`; nếu `fade_in < t` hoặc `fade_in = 0`: khi `fade_out ≤ t` và `fade_out ≠ 1`,
  `op *= 1 − (t − fade_out)/(1 − fade_out)`; ngược lại `op *= t/fade_in`. **Cả RGBA** nhân `op`.
- Dữ liệu: 37.210/42.845 khối không ghi `time0` → với 0.85 chúng bị ghim colour0 suốt đời hạt.

### 6.2 `ScaleInterpolator` (FACT: ctor `18000c160`, `_initParticle` `18000dba0`, `_affectParticles` `18000d640`)

Khoá: `uniform_size`, `width/height/depth_range_start/end`, `use_constant_scale`, `constant_scale`, `use_interpolated_scale`,
`scaleN`, `timeN`, `repeat_times`, `use_interpolated_increment`, `increment_valueN`, `increment_timeN`, `increment_repeat_times`.

| Tham số | B |
|---|---|
| `scaleN` | (1,1,1); `time0 = 0`, còn lại 1 |
| `use_interpolated_scale` | **true** (0.85 false; dữ liệu viết `false` 2.620 lần → ~26.700 khối dựa vào mặc định true) |
| `use_constant_scale`, `use_interpolated_increment` | false |
| `constant_scale`, `increment_valueN` | (1,1,1) |
| `increment_timeN` | **tất cả 1, kể cả time0** (ctor +0x10c) |
| `uniform_size` | true |
| khoảng kích thước | = kích thước mặc định của hệ (w, h, d) |

- Sinh: nếu một khoảng khác kích thước mặc định: `uniform_size` → `s = RangeRandom(wStart, wEnd)`, đặt (s, s, s); ngược lại rút
  theo thứ tự depth, height, width.
- Cập nhật, chế độ đầu tiên đang bật: hạt chưa có kích thước riêng → kích thước mặc định; `use_constant_scale` → `kt += constant·dt`
  (kẹp ≥ 0); `use_interpolated_scale` → `kt = mặc định × curve(scale)`; `use_interpolated_increment` → `kt += curve(increment)·dt` (kẹp ≥ 0).
  Curve: `t ≤ time0` → v0, `t ≥ time5` → v5, còn lại nội suy trong đoạn đầu tiên chứa t.
- `use_uniform_size` (113 dòng, dữ liệu "im85" tự làm) **không phải khoá của B lẫn C** → bị từ chối như ở B (ghi nhận, không hỗ trợ).

### 6.3 `Movement` (FACT ctor `180003cd0`)

`use_start_velocity` mặc định **true** (0.85 false; dữ liệu chỉ viết `false`, 1.270 lần). Toán học như 0.85.

### 6.4 `Revolution` (FACT `18000b660`, `calculateDirection` `18000baa0`)

- `dt` = 0 (RealEqual) → không làm gì. `dt > 0,02` → **hai bước con** `h = dt/2` (game chạy 0,033 s nên luôn là đường này).
- Ma trận quay `Q(rotation_speed·h, rotation_axis)`; tâm = `RangeRandom(center_offset_min, max)` một lần mỗi lần gọi
  (+ vị trí hệ khi hạt ở world space). Hạt trùng tâm → hướng 0.
- `v(p) = (c + M(p − c) − p)/h + dir·inc(t)` với `inc` = `radius_increment` hoặc curve `radius_increment_scaleN`/`timeN`
  (`repeat_times`), `t` tính theo tuổi (bước con đầu dùng `ttl + h`).
- Chống vượt tâm: `a = c − p`, `b = v·h`: nếu `|p + b − c|² + |a|² − |b|² < 0,1` và `|a|² < |b|²` thì `v = a/h`.
- Một bước: `direction = v`. Hai bước: `p += v1·h`, rồi `direction = v2·0,5` (`_applyMotion` cộng `v2·h`).
- 0.85: một bước, không chống vượt tâm. Chi phí CPU của B xấp xỉ gấp đôi 0.85 (mục 11).

### 6.5 `RevoluMove` (FACT `180009da0`), `PolarMove`

`RevoluMove` của CY-Source (nhánh trước) khớp B, kể cả `rotation_speed` đọc bằng `parseAngle`. `PolarMove` giữ như trước (chưa thấy khác biệt).

## 7. Affector của plug-in `ParticleFX`

`Rotator`, `LinearForce`, `DirectionRandomiser`, `ColourFader`, `ColourInterpolator`, `ColourImage`: như 0.85. `Scaler`: như 0.85 nhưng đặt độ sâu 0.

### 8.1 `billboard` (FACT `BillboardParticleRenderData` ctor `18004ce30`)

`billboard_type point`, `billboard_origin center`, **`billboard_rotation_type vertex`** (0.85 BillboardSet: texcoord; dữ liệu viết
`texcoord` 5.478 lần), `common_direction +Z`, `common_up_vector +Y`, `point_rendering false`, `accurate_facing false`,
`speed_relatived_size_factor 0,01`. `_updateRenderQueue` (`18004e030`) như 0.85.

### 8.4 `ribbon`

Chưa đối chiếu chi tiết với B (mục 13).

## 10. Census khoá (Canonical / S2)

`py -3 Tools\fx\fx_census.py --set canonical|s2 --run --viewer <TlbbViewer> --raw <tuyệt đối> --out <tuyệt đối>`
(đường dẫn `--raw` phải tuyệt đối: viewer chạy với thư mục làm việc là thư mục bin).

| | Trước (`Registry\fx`, run-b3) | Sau (fx-particles) |
|---|---:|---:|
| Canonical: dòng hạt bị từ chối | 18.831 | 122 = `use_uniform_size` 113 (B/C cũng từ chối) + `anim_pos1..3` 9 (B cũng từ chối) |
| S2: dòng hạt bị từ chối | 19.141 | 9 = `anim_pos1..3` (B cũng từ chối) |
| Canonical "value-not-applied" | 1.449 (Ring inner 0) | 4.460: `stacks/slices/repeat_times` về SequenceFrame (mục 1.3) + `quota 0` (mục 1.1) |

Số liệu chi tiết: `Build\Logs\2026-09-13-fx-particles\census\census-*.tsv`.

## 10b. Thay đổi hình ảnh so với mốc `run-b3` (fx-audit mục "hồi quy") và nguyên nhân theo B

Sheet `canonical-oracle-fxp` / `canonical-frontend-fxp` (`Build\Logs\2026-09-13-fx-particles\sheets`, `classify-*.txt`,
`diff-*.txt`). Các mục fx-audit gọi là hồi quy đều do **làm đúng như B**, không phải lỗi mới:

| Mục | Hiện tượng | Cơ chế B (bằng chứng) |
|---|---|---|
| S001 Thiếu Lâm (effect `wq_九大门派神器少林禅杖01`) | vòng sét dưới chân nhỏ lại | template `_02/_05`: `particle_width 50`, ScaleInterpolator `width_range 150–200`, `scale0 0 → scale1 1.5`, không ghi `use_interpolated_scale` ⇒ B nội suy mặc định: kích thước = **kích thước mặc định của hệ (50) × curve** (0 → 75), đè kích thước lúc sinh (`18000d640`; vtable IParticleSystem +0x20/+0x28/+0x30 = `getDefaultWidth/Height/Depth`, tên export). 0.85 giữ 150–200. |
| S002 Minh Giáo (`wq_九大门派神器明教刀01`) | khối lửa trắng mép vuông → 3 ngọn lửa cam nhỏ đúng chỗ | cùng cơ chế ScaleInterpolator + ColourFading (không `time0` ⇒ B nội suy từ đen, 0.85 ghim colour0 cả đời) |
| E048 | độ phủ 0,261 → 0,006 | billboard `particle_width 150 / height 10`, ranges 400: B vẽ vệt mảnh 150×10 × curve thay cho khối 400×400 |
| E097 | visible → alive-nothing-drawn | ColourFading không `colour0/time0`: B bắt đầu từ đen và tắt dần về đen (`opacity3/4 0`); phần tử bắt đầu ở 0,40/0,48 s, quota 1, sống 0,3–0,6 s ⇒ chỉ sáng khoảng 0,5–0,75 s, lọt giữa các mốc chụp. Chụp ở 0,5/0,55/0,6/0,7 s thì **visible** (`sheets\canonical-regress-regress`) |
| E061 | 0 % → phủ 90 % khung | một hạt mesh `particle_width/height 0,1`, không `particle_depth`: bản 18:42 ép phẳng (lỗi depth 0), nay vẽ đúng tỷ lệ B 0,1; khung hình phóng to vì camera của sheet bám theo bounds 0,1 của hạt |
| E016 | nothing → saturated | Ring `inner_width 0` là đĩa đặc ở B (0.85: vòng mảnh) ⇒ nhiều hạt chồng nhau hơn |
| E090, E044 | bão hoà / bounds 3.589 → 5.995 | ScaleInterpolator mặc định, `opacity 2` (B nhân cả RGBA), Revolution hai bước con có chống vượt tâm |


## 11. Hiệu năng (200 hệ thật, `Tests\fx\particles\particle_bench.cpp`)

200 hệ lấy theo bước cố định trên `all.particle` Canonical (132 billboard, 47 mesh, 21 texcoord_billboard), dt 0,033 s,
trung vị lượt 2–5 (mỗi lượt = trung vị 3 × 300 khung); trước = HEAD `3c50ba7`, sau = nhánh này:

| mỗi khung | trước | sau | chênh |
|---|---:|---:|---:|
| cập nhật (`_update` 200 hệ) | 0,490 ms | 0,620 ms | +26 % (2,45 → 3,10 µs/hệ) |
| nộp render queue | 0,584 ms | 0,652 ms | +12 % |
| scene (`_updateSceneGraph` + `_findVisibleObjects`, gồm entity mesh) | 1,357 ms | 1,415 ms | +4 % |
| tổng | 2,43 ms | 2,69 ms | +11 % |
| hạt đang sống | 2.749 | 2.576 | −6 % |

Tóm tắt nguyên nhân chênh lệch so với HEAD 0.85:

- Tăng do **làm đúng như B** (không bỏ được mà vẫn giữ B): Revolution hai bước con; ScaleInterpolator mặc định nội suy (mỗi hạt mỗi
  khung gọi `setDimensions`); flip-book SequenceFrame thay cho texcoord tĩnh; thứ tự emit → affect (hạt mới cũng được affector xử lý).
- Đã bỏ lãng phí: Revolution bỏ `normalise()` khi gia tốc bán kính = 0 (kết quả y hệt).
- Lãng phí còn thấy (ngoài phạm vi nhánh này): `WXSequenceFrameAffector::_getTexCoordIndex` tra `std::map<const Particle*, …>`
  cho mỗi hạt mỗi khung (`WXSequenceFrameAffector.cpp:387`); renderer mesh 1 entity/hạt (như B).

## 12. Kiểm thử

- `Tests\fx\particles\particle_unit_test.cpp` (`CYSParticleUnitTest.exe`): so toán học từng loại với giá trị tính tay từ thuật toán B:
  kích thước 3 chiều, mặc định template/emitter, trục AreaEmitter, Ring inner 0, phân bố Ellipsoid (đặc/mặt/rỗng, angle/height_range)
  và công thức nghịch đảo (tuyến tính/Cardano/lượng giác), ColourFading, ScaleInterpolator, Revolution, PolarEmitter, khoá
  Plugin_ParticleFX2, renderer mesh (khoá + phép biến đổi), MeshAnimation, parser SequenceFrame, thứ tự `_update`, ngẫu nhiên tất định.
- `Tests\fx\particles\particle_bench.cpp` (`CYSParticleBench.exe`): 200 hệ, chi phí update + nộp render queue (+ scene).
- Chạy: `Build\Logs\2026-09-13-fx-particles\build_tests.cmd <log> cur|base` rồi chạy exe trong `bin` của cây tương ứng
  (`Tests\fx\particles\particles_test.cmake` được tiêm bằng `CMAKE_PROJECT_CYSource_INCLUDE`).
- Danh sách render so sánh: `Tests\fx\particles\make_list.py` → `lists\particles.tsv` (51 template theo từng tính năng + frontend).

## 13. Còn thiếu / việc sau

- `setDefaultNonVisibleUpdateTimeout(5.0)` của Render B chưa đặt trong WXRender (`RenderSystem.cpp`, nhánh khác đang sửa file này).
- `setLogicParentTrans` / `_applyLogicParentMotion` của B chưa có (xem `07c-effects_vi.md`).
- Renderer `ribbon`, `Dissolve`, `RotationCurve`, `PolarMove`: chưa đối chiếu từng lệnh với B.
- Ảnh B (client_GL) chưa chụp được trong phạm vi này: so sánh ảnh hiện dựa trên phân loại của `fx_report.py`.
