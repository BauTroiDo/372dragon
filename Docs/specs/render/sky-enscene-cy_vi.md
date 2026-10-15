# Bầu trời CY 3.71: EnScene và SkySphere (sky-enscene, 15/09/2026)

Agent `sky-enscene`, nhánh `sky-enscene`, hook `// CYS-SKY:`. Bằng chứng ở `Build\Logs\2026-09-15-sky-enscene\`.
Bản dump Ghidra (bản sao Render.dll CY): `Build\re\sky-enscene\out\s*.txt`. Trace gốc lấy từ d3d9-trace
(`Build\Logs\2026-09-15-d3d9-trace\cy-login-2-trace`, `cy-world-1-trace`) và các lượt chụp của agent này.

Quy ước: **FACT** là điều đọc được trong mã/trace/dữ liệu. **INF** là suy luận chưa kiểm hết.

## 1. Tóm tắt

- CY vẽ bầu trời bằng shader của `MaterialTemplates.zip` (FACT). Có hai hệ tách biệt:
  - **EnScene** (`.EnScene`): vòm `EnScene.hlsl En_sky_dome_*`, mây đỉnh `En_cloud*`, mây vòng `En_ringcloud*`,
    trăng/mặt trời `En_sunandmoon_*`.
  - **SkySphere** (`.skysphere`): các dải `SkySphereLayer.hlsl blend_vp/blend_fp`.
- Mọi vertex program của bầu trời ép `z = 0.999999·w` (trăng/mặt trời `z = w`). Vì vậy kích thước lưới không ảnh
  hưởng tới hình. Z test `LESS_EQUAL` loại phần bị cảnh che, và không ghi z.
- Thứ tự vẽ (FACT, trace):
  - Vòm EnScene và các lớp SkySphere là **lệnh vẽ đầu tiên của pass cảnh** (queue 5, priority 100). Z-buffer vừa
    xoá nên vòm tô đủ 921.600 px.
  - Mây, mây vòng, trăng và mặt trời thuộc queue 59 và vẽ **sau đồ đục**. Priority = 90 + layer (mây, trăng,
    mặt trời) hoặc 110 + layer (mây vòng). Chúng chỉ tô ở chỗ còn nhìn thấy trời.
- Dự án trước đây vẽ 15 lệnh fixed-function ở queue 1–9, tắt Z, tổng 9,79 triệu px (khoảng 10,6 lần màn hình).
  Màu sai: mây đỏ gắt vì không có tán xạ, fog map và ambient blend.

## 2. Đọc dữ liệu

`CYSEnSceneData` / `CYSSkySphereData` (scene agent) đã đọc đủ cây XML. Đối chiếu với Render.dll:

| Dữ liệu | CY đọc (FACT) | Dùng ở |
|---|---|---|
| `<SkyDome> texture/hight/mieAmount/vertexHeightEffect/sunHeightEffect/power` | `FUN_1802391e0` mặc định `Normal_qing001_color.tga`, mie 0,01, 1, 1, 1, turbidity **0,2** (hằng, không có trong file) | `EN_DOME_PARAM1/2` |
| `<SkyCloudsLayer>` + `TimeNode fog/alpha/cloudspeed/ambientBlend` | `FUN_18023a350`; parser `FUN_180202370`/`FUN_1801fc2e0` | mây đỉnh |
| `<RingCloudsLayer>` + `TimeNode fogblend/ambientBlend/alpha/rollspeed/verticalSpeed/fadeRange` | `FUN_18023b940`; parser `FUN_180203ee0`/`FUN_1801fe680` | mây vòng |
| `<Moon>/<Sun>` | ctor `FUN_180235a10` / `FUN_180236220` (mặc định sun: scale 10, angle 50, 6→18 h) | trăng/mặt trời, **hướng mặt trời dùng cho hằng vòm/mây kể cả khi Sun Enable=false** |
| `<SkyLayer pitch_start/pitch_end/distance/rotate_speed>` | `FUN_1800ecbc0`; `rotate_speed` → layer `+0x74` (`FUN_1801ce6e0`) | lưới dải + quay |
| `<TextureGroup <layer>_texture/_wrap + AlphaKeyList>` | `FUN_1800f20f0` nội suy tuyến tính vòng theo phân số ngày | `texUWrap`, `blendFactor` |

## 3. Đồng hồ ngày

- FACT (`FUN_1800dde40`, `FUN_1800ddec0`, `DAT_1803b5d68`): đồng hồ toàn cục, `+4` = độ dài ngày **60 s**, `+8` =
  phân số ngày. Mỗi lần đọc cộng `Δms·0,001/60` nếu không bị dừng.
- FACT (`FUN_18002e3d0`): hàm đặt giờ của System. Nếu cảnh không có SkySphere thì dừng đồng hồ và gán phân số
  ngày; nếu có thì đặt giờ/ngày âm lịch cho SkySphere.
- FACT (`FUN_1801ea5c0`): `hours = phân số·24`, kẹp 23,9. Giá trị này dùng cho EnvKey, mặt trời, trăng và hằng
  vòm/mây.
- FACT trace đăng nhập (`cy-login-2`): `EN_DOME_PARAM1.x` = 0,3933 lúc 11:48:12,9 và 0,7266 lúc 11:48:32,9. Tức
  +0,3333 sau 20 s: đồng hồ **chạy 60 s/ngày ở màn đăng nhập**, vì Game.exe không đặt giờ ở thủ tục đăng nhập.
- Bảng màu `DJLTyewan_color1.tga` không đổi theo u, nên màu vòm không nhấp nháy. Thứ thay đổi là hướng mặt trời,
  kéo theo ánh sáng rìa mây.
- CY-Source:
  - `CYSEnvironmentManager::setCyFreeClock` chạy đồng hồ CY (60 s/ngày).
  - `CysLoginScene::Enter` bật nó qua export `CysSceneSkyClock` sau khi nạp cảnh thủ tục.
  - Mọi lần nạp cảnh và mọi `setTimeOfDay` đều tắt nó.
  - `CYS_SKY_CLOCK=0` hoặc `CYS_TIME_OF_DAY` tắt hẳn.
  - Cảnh thế giới giữ giờ cố định như trước (Game.exe của dự án chưa đặt giờ từ server — ngoài phạm vi).

## 4. Hướng mặt trời và trăng

FACT (`FUN_1802378a0` sun, `FUN_180236000` moon): nút theo camera, `resetOrientation`, rồi quay lần lượt:

1. `(orient + 180)°` quanh −Y;
2. `−angle°` quanh −X;
3. nếu không `fix`: `arc·360°` quanh −Y.

Cung ngày `arc` của mặt trời:

- trong khoảng mọc→lặn: `arc = (h − up)/((down − up)·2) + 0,25`;
- ngoài khoảng đó: `+0,75` (có xử lý qua nửa đêm);
- `sunfix` → `arc = 0,5`.

Trăng dùng cùng công thức với vai trò mọc/lặn đổi chỗ, và `moonfix` bỏ phép quay thứ ba.

Hướng mặt trời = `q·(0,0,1)` (hiệu vị trí nút con − nút cha). Kiểm với trace: h = 9,439 cho (0,621; 0,600; 0,504),
trace (0,6229; 0,5993; 0,5029). h = 17,44 cho (−0,989; 0,112; 0,094), trace (−0,9889; 0,1137; 0,0954). Khung
đầu (f000002, lúc đang nạp cảnh) lệch — INF: hằng còn giá trị của lượt trước.

Trăng: mặt phẳng prefab 200×200 ở nút con (0,0,−9000), scale = `scale`. erengu_DL (orient 344, angle 9, moonfix)
cho hướng (0,272; 0,156; 0,949), khớp login-polish.

## 5. Hằng shader (FACT, hàm cập nhật và trace)

### 5.1 Vòm (`FUN_18023a0e0`, material `EnScene/skyDome`, lưới `enskydome.mesh` 554 đỉnh / 1104 tam giác)

| Hằng | Giá trị | erengu_DL (trace) |
|---|---|---|
| `SUN_POSITION` | hướng mặt trời §4 | (0,6229; 0,5993; 0,5029) |
| `SUN_COLOUR` | `light_one` (rgb EnvKey) | (0,639; 0,722; 0,757) |
| `EN_DOME_PARAM1` | (h/24, `hight`, `mieAmount`) | (0,3933; −573; 0,01) |
| `EN_DOME_PARAM2` | (0,2; `vertexHeightEffect`; `sunHeightEffect`; `power`) | (0,2; 1; 1; 1) |
| `weight` (PS) | `+0xb0` = 1 | 1 |
| `ambientCol` (PS) | auto `skydome_ambient_color` = `skyDomeAmbientColor`·strength | (1,1,1,1) |
| `FOG_AMOUNT` | CY không đặt (giá trị thanh ghi cũ) | 0,000183 |

- Texture:
  - s0 `mie_gradient.dds` 32×256;
  - s1 `<texture>` (u wrap, v clamp, không mip);
  - s2 `TextureUnitEx` — bảng Rayleigh thứ hai khi pha trộn vùng; trace bind cùng bảng.
- Lọc MIN/MAG LINEAR, MIP POINT.
- Nút ở vị trí camera, scale 1.
- State: không blend, Z test ≤, không ghi z, cull CW.

### 5.2 Mây đỉnh (`FUN_18023b200`, bản sao `EnScene/cloud`, lưới `<meshname>` mặc định `enskycloud.mesh`)

| Hằng | Giá trị |
|---|---|
| `textureTile` (VS) | (tileU, tileV, `skyCloudHeight`·15, w) |
| `windSpeed` (VS) | cộng dồn `cloudspeed·dt·0,1` |
| `control` (PS) | (fog, cloudspeed, ambientBlend, alpha) |
| `rimParam` (PS) | (rimStrength, rimPower, rimDetectPower, rimDetectWidth) |
| `dLight` (PS) | (hướng mặt trời, scatteringStrength) |
| `lcolor` (PS) | (light_one, scatteringPower) |

- Texture: s0 `<texturename>` wrap; s1 `bmp_overhead_weak_fog.dds` clamp (`FUN_18023ac50`).
- `turnoverMesh` → roll π một lần.
- Pass occlusion `EnScene/cloudocclusion` (alpha reject `alpha·150`) chỉ dùng cho lens flare. CY-Source chưa làm.

### 5.3 Mây vòng (`FUN_18023c7a0`, bản sao `EnScene/ringcloud`, lưới `ringcloud.mesh` 51 đỉnh / `ZMcloud.mesh` 152)

- Nút = camera + (0, `CloudHeight`, 0), scale (1, `CloudScale`, 1).
- Hướng: nếu `rollspeed` = 0 thì yaw `CloudOffset`°; nếu khác 0 thì yaw cộng dồn `rollspeed·dt`°.
- `offsetParam` (VS) = (`TextureRepeat`, cuộn v cộng dồn `verticalSpeed·dt` trong [−1,1], `parallax`, 1).
- `control` (PS) = (fogblend, fadeRange, ambientBlend, alpha).
- `rimParam`, `dLight`, `lcolor` như mây đỉnh.
- Texture: s0 `<texturename>` (u wrap, v clamp — thành wrap khi v đang cuộn); s1 `bmp_horizon_fog_strong.dds`.
- Kiểm trace erengu_DL: 7 lệnh vẽ đúng 7 lớp có alpha > 0, theo priority 110, 115, 117, 117, 118, 118, (trăng 120), 121. Cùng priority thì xa trước, ví dụ cloud1 (−76) trước jianbian (−11).
- `worldMatrix` khớp scale/yaw từng lớp, ví dụ shan `CloudOffset 85`, `CloudScale 3,7` → (0,087; 0; −0,996 / 0; 3,7; 0).

### 5.4 SkySphereLayer (`FUN_1801ce6f0` nhánh shader, `FUN_1801ce0f0`, `FUN_1800f53b0`)

- Lưới `FUN_1801d0ba0`:
  - Bước pitch π/10, bước yaw 2π/40, dịch y −0,05 (`FUN_1800f0260` → `FUN_1801d1430`).
  - `rows = int((pe − ps)/(π/10))`, `cols = 40`. Đỉnh `(rows+2)(cols+2)`, tam giác `2(cols+1)(rows+1)`.
  - Vị trí `(cos yaw·sin p, cos p − 0,05, sin yaw·sin p)`, pháp tuyến `−(không dịch)`.
  - Toạ độ `u = j/41`, `v = i/(rows+1) + 0,005` (hàng cuối 0,995).
  - Nút scale `distance/√(1 − 0,05²)`.
  - Kiểm trace Đại Lý: background 294/492, far_cloud 126/164, mountain 84/82, fog 126/164 — khớp công thức.
- Material:
  - 1 pass, blend SRC_ALPHA/INV_SRC_ALPHA, không ghi z, không chiếu sáng, fog none.
  - Program `SkySphereLayerBlend_<One|Two|Three>Texture_VS_1_1_hlsl` / `_PS_2_0_hlsl`.
  - Mỗi nhóm texture có alpha ≥ 0,001 thành một texture unit (tối đa 3).
- Hằng:
  - `texUWrap` = `<layer>_wrap` từng nhóm; `texVWrap` = 1.
  - `blendFactor`: khi dựng lại material là (aᵢ/Σ, w = min(Σ,1)); mỗi khung tiếp theo là (aᵢ thô, w = Σ).
  - `blendColour` = trắng, riêng lớp fog = `sky_fog` (trace (0,6118; 0,6392; 0,9725)).
- Quay: `FUN_1801d0a50` → `FUN_1801cdc20`: `yaw(rotate_speed·Δt giây thật)` theo `Root::getTimer`.
- Queue (5, 100) cho mọi lớp (ctor `FUN_1801cd0b0`). Thứ tự trong trace: background, far_cloud, mountain,
  near_cloud, fog. CY-Source ép thứ tự này bằng priority 100..104.

## 6. Cài trong CY-Source

| Việc | Chỗ |
|---|---|
| Bầu trời shader CY | `Src/Engine/WXCore/CYS/Scene/CYSSkyCyRenderer.{h,cpp}` |
| Renderable có priority (Fairy `setRenderQueueGroup(group, priority)`; entity OGRE 1.2 không có) | `CYSSkyMesh : SimpleRenderable`, `addRenderable(this, group, priority)` |
| Chọn renderer, đồng hồ CY | `CYSEnvironment.{h,cpp}` (`rebuildSky`, `update`, `setCyFreeClock`) |
| Phần CY không có lệnh shader trong khung đã chụp: sao, flare, trăng/sao SkySphere | `CYSSkyRenderer::setExtrasOnly` (fixed-function, INF) |
| Cầu đồng hồ | `RenderSystem.cpp` export `CysSceneSkyClock`; `CysLoginScene::Enter` |
| Công tắc A/B | `CYS_SKY_SHADER=0` → bầu trời fixed-function cũ |
| Công cụ | `Tools/render/sky_draws.py` (lọc lệnh vẽ trời trong trace, `compare`), `Tools/render/sky_sheet.py` (ảnh ba cột) |

## 7. Kết quả

Bằng chứng ở `Build\Logs\2026-09-15-sky-enscene\`. Lọc lệnh vẽ bằng `sky_draws.py <frame>` và
`sky_draws.py compare <cy> <proj>`.

### 7.1 Đăng nhập `erengu_DL` (Game.exe, stage `stage-1-sky`)

| | CY (`d3d9-trace\cy-login-2-trace\f001767`) | Sau (`proj-login-sky-2-t944`, `CYS_TIME_OF_DAY=9.439`) | Trước (`proj-login-ff-3-t944`, `CYS_SKY_SHADER=0`) |
|---|---|---|---|
| Lệnh vẽ trời | vòm + 7 mây vòng + trăng | vòm + 7 mây vòng + trăng | 15 lệnh fixed-function (11 không shader) |
| Shader | vs `1300debd`/ps `0aca8e63`; vs `f5f34bd0`/ps `b28d7b03`; trăng `def1679d`/`63399073` | trùng từng hash | — |
| px | vòm 921.600; mây vòng 1.583.073; trăng 61.300 | 921.600; 1.583.253; 61.351 | 9.791.007 (Z tắt) |
| Vị trí trong khung | vòm = lệnh đầu pass cảnh; mây/trăng sau đồ đục | như CY | đầu pass, trước địa hình |
| Hằng | `EN_DOME_PARAM1` (0,3933; −573; 0,01), `SUN_POSITION` (0,6229; 0,5993; 0,5029) | (0,3933; −573; 0,01), (0,6214; 0,6002; 0,5036) | — |
| Ma trận WVP trăng | … | trùng từng bit | — |

- Màu vùng trời đo trên đích cảnh FP16, không có UI (0..1280 × 0..330):
  - sai khác tuyệt đối trung bình so với CY: trước 26,6 / 14,6 / 17,2; sau 2,2 / 3,9 / 4,9;
  - dải trên cùng: CY 101,55,67; sau 101,55,67.
  - Số đo: `metrics\login_game_sky_diff.txt`. Ảnh: `metrics\login_game_cy_before_after.png`.
- Đồng hồ ngày chạy khi không đặt `CYS_TIME_OF_DAY` (`proj-login-sky-1`): log có
  `CYS-SKY: CY day clock running (60 s per day)`, hằng đổi theo giờ như CY.
- Mean rgb vùng trời từng lệch +6/+8. Đó là do đo trên ảnh CY có UI và do pha đồng hồ khác nhau, không phải do
  hằng sai.
- Frame time (máy có tải): trước 20,7 ms trung bình / p95 24,6; sau 19,2 / 22,7 (`metrics\login_frametimes_ab.txt`).

### 7.2 Đại Lý, camera ngửa

- CY: `cy-world-sky-1-trace`, oracle `dali`, `Camera_Pitch=-30` trong System.cfg của bản sao (khôi phục sau lượt).
  Mô phỏng chuột phải/lăn chuột không đổi camera; xem `cy-probe-1`.
- 5 lệnh `SkySphereLayer` là lệnh đầu pass cảnh, vs `56cd7c90`, ps `efff5b67`:
  - `blendFactor` (1,0,0,1): 12:00 chỉ nhóm "bt" có alpha;
  - `texUWrap` 4/3/3/3/1;
  - `blendColour` lớp fog (0,6118; 0,6392; 0,9725).
- Dự án (`world-sky-3`, world replay PASS, ảnh `cam-sky-low`): 5 lệnh ở đầu pass cảnh. Hash vs/ps, hash dữ liệu
  texture, hằng và số đỉnh/tam giác (294/492, 126/164, 84/82) đều trùng CY. px 2,08 triệu (CY 2,20 triệu, camera khác).
- Hai lỗi tìm ra nhờ trace và đã sửa:
  1. VS biên dịch `vs_1_1` (hash `9146c82c`). CY nâng đích 1.x lên 2.0 (§8).
  2. Pha đồng hồ màn đăng nhập rò sang Đại Lý, làm dùng nhóm texture đêm.
- Ảnh (TlbbViewer, cùng hướng nhìn với CY u08, mắt nâng 5000 để cảnh xa không che trời):
  - `metrics\dali_sky_cy_before_after.png`; mean rgb dải trời CY 150,160,244, trước 163,169,245, sau 146,156,244.
  - Mây trôi sau 5 s: `metrics\dali_cloud_drift_t4_t9_diff.png`. 31 nghìn px đổi; núi (`rotate_speed 0`) đứng yên.
  - Ảnh Game.exe cùng lượt: `metrics\dali_game_cy_before_after.png`. Camera replay giữa hai lượt khác nhau.
- CY không vẽ vật thể xa ở camera này (khoảng render): ngoài phạm vi bầu trời.

### 7.3 Không lùi

- Trăng đỏ đăng nhập: ma trận/px như CY (7.1).
- `Tests\scene\run_scene_test.cmd` PASS (`scene-test.log`, `scene-test-2.log`).
- World replay PASS (`world-sky-1`, `world-ff-2`, `world-sky-3`). Build rc 0.

## 8. Biên dịch HLSL đích 1.x

FACT (`RenderSystem_Direct3D9.dll` CY, `FUN_180009270` = `D3D9HLSLProgram::loadFromSource`): trước
`D3DXCompileShader`, đích chứa "vs_1" được đổi thành "vs_2_0", "ps_1" thành "ps_2_0". Cờ chỉ có pack matrix
(8 = row major, 0x10 = column major).

CY-Source `OgreD3D9HLSLProgram.cpp` làm như vậy, khoá cache microcode dùng đích sau khi đổi. `CYS_HLSL_SM1_UPGRADE=0`
giữ cách cũ (cờ tương thích cho ps_1_x).

## 9. Giờ thế giới theo server (15/09 tối, commit `e808b0ed`)

FACT (Game.exe CY 3.71, `e\sky-enscene\out\g3_worldtime.txt`, `g6.txt`, `t3_vtidx.txt`):

- `GCWorldTime` (id 349 ở CY, 472 ở skynet; Read `14086a940`, handler `FUN_1405420a0`). Nội dung 12 byte:
  - `u32 WorldTime` → biến `WorldTime`;
  - `i32 counter` = ms trong ngày → `DAT_1410393dc`;
  - `f32 NewWorldTime_Interval` (`MOVSS`) → biến cùng tên.

  Handler gọi `FUN_14064d030` ngay nếu thủ tục chính đã có.
- Tick `CGamePro_Main` (`FUN_14064a0a0`): cứ `View_SkyBoxRefreshTime` ms (CY `System.cfg` = 3000) và `interval > 0` thì
  `counter = (counter + elapsed_ms·interval) % 86400000`, rồi gọi `FUN_14064d030`.
- `FUN_14064d030`: `fraction = clamp(counter/8.64e7, 0.01, 0.99)`, rồi gfx vtable `+0x350` =
  `CRenderSystem::vftable[106]` = Render.dll `FUN_18002e3d0 (localtime().tm_mday, fraction)`.
  - Cờ `DAT_14102f080 + 0x5efa00` ≠ 0 → luôn 0,5. Chỉ thấy chỗ đọc, chưa rõ nguồn (INF: cấu hình theo cảnh).
- `FUN_18002e3d0` dừng đồng hồ Render.dll và gán phân số ngày (§3). Với cảnh có SkySphere thì đặt giờ + ngày âm lịch.
- Server skynet riêng (`cys-test-20260913/GameServer`, FACT mã Lua) gửi `GCWorldTime` khi vào cảnh và mỗi 150 tick
  (`worldcore.lua`). `counter` bắt đầu 3:00 (10.800.000), +8000 mỗi tick, `unknow` (interval) = 8,0.
- CY-Source:
  - `Procedure/CysWorldTime.{h,cpp}`: gói + tick như trên.
  - `GCWorldTime` đọc đủ 12 byte; `CysModernHandlers` dispatch 472.
  - Cầu `CysSceneSetTime` → `CYSEnvironmentManager::setWorldTime`, log
    `CYS-SKY: world time day … fraction … -> … h, sun direction (…)`.
  - Công tắc thử: `CYS_WORLD_TIME=<giờ>` ghim giờ; `CYS_TIME_OF_DAY` vẫn thắng.
- Kiểm:
  - World replay `world-time-7`: log `GCWorldTime WorldTime=7 counter=62920000 ms (17.478 h) interval=8.000` → 17,478 h,
    tick 3 s cộng 24 s giờ game.
  - Fixture sửa counter 23:00 (`world_session_t2300.bin`, `world-time-2300-8`): khung `cam-sky-low` lúc 23,6 h (0,983)
    dùng nhóm texture đêm và `sky_fog` đêm.
  - Ảnh: `metrics\worldtime_proj_1748_2300.png`.
  - CY cùng camera, oracle `counter` 12:00 / 23:00 (`cy-cam-noon-9`, `cy-cam-2300-10`): bầu trời đổi theo giờ, 23:00
    = nhóm xy + `sky_fog` (0,576; 0,384; 0,886). Ảnh: `metrics\worldtime_cy_1200_2300.png`.
  - Giờ khác nhau giữa hai cột nên đây là kiểm cơ chế, không phải so điểm ảnh.

## 10. Vật xa che trời — đo, CHƯA sửa (dừng theo lệnh người dùng)

Bằng chứng: `metrics\far_objects_match_t58.txt`, `metrics\cull_fit_cy_t58.txt`, `metrics\cull_fit_cy_n58.txt`. Công cụ:
`Tools/render/draw_distances.py`, `draw_match.py`, `cull_fit.py`.

- Ảnh CY u08 cũ "không có vật xa" là **CY chưa dựng xong cảnh** (khoảng 8 s sau khi vào). Builder CY dựng 64 vật lúc đầu,
  sau đó 30 vật/giây. Cùng camera sau 58 s, CY vẽ vật tĩnh tới khoảng 10,1–10,6 nghìn đơn vị.
- Cùng camera `t58` (TlbbViewer + proxy, `viewer-4`):
  - CY 176 lệnh vẽ; dự án 787, khớp 161 lệnh của CY.
  - Dự án thừa 610 lệnh ở ≥ 4000, gần hết 10.000–20.000 (cây/nhà lớn).
  - Far clip: Game.exe dự án 14.935 = CY; TlbbViewer 50.010.
  - Sương CY `fog_params` (7600, 13100); dự án (6500, 12000) = khoá EnvKey. Khoản +1100 của CY chưa tìm ra; không
    có trong `SceneManager::setFog` / `AutoParamDataSource::setFog` của OgreMain CY.
- Luật CY đo được (FACT số đo):
  - Gần: `dist ≤ max(4000, 14·radius·scale)`, khớp camdiscull của perf-cy, trừ vài ngoại lệ.
  - Xa: có **giới hạn cứng** độc lập bán kính — t58 ở khoảng (10.131; 10.307), n58 ở khoảng (10.559; 10.718).
    Không phải cửa sổ ô lưới (hai vật cùng ô, một vẽ một không). Không phải khoảng cách 3D thuần (hai camera cho hai
    ngưỡng; chênh ≈ chênh độ cao mắt 431).
- RE đã có (Render.dll):
  - Builder `FUN_18008b4f0` / `FUN_180089d40`: cửa sổ ô `tileSize·scale` (Đại Lý 3200) quanh camera, bán kính
    `D = far` khi không fog; có fog thì `D = min(far, fogEnd)` nếu `far·0,75 ≤ fogEnd`, còn lại lấy trung bình
    (`_DAT_1803b1978 = 0,75`, ngưỡng làm mịn 300).
  - camdiscull: `StaticEntity` có `Distance Cull` và `+0x84 == 1`.
  - Gfx `+0x380` = `setMaterialLODDistance(0, 5000 | 10000 / scale)` + hằng 5,0 → LOD vật liệu, không phải cull.
  - Gfx `+0x378` = bật HeightFog.
- Nguồn của giới hạn cứng chưa rõ. Việc tiếp: RE `CScene`/SceneManager cull theo sương hoặc độ cao, rồi port. Theo lệnh,
  báo perf-cy trước khi chạm cull.

## 11. Còn lại / sai khác có chủ ý

- Texture nền `.jpg`: CY tạo X8R8G8B8, dự án A8R8G8B8 (cùng dữ liệu, alpha 255).
- `FOG_AMOUNT` của vòm: CY không đặt (thanh ghi cũ), dự án để mặc định 1. Giá trị này chỉ vào `diffuse.w`,
  và alpha không dùng vì vòm không blend.
- Giờ thế giới: **ĐÃ LÀM** (§9).
- Mây đỉnh `rotangle`: CY chưa thấy chỗ áp (INF: yaw khi dựng).
- Pha trộn vùng EnScene (`TextureUnitEx`, `weight`) chưa làm; dự án chỉ dựng bầu trời vùng nền.
- Lens flare / occlusion (`EnScene/sunocclusion`, `cloudocclusion`), sao `SkySphere/FixedStar` chưa làm.
- Ẩn lớp alpha = 0: trace không có lệnh vẽ (FACT); cơ chế ẩn chưa lần ra (INF: env apply).
