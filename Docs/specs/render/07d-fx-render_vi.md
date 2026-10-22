# 07d — Hậu kỳ trong game và đường material của hạt/hiệu ứng (fx-render, 13/09/2026)


## 0. Kết quả chính

| Việc | Kết quả |
|---|---|
| Đưa hậu kỳ vào WXCore | 5 file `.cxx` → `.cpp`, stub bị thay; kiểm biên dịch bằng đúng cờ WXCore trước khi đổi tên (5/5) và sau mọi lần sửa (6/6, 1/1). SSIM 17 ca: **16/16 ca của run2 lệch ≤ 0,0009** (DoD ±0,01) — `ssim-dod.txt`. |
| Tích hợp game | Render.dll áp khoá System.cfg lúc khởi động và mỗi lần `VARIABLE_CHANGED`; thiếu khoá thì lấy mặc định = cái người dùng thấy trong client_GL. |
| Viewer | `--postfx b | key=value | file` (lặp được), áp ngay sau khi có thiết bị nên dùng được cho cả `--fx-sheet`. |
| Material hạt (1) | Biến thể material là **ảnh chụp** của material nguồn → màu mesh-particle, dissolve, sequence-frame, fade không tới GPU. Đã sửa (theo dõi thay đổi của nguồn, mục 4). |
| fx-audit D2/D4/D20 | D2: 35 (b3) → 7 (b8) → **3**; D4: 8/8 mục `saturated_black_max` ≤ 0,014 (b3 0,03–0,23); D20: bục chọn đúng màu xanh/cam/lam (chroma 0,18–0,21, như P027/P028) — mục 9. |
| Hậu kỳ giống hệt B | Tường trắng cháy ở S01 = NewHDRBloom cũ (FP16, ACES, Intensity 3,0 làm trọng số thẳng). Nay bộ mặc định **giống hệt B** (`PostFX.Preset=b`): đích 8 bit A8R8G8B8, material NewHDRBloom của chính B, trọng số bloom = 2^(I/10)−1 = **0,231**. Đường FP16/ACES giữ làm preset `cinematic`, tắt mặc định — mục 10. |
| Hiệu năng | Bộ mặc định (FXAA + NewHDRBloom, B-exact) **+0,30 ms GPU** ở 1080p RTX 2060 (các pass 0,36); có sương độ cao +0,45 ms; preset cinematic ~+0,02 ms. Hook material S01: 197 → **73 ns/lần**. Dưới ngân sách 3 ms. |
| OgreSmoke | Binary cuối: `census: no material/shader/texture warnings`; Ogre.log error 1 / exception 1 như CI 91148e1 (`ogresmoke-final\`). |
| DoD SSIM | Các ca hậu kỳ **không** dùng bloom (fxaa, ssao, dlaa, godrays, dof, colorlut, heightfog…) giữ nguyên; các ca có NewHDRBloom **cố ý đổi** vì mặc định nay là B-exact (`bloom_gl` SSIM vs none 0,972 → 0,993). Ca `bloom_gl_cinematic`/`preset_cinematic` tái tạo bản cũ để theo dõi. |

## 1. Đưa hậu kỳ vào WXCore

- `CysPostFxMain.cxx` → `CysPostFx.cpp` (thay stub no-op), `CysPostFxStage/Pipeline/Depth/Filters.cxx` → `.cpp`. Đổi tên bằng thao tác
  file (không `git mv`), hai pha để bản build đang chạy của agent khác không bị đứt giữa chừng. `postfx_test.cmake` bỏ glob `.cxx`.
- WXCore glob `CYS\**\*.cpp`, nên trước khi đổi tên đã biên dịch 5 file với **đúng dòng lệnh WXCore** (lấy từ `ninja -t commands`) vào
  thư mục tạm: `compile_check.cmd`, `compile-check-1.log` (5/5), `-2.log` (6/6 sau khi sửa), `-3.log`.
- Chạy đối chứng trước khi đổi tên (RelWithDebInfo, `postfx-before`) và sau (`postfx-after`): SSIM so với `2026-09-12-postfx\run2`
  lệch lớn nhất 0,0009 (bảng đầy đủ `ssim-dod.txt`).

## 2. Tích hợp game (Render.dll)


`RenderSystem.cpp` (hunk gắn `// CYS:`):
1. Sau `registerAllPostFilterFactories` + Floodlighting/Fade: `CysPostFx::applyStartup(manager, viewport, _CysPostFxLookup, 0)`.
2. `_OnVariableChangedEvent`: `CysPostFx::applyVariable(...)` cho mọi biến (khoá lạ trả false, không tốn gì).
3. `Scene_Load`: `CysPostFx::onSceneLoaded(manager, viewport, nID)` — id < 0 giữ NewHDRBloom tắt như B, scene thế giới trả lại.
4. Khi `Gfx_PostFX` bật (mặc định): `FSAA = 0`. Scene đã vẽ vào đích FP16 riêng và `View_Fanhunjiao` là FXAA; MSAA của back buffer chỉ
   còn phủ bản sao cuối + UI. UI (hàng đợi OVERLAY) vẽ sau compositor nên không bị hậu kỳ.

Khoá và mặc định (`CysPostFx.cpp` `kStartupKeys`, áp theo thứ tự này; giá trị của System.cfg thắng mặc định):

| Khoá | Mặc định | Lý do |
|---|---|---|
| `Gfx_PostFX` | 1 | công tắc tổng (0 = tắt mọi bộ lọc CY) |
| `View_Fanhunjiao` | 1 → FXAA | B |
| `View_HDRFilter` | 1 → NewHDRBloom, lấy `.newhdrbloom` của scene | B |
| `Gfx_HeightFog` | 1 = như B: chỉ dựng khi môi trường scene có sương độ cao; 2/force = luôn | B (EnvKey) |
| `Gfx_SSAO`, `Gfx_GodRays`, `Gfx_DoF`, `Gfx_ColorLUT` | 0 | B không bật |
| `View_FullScreenLight`, `Gfx_AA`, `Gfx_HDRBloom`, `PostFX.Media` | chỉ khi System.cfg có | — |
| `PostFX.Config` | (tuỳ chọn) tệp `key=value`, gồm `PostFX.<Filter>.<Param>` | tinh chỉnh |

Stage đang chơi (`stage-91148e1`) không có khoá nào ở trên → dùng mặc định. Hàm mới: `applyStartup`, `getDefaultValue`,
`onSceneLoaded`, `setPassObserver` (GPU profiler). Tìm media thêm `<exe>\Media\CysPostFX` (cạnh `Media\Scorpio` của stage).

HeightFog "auto": `CysPostFxStage::isActive()` mới; pipeline so tập stage "muốn chạy" mỗi khung và chỉ dựng lại khi tập đổi. Kiểm:
S01 Tô Châu (không `.hfog`) dựng FXAA + NewHDRBloom, **không** có depth node; S08 cy4_guigu dựng thêm HeightFog + depth node; S10
cy4_tangmen 12:00 EnvKey tắt sương nên như S01 (`scenes\S0x_on.png.log`).


## 3. Viewer

`--postfx b` = bộ khởi động của game; `--postfx View_HDRFilter=0`, `--postfx PostFX.NewHDRBloom.Intensity=2`, hoặc `--postfx <tệp>`.
Áp cuối `initEngine` (sau khi có thiết bị) nên cả `--shot`, chế độ tương tác và `--fx-sheet`/`--fx-census` của fx-audit đều đi qua;
`--postfx` tắt MSAA của back buffer trừ khi có `--fsaa`. `postfx-bgl.cfg` = độ bloom điển hình của client_GL cho ảnh không có scene.

## 4. Đường material của hạt: đối chiếu B và sửa

Nguồn B: `MaterialTemplates.zip` (`Mtl_Particle.material`, `Particle.program`, `Particle_vs/ps.hlsl`, `Particle_2Tex_ps.hlsl`,
`ParticleDef.inc`, `ShaderLib\*.inc`; bản giải nén `Assets\Staging\materialtemplates\B`).

| Mục | B (FACT) | CY-Source |
|---|---|---|
| Màu/alpha đỉnh | `Particle_VS` `USE_VERTEXCOLOR=1`: màu = vColor + `surface_emissive_colour` (bão hoà trừ khi `isystem_userdata.z`), alpha = vColor.a (`CalcLight.inc:78-85`); PS alpha = tex.a·vColor.a·`surface_diffuse_colour.a` (`Particle_ps.hlsl:34-38`) | cùng shader B. **Lỗi**: mesh particle đặt màu bằng self-illumination mỗi khung (`OgreMeshParticleVisualData.cpp:156`) lên material nguồn, còn GPU vẽ biến thể → màu đứng yên. Đã sửa (mục dưới) |
| UV động | `TEX_EFFECT_0/1` → `texture_matrix_2x4_0/1` (`CalcUV.inc:4-19`) | tự gắn theo tên (`OgreGpuProgram.cpp:1551-1552`), hai hàng đầu của transform TUS (`:845`, `OgreAutoParamDataSource.cpp:890`) — đúng. `sequenceFrameUVFactor`, `useRibbon`… do affector ghi lên material nguồn → trước bị mất, nay theo |
| `scene_blend` | template: `add` (Mtl_Particle, ColorX2/X4, Dissolve), `alpha_blend` (Outline, Transperant_VertexAlpha), TwoTex mặc định; con trong all.material tự đặt | parser đủ, gồm `separate_scene_blend`; thay đổi lúc chạy nay theo sang biến thể |
| `depth_write`/`depth_check` | `depth_write off` ở mọi template trừ TwoTex; `depth_check` mặc định | đúng |
| Alpha rejection | `Tex_Kill` chỉ khi `ALPHATEST_ENABLE` (không đặt cho hạt); `alpha_rejection` cố định của D3D9 vẫn áp sau PS | đúng |
| Soft particle | shader hạt của B **không** đọc depth; chỉ nước/FakePointLight/HeightFog/DoF dùng `content_type compositor SceneRender depth_buffer` (`Mtl_Character.material:2280-2471`) | không thêm (khác B); depth node vẫn phục vụ các material đó khi bật |
| Hệ số HDR | `BLEND_OP_0` = ×2/×4 (`Diffuse.inc:40-45`); đầu ra kẹp [0, 1] (`Particle_ps.hlsl:42`, `Particle_2Tex_ps.hlsl` saturate); `scene_buffer` 8-bit | giống; bloom LDR kẹp scene như B (ClampScene) |
| Sương | `fog_override true none` ở mọi template; SM3 không có sương cố định | giống |
| Thứ tự vẽ | OGRE sắp trong suốt từ xa tới gần; `render_queue on 69/70/73/77/41` theo pass | `OgreRenderQueue.cpp:118-133` — đúng |

**Lỗi gốc và cách sửa (`CysMaterialSystem.*`).** Template của B chỉ có pixel shader, nên hệ material ghép vertex shader vào **bản sao**
`<tên>@CYS<trạng thái>` (sub-entity) hoặc qua `resolveTechnique` (billboard). Game lại ghi vào material nó đang giữ:
- mesh particle: `setSelfIllumination(màu hạt)` mỗi khung — 10.681/43.296 template hạt (25 %) dùng `renderer mesh`;
- `WXDissolveAffector` ghi `dissolveClip/ColorA/B/...` vào material của billboard set/mesh — mặc định `dissolveClip = 1,0` của
  `Particle_Dissolve_PS` loại gần hết pixel → 359 material `Mtl_Particle_Dissolve` (+ TwoTex_Dissolve) gần như vô hình;
- sequence frame / ribbon (`sequenceFrameUVFactor`, `useRibbon`...), fade độ trong suốt của model.


Kiểm trên dữ liệu thật: 16 hiệu ứng sáng của `oracle.tsv` (`fx-glow16.tsv`), cùng binary, cùng seed: 11/16 đổi ảnh; độ phủ trước → sau
E019 0,0000 → 0,0036, E021 0,0008 → 0,0130, E033 0,0005 → 0,0092, E050 0,0038 → 0,0245, E065 0,0008 → 0,0077, E100 0,0000 → 0,0024
(`sheet-diff.tsv`, ảnh `sheets\fix_post_compare.png`). S08 thật: 1.505 thay đổi được theo trong 420 khung.

### 4b. Vertex shader cho shader hạt trên mesh (lỗi thứ hai, sửa 13/09 tối)


Ta ghép `Particle_VS` (`USE_VERTEXCOLOR=1`) cho cả mesh. Mesh hiệu ứng không có COLOR0, D3D9 trả vColor.a = 0 → alpha 0: mọi hạt mesh
`scene_blend src_alpha …` **vô hình** (Canonical: 5.157 template hạt mesh `src_alpha`, cộng 3.690 `one`, 1.091 `zero`; ví dụ D2 còn
lại E023, E045, E056, E061). Sửa (`pickVertexProgram`): shader hạt trên mesh → `Model_VS`/`Model_Skin_VS` + `TEX_EFFECT_0/1=1`
(UV động như Particle_VS), `USE_VERTEXCOLOR` chỉ khi mesh có màu đỉnh, `LIGHT_CALC_TYPE=0` khi pass tắt lighting (23/35.451 pass);
billboard/ribbon giữ `Particle_VS`. Mesh có xương nay được skin bằng phần cứng như B (trước rơi về skin phần mềm). PS không cần biên
dịch lại với `USE_MODEL_VS_OUT`: D3D9 SM3 nối đầu ra VS với đầu vào PS theo semantic (TEXCOORD0, COLOR0). A/B: `CYS_MATSYS_MESH_VS=particle`.

## 5. Hiệu năng (1920×1080, RTX 2060, máy dùng chung)


| Pass | GPU ms (`postfx-final2`) |
|---|---|
| Bản sao cuối FP16 → back buffer (+ dither) | 0,04–0,07 |
| FXAA | 0,12–0,14 (ca `fxaa` đứng đầu đo 0,55: GPU chưa lên xung, ca `preset` đo lại 0,123) |
| FXAAQuality / DLAA | 0,24 / 0,46 |
| NewHDRBloom LDR (giá trị client_GL) | 0,23–0,24 |
| NewHDRBloom HDR + tự phơi sáng / + bloom | 0,22 / 0,33 |
| HeightFog / depth node | 0,07–0,09 / 0,09–0,13 |
| GenSSAO (nửa độ phân giải) | 0,29–0,36 (0,50 trong bộ `all`) |
| GodRays / DoF / ColorLUT | 0,29–0,37 / 0,51 / 0,27 |
| **Bộ mặc định** (FXAA + NewHDRBloom, B-exact 8 bit) | **+0,30 ms GPU so với không lọc** (`postfx-bexact`: FXAA 0,11 + NewHDRBloom 0,21 + bản sao 0,04) |
| Bộ mặc định + sương độ cao | +0,45 ms GPU (thêm HeightFog 0,07 + depth node 0,10) |
| Preset cinematic (FP16 + ACES) | +0,32 ms (NewHDRBloom 0,23, bản sao có dither 0,05) — nhỉnh hơn ~0,02 ms |

Số cũ (đích FP16 cho mọi bộ lọc, `postfx-final2`): bộ mặc định +0,46 ms. Ngân sách 3 ms: bộ mặc định dùng ~10 %; kể cả bộ nặng nhất
(`all`: SSAO + FXAA + HDR bloom + HeightFog + GodRays) +1,52 ms.


Hậu kỳ thêm vài chục draw quad; depth node vẽ lại toàn bộ vật đục (tốn CPU theo số draw call) nên chỉ dựng khi có
HeightFog/SSAO/DoF/GodRays — lý do HeightFog "auto".

## 6. Ảnh

- Scene off/on: `scenes\S01_off_on.png`, `S08_off_on.png`, `S10_off_on.png` (SSIM off↔on 0,964 / 0,967 / 0,971).
- Hiệu ứng: `sheets\off|on|off-nofollow\<id>\*.png`, so sánh `sheets\fix_post_compare.png`.
- 17+2 ca hậu kỳ: `postfx-after\contact.png`, `postfx-after2\contact.png`, binary cuối `postfx-final2\contact.png`.
- Harness fx-audit (`Tools\fx\fx_sheet.py`) với viewer của tôi, `audit-sheets\`: `canonical-oracle-{follow,nofollow,modelvs,particlevs}`,
  `stage-frontend-{follow,nofollow,modelvs,particlevs}` (mỗi thư mục có `sheets\<id>.png`, `overview-*.png`, `sheet-index.tsv`);
  ví dụ `canonical-oracle-modelvs\sheets\E056.png` (lưỡi đao lửa, trước không vẽ gì), `stage-frontend-modelvs\sheets\S002.png`.
- S01 binary cuối (`--postfx b`): `scenes\S01_on_final.png` (+ `.log`).

## 7. Còn thiếu / việc cho phạm vi khác

- `Tools\build\stage.ps1` (CI): chép `Src\Engine\WXCore\CYS\PostFX\media` → `Bin64\Media\CysPostFX`; hiện Game tìm thấy nhờ đường dẫn
  nguồn lúc build (chỉ đúng trên máy này).
- Ảnh baseline màn đăng nhập/chọn nhân vật của CI/game-layer sẽ đổi (FXAA trên cảnh 3D; bloom giữ tắt như B; UI không đổi). Kiểm
  pixel-identity thì đặt `Gfx_PostFX=0` trong profile test.
- fx-particles: `OgreScaleInterpolatorAffector.h` (typedef dùng member khai báo sau) đang làm hỏng build ParticleFX2 lúc 17:51–18:17;
  các exe của tôi được link lại bằng lệnh ninja phát lại (`manual_build.cmd`), DLL plugin lấy từ bản build tốt 17:29.
- Chưa có: hiệu ứng lướt (grading EnvKey), FakeLight thật, `.pu` của GL, MSAA + resolve cho đích scene, INTZ.
- **Crash mới (không thuộc phạm vi của tôi):** sau khi link lại lúc 19:12 (mã đang dở của nhánh khác trong cây chung), viewer
  crash ở mục oracle E070 `wq_2025冰元素镰刀_展示`, `0xC0000005` tại `TlbbViewer.exe+0x70599` = `WX::Effect::removeParentSceneNode`
  (`WXEffect.cpp:284`), ở **cả hai** cách ghép VS; minidump `audit-sheets\canonical-oracle-{modelvs,particlevs}\sheet.dmp`. Lượt
  18:53 (binary trước) không crash. Chủ: fx-effects.
- E061 `buff_2025灯柱` nay phủ 90 % khung ở mọi A/B của tôi (b8: 0 %) — thay đổi transform/scale hạt mesh của nhánh khác (fx-particles).
- D2 còn 3: E017 (UIParticle vẽ trong 3D, hộp bao 0 — cần đường UI), E024 (texcoord_billboard + SequenceFrame), E097 (hạt mesh +
  billboard `one one`); cả ba không đổi khi bật/tắt follow hay đổi VS → không thuộc đường material.
- D13 (200 material hạt `one zero`): dữ liệu như B viết, B không thêm alpha rejection (không có bằng chứng) → giữ nguyên.

## 8. CY 3.71 (C) làm tham chiếu song song với B (yêu cầu 13/09)

Nguồn chỉ đọc: `Tools\DATA NEW\CY Game\Bin64\Render.dll` (4.057.088 B, SHA-256 `e6e67de4…`), `CY Game\Data\MaterialTemplates.zip`,
S2 `DataCY31-08-26\MaterialTemplates` (thư mục). Kết quả: `mtltemplates-B-vs-C.txt/.diff`, `render-strings-B-vs-C*.txt`.

| Mục | B | C | Quyết định |
|---|---|---|---|
| MaterialTemplates | 112 file | 112 file, **C = S2 từng byte**; khác B đúng 6 file: 2 ảnh loginSplash, `Model_ps.hlsl`, `Model_Flow_ps.hlsl`, `ShaderLib\ParamNamed.inc`, `ShaderLib\TexKill.inc` | mọi template/program hạt giống hệt → không có template hạt mới, không soft particle |
| Dissolve model hướng (`DISSOLVE_EFFECT 5`) | nhiễu theo UV + `time_0_x` | nhiễu theo toạ độ object trong hộp `dissolveBox` (mặc định `0,1,0,1`), hai tầng nhiễu, công thức cắt/viền mới | thêm `dissolveBox` vào bảng hằng per-instance (C mới hơn); việc sinh biến thể `DISSOLVE_EFFECT 5` cho model chưa có ở engine (fx-effects/materials) |
| Post-filter | 27 factory + HDR + SceneRender | cùng danh sách file nguồn (chỉ khác tiền tố `D:\Fairy_New` / `E:\Fairy_TLBB_Truck`) | không có bộ lọc mới |
| `.newhdrbloom` | client_GL: 527/548 = `3 / 0,65 / 0,35 / 0`, LDR (`hdr_tune.py`) | S2: 73 file gốc Changyou, 37 = mặc định reader (Intensity 0, UseHDR 1, tự phơi sáng), còn lại chỉnh tay (vd. `2 / 0,65 / 0,05 / −0,3`) | Canonical giữ bộ của B (người dùng đang thấy); scene S2 dùng file S2 của chính nó |


## 9. Các mục fx-audit thuộc R (fx-render) và các "hồi quy" orchestrator nêu

Cách đo: harness của fx-audit (`Tools\fx\fx_sheet.py`, 512², seed 1234, t = 0,15/0,4/0,8/1,5/3 s, nền đen + xám, orbit 30,30) chạy
viewer của tôi; **A/B cùng một binary** bằng biến môi trường: `CYS_MATSYS_FOLLOW=0` (tắt theo nguồn), `CYS_MATSYS_MESH_VS=particle`
(ghép VS cũ). Mốc: `canonical-oracle` (b3) và `canonical-oracle-b8` (18:42) của fx-audit. Phân loại theo `fx_report.py`.

| Mục | Kết quả (binary cuối, `modelvs`) | Bằng chứng |
|---|---|---|
| D2 hạt sống không vẽ gì (oracle 100) | b3 35 → b8 7 → **3** (E017, E024, E097). VS mới sửa E023, E045, E056; 10 mục đổi, đều theo hướng hiện ra/sáng hơn (E026, E031, E057, E062 độ phủ ×2–3; E049, E053 hiện ra) | `fx_report --diff particlevs modelvs` |
| D4 vũ khí môn phái cháy trắng (tạo nhân vật) | S002/S017/S027/S012/S008/S023/E002/E008: `saturated_black_max` 0,005–0,014 (b3 0,031–0,226); mục bão hoà 15 → 2 (P020, P022 là hạt FF). Độ phủ còn 13–64 % của b3 — b3 chính là vệt trắng che khung; A/B follow và VS cho **0 mục đổi** trên dữ liệu stage | `stage-frontend-*` |
| D20 bục chọn mất màu | P009 xanh lá (0,16/0,28/0,08), P011 cam, P013 lam; chroma 0,18–0,21 = P027/P028 (b3: xám, chroma 0,00); không phụ thuộc follow/VS (ColourFading mặc định client_GL của fx-particles) | đo màu trung bình pixel sáng |
| D14 lửa Minh Giáo mép vuông | `S002.png` nay là 3 ngọn lửa tròn cam, không còn khối vuông trắng | `stage-frontend-modelvs\sheets\S002.png` |
| D15 số material tăng | Có trần: E042 +84 (3 s) → +102 (20 s) = +102 (60 s); E018/E026/E047/E085 không đổi từ 3 s; E065 trả lại (−103) khi hiệu ứng kết thúc; 656 biến thể được dọn trên oracle | `audit-sheets\d15-t{3,20,60}\metrics.tsv` |
| D13 hạt `one zero` | giữ như dữ liệu/B | mục 7 |

## 10. Chuỗi mặc định giống hệt B ("B-exact", 13/09 tối)


| Mục | B (FACT) | CY-Source trước | Nay (preset `b`) |
|---|---|---|---|
| Ngưỡng | `Threshold` qua `Math::GammaToLinearSpaceExact` (OgreMain B, hằng 0,04045 / 12,92 / 0,055 / 1,055 / 2,4): 0,65 → **0,380**; knee = t·SoftKnee + 1e-5; hằng `threshold` = (t, t − knee, 2·knee, 0,25/knee) | 0,65 (không tuyến tính hoá) | như B |
| Màu bloom | `Math::GammaToLinearSpace(Vector3)` (đa thức 0,305306 / 0,682171 / 0,012523) | không đổi | như B (mọi file = trắng) |
| Exposure | `exp(Exposure · ln2)` = 2^Exposure | 2^Exposure | như B |
| Pass | ConvertToLinearSpace → GrayDownScaleLum (0x3e3) → Downscale3x3 ×4 (0x3e2…0x3df, **luôn dựng**) → DownsampleBrightpass (0x323) → Downsample ×3 (0x322, 0x321, 800) → Upsample ×3 (702, 701, 700) → FinalPass / _HDR / _HDR_AutoExposure (500/600) | shader của ta | **material của chính B** trong dữ liệu game |


"Hồi quy" orchestrator nêu (so với b3), kiểm bằng A/B cùng binary — **không mục nào do thay đổi material/hậu kỳ của tôi**:

| Mục | b3 → nay | follow on/off | VS mới/cũ | Kết luận |
|---|---|---|---|---|
| E016 bão hoà | không vẽ gì → cov 0,194 sat 0,066 | như nhau | như nhau | UIParticle 301 hạt `src_alpha one` nay được vẽ (fx-particles/fx-effects) |
| E090 bão hoà | sat 0,003 → 0,020–0,022 | như nhau | 0,020 ↔ 0,022 (quanh ngưỡng) | billboard **FF** (không có shader, hệ material không chạm) → ColourFading |
| E097 mất hẳn | cov 0,032 → 0 | như nhau | như nhau | không thuộc đường material (hạt/transform) |
| E048 gần mất | cov 0,261 → 0,006–0,009 | như nhau | như nhau | như trên |
| Vòng sét Thiếu Lâm, lửa Minh Giáo | cov −50…−90 % | 0 mục đổi | 0 mục đổi | ColourFading mặc định client_GL (đen ở đầu/cuối, `opacity` nhân cả RGB) và bounds của fx-particles |
