# Bóng đổ theo CY 3.71.9609 — đặc tả và hiện trạng CY-Source

Ngày 14/09/2026, agent shadow-cy, nhánh `shadow-cy`. Chuẩn duy nhất là CY 3.71 (`Tools\DATA NEW\CY Game`); client_GL (B) chỉ để tham khảo khi CY thiếu. Ký hiệu: **FACT** = có bằng chứng (hàm/offset/chuỗi/file), **INF** = suy luận.

Bằng chứng: `Build\Logs\2026-09-14-shadow-cy\` — `cy-re\decomp\*.txt` (Ghidra trên bản sao Render.dll/Game.exe CY, `Build\re\shadow-cy\cy-re`), `cy-re\strings\*.txt`, `cy-re\cy-original-ui\`, các thư mục `diag-*`, `shots-*`, `cydata-*`, `viewer-*`, `replay-run-*`. Đặc tả cũ theo B: `03-shadows.md` (vẫn đúng về đường ống; các sửa ở mục 7).

## 1. Đường ống CY (FACT)

- Cùng đường ống với B: 58 chuỗi bóng giống hệt (`cy_render_shadow_strings.txt` ↔ `b_render_shadow_strings.txt`); `MaterialTemplates.zip` của CY có `CalcShadow.inc`, `Character.program` trùng byte với B.
- Bảng hàm B → CY:

| Chức năng | B | CY |
|---|---|---|
| ctor cấu hình (singleton `DAT_1803b5d00`) | `FUN_1800cbef0` | `FUN_1800d7a20` |
| cập nhật mỗi khung | `FUN_1800cdc70` | `FUN_1800d97e0` |
| fit CSM | `FUN_1800cd580` | `FUN_1800d90b0` |
| snap texel | `FUN_1800cc5a0` | `FUN_1800d80d0` |
| setShadowMapEnabled | `FUN_1800cd940` | `FUN_1800d9470` |
| setCascades / setShadowMapSize | `FUN_180014b40` / `FUN_180016f70` | `FUN_18002c3a0` / `FUN_18002eb80` |
| render node ShadowMap | `FUN_1802143b0` | `FUN_18021f220` |
| slot macro material | `FUN_180154160` | `FUN_180160130` |

- Hằng số ctor `FUN_1800d7a20`: mode +0x40 = 1 (CSM); cascade +0x4c = 4; split +0x50/+0x9c/+0xe8/+0x134 = **668 / 1945 / 4508 / 9625**; kích thước bản đồ +0x1c8 = **1024.0** mỗi tầng; back-off +0x38 = 8000; +0x3c = 1000; cường độ +0x44/+0x48 = 1.0/1.0; +0x180 = 0.1779; dải hoà trộn +0x184 = 0.005; +0x188 = 4 (số tầng cho actor).
- Mỗi khung (`FUN_1800d97e0`): hướng ánh sáng = hướng dẫn xuất của đèn chính cảnh; `setShadowCSMParams(4, 1/4, 0.005, 9625)` ⇒ khoảng bóng tối đa 9625 (mờ dần 0,95…1,0); fit: camera sáng tại tâm − dir·|halfSize|·1,2, near = −AABB.max.z − 8000, far = −AABB.min.z, snap nửa texel rồi làm tròn xuống lưới texel.
- Atlas: `FUN_180168d70` định kích thước mục tiêu nút 4 = số tầng × size × size ⇒ **4096 × 1024** mặc định (INF: ghi đè định nghĩa 4096² của nút).
- Bias: CY không gọi `setShadowConstBias/NormalBias`; mặc định AutoParamDataSource **const 5,0 / normal 20,0** đơn vị thế giới (OgreMain `0x180044258`). `isystem_userdata` = (constBias, linear, colorGreaterOne, normalBias).
- Lọc: `CalcShadow.inc` ManualPCF 3×3 mẫu điểm trên độ sâu tuyến tính, 4 phép PCF song tuyến; so sánh `step(depth + bias.x, sceneDepth)`.
- EnvKey `shadow_strength` (kẹp [0,1]) → +0x44, `pbr_shadow_strength` (≥ 0) → +0x48 (`FUN_1801e7f80` → `FUN_1800d95e0`/`FUN_1800d9610`).

## 2. Cấu hình người dùng (FACT)

- Khoá **`View_HumanLightmap`** (人物阴影). `CY Game\Bin\System.cfg` dòng 67: `View_HumanLightmap =2`. UI `ViewSetup.layout.xml` (Interface.axp): thanh trượt 3 nấc; Lua gốc CY bị mã hoá, bản GL ánh xạ nấc 4 = `rwyy`.
- Render.dll `FUN_18002ec20` chuyển sự kiện biến → vtable `CRenderSystem` 0x338 = `FUN_18002e100(atoi)`. Game.exe `FUN_1406be820` gửi lại khoá này **mỗi lần vào cảnh**.
- `FUN_18002e100`:
  - **0**: địa hình chế độ 0, `setCurRenderConfigLevel(1)`, model không đổ bóng, `setShadowMapEnabled(0)`.
  - **1**: như 0, địa hình chế độ 2. **Bản đồ bóng TẮT.**
  - **2**: `setCurRenderConfigLevel(0)`, ColorLUT bật, model đổ bóng (`FUN_1800ac630(1)`), **`setShadowMapEnabled(1)`**.
  - Không mức nào đổi mode/size/số tầng/split: luôn là hằng số ctor.
- Chỗ bật/tắt khác: vtable 0x260 `FUN_18002b5e0` bật bóng + far clip 65000 + `setShadowDis(18000, 1000)` sau khi nạp cảnh đăng nhập `erengu_DL.Scene`; vtable 0x228 `FUN_18002b710` tắt bóng (far 5000) ở màn chọn nhân vật `tl3chuangjian.Scene`.
- Lệnh console Game.exe (`FUN_140446700`): `setShadowDis`, `setShadowActorCascadeNum`, `setShadowMapSize`, `setShadowConstAndNormalBias`, `setCascadeParam`. Bảng ghi đè theo cảnh `DAT_140fb35b0` (nguồn dữ liệu chưa rõ).

## 3. Ai nhận bóng, ai đổ bóng (FACT)

- **Model** (`FUN_18021b1e0`): mỗi pass được thêm cặp chương trình nhận bóng: VS = define gốc với **LIGHT_CALC_TYPE ép = 2 (thêm nếu thiếu, chỉ giữ nếu = 0)** + `SHADOWMAP_TYPE=1`; PS = như VS + `LUT_ENABLE=1`.
- **Địa hình** (`FUN_180166280`, gọi từ `Terrain::_getGridMaterial` `FUN_1800cfa30`): VS {SHADOWMAP_TYPE=1, LIGHT_CALC_TYPE=2}, PS {SHADOWMAP_TYPE=1, LUT_ENABLE=1, LIGHT_CALC_TYPE=2}.
- `ShaderCache` của CY trên máy này có đúng các PS đó (CTAB có `ShadowMapSampler`/`LUTSampler`/`ssao_buffer`; địa hình `$shadowTex`/`$lightmap`/`$lutTex`).
- Đổ bóng: `FUN_180085530` = `LogicModel::setShadowCastable` (bỏ qua nếu model có thuộc tính `ShadowCast`); toàn bộ model bật ở mức 2. Thực thể tĩnh theo thuộc tính "cast shadows" của `.Scene`. Không có contact shadow, không blob shadow trong Render.dll.

## 4. Nguyên nhân gốc "model không nhận bóng" trong CY-Source (FACT)

- `ShaderLib/CalcLight.inc:305` chỉ gọi `Calc_Shadow_Ps` khi `LIGHT_CALC_TYPE == LIGHT_CALC_PS (2)`. `Character_Skin_PS` (8.956 material CY dùng `Mtl_Character_Lit`) để mặc định 1 (chiếu sáng theo đỉnh, `ParamNamed.inc:41`). CY-Source chỉ thêm `SHADOWMAP_TYPE=1` nên fxc bỏ hết hằng bóng: chẩn đoán `diag-1-asis\receiver_diag.tsv` — 56 pass, **0 pass LIGHT_CALC_TYPE=2**, s5 có gắn nhưng PS không có `shadow_param`.
- Nghi phạm cũ (bẫy 12, mảng đèn 3 phần tử đè thanh ghi) **bị bác bỏ**: 0 phép ghi đè (parser đã kẹp số phần tử theo mảng fxc cấp phát; D3D9 HLSL không đặt tên phần tử không có thanh ghi).
- Địa hình cũng không nhận vì `FairyTerrain*.program` không có define bóng; CY chèn lúc chạy (mục 3).

## 5. Hiện trạng CY-Source (nhánh shadow-cy)

| Hạng mục | CY | CY-Source | Ghi chú |
|---|---|---|---|
| Khoá mức | `View_HumanLightmap` 0/1/2 | cùng khoá; 2 = bật, 0/1 = tắt | `CYSShadowHost::configForLevel`; `CYS_SHADOW_LEVEL` ghi đè để thử |
| Mode, tầng, size, split | CSM, 4, 1024, 668/1945/4508/9625 | cùng | |
| Bias | 5 / 20 | 5 / 20 | |
| Fit | AABB từng khung + snap | hình cầu bao + snap (ổn định) | **Lệch có chủ ý**: nháy ít hơn 18× (`handoff/shadow.md`); `Gfx_ShadowFit=tight` để giống hệt |
| PCF, công thức nhận | `CalcShadow.inc` | cùng file của CY | |
| Nâng LIGHT_CALC_TYPE model | ép 2 trừ 0 | cùng luật (`CysMaterialSystem::promotesToPixelLighting`) | |
| Địa hình nhận bóng | LIGHT_CALC 2 + SHADOWMAP 1 | cùng (`isTerrainShadowPass`) | |
| `LUT_ENABLE=1` trên PS nhận bóng | có | **chưa** | Chưa có nguồn LUT (`CYS/Global/LUT` chỉ là ô trắng) — việc của mảng hậu kỳ/material |
| Model đổ bóng ở mức 2 | có | có (`setShadowCastable(true)`) | |
| Bật ở cảnh đăng nhập (dist 18000), tắt ở chọn nhân vật | có | **chưa** | Hiện theo mức ở mọi cảnh |
| Lệnh console, bảng ghi đè theo cảnh | có | **chưa** | |
| Đổi mức lúc chạy | áp lại mỗi lần vào cảnh | 2→0 tắt ngay; 0→2 cần khởi động lại (chất lượng nhận bóng đã biên dịch) | |

Tích hợp: `WXRender\RenderSystem.cpp` (thẻ `CYS-SHADOW`) — đọc cấu hình trước khi parse tài nguyên, `setGlobalDefine("SHADOWMAP_TYPE")`, `CYSShadowHost::start` sau `setup`, `applyVariable` trong `VARIABLE_CHANGED`, `stop` trước `uninstall`. `TlbbViewer --shadow <0|1|2|off|high|Gfx_Shadow*=v>`. Stage chép `Media\CysShadow`. Log `CYS shadow: stats` mỗi 5 s.

Sửa phụ bắt buộc: `WXLogicModel::_setEntityColour` ghi màu vào material nguồn (`SubEntity::getSourceMaterial`) — khi có define toàn cục, material hiển thị là biến thể được đồng bộ từ nguồn nên màu tóc đổi màu bị ghi đè thành trắng (`replay-run-1/2/4` tóc trắng, `replay-run-5` đen lại).

## 6. Số đo

- Độ sáng vùng model dưới tấm che (bật/tắt bóng), `receiver_luma_*.tsv`:
  - dữ liệu GL (`diag-1-asis` → `diag-2-cy`): M07 0,986 → 0,719; M08 0,990 → 0,721; M09 0,765 → 0,638; M19 0,991 → 0,711; M38 0,990 → 0,713; cây M40 0,996 → 0,404; đất 0,44.
  - dữ liệu CY (`cydata-asis` → `cydata-cy`): C1 0,997 → 0,579; C2 0,977 → 0,717; C3 0,998 → 0,720; C5 0,999 → 0,588; C6 0,994 → 0,726; C4 1,000 → 1,000 (pet template LIGHT_CALC_TYPE=0, không nhận — đúng luật CY).
- Hiệu năng Đại Lý, replay 1024×768, nhịp 60 khung (`perf_dali.tsv`, `CYS_PERF=1`): tắt — GPU frame 1,15 ms (rtt 0,81–0,84), CPU render 3,1–3,3 ms; CY mức 2 — GPU frame 1,59 ms (rtt 1,15), CPU render 4,95 ms, cập nhật atlas CPU 1,8 ms (caster 0/5/5/5). Cấu hình B cũ 4 tầng 4096: +3,4 ms GPU. Bàn thử 1920×1080 (`shots-cy-level2\timing.tsv`): pass bóng GPU 0,83 ms (tổng quan) / 1,09 ms (góc game), CPU 2,3–2,5 ms.

## 7. Sửa cho `03-shadows.md`

- +0x38 cũng là khoảng ortho/back-off của SIMPLE, đặt bởi `setShadowDis`; +0x3c là độ lệch về phía trước của SIMPLE; +0x180 = clamp(dist / (far − near) · 1,2, 0, 1); +0x188 = số tầng cho actor.
- Kích thước mặc định là 1024/tầng (không phải 4096), split cố định 668/1945/4508/9625.
- B gọi `setShadowMapEnabled(0)` ở mức 2; CY gọi 1.

## 7b. Tiếp theo: `shadow-finish_vi.md` (17/09/2026)

Đợt `shadow-finish` đã khép phần còn lại và bổ sung FACT: nút `defRenderNode_ShadowMap` (`FUN_18021f220`) tạo
`shadow_buffer` **4096 × 4096**, scheme "Depth", dải hàng đợi 40–50 + 68–70; `FUN_1800d90b0` dựng camera bóng bằng
`Ogre::Camera::setDirection` nên **trục cơ sở ánh sáng neo theo +Y** (dự án trước đó neo theo +Z ⇒ hộp ortho to hơn
CY 3,0 %/1,7 %; đã sửa trong `CYSShadowFitting::lightBasis`). Cũng ở đó: bác bỏ giả thiết "CY có luật chọn caster".

## 8. Chưa xác minh

Nguồn dữ liệu của bảng ghi đè theo cảnh; điều kiện OgreMain chuyển sang chương trình nhận bóng (INF: cờ GfxLayer +0x12); giá trị mặc định cờ đổ bóng của LogicModel; màu địa hình khi bật bóng lệch ấm → xám (chiếu sáng điểm ảnh + thiếu LUT) — cần ảnh CY thật để so.
