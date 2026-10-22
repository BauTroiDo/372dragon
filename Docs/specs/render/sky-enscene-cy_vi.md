# Bầu trời CY 3.71: EnScene và SkySphere (sky-enscene, 15/09/2026)


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


## 4. Hướng mặt trời và trăng


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


CY-Source `OgreD3D9HLSLProgram.cpp` làm như vậy, khoá cache microcode dùng đích sau khi đổi. `CYS_HLSL_SM1_UPGRADE=0`
giữ cách cũ (cờ tương thích cho ps_1_x).

## 9. Giờ thế giới theo server (15/09 tối, commit `e808b0ed`)

FACT (Game.exe CY 3.71, `e\sky-enscene\out\g3_worldtime.txt`, `g6.txt`, `t3_vtidx.txt`):


## 10. Vật xa che trời — đo, CHƯA sửa (dừng theo lệnh người dùng)

Bằng chứng: `metrics\far_objects_match_t58.txt`, `metrics\cull_fit_cy_t58.txt`, `metrics\cull_fit_cy_n58.txt`. Công cụ:
`Tools/render/draw_distances.py`, `draw_match.py`, `cull_fit.py`.


## 11. Còn lại / sai khác có chủ ý

- Texture nền `.jpg`: CY tạo X8R8G8B8, dự án A8R8G8B8 (cùng dữ liệu, alpha 255).
- `FOG_AMOUNT` của vòm: CY không đặt (thanh ghi cũ), dự án để mặc định 1. Giá trị này chỉ vào `diffuse.w`,
  và alpha không dùng vì vòm không blend.
- Giờ thế giới: **ĐÃ LÀM** (§9).
- Mây đỉnh `rotangle`: CY chưa thấy chỗ áp (INF: yaw khi dựng).
- Pha trộn vùng EnScene (`TextureUnitEx`, `weight`) chưa làm; dự án chỉ dựng bầu trời vùng nền.
- Lens flare / occlusion (`EnScene/sunocclusion`, `cloudocclusion`), sao `SkySphere/FixedStar` chưa làm.
- Ẩn lớp alpha = 0: trace không có lệnh vẽ (FACT); cơ chế ẩn chưa lần ra (INF: env apply).
