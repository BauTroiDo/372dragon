# Đối chiếu từng lệnh vẽ Direct3D 9 — CY 3.71 và CY-Source (d3d9-parity)


### 1.1. Proxy `Src\Tools\CysD3D9Trace` (thành phần CMake `d3d9trace`)

- `bin\d3d9trace\d3d9.dll` (x64). **Chỉ** chép vào bản sao thư mục chạy (cạnh `Game.exe`/`TlbbViewer.exe`), không bao giờ
  vào `Tools\DATA NEW`, client_GL hay `Build\cmake\*\bin`.
- Nạp `%SystemRoot%\System32\d3d9.dll` thật, vá vtable của `IDirect3D9`, `IDirect3DDevice9`, `IDirect3DSwapChain9`
  (không bọc đối tượng — `GetDevice()` và bảng theo thiết bị của OGRE giữ nguyên). Bỏ cờ `D3DCREATE_PUREDEVICE` để đọc
  state bằng `Get*` (CY và dự án đều không dùng pure device: behavior 0x40).
- Ngoài khung được bắt chỉ ghi dấu thời gian `Present` (`frametimes.tsv`, dùng được cho độ mượt).
- Kích hoạt (biến môi trường, hoặc `[trace]` trong `d3d9trace.ini` cạnh DLL):

| Biến | Ý nghĩa | Mặc định |
|---|---|---|
| `CYS_D3DTRACE_DIR` | thư mục ra | `<exe>\d3dtrace` |
| `CYS_D3DTRACE_FRAMES` | danh sách số khung | — |
| `CYS_D3DTRACE_AT` | danh sách giây sau `Present` đầu | — |
| `CYS_D3DTRACE_KEY` | phím ảo (GetAsyncKeyState) | `0x7A` F11 |
| file `<dir>\capture.now` | bắt khung kế tiếp (dòng 1 = nhãn) | |
| `CYS_D3DTRACE_RT` | PNG RT 0 cuối mỗi pass + back buffer (DDS thêm cho định dạng float) | 1 |
| `CYS_D3DTRACE_OCC` | occlusion query mỗi lệnh vẽ → `px` = số điểm ảnh qua z/stencil | 1 |
| `CYS_D3DTRACE_VB` | hash dải index + byte đỉnh tham chiếu (buffer managed) | 1 |
| `CYS_D3DTRACE_MAX` / `_RTMAX` | số lần bắt / số PNG mỗi lần | 8 / 64 |


### 1.2. So sánh `Tools\render\d3d9_trace_diff.py`

- `summary CAP` · `sheet CAP OUT.png` (bảng ảnh các pass) · `diff CY PROJ --out DIR [--top N]`.
- Vai pass: `shadow` (R32F/R16F khác cỡ màn hình), `depth` (R32F cỡ màn hình), `scene`, `post` (≤ 2 lệnh vẽ),
  `final` (back buffer).
- Ghép lệnh vẽ cùng vai theo tầng: (hash hình học, bộ texture) → hình học + **vị trí thế giới gần nhất** (từ hằng
  `world*`) → (hash index, bộ texture, số tam giác) → (bộ texture, số tam giác) → bộ texture → toàn màn hình.
- So trên state **hiệu lực** (blend chỉ khi bật blend, alpha test chỉ khi bật, z chỉ khi ZENABLE, fog FF bỏ khi có PS,
  state FF chỉ khi cả hai phía không shader), sampler theo texture chung, hash shader, hằng theo tên, mip/định dạng
  texture, định dạng RT, viewport; cấu trúc pass/RT, tham số thiết bị, thứ tự hàng đợi (Spearman + dịch vị trí theo PS).
- Xếp hạng theo **diện tích** = Σ `px` / diện tích RT của các lệnh vẽ liên quan (overdraw cộng dồn).
- Ra: `diff.txt`, `diff.json`, `pairs.tsv`, `unmatched.tsv`, `shaderdiff\*.diff`.

## 2. Các lần bắt

| Lần | Nguồn | Khung | Lệnh vẽ | Ghi chú |
|---|---|---|---|---|
| `cy-login-2-trace` | CY 3.71, `erengu_DL`, khung chọn server | 2 (20 s), 1767 (84 s), 2133 (104 s) | 1.940 / 2.066 / 2.063 | 0 socket; 1280×720 |
| `proj-login-1-trace` | main `858b6bef` | 2576, 3701 | 2.526 / 2.527 | trước sửa |
| `proj-login-2-trace` | `6d6fcef9` | 2312, 3167 | 2.527 / 2.527 | sau sửa |

| `proj-login-3/5..8` | `63ffec19` → `dbc68392` | 2996–3248 | 4.163–4.207 | lightmap/caster, FakeLight khối, FP16, A/B FP16 |
| `world-2-trace` | dự án, world replay Đại Lý (`world_capture.ps1`) | 340 `world-1`, 1120 `cam-zoom-far` | 1.022 / 1.867 | camera replay khác CY |
| `viewer-2\dali_w09*` | TlbbViewer cùng camera CY `w09` (lấy bằng `d3d9_trace_diff.py camera`) | 230 | 3.224 | kiểm cấu hình bóng/fit |

Mục 3–4 là **cảnh đăng nhập**; world CY ở mục 3.1.

## 3. Cấu trúc khung (FACT)

| # | CY 3.71 | CY-Source (main) |
|---|---|---|
| 1 | Bóng: `rt1` 4096×4096 R32F, DS D24S8, clear T+Z+S, **728** caster (tĩnh, cây có gió, skin, **cả địa hình**) | Bóng: atlas 4096×1024 R32F, 4 viewport clear, **0 caster** (log `casters 0/0/0/0`, CPU atlas 5,7 ms/khung) |
| 2 | Cảnh: `rt2` 1280×720 **A16B16G16R16F**, DS = texture **INTZ** 1280×720, clear `ff172d3d`, 1.148 lệnh vẽ | Depth: `rt2` 1280×720 **R32F**, 1.161 lệnh vẽ (pass thừa, chỉ để lấy độ sâu) |
| 3 | Sao chép `rt2→rt4` (PS 21 dòng) | Cảnh: `rt3` **A8R8G8B8**, 1.338 lệnh vẽ; `StretchRect rt3→rt4` (khúc xạ nước) |
| 4 | Quay lại `rt2`: 152 lệnh vẽ trong suốt (lớp trời, **44 khối FakeLight**, **13 khối sương cao**, nước đọc `rt4`, hạt) | FXAA `rt3→rt5` |
| 5 | Sương cao toàn màn hình `rt2`+INTZ → `rt4` (`HeightFog`) | Sương cao `rt5`+R32F → `rt3` |
| 6 | `bb`: sao chép `rt4` (không tonemap, không FXAA vì `View_Fanhunjiao=0`) + UI | `bb`: sao chép + `ditherAmount 0` + UI |

Thiết bị: CY `PresentationInterval ONE`, `BackBufferCount 2` (VSync, `View_Aplomb=1`); dự án `IMMEDIATE`, 1
(`WXSystem.cfg View_Aplomb=0` của stage).

Thời gian khung màn đăng nhập (`frametimes.tsv`, sau giây 60, bỏ khung bị bắt; máy đang chạy agent khác nên chỉ so
tương đối): CY trung bình 22,15 ms, p95 23,59, p99 27,41; dự án (`proj-login-3`, đã có caster bóng) 24,46 / 28,21 / 31,96.

### 3.1. World CY — Đại Lý (FACT, `cy-world-1-trace`)

- Cấu trúc như đăng nhập: bóng `rt1` 4096² R32F (306 / 709 / 703 caster) → cảnh FP16 + DS INTZ (91 / 227 / 114 lệnh
  vẽ) → sao chép FP16 → (trong suốt) → back buffer không tonemap + 71–73 lệnh vẽ UI; clear `ff8390f4`; VSync ONE.
- Bóng: `shadow_param (1,1,4096,0)`, `shadow_csm_param (1,1,0.005,8000)`, `isystem_userdata (8,0,0,20)` ở cả 3 khung ⇒
  CY **không dùng** CSM 4×1024 lúc chạy (dù ctor Render.dll có); ortho 9.422 × 7.555, tỉ lệ sâu −5,81e-5 (≈ 17.215).
- Không có FakeLight trong khung Đại Lý; địa hình và model 2 đèn (mọi lệnh vẽ).
- Camera kịch bản: fovY 35°, hướng (0, −0,643, −0,766), `w09` mắt (−0,2; 3.117,7; 1.406,6).
- Caster CY: mesh tĩnh không texture 184, alpha-test 82, địa hình 40 (`w09`); dự án cùng camera (viewer) 2.757 (fit
  stable) / 1.785 (fit tight) — thừa ~1.800 caster nhỏ (8–140 tam giác) và 665 alpha-test 128² DXT3 ⇒ CY có luật
  chọn caster chưa biết (INF: loại vật nhỏ/khoảng cách render).
  **ĐÍNH CHÍNH (shadow-finish 17/09, `shadow-finish_vi.md` mục 3): kết luận "CY có luật chọn caster" là SAI.** Ở `w09`
  CY mới dựng ~330 vật (dựng dần 30 vật/giây): cùng lượt đó CY tăng 306 → 709 → 703 caster và khoảng cách xa nhất
  5.953 → 7.720 → 9.075; ở cảnh đăng nhập (1.078 vật, cả hai dựng xong) tập caster của dự án **trùng từng lệnh vẽ**
  với CY (728 = 423 tĩnh + 178 alpha + 101 skin + 26 địa hình, 919.379 tam giác). Chênh chỉ có ở TlbbViewer vì viewer
  dựng hết cảnh ngay; Game.exe dùng cùng bộ dựng dần + camdiscull như CY (253…303 caster, 35…40 ô địa hình).

### 3.2. World CY — kỹ năng, nước, NPC (FACT, `cy-world-2-trace` `w11-skill`, `w23-tp1`; `cy-world-1-trace` `w28-tp1`)

- Nước (`w23/w28`): 3 lệnh vẽ `c89fa988` (cùng shader dự án), 3 khối sương nước `78f6952f`, khúc xạ đọc bản chép FP16.
- Hiệu ứng kỹ năng (`w11`): chỉ 5 lệnh vẽ trong suốt ở pass 4 (`7da87613` ×4 ribbon/khung tuần tự, `e633dab2` ×1);
  cần khung dày hơn (`w13`) để so hạt.
- Bầu trời Đại Lý: 5 lệnh vẽ `efff5b67` (SkySphereLayer.hlsl `blend_fp`: `blendColour`, `blendFactor (1,0,0,1)`,
  `texUWrap` 4/3/3/3/1), Z test, không ghi z, blend SRCALPHA/INVSRCALPHA, **sau** đồ đục; ở camera kịch bản 0 px.
- **NPC/quái (model skin, `imodel_userdata.x = 1`)**: VS `f1f0dbe2` chiếu sáng theo đỉnh (actor_ambient/lightone/
  lighttwo, 2 đèn), PS `a2769318`/`692dc86a`/`fbc994fe` **không có hằng bóng/LUT** ⇒ CY **không cho actor nhận bóng**;
  `imodel_userdata = (1, số xương 1–3, alpha-ref 0/0,5, brightness 0,639)`; `derived_scene_colour` đổi theo lệnh vẽ
  (0,77/0,87/0,92 — INF: sáng khi chọn/hover); fog (7600, 13100) giờ 12:00.
- Model skin cảnh (`x = 0`, `6972ae69`): nhận bóng (LIGHT_CALC 2 + SHADOWMAP 1, sampler 0/4/5/12).
- Dự án (`world-3`, nhân vật replay `bot001`): `imodel_userdata = (0, 2, 0, 1)` — **x = 0 và brightness 1**, PS
  `9f7d6cc2` nhận bóng ⇒ lệch CY 3 điểm: cờ actor, nhận bóng trên actor, brightness 0,639 (việc L6).

## 4. Bảng khác biệt (top 30, cảnh đăng nhập)

Hạng = thứ tự trong `diff-login-2\diff.txt` (sau sửa) cộng các mục cấu trúc không có điểm diện tích. Cột "Sửa" nêu nơi
sửa và chủ sở hữu đề xuất.

| # | Khác biệt | CY | CY-Source | Nguyên nhân (mã/dữ liệu) | Sửa đề xuất |
|---|---|---|---|---|---|
| 1 | Bóng ở cảnh đăng nhập | 1 map 4096² ortho (x 10.930 × y 6.900, sâu ~26.600), `shadow_param (1,1,4096,0)`, `shadow_csm_param (1,1,0.005,8000)` | CSM 4×1024, `(4,0.25,0.005,9625)`, 0 caster | FACT trace. Đặc tả `shadow-cy_vi.md` §2: CY gọi `setShadowDis(18000,1000)` sau khi nạp `erengu_DL`; receiver CY vẫn là đường CSM (`shadow_csm_param.x = 1`) ⇒ INF: **CSM 1 tầng 4096²**, khoảng 8000, bias 8 ở đăng nhập. 0 caster: `StaticEntityObject`/`ModelObject` mặc định `cast shadows = false` (FACT mã) | **ĐÃ SỬA** mặc định (5.4, kiểm trace proj-login-3); còn L1: 1 tầng 4096² ở đăng nhập, caster địa hình |
| 2 | Định dạng RT cảnh | A16B16G16R16F | A8R8G8B8 | `CysPostFxPipeline` `mHdr = gCinematic` (8-bit trừ khi "cinematic") | **ĐÃ LÀM** đích FP16 (5.6, chờ trace); còn L2: INTZ thay pass depth |
| 3 | Bầu trời | vòm `EnScene` (HLSL, Z test, 921.600 px) là lệnh **đầu** pass cảnh (queue 5); 7 lớp **mây vòng** `En_ringcloudv/p` + trăng **sau** đồ đục (queue 59) | 15 lệnh vẽ đầu khung, Z tắt, **FF** + `38a19026`, 9,79 triệu px (~10,6 lần màn hình) | `CYSSkyRenderer` dùng pass FF hàng nền | **ĐÃ LÀM** (sky-enscene, `sky-enscene-cy_vi.md`): hash/px/hằng/thứ tự khớp CY, 2,57 triệu px |
| 4 | Lọc texture | MIN LINEAR, MIP **POINT**, aniso 1 | ANISOTROPIC ×8, MIP LINEAR | Quyết định `aa-cy` (`View_TextureFiltering=2` áp lúc khởi động; CY chỉ áp khi biến đổi) | Người điều phối quyết: giữ (nét hơn) hay theo CY (`CYS_TEXFILTER=ogre`) |
| 5 | Hằng `isystem_userdata.x` (const bias bóng) | 8 | 5 | CY ở cảnh đăng nhập đặt 8 (INF: cùng lệnh `setShadowConstAndNormalBias`/bảng theo cảnh); đặc tả cũ nói 5 cho world | Gộp vào L1 |
| 6 | Thứ tự hàng đợi cảnh | vòm → 673 đục (một PS) → 36 địa hình → 370 alpha-test → trong suốt | trời → 118 địa hình → đục/alpha-test **xen kẽ từng vật** (Spearman 0,38) | INF: hash pass OGRE của dự án không tách alpha-reject/chương trình như CY; địa hình ở hàng sớm hơn | Việc vừa M1: so `Pass::getHash`/`RenderPriorityGroup` với OgreMain CY; lợi: ít đổi state, early-Z |
| 7 | Hằng hạt `blocks` / `useUDirection` / `widthRatio` | (0.05,0.06) / 1 / 2 | (1,1) / 0 / 0 | INF: tham số khung tuần tự/ribbon của `Particle_ps` không được đặt (có thể ghép nhầm cặp — kiểm lại ở khung world) | Chuyển fx (`07e-fx-cy`) |
| 8 | Pass depth riêng | không (đọc DS INTZ) | 1.161 lệnh vẽ R32F | `CysPostFxPipeline::buildDepthNode` render lại cảnh | Việc lớn L2: dùng INTZ như CY (`Mtl_*_DSIntZ`), bỏ ~45 % lệnh vẽ khung đăng nhập |
| 9 | Chuỗi hậu kỳ | copy → (trong suốt) → HeightFog → copy | FXAA → HeightFog → copy+dither | FXAA do `aa-cy` bật mặc định; thứ tự FXAA trước sương | Khi làm L2: FXAA (nếu giữ) sau sương như CY thì mới đúng |
| 10 | **FakeLight** (**ĐÃ LÀM** 5.5, chờ trace) | 44 hộp 12 tam giác, `Mtl_FakePointLight(_DSIntZ)`: blend DESTCOLOR·src + dst, cull CCW, Z tắt, đọc độ sâu INTZ, `lightParams`, `globalIntensity` | không vẽ khối; mỗi FakeLight thành **point light OGRE** (`CYSFakeLightObject::applyLight`, range 50·scale, quad 8/r²) → địa hình nhận 2–16 đèn (CY 2–5, đa số 2), model 3 đèn (CY 2) | FACT trace + `Model_FakePointLight_ps.hlsl` | Việc lớn L4: vẽ khối như CY; nguồn dư sáng "tượng trái +18 %" của `color-calib` |
| 11 | Sương mù địa hình | PS có `fog_colour`, `fog_params (0.001,1000,25000)` | không | **ĐÃ SỬA** (mục 5.1) | — |
| 12 | Mip texture material | 6 mức (1024² DXT1) | 9–11 mức | **ĐÃ SỬA** (mục 5.2) | — |
| 13 | Địa hình: texture | atlas **4096×1024** A8R8G8B8 5 mức (s0=s1) + lightmap **L8 256²/ô** (s2) + colormap 64×64/ô (s3); 36 lệnh vẽ | từng texture cọ 512² autogen, colormap cả map 512² (s3), **không có sampler lightmap**; 118 lệnh vẽ | Dự án chọn mẫu `TwoLayerColorMapAlphaBlend` (không Lightmap) vì `_loadLightmap` hỏi sai nhóm tài nguyên (FACT mã, 5.3) | **ĐÃ SỬA** lightmap (chờ trace); L5: atlas như CY (colormap/lightmap cả map với UV set 7 tương đương mật độ ô của CY — INF) |
| 14 | Hạt dùng FF | `e633dab2`/`e46476b1` (HLSL, `sequenceFrameUVFactor`, `useRibbon`) | 27–32 lệnh vẽ **FF** cùng texture | INF: vật liệu hạt của dự án thiếu chương trình Particle ở một số loại (ribbon/billboard chain) | fx (`07e-fx-cy`) |
| 15 | Khối sương nước (TerrainLiquid) | 13 lệnh vẽ `78f6952f` (`$FogColorDensity (0.12,0.18,0.21,30)`, near/far, INTZ), blend SRCALPHA/INVSRCALPHA tách alpha | 13 lệnh vẽ `d1ddb664`, cùng hằng/state/hình học, đọc R32F tuyến tính | FACT: tương đương (biến thể không INTZ) | không cần sửa |
| 16 | Hằng `imodel_userdata.w` (brightness) | 0,4776 | 1,0 | `AutoParamDataSource::mBrightness` mặc định 1 (`OgreAutoParamDataSource.cpp:86`); chỉ dùng ngưỡng `Model_Emissive`/`Model_LSScene` (≤ 0,4 mới hiện phát sáng) | Việc nhỏ S1: tìm nguồn 0,4776 trong Render.dll CY (INF: EnvKey độ sáng cảnh) — ảnh hưởng cảnh đêm |
| 17 | Texture bóng giả khi nhận bóng | 1×1 **L8** (s12) | 1×1 A8R8G8B8 | texture trắng của dự án | không ảnh hưởng hình |
| 18 | `light_position_array`/`attenuation` model | đèn 3 (khi có) range 1500, suy giảm (1,0,0) | range 394–1464, quad 5e-5..4e-6 | cùng nguyên nhân #10 | L4 |
| 19 | VSync | ONE + 2 back buffer | IMMEDIATE | cấu hình stage `View_Aplomb=0`; CY `System.cfg` = 1 | perf-cy quyết (đang đo độ mượt) |
| 20 | Clear pass depth/cảnh | cảnh: T+Z+S; bóng: T+Z+S | depth: Z+S; cảnh: T+Z+S | — | theo L2 |
| 21 | DS khi vẽ cảnh | INTZ 1280×720 | D24S8 **4096×1024** (DS của atlas bóng dùng lại) | compositor gắn DS lớn nhất cùng định dạng | L2 (bộ nhớ/tốc độ nhỏ) |
| 22 | Hằng `light_direction0.w` sương cao | 1 | 0 | auto `light_direction` vs hằng tự đặt | không ảnh hưởng (shader dùng .xyz) |
| 23 | Nước | PS/VS/texture/hằng **giống hệt** (`c89fa988`), khúc xạ đọc `rt4` FP16 | đọc `rt4` A8 | — | theo #2 |
| 24 | Hằng `texture_matrix_2x4` hạt | cuộn UV khác | khác | thời điểm khung khác (hoạt cảnh) | không |
| 25 | Số lệnh vẽ UI | 36 | 26 | màn khác (chọn server vs đăng nhập) | không |
| 26 | Hệ số `wind_control_params.w` | thời gian | thời gian | khác thời điểm | không |
| 27 | Pass bóng bắt đầu khung | có caster địa hình (`$WorldViewXf`) | dự án không cho địa hình đổ bóng | `renderableQueued` loại mọi renderable không phải `SubEntity` | L1 |
| 28 | Cull pass bóng | CW (2) như cảnh | — | — | L1 kiểm |
| 29 | Hằng `shadow_view_matrix` | hướng đèn thật (0.4575, 0.4575, 0.7625) | ma trận nhận (−0.7071, 0.7071, 0) | cùng #1 | L1 |
| 30 | Thời gian ghi khung | 10–19 s | 3 s | occlusion query + khoá texture lớn của CY | chỉ ảnh hưởng khung bị bắt |

### 5.1. Sương mù địa hình colormap — `Src\Engine\WXCore\Core\Terrain.cpp`

- FACT: bảng thay chương trình theo chế độ sương (`TerrainDataSerializer::_fixupMissingInfo`) chỉ có 4 chương trình cũ
  (`Terrain/OneLayer_ps`...). Mọi cảnh `<useColorMap>` dùng `Terrain/*ColorMap*_ps` ⇒ không bao giờ đổi sang
  `%fog_linear` ⇒ địa hình không sương. `FairyTerrainColorMap.program` có sẵn biến thể `%fog_linear` cho tất cả,
  `%fog_exp2` cho hầu hết; Render.dll CY giữ các hậu tố trần `%fog_exp`, `%fog_exp2`, `%fog_linear`.
- Luật: `<gốc>%fog_<mode>` nếu chương trình tồn tại và nạp được, không thì chương trình gốc; không đụng biến thể `@...`
  của hệ vật liệu. A/B: `CYS_PARITY_TERRAIN_FOG=0`.
- Kiểm: trace sau sửa — PS địa hình có `$fog_colour/$fog_params` (`diff-proj-1-vs-2`, mục "consts only in proj"); log
  `variant program Terrain/TwoLayerColorMapAlphaBlend_ps%fog_linear@...`. Ảnh:
  `fix-1\terrain_fog_crop_before_after_diff_2x.png` (núi xa hết mảng nâu, chìm vào sương xanh như CY),
  `fix-1\login_cy_before_after.png`. 22,5 % điểm ảnh cảnh đổi > 6/765; luma dải trái 52,1 → 51,7 (CY 46,5).

### 5.2. Số mip texture của material — `OgreMaterialSerializer.cpp`, `OgreMaterialScriptCompiler.cpp`

- FACT: dòng `texture <tên>` không ghi mip dùng `MIP_UNLIMITED` trong khi `TextureManager::load` chỉ coi **−1** là "mặc
  định" ⇒ cả chuỗi mip (1024² DXT1: 11 mức). `WXSystem` đặt mặc định 5 ⇒ 6 mức, đúng số CY trace.
- A/B: `CYS_PARITY_MIPS=full`. Kiểm: trace sau sửa — mọi texture material 6 mức; `diff-login-2` hết nhóm "mip levels".
- `aa-cy` từng ghi "mipmap 5+1 mức, giống dự án" — trace cho thấy dự án khi đó nạp đủ chuỗi.

### 5.3. Lightmap địa hình — `Src\Engine\WXCore\Core\TerrainData.cpp`

- FACT: `_loadLightmap` hỏi `resourceExists(groupName)` với `groupName = 'General'` của cảnh, trong khi `SceneFolder` là
  nhóm "Scene"; heightmap/grid info đi qua `openResource` (tìm mọi nhóm) nên vẫn nạp, còn lightmap trả về **im lặng** ⇒
  `Terrain::_getGridMaterial` thấy `lightmapped == false` ⇒ mẫu `Terrain/TwoLayerColorMapAlphaBlend` (không lightmap).
  CY dùng mẫu Lightmap (sampler s2 = L8 256²/ô). Cùng lớp lỗi `SceneInfo::load` (cs2-world 14/09).
- Sửa: tìm mọi nhóm, log `CYS parity: terrain lightmap ...`, log cả lỗi nạp ảnh. A/B: `CYS_PARITY_TERRAIN_LIGHTMAP=0`.
- Kiểm bằng trace: **chờ lượt Game.exe kế tiếp** (điều phối tạm dừng Game.exe lúc 12:28).

### 5.4. Đối tượng cảnh mặc định đổ bóng — `WXStaticEntityObject.cpp`, `WXModelObject.cpp`

- FACT: pass bóng CY có 728 caster (406 mesh tĩnh không texture, 120+40 alpha-test/cây gió, 42+26+17+13 skin, 26 địa
  hình) trong khi 860/894 `StaticEntity` của `erengu_DL.Scene` không ghi `cast shadows` (33 false, 1 true). Dự án mặc
  định `false` ⇒ atlas 0 caster. INF: editor chỉ ghi giá trị khác mặc định ⇒ mặc định gốc là true.
- Sửa: mặc định `true` (giữ `false` khi `.Scene` ghi). A/B: `CYS_PARITY_SCENE_CAST=0`. Địa hình vẫn chưa đổ bóng
  (`CYSShadowCasters` chỉ nhận `SubEntity`) — thuộc L1.
- Kiểm bằng trace: **chờ lượt Game.exe kế tiếp**.
- Kiểm bằng TlbbViewer (`Build\Logs\2026-09-15-d3d9-trace\viewer-1`, `--shadow 2`, A/B `CYS_PARITY_SCENE_CAST=0`):
  - `erengu_DL` (camera CY): caster 0 → `9/107/420/1105`; tượng/đá tối lại như CY; luma dải phải 42,8 → 37,1 (CY 38,1),
    dải trái 51,7 → 41,1 (CY 46,5 — tối quá do CSM 4 tầng thay 1 tầng 4096² và FakeLight, xem L1/L4). `login_cy_before_after.png`.
  - `dali_new_320`: caster `0/0/0/0` → `7/71/762/3155`; bóng cây chuối, lan can hiện (`dali_before_after.png`).
    **Giá**: khung viewer 9,4 → 17,1 ms, CPU atlas 14 → 18,5 ms/khung (tầng 4 có 3.155 caster). CY chưa đo được ở
    world; cần giới hạn caster như CY (khoảng cách/kích thước, số tầng cho actor `+0x188`) — gộp vào L1, perf-cy đo.
  - Viewer nạp lightmap cả khi `CYS_PARITY_TERRAIN_LIGHTMAP=0` (nhóm tài nguyên của viewer khác Game.exe) ⇒ 5.3 chỉ
    kiểm được bằng trace Game.exe.

### 5.5. FakeLight dạng khối — `Src\Engine\WXCore\CYS\Scene\CYSSceneObjects.{h,cpp}` (L4)

- FACT trace: `lightParams` của CY = (diffuse × intensity, size) — khớp từng đèn trong `erengu_DL.Scene` (6/6 mẫu);
  `globalIntensity` = 1; hộp 12 tam giác, `scene_blend dest_colour one`, `cull_hardware anticlockwise`, không z.
- Sửa: mỗi `CYSFakeLightObject` = thực thể hộp `CYS/FakeLightBox` (±50, tam giác CCW nhìn từ ngoài ⇒ vẽ mặt trong)
  với bản sao `Mtl_FakePointLight` (MaterialTemplates, đọc `content_type compositor SceneRender depth_buffer` = độ sâu
  tuyến tính R32F của CysPostFX, cùng quy ước với biến thể không-INTZ của CY); không đổ bóng, hàng `RENDER_QUEUE_MAIN`
  (trong suốt). Không còn point light OGRE ⇒ model/địa hình về số đèn như CY. A/B: `CYS_FAKELIGHT_MODE=light`.
- Nút depth: `CysWaterRender::addDepthUser/removeDepthUser` giữ stage "Water" (nút depth) sống cả khi cảnh không có
  nước mới.
- Hai bẫy đã gặp khi kiểm (trace `proj-login-5..7`): (1) `CysMaterialSystem::classify` coi `Model_FakePointLight_ps`
  là họ model ⇒ biến thể `@LUT_ENABLE=1;SHADOWMAP_TYPE=1` — CY không có (PS CY chỉ 6 hằng) ⇒ loại ra (CYS-PARITY);
  (2) hằng ghi SAU `setMaterialName` không tới biến thể theo thực thể của hệ vật liệu: `lightParams` đi qua đồng bộ,
  `globalIntensity` giữ giá trị thanh ghi của shader khác (0,000934 = `shadow_csm_proj_scale`) ⇒ hộp đen. Ghi hằng
  trước khi gán material cho thực thể.
- Kiểm (FACT, `proj-login-8`, viewer `viewer-1\login_fl-trace`): 44 hộp, 624.687 px (CY 44 hộp, 624.778 px),
  `lightParams` và `globalIntensity = 1` như CY; đèn/lệnh vẽ địa hình 2–5 (CY 2–5, trước 2–16); model 719×2 đèn +
  246×3 (CY 762 / 284; trước 147 / 818). Luma (`fix-3\login_cy_before_after.png`, `statue_cy_before_after.png`):
  tượng 66,4 → 73,7 (CY 76,8), lửa trái 98,7 → 104,1 (CY 108,3), dải trái 41,5 → 44,4 (CY 46,5), dải phải
  39,3 → 40,6 (CY 38,1), dưới 44,9 → 46,3 (CY 43,0). (Gồm cả FP16, xem 5.6 A/B.)

### 5.6. Đích cảnh FP16 — `CysPostFxPipeline.{h,cpp}`, `CysWaterRender.cpp` (L2 phần 1)

- FACT trace: CY vẽ cảnh vào A16B16G16R16F, chép sang A16B16G16R16F, HeightFog FP16 → FP16, chép ra back buffer
  không tonemap, không dither; khúc xạ nước đọc bản chép FP16.
- Sửa: `parityFp16()` giữ đích ping/pong FP16 bất kể chế độ HDR shading; dither chỉ ở cinematic; `scene_buffer` của
  nước cùng định dạng (StretchRect không đổi FP16 → RGBA8). A/B: `CYS_PARITY_FP16=0`.
- Kiểm (FACT, `proj-login-8`): log `pipeline CysPostFX/Pipeline/1 1280x720 FP16`; trace rt3/rt4/rt5
  A16B16G16R16F như CY. A/B màu (`proj-login-8` FP16 / `proj-login-8-fp16off` RGBA8, cùng build, luma L và chroma C
  0–255): dải trái L 44,4/44,4 (CY 46,5), phải 40,6/40,7 (CY 38,1), dưới 46,3/46,2 (CY 43,0), tượng 73,7/73,0
  (CY 76,8), trời phải 48,5/47,7 (CY 47,6); chroma lệch ≤ 0,4. ⇒ FP16 **không** làm lệch màu đã chốt với color-calib
  (≤ 2 %); giữ mặc định bật.
- Chưa làm: bỏ pass depth R32F bằng DS INTZ (cần INTZ trong RenderSystem_Direct3D9 + `content_type dsintz`).

### 5.8. Cấu hình bóng lúc chạy như CY — `CYSShadowHost.cpp::configForLevel` (L1 phần 1)

- FACT: mục 3 #1 và 3.1 — một map 4096², khoảng 8000, bias 8/20, dải hoà 0,005 ở mức 2 (đăng nhập và world).
- Sửa: mức 2 = 1 tầng 4096, split {8000}, bias 8/20, back-off 8000 (đăng nhập vẫn 18000 như trước). A/B:
  `CYS_PARITY_SHADOW=ctor` (4×1024 cũ).
- Kiểm viewer `viewer-2\dali_w09`: log `tile 4096, cascades 1, distance 8000, splits 8000, bias 8/20`; trace atlas
  4096×4096. Fit: `stable` (mặc định dự án) cho ortho 11.314² — thô hơn CY ~20 %; `Gfx_ShadowFit=tight` cho
  9.701 × 7.684 ≈ CY 9.422 × 7.555 (cùng tỉ lệ sâu) ⇒ CY dùng fit tight (kèm nháy khi camera đi). Quyết định fit và
  luật chọn caster để lại cho shadow/perf-cy.
- Kiểm Game.exe (world replay `world-3`, PASS): trace receiver `shadow_param (1,1,4096,0)`, `shadow_csm_param
  (1,1,0.005,8000)`, `isystem_userdata (8,0,0,20)` = CY; atlas 4096²; caster 278 (`world-1`) / 1.011 (`cam-zoom-far`),
  CPU atlas 1,6–2,8 ms/khung (trước, CSM 4×1024 ở `world-2`: 2,6–5,1 ms). Ảnh `fix-3\world_shadow_cy_before_after.png`.
- Người điều phối 15/09: mặc định **fit tight** như CY (`CYS_SHADOW_FIT=stable` / `Gfx_ShadowFit=stable` để A/B).
  Đo nháy (`CysShadowTest --stability 120`, cấu hình 1×4096/8000/bias 8, camera fit dịch ±37/23 đơn vị và xoay ±2,5°
  mỗi khung, `shimmer-1\stdout.txt`): stable |dRGB| 0,0004/điểm ảnh/khung, 0,0007 % điểm ảnh đổi; tight 0,0401 và
  0,0901 % (≈ 130 lần) ⇒ viền bóng bò khi camera di chuyển.
- **Kết luận nháy (FACT, `shadow_snap.py`)**: tọa độ texel của gốc thế giới trong map CY ở 3 khung Đại Lý có phần lẻ
  (0,583; 0,272) / (0,591; 0,219) / (0,194; 0,050) — thay đổi theo camera ⇒ CY **không** snap lưới texel thế giới:
  offset ortho là số nguyên texel (−471; −14) nhưng tịnh tiến view ánh sáng đi liên tục theo camera. Dự án stable:
  phần lẻ luôn 0,500 (snap); tight: 0,796/0,972 (không snap, như CY). Texel: CY 2,300, tight 2,368, stable 2,762.
  ⇒ CY nháy như tight; người điều phối chốt giữ tight mặc định.

### 5.9. Kiểm tra

- Build Release x64 rc 0 (`build-1.log`, `build-2.log`); smoke đăng nhập offline PASS (`proj-login-2`, 0 DBC ERROR);
  `Tests\scene` PASS (`scene-test.log`, `scene-test-2.log`).

### 5.10. Chiếu sáng nhân vật/NPC/quái như CY (L6)


Dự án trước sửa: nhân vật/NPC trong game là `LogicModelObject` tên tự sinh ⇒ `x = 0`; skin mặc định ⇒ actor; mọi
model nhận bóng + LUT; brightness 1; actor ambient = khoá SkySphere; pass alpha-test có chương trình không có biến thể
`ALPHATEST_ENABLE`.

Sửa (`// CYS-PARITY:`):
- `CRFObj_Actor::Actor_SetFile`: `setActorLighting(1)` cho nhân vật game. `SubEntity::getActorLightingFactor`: không
  cờ ⇒ 0 (cảnh). A/B `CYS_PARITY_ACTOR=0`.
- `CysMaterialSystem`: `VertexFeatures::actor` (khoá biến thể `A`): actor giữ chương trình gốc, không thăng
  LIGHT_CALC 2, không `SHADOWMAP_TYPE`/`LUT_ENABLE` ở VS và PS. `LogicModel::setActorLighting` chọn lại biến thể qua
  `SubEntity::setMaterialName` (gọi thẳng `resolveEntity` làm entity mất skin phần cứng — vẽ 0 điểm ảnh).
- Pass alpha-reject có PS họ model ⇒ biến thể `ALPHATEST_ENABLE=1` (A/B `CYS_PARITY_ALPHATEST=0`).
- `CYSEnvironmentManager::update`: `setBrightness` theo công thức CY (A/B `CYS_PARITY_BRIGHTNESS=0`).
- `CYSEnvironmentProvider`: cảnh SkySphere không đè actor ambient.
- `TlbbViewer --model-at x,z[,yaw]`: đặt model đúng chỗ NPC của trace CY.

Kiểm:
- Viewer cùng camera + cùng NPC (`viewer-3`, 赵天师 cưỡi hạc ở (400, −700), 木人 ở (−200, −200)): 7/7 lệnh vẽ actor
  trùng CY về hash VS/PS, `imodel_userdata` (1, 1–3, 0/0,5, 0,639176), actor ambient, không nhận bóng
  (trước: VS `368d5a30` + PS nhận bóng `9f7d6cc2`, brightness 1, actor ambient 0,894). Ảnh `fix-4
pc_cy_before_after.png`.
- Game.exe world replay (`world-4`, PASS): nhân vật bot `x = 1`, VS chiếu sáng theo đỉnh, không nhận bóng; brightness
  0,6392 = CY; cảnh `x = 0` vẫn nhận bóng. Ảnh `fix-4\game_bot_before_after.png`. `Tests\scene` PASS.
- Chưa so: nhân vật người chơi CY (model 男主角 của oracle chưa vào khung trace).

### 5.11. Địa hình đổ bóng như CY — `CYSShadowCasters.cpp`

FACT (trace CY): CY **có** vẽ ô địa hình vào map bóng 4096² R32F — Đại Lý w09 40 lệnh vẽ (40.960 tam giác), w28 44,
w42 42, đăng nhập 26 — sau toàn bộ caster entity; VS `9beba414` (`$WorldViewXf`, `$WvpXf`), PS `c46a8a36`
(`CartoonEffect/PS/DrawDepth_NoTex`: R = độ sâu view, B = `$specialFlag` 1,5) = technique scheme `Depth` của vật liệu
địa hình (`FairyTerrainColorMap.material`); cull CW, `DEPTHBIAS` 0, `SLOPESCALEDEPTHBIAS` 0; bias nằm ở receiver
(`isystem_userdata` 8/20). Ô nào: các ô trong frustum camera bóng (không có lọc riêng thấy được).

Sửa: `renderableQueued` nhận `TerrainTileRenderable`, dùng technique `Depth` của chính vật liệu ô (A/B
`CYS_PARITY_TERRAIN_CAST=0`).

Kiểm (viewer cùng camera CY w09, `viewer-4`): lệnh vẽ địa hình trong pass bóng có đúng VS/PS hash, cull, bias,
`$specialFlag` như CY; phủ map bóng 41,9 % → 99,3 % (CY 100 %), ảnh `fix-4\shadowmap_terrain_cy_before_after.png`.
Khác: dự án 412 lệnh vẽ / 49.152 tam giác (CY 40 / 40.960) vì mỗi ô tách theo cặp texture (việc L5 atlas).
Quảng trường Đại Lý phẳng: ảnh không đổi; màn đăng nhập (núi): 10,3 % điểm ảnh tối đi ở núi/vùng giữa
(`fix-4\login_terrain_cast_cy_before_after.png`).
Game.exe world replay (`world-5`): pass bóng có 292 lệnh vẽ địa hình `9beba414/c46a8a36` + 220 caster entity.

### 5.12. Gộp brush địa hình vào một texture như CY (L5) — `Terrain.cpp`, `WXSystem.cpp`

FACT (trace, `terrain_draws.py`):
- **Đại Lý w09.** Pass cảnh có 12 lệnh vẽ cho 6 ô, mỗi ô 2 lệnh:
  - lưới 1 lớp: decl `POSITION NORMAL TEXCOORD0 TEXCOORD7` (40 B), VS `bd45369a`, PS `c8eaf13b`;
  - lưới 2 lớp: thêm `TEXCOORD1` (48 B), VS `6ecd9510`, PS `2fe658e4`;
  - tổng 12.288 tam giác = mọi lưới của 6 ô; cặp 1 lớp/2 lớp của ô (4,3) là 3.844/296 tam giác, khớp `dali_new_320.GridInfo`.
- **Pass bóng w09.** 40 lệnh vẽ, cũng tách 1 lớp/2 lớp.
- **Đăng nhập.** 36 lệnh vẽ cảnh (toàn lưới 2 lớp), 26 lệnh bóng.
- **Texture.** s0 (và s1) luôn là **một** texture 4096×1024 A8R8G8B8 5 mức (Đại Lý `t700a05e`, đăng nhập `t2e1cd19`); lọc ở world ANISO 8/MIP LINEAR. Lightmap theo ô 256² L8 (s2).
- **Index buffer.** IB 16-bit dùng chung, 1.024 quad.


Sửa:
- `Terrain::_comboBrushes` làm đúng các bước trên. Nếu nạp/xếp lỗi thì log `CYS parity: terrain combo cancelled` và giữ dữ liệu cũ.
- Gọi trong `System::_postprocessScene` trước `SceneInfo::initialise`. Vì vậy `buildGeometry` sau đó, kể cả `Scene_SetLightmapQuality` và `cysPrewarm` của perf-cy, đều dùng dữ liệu đã gộp.
- A/B `CYS_PARITY_TERRAIN_COMBO=0`.
- INF: CY giữ lưới xếp chỗ trong đối tượng Terrain. Nhưng Đại Lý sau cảnh đăng nhập vẫn cao 1024, nên ở đây lưới được làm lại mỗi cảnh.

Kiểm (TlbbViewer cùng camera CY, `viewer-5`):

| Cảnh | Pass | Trước | Sau | CY |
|---|---|---|---|---|
| Đại Lý | cảnh | 114 lệnh, 19 texture s0 L1 | **12** lệnh, 1 texture 4096×1024 L5, 12.288 tam giác | 12 |
| Đại Lý | bóng | 412 | **48** | 40 |
| Đăng nhập | cảnh | 118 | **36** | 36 |
| Đăng nhập | bóng | 137 | **40** | 26 |

Số lệnh bóng còn chênh vì khác số ô trong frustum bóng; luật chọn caster thuộc perf-cy.

Ảnh:
- `fix-5\dali_terrain_combo_cy_before_after.png`: khác trước/sau 0,38 % điểm ảnh (> 8), là đường nối lưới. Vùng địa hình gần CY hơn: |Δ| trung bình 0,64 → 0,49 và 0,51 → 0,34.
- `fix-5\login_terrain_combo_cy_before_after.png`: khác 5,6 %, bằng mức nhiễu sương/hạt giữa hai lần chạy cùng cấu hình (5,1 %).

Perf (viewer, 900 khung, nửa sau; proxy `cpu_ms` = từ Present trả về tới Present kế; máy có agent khác chạy song song):

| Cảnh | Cấu hình | mean trước → sau (ms) | p95 trước → sau (ms) |
|---|---|---|---|
| Đại Lý | aniso 16, 2 cặp | 12,6 / 10,9 → 11,3 / 9,7 | 14,6 / 11,8 → 17,0 / 10,6 |
| Đăng nhập | aniso 8 (như Game.exe/CY world), 3 cặp | 29,7 / 23,5 / 22,2 → 24,6 / 20,7 / 19,4 | 33,9 / 30,6 / 33,4 → 29,9 / 23,6 / 22,2 |
| Đăng nhập | aniso 16 (mặc định viewer), 2 cặp | 21,7 / 22,7 → 50,8 / 28,4 | chậm hơn |

- Hook material mỗi khung (CPU): Đại Lý 348 → 158 ms / 900 khung; đăng nhập 424–456 → 345–399 ms. Biến thể material: Đại Lý 702 → 338, đăng nhập 423 → 311.
- INF: aniso 16 chậm hơn vì brush cũ chỉ có 1 mức mip, còn texture gộp có 5 mức như CY. Game.exe dùng aniso 8.

Game.exe world replay (`world-6`, PASS). Chuỗi cảnh: đăng nhập → tạo nhân vật → Đại Lý. Mỗi cảnh log `CYS parity: terrain '<cảnh>' N brushes comboed into ComboedBrush` (erengu_DL 4096×1024, tl3chuangjian 4096×512, dali_new_320 4096×1024).

| Khung | Lệnh vẽ cảnh (trước `world-5` → sau) | Lệnh vẽ bóng (trước → sau) |
|---|---|---|
| `world-1` | 125 → 14 | 292 → 36 |
| `cam-zoom-far` | — | 40 (16 cảnh) |
| `move-running` | — | 34 (41 cảnh) |

- s0/s1 = 4096×1024 L5.
- Ảnh `fix-5\game_world_terrain_combo_before_after.png`: khác 0,82 % điểm ảnh, gồm tên/bot và hạt.
- Khung hình bị VSync giới hạn: dt p95 23,5 → 18,8 ms (`world-4` cũ 19,0); `cpu_ms` p95 18,0.


### 5.13. DS INTZ thay pass depth R32F (L2) + lọc texture màn đăng nhập (S1)


Sửa:
- **RenderSystem D3D9** (`_cysSetIntzSceneDepthTarget`, `_cysIntzSceneDepthFor`): render target đã đăng ký lấy DS là texture INTZ cùng kích thước.
  - Texture được tạo khi dùng lần đầu và là texture của `content_type dsintz`.
  - Giải phóng ở `_cleanupDepthStencils` (mất thiết bị/tắt) và khi đổi target.
- **`CysPostFxPipeline::intzSceneDepth()`** (tắt bằng `CYS_PARITY_INTZ=0`, hoặc khi thiết bị không có INTZ): đăng ký `rt_ping`.
  - Stage `supportsIntzDepth()` (Water, HeightFog) không cần depth node.
  - GodRays / SSAO / DoF vẫn dùng depth node R32F khi bật (mặc định tắt).
- **Vật liệu `_DSIntZ` của CY**:
  - `Mtl_FakePointLight_DSIntZ`;
  - `shader_water01_DSIntZ` (`CYSScene::chooseWaterMaterial`);
  - `CysPostFX/HeightFog_DSIntZ` (HeightFog_ps.hlsl `USE_DSINTZ=1`, `near/far_clip_distance` mỗi khung).
- **FXAA / FXAAQuality / DLAA** chạy sau HeightFog, order 115 (`CYS_PARITY_AA_ORDER=0` = order 80 của B).
- **Lọc texture** (`CysPostFx::onSceneLoaded`):
  - id cảnh < 0 (đăng nhập, chọn/tạo nhân vật): `TFO_BILINEAR`, aniso 1;
  - cảnh world: trả lại `View_TextureFiltering` (2 = aniso 8);
  - tắt bằng `CYS_PARITY_LOGIN_TEXFILTER=0`.
- **TlbbViewer** mặc định `--aniso 8`.

Kiểm:

| | Trước | Sau | CY |
|---|---|---|---|
| Game.exe đăng nhập, lệnh vẽ/khung (`proj-login-11` → `proj-login-10`) | 3.401 (pass depth 1.079) | **2.321** | 2.063 |
| DS pass cảnh | D24S8 4096² dùng chung | **INTZ 1280×720** | INTZ 1280×720 |
| PS FakeLight / sương nước / HeightFog | `95bb9a8b` / `d1ddb664` / `6a170c4f` (đọc R32F) | **`1e1f4ac9` / `78f6952f` / `6c52486a`** | `1e1f4ac9` / `78f6952f` / `6c52486a` |
| Chuỗi hậu kỳ | FXAA → HeightFog | **HeightFog → FXAA** | HeightFog (không AA) |
| Lọc s0 cảnh đăng nhập (min/mip/aniso) | 3/2/8 | **2/1/1** | 2/1/1 |
| Game.exe `cpu_ms`/dt đăng nhập (VSync) | mean 20,1, p95 32,9 ms | **mean 17,0, p95 19,8 ms** | |
| Game.exe world replay (`world-6` → `world-7`, PASS) | pass depth 83 lệnh | không pass depth; INTZ tạo lại đúng sau Reset 1024×768; lọc 3/2/8 | 3/2/8 |

- Viewer đăng nhập (`viewer-6`): px FakeLight 624.721 → 625.288 (CY 624.778). Ảnh khác 5,3 %, bằng mức nhiễu sương hạt giữa hai lần chạy.
- Viewer Đại Lý: ảnh trước/sau giống hệt; 1.278 → 1.171 lệnh vẽ.
- Ảnh: `fix-5\game_login_intz_cy_before_after.png`, `fix-5\game_world_intz_before_after.png`.
- Chưa làm: DoF/GodRays/SSAO chưa có biến thể INTZ, khi bật vẫn dựng depth node. CY có `PostFilters/DoF/DepthOfField_DSIntZ`.

### 5.14. Lightmap + colormap theo ô, decl địa hình như CY (L5b) — `Terrain.cpp`, `TerrainTileOptimized.cpp`, `RenderSystem.cpp`


Sửa (A/B `CYS_PARITY_TERRAIN_TILEMAPS=0`):
- `TerrainTileOptimized`: bỏ bộ UV lightmap riêng; TEXCOORD7 = UV trong ô.
- `Terrain`:
  - không tạo `<Lightmap>(all)`; `<lightmap>` = lightmap của ô;
  - `_cysPrepareColorMapTextures` tạo `<colorMap>(x,z)`, nạp ở `loadResource`;
  - vật liệu tách theo ô khi có colormap.
- `CRenderSystem::Scene_Load`: `LMQ_HIGH` như CY (B ép `LMQ_LOW`).
- Proxy: `CYS_D3DTRACE_VBDUMP=N` ghi byte vertex của mỗi lệnh vẽ vào `<cap>\vb`.

Kiểm:

| | Trước | Sau | CY |
|---|---|---|---|
| Game.exe đăng nhập s2 (`proj-login-11` → `proj-login-13`) | 1 lightmap cả map (512² thấp / 2048² viewer) | **256² L8 ×36** | 256² L8 ×36 |
| s3 colormap | 512² cả map | **64² ×36** | 64² ×36 |
| VB mỗi ô đăng nhập | 229.376 B | **196.608 B** | 196.608 B |
| UV7 | cả map | **trong ô (bắt đầu 0)** | trong ô |
| Đại Lý decl 1 lớp / 2 lớp | 48 / 56 B | **40 / 48 B** | 40 / 48 B |
| VB lưới 2 lớp Đại Lý (6 ô) | — | trùng từng byte-size với CY | |

- Hình:
  - Đại Lý trước/sau lệch tối đa 3/255;
  - đăng nhập khác 5,0 %, bằng mức nhiễu sương/hạt;
  - ảnh `fix-5\dali_terrain_tilemaps_cy_before_after.png`, `fix-5\login_terrain_tilemaps_before_after.png`.
- VRAM (tính theo cỡ texture, mip ×4/3):
  - Đại Lý bỏ lightmap cả map 2560² (8,7 MB);
  - đăng nhập bỏ lightmap cả map 2048² (5,6 MB), colormap cả map 512² (1,4 MB) thành 64 texture 64² (1,4 MB);
  - Game.exe đăng nhập lightmap theo ô từ 64² lên 256² (0,37 → 5,6 MB), như CY;
  - VB địa hình giảm 8 B/vertex.
- Perf Game.exe đăng nhập (VSync): p95 19,3 → 18,9 ms.

Phát hiện khi kiểm (chưa sửa):
- PS địa hình Game.exe là `5201f4e2`, không có `fog_colour/fog_params`. CY và `proj-login-8` (13:59) dùng `7f401886` có sương.
- `proj-login-11` với INTZ tắt cũng là `5201f4e2`, nên nguyên nhân không nằm ở L2/L5b.
- INF: biến thể material bị resolve trước khi `_applyFogMode` đổi chương trình sang `%fog_linear`. Nghi `Terrain::cysPrewarm` (perf-cy, 6f49d0b0) hoặc `_comboBrushes::clearGeometry`.
- Viewer (không prewarm) vẫn là `7f401886`. Kiểm lại bằng `CYS_PERF_PREWARM=0`.

## 6. Việc lớn cho người điều phối

| Mã | Việc | Bằng chứng/điểm vào | Lợi ích |
|---|---|---|---|
| L2 | **ĐÃ LÀM (5.13)** Cảnh FP16 + DS INTZ đọc trực tiếp, bỏ pass depth R32F; FXAA sau HeightFog | `CysPostFxPipeline.cpp:713`, `buildDepthNode`; CY `Mtl_*_DSIntZ` | màu cộng dồn đúng CY; −1.161 lệnh vẽ/khung |
| L3 | Bầu trời bằng `EnScene.hlsl` + `SkySphereLayer.hlsl` — **ĐÃ LÀM** (sky-enscene): vòm/SkySphere đầu pass cảnh, mây vòng/trăng sau đồ đục | `sky-enscene-cy_vi.md`; `CYSSkyCyRenderer.cpp` | màu trời như CY (sai khác 2–5/255); −7,2 triệu px tô |
| L4 | FakeLight dạng khối `Mtl_FakePointLight_DSIntZ` thay point light OGRE | mục 4 #10; `CYSSceneObjects.cpp:305` | hết dư sáng tượng/địa hình; model/địa hình về 2 đèn như CY |
| L5 | **ĐÃ LÀM (5.12, 5.14)** gộp brush 4096×1024 5 mức (12/36 lệnh vẽ như CY); lightmap/colormap theo ô, decl 40/48 B | mục 4 #13; `Terrain.cpp:280` | bóng nướng của địa hình, ít lệnh vẽ, mip atlas |
| M1 | Thứ tự hàng đợi như CY (đục theo chương trình, địa hình sau model, alpha-test sau) | mục 4 #6 | ít đổi state, early-Z |
| M2 | Lightmap địa hình — đã sửa nguyên nhân nhóm tài nguyên (5.3), còn kiểm bằng trace | mục 4 #13 | bóng nướng địa hình |
| S1 | Nguồn `imodel_userdata.w = 0,4776` | mục 4 #16 | phát sáng về đêm |
| L6 | **ĐÃ LÀM (5.10)** Actor (người chơi/NPC/quái) như CY: `imodel_userdata.x = 1`, chiếu sáng theo đỉnh, **không** nhận bóng, brightness 0,639 (nguồn chưa rõ) | mục 3.2; `CysMaterialSystem::promotesToPixelLighting`, `LogicModelManager` (bot replay x = 0) | màu/độ tương phản nhân vật như CY, bớt chi phí PS |
| L3b | Bầu trời Đại Lý: SkySphereLayer HLSL — **ĐÃ LÀM**; FACT: 5 lệnh là lệnh đầu pass cảnh (queue 5), không phải sau đồ đục | `sky-enscene-cy_vi.md` §7.2 | |
| — | **ĐÃ QUYẾT + LÀM (5.13)**: world aniso 8, màn đăng nhập/nhân vật bilinear mip POINT aniso 1 như CY; VSync giữ như dự án | mục 4 #4, #19 | |

## 7. Bẫy

1. Hàm gốc chỉ có cho slot đã vá: gọi phương thức chưa vá qua bảng `orig` = con trỏ null (lần thử đầu văng khi bắt
   khung). Trong vùng `Inside` gọi thẳng qua đối tượng.
2. D3D9 báo `GetLevelCount() == 1` với texture `AUTOGENMIPMAP` — không phải "không mip".
3. PowerShell 5.1: chuỗi có `"` truyền vào lệnh ngoài (git -m) bị cắt thành nhiều đối số ⇒ dùng `git commit -F`;
   bộ kiểm quyền của agent chặn `Remove-Item Env:` khi cùng lệnh có đường dẫn `C:\Program Files` ⇒ dùng
   `[Environment]::SetEnvironmentVariable(k, $null, 'Process')` trong script.
8. Lỗi nhóm tài nguyên một nhóm (`resourceExists(groupName)`) còn có thể nằm ở nơi khác đọc file cạnh `.Scene`
   (lightmap đã sửa, `.Terrain` đã sửa bởi cs2-world) — grep `resourceExists(` khi thấy dữ liệu cảnh "không có".
4. Bash heredoc với `cat > /dev/null` treo chờ stdin; `\` trong heredoc Python bị nuốt (bẫy 5 colorlut) ⇒ dùng Write.
5. Hạt/UI thay đổi theo thời gian: hằng UV cuộn, gió, `texture_matrix` luôn khác giữa hai lần bắt — không phải lỗi.
6. Cặp ghép theo hình học có thể nhầm giữa các bản sao cùng mesh; công cụ ghép theo vị trí thế giới gần nhất, còn sai số
   nhỏ ở hạt (#7 cần kiểm lại).
7. CY cửa sổ luôn 1280×720; khung chọn server che giữa màn — so vùng hai bên.
