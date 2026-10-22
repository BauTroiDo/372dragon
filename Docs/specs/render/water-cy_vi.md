# Nước của CY 3.71 và bản dựng trong CY-Source (water-cy, 14/09/2026)


## 0. Tóm tắt

| Hạng mục | CY 3.71 (C) | B (client_GL) | CY-Source trước 14/09 | CY-Source sau water-cy |
|---|---|---|---|---|
| Template/shader nước | `Water_vs`, `Model_Water_ps`, `Base_Water_ps`, `WaterReflectionReraction.hlsl` | **giống hệt C** (cùng nội dung trong `MaterialTemplates.zip`) | nạp được | như C |
| Material nước (`all.material`) | `shader_water01`, `shader_water_mirror`, `baseWater`, `haihuwater`… | **giống hệt C** (khối 17 965 byte, cùng md5) | nạp được | như C |
| Dữ liệu cảnh | 2 597 TerrainLiquid / 418 cảnh; **`shader_water01` 1 073**, `haihuwater` 891 | 2 253 / 416; `haihuwater` 1 287, `shader_water01` 351 | — | đọc dữ liệu C |
| Nước mới (khúc xạ + phản chiếu cube + sương dưới nước) | bật theo mục chất lượng "nước" | có | **tắt**: rơi về `replaceMaterial` (ảnh động `huwaterlv`…) | **bật** |
| `scene_buffer` (RefractTex) | chép cảnh tới queue 76 | có | không ai tạo | chép bằng StretchRect |
| Nút độ sâu cho nước | `SceneDepthForWater` R32F | có | có nút độ sâu của hậu kỳ nhưng chỉ khi một bộ lọc cần | stage `Water` giữ nút sống |
| Nước gương | RT 1024² dùng chung, camera `ReflectRTCamera` | có | không | có |

## 1. Dữ liệu nước của C (FACT, `census_cy.json`, `census_cy.tsv`)


| Material | C: đối tượng / cảnh | B: đối tượng / cảnh | Loại |
|---|---|---|---|
| `shader_water01` | **1 073 / 168** | 351 / 89 | nước mới (2 technique `WaterFog` + `Effect`) |
| `haihuwater` | 891 / 184 | 1 287 / 246 | cũ: ảnh động 28×2 + `water_depth.tga` 1D |
| `岩浆1` (dung nham) | 195 / 33 | 206 / 46 | cũ |
| `PBRScene_Water` | 111 / 40 (toàn bộ là nước dạng mesh) | 62 / 25 | nước mới trên mesh (`Model_Water_ps`) |
| `shader_water_mirror` | 77 / 77 | 68 / 67 | nước mới, phản chiếu gương |
| `bingwater` 70, `heliuwater` 59, `水01` 36, `waterNormal` 14, `水01Depth` 13, `岩浆11` 12, `PBRScene_Water2` 10, … | | | |

- `replaceMaterial` (1 357 đối tượng): `shader_water01 → huwaterlv` 568, `→ haihuwaterlv` 362; `PBRScene_Water → huwaterlv` 82…
- `showNewWaterEnabled=true` 156, `showMirrorReflectWaterEnabled=true` 79; `mesh name` 127 (111 `PBRScene_Water`,
  10 `PBRScene_Water2`, 6 `shader_water01`).
- ShaderParams (≈1 370 đối tượng mỗi khoá). Giá trị hay gặp: Fog Density 100/400/200, Reflection Amount 0,5/0,2,
  Transparency 0,3/0,2, SunShine Pow 800/12, Fresnel Bias 0,5/0,3/0,2, Wave Speed 6/15/10/30, uvScale "0.05 0.08".
- Thành phố chính: `dali_new_320` 10 `shader_water01`; `suzhou_new` 26; `luoyang_new` 17; `jinghu` (Kính Hồ) chỉ
  `haihuwater` (nước cũ ở cả C lẫn B). `dali.Scene` của B chỉ có `haihuwater`/`水01` (không có nước mới).
- Texture: `oceanwaves.dds` (normal/noise), `Water_Cubicmap.dds` (cube), `water_depth.tga` đều có trong `MaterialFolder` của C.

### 2.1 `shader_water01` (nước mới, không gương)

- Technique 0 **`WaterFog`**: `depth_write off`, `separate_scene_blend src_alpha one_minus_src_alpha zero zero`
  (màu trộn theo alpha, **alpha đích bị ghi 0**); VS `Water/water_Fog/VS`, PS `Water/water_Fog/PS` (`WaterFog_PS`):
  độ dày nước = `min(dot(eyeDir, −camFront) − sceneDepth, 0)`, `fog = 1 − exp(depth · FogColorDensity.w · 1e-5)`,
  xuất `(FogColorDensity.rgb, fog)`. `sceneDepth` đọc `content_type compositor SceneRender depth_buffer` (độ sâu tuyến tính).
- Technique 1 **`Effect`**: không blend, `depth_write off`; VS `WaterReflectionReraction_VS` (sóng: `time·0.0125·wavesSpeed`,
  4 toạ độ `wave0/1` ở tỉ lệ 1,2,4,8; `oUV.z = tex_depth` = TEXCOORD1 1D của lớp độ sâu), PS
  `WaterReflectionReraction_PS`:
  - normal: 4 mẫu `oceanwaves.dds` × `UVScale`, sóng lớn/nhỏ × `BigWavesScale`/`SmallWavesScale`, xz × `BumpScale`;
  - phản chiếu: `texCUBE(Water_Cubicmap.dds, reflect(eye, n))` × `ReflectionAmount`;
  - khúc xạ: `RefractTex` = `SceneRender scene_buffer` tại `uv + n.xz·0.1`; nếu `alpha` của mẫu gốc hoặc mẫu lệch > 0,0001
    (điểm KHÔNG nằm sau mặt nước) thì dùng mẫu gốc — **mặt nạ alpha do pass `WaterFog` ghi 0**;
  - fresnel `saturate(FresnelBias + (1−FresnelBias)(1−|v·n|)^5)`; màu = `lerp(refract, reflect, fresnel·TransparencyRatio)`;
  - nắng: `pow(saturate(dot(R, −L0)), SunShinePow) · light0 · SunMultiplier`;
  - **mép bờ**: `lerp(scene gốc, màu nước, saturate(tex_depth·10))` — mép nước mờ dần theo độ sâu địa hình (không có bọt);
  - sương cảnh `Fogging(fog_type, fog_params)`; alpha 1.
- Bản `_DSIntZ` giống hệt nhưng đọc `content_type dsintz` (INTZ phần cứng).

### 2.2 `shader_water_mirror`

Như 2.1 nhưng PS có `USE_MIRROR=1`: unit 1 là `texture ReflectTexInput` (2D), phản chiếu `tex2D(reflect, uv + n.xz·0.1)`,
`lerp(refract, reflect, fresnel·clamp(TransparencyRatio, 0.8, 1))` (không nhân `ReflectionAmount`).

### 2.3 `PBRScene_Water(2)` (nước mesh, `Mtl_Character.material`)

Một pass `render_queue on 77`, VS `Model_Water_VS`, PS `PBRScene_Water_PS` (`Model_Water_ps.hlsl`): s0 depth_buffer, s1
`oceanwaves.dds`, s2 cube, s3 scene_buffer; sương thể tích và khúc xạ trong cùng một pass, xoay/tỉ lệ UV
`texRotateScale`, mép `texDepthFactor` (mặc định 20). Bản `2` dùng `wind_control_params.w` thay `time`.

### 2.4 Nước cũ

`haihuwater`, `huwaterlv`, `bingwater`…: fixed-function, `anim_texture` + `water_depth.tga` 1D qua `tex_coord_set 1`,
`alpha_blend`. `baseWater(_DSIntZ)`: `Base_Water_VS/PS`, queue 77, sương theo depth (C chỉ dùng cho mesh không phải shader).

### 3.4 Độ phân giải và chất lượng

| RT | C | Ghi chú |
|---|---|---|
| `scene_buffer` | 1,0× viewport, A8R8G8B8 | FACT |
| `depth_buffer` (nước) | 1,0×, R32F | FACT |
| `waterMirrorReflectTex` | 1024², format 0xb | FACT |
| `waterReflectTex`/`waterRefractTex` (0.85) | 512², format 0x1a | FACT, không dữ liệu C nào dùng |

Không có caustic hay bọt bờ trong shader C (FACT: không có sampler/hằng nào cho chúng); mép nước chỉ là trộn theo `tex_depth`.

## 4. Lệch giữa B, hiện trạng và C

- **Dữ liệu**: C dùng `shader_water01` gấp 3 lần B → trên nền dữ liệu C, thiếu nước mới là lệch lớn nhất nhìn thấy.
- **Hiện trạng trước 14/09** (`CYSWater.cpp`): `supportsNewWater()` = false → mọi `shader*` lấy `replaceMaterial`;
  `PBRScene_Water` được vẽ nhưng `RefractTex` không tồn tại; material có `WaterFog` chỉ vẽ technique tốt nhất (tức sương) ở
  queue 75; mặc định ShaderParams lấy "giá trị hay gặp của client_GL" thay vì mặc định chương trình của C.
- **B**: Render.dll khác C (md5 `387a231c…`) nhưng template, material và tên RT/nút giống C (doc 05 §5). Không lấy gì riêng
  của B cho nước.

## 5. Bản dựng CY-Source (hook `// CYS-WATER:`)

| Phần | File | Theo C |
|---|---|---|
| Chép render target | `OgreRenderSystem.h` `_copyActiveRenderTarget`; D3D9 `StretchRect` | nút `FrameCopy` |
| Cài vào host | `WXRender\RenderSystem.cpp`, `TlbbViewer\ViewerApp.cpp` | — |

Chi tiết cách dựng:

1. **Hàng đợi.** `LiquidRenderable` nhận thêm `mCysTechnique` và ghi đè `getTechnique()` vì `RenderQueue::addRenderable`
   của OGRE 1.2 không nhận technique; `_updateRenderQueue` đặt technique rồi thêm hai lần (76, 77, priority 100).
2. **`scene_buffer`.** `CysWaterRender::renderQueueStarted(77)` của pass cảnh chính chép render target đang vẽ vào
   texture A8R8G8B8 cùng kích thước viewport tên đúng như CY tham chiếu (`CYS/Compositor/SceneRender/scene_buffer`),
   nên `content_type compositor SceneRender scene_buffer` của material tự tìm thấy. Mỗi pass quad của hậu kỳ cũng phát
   `renderQueueStarted` với camera chính nhưng **không duyệt cảnh**, nên chỉ pass có nước vào hàng đợi mới được chép
   (cờ `surfaceQueued`), một lần mỗi khung.
3. **Nút độ sâu.** Bộ lọc hậu kỳ `Water` (không có pass riêng) khai `needsDepth()` và `isActive()` = "cảnh đang có
   nước mới", nên pipeline dựng nút `depth_buffer` R32F đúng lúc cần và bỏ khi đổi sang cảnh không có nước.
4. **Gương.** RT 1024² tự cập nhật với listener: camera `ReflectRTCamera` sao chép camera chính, `enableReflection` +
   `enableCustomNearClipPlane` ở mặt phẳng `y = h` của nước gương gần nhất, ẩn mọi liquid trong lúc vẽ. Vì RT vẽ lại
   **toàn bộ cảnh**, nó chỉ cập nhật khi khung trước có mặt nước gương thật sự vào hàng đợi (xem 7).

Khác biệt có chủ ý (ghi rõ):
1. Không có INTZ trong nhánh chính → luôn dùng material không `_DSIntZ` với nút `depth_buffer` R32F (C cũng làm vậy khi
   không có INTZ).
2. Bản chép `scene_buffer` làm trong `renderQueueStarted(77)` bằng `StretchRect` thay cho nút FrameCopy của framework render
   node (không có trong OGRE 1.2). Kết quả tương đương: cảnh tới hết queue 76.
3. RT gương tự cập nhật (`setAutoUpdated(true)`) với listener riêng thay vì danh sách của trình quản lý C.
4. Công tắc: biến môi trường `CYS_WATER=0` (tắt nước mới, về `replaceMaterial`), `CYS_WATER_MIRROR=0`,
   `CYS_WATER_MIRROR_SIZE`. Chưa nối vào bảng thiết lập đồ hoạ của game.
5. **Gương chỉ cập nhật khi nhìn thấy** (không có trong C, INF): `TerrainLiquid::_updateRenderQueue` chỉ đưa mặt nước
   vào hàng đợi khi nằm trong tầm nhìn, nên cờ đó quyết định `RenderTarget::setAutoUpdated` của RT gương ở khung sau.

## 6. Kết quả đo (14/09/2026, GeForce RTX 2060, 1600×900, dữ liệu `Assets\CanonicalCY\Data`)

Ảnh trước/sau cùng khung hình: `Build\Logs\2026-09-14-water-cy\shots\{before,after}\<cảnh>-<giờ>.png`, ảnh ghép đôi
`shots\compare\*.jpg`. "Trước" = cùng binary với `CYS_WATER=0` (rơi về `replaceMaterial` như trạng thái cũ).

| Cảnh | Nước | Trước (fallback) | Sau (nước CY) |
|---|---|---|---|
| `dali_new_320` (Đại Lý mới) | 10 `shader_water01` | ảnh động `haihuwaterlan` phẳng | mặt nước trong, sóng bump, ánh nắng, sương theo độ sâu |
| `suzhou_new` (Tô Châu, kênh + hồ sen) | 26 `shader_water01` | `haihuwaterlv`/`huwaterlv` | nước xanh lục trong, thấy đáy, sóng, mép bờ mềm |
| `xihu_JiaoLuo` (Tây Hồ) | 6 `shader_water01` + 1 `shader_water_mirror` | ảnh động phẳng | **phản chiếu gương** cầu, đèn đá, cây (RT 1024²) + khúc xạ |
| `taohuadao` (Đào Hoa Đảo, biển) | 8 `shader_water01` | ảnh động lát gạch, thấy rõ đường lặp | biển sâu: sương theo độ sâu, đáy cát khúc xạ gợn sóng, mép bờ mềm |

Chi phí (thời gian khung trung bình nửa sau, vsync tắt; `shots\perf\*`):

| Cảnh | `CYS_WATER=0` | Nước CY | Chênh | Nguồn chi phí |
|---|---|---|---|---|
| dali_new_320 | 14,4 / 24,8 ms | 24,7 / 29,6 ms | +5–10 ms | nút độ sâu vẽ lại cảnh (như `SceneDepthForWater` của C) |
| suzhou_new | 18,5 / 22,6 ms | 34,3 / 37,2 ms | +12–19 ms | nút độ sâu (cảnh rất nhiều đối tượng) |
| xihu_JiaoLuo | 8,9 / 15,1 ms | 18,0 / 28,3 ms | +9–13 ms | nút độ sâu + RT gương (một lần vẽ cảnh nữa) |

- Bản chép `scene_buffer` gần như miễn phí về CPU (0,2–0,7 ms cho 60–90 khung, tức < 0,01 ms/khung; công việc GPU là một
  `StretchRect`).
- RT gương là phần đắt nhất: đo riêng ở `xihu` 1280×720 là ~36 ms CPU mỗi lần cập nhật (OGRE 1.2 duyệt cảnh trên CPU).
  Khi không có nước gương trong tầm nhìn, RT không cập nhật (60 khung → 1 lần, 37 ms → 13 ms mỗi khung).
- Muốn rẻ hơn: `CYS_WATER_MIRROR_SIZE=512` hoặc `CYS_WATER_MIRROR=0`; tắt hẳn nước mới bằng `CYS_WATER=0`.
- Cảnh báo đo đạc: máy dùng chung với các agent khác (build, WSL, Game.exe của agent khác), nên số trong bảng là cửa sổ
  yên nhất đo được; các lượt chụp muộn hơn cùng binary cho 30–90 ms cả hai phía. Chỉ nên so tương đối trong cùng một lượt.

## 7. Kiểm chứng khác

- Trong game (phát lại offline, stage `Build\world-gui\stage-314aae4-water`, log `replay-run-1`): 10/11 phép kiểm PASS
  (`finished_in_time` FAIL vì 91 s > hạn 90 s của bộ chạy, không liên quan nước); không socket, không dump, quit flag 0.
  Cảnh 2 của bản phát lại là `dali.Scene` của **dữ liệu GL**, chỉ có nước cũ → `CYS water: scene without new water`
  (liquids = 0). Nước CY chỉ xem được trên `Assets\CanonicalCY\Data` cho tới khi Game.exe chạy dữ liệu CY.
- `Tests/scene/run_scene_test.cmd`: `RESULT: PASS` (failures 0, unknown keys 0), 2 253 TerrainLiquid của client_GL vẫn
  đọc đúng (`scene-test-2.log`).
- Build đầy đủ Release x64 của cây `Build\wt-water-cy`: rc 0 (`build-8.log`).
