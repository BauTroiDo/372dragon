# Nhìn như CY 3.71.9609 — công trình tĩnh và LUT nhận bóng

Ngày 14/09/2026, agent cy-look, nhánh `cy-look`. Chuẩn duy nhất là CY 3.71 (`Tools\DATA NEW\CY Game`, chỉ đọc); client_GL (B) chỉ tham khảo.
Ký hiệu: **FACT** = có bằng chứng (hàm/offset/chuỗi/file/ảnh), **INF** = suy luận.
Bằng chứng: `Build\Logs\2026-09-14-cy-look\` (`re\` = Ghidra trên bản sao CY OgreMain.dll ở `Build\re\cy-look`, `viewer\` = ảnh TlbbViewer, `metrics\` = số đo màu).
Đặc tả bóng đổ: `shadow-cy_vi.md` (mục 1–8). File này bổ sung mục LUT và luật theo cảnh còn thiếu ở đó.

## 1. Công trình tĩnh của CY hiện trắng — nguyên nhân gốc (FACT)

Không phải lỗi bóng đổ, cũng không phải lỗi material CY.

- Nhánh `shadow-cy` tách từ main **trước** khi hợp nhất `cy-switch`, nên nhị phân của nó thiếu commit `c8ff9a3`
  (`OgreMaterialSerializer.cpp`: material trùng tên thì bỏ bản sau, không bỏ phần còn lại của file).
- `all.material` của CY khai báo 184 material trùng tên (handoff `cy-switch`). Với OGRE chưa vá, lần trùng đầu tiên
  (`W_hair_2026孔慈筷子头`) ném `ResourceManager::add` **Error #6** và parser bỏ **toàn bộ phần còn lại của file**.
- Số đếm trong log chứng minh: bản `shadow-cy` `TlbbViewer: ... 1 aborted by an exception; 62384 materials`
  (`Build\Logs\2026-09-14-shadow-cy\viewer-cydata-dali\dali_scene_off.png.log`), bản có `c8ff9a3`
  `0 aborted by an exception; 85874 materials` (`Build\Logs\2026-09-14-cy-switch\viewer\scene-dali-new-3.png.log`).
  **23.490 material bị mất** — gần hết phần công trình/cảnh vật đọc sau chỗ trùng; entity không tìm thấy material sẽ
  vẽ bằng `BaseWhite` ⇒ tường, lan can, cây, tượng trắng toát, còn địa hình (material riêng trong `SceneFolder`) vẫn đúng.
- Cách sửa: dựng lại trên main (đã có `c8ff9a3`). Không cần đổi dữ liệu CY, không cần đổi material/technique/define.
  Ảnh đối chứng: `viewer\dali_*`(cy-look) so với `Build\Logs\2026-09-14-shadow-cy\viewer-cydata-dali\dali_scene_off.png`.

**BẪY (chung cho mọi agent):** mọi nhị phân chạy trên `Assets\CanonicalCY` phải có `c8ff9a3`. Dấu hiệu nhận ra trong
một dòng log: `scripts ... 1 aborted by an exception` và số material < 80.000.

## 2. LUT của shader nhận bóng — CY làm thế nào (FACT)

- Macro `LUT_ENABLE` là **slot 0x12** của bảng macro material (CY Render.dll `FUN_180160130`; xref
  `Build\Logs\2026-09-14-shadow-cy\cy-re\decomp\01`). Cặp chương trình nhận bóng đặt:
  - model (`FUN_18021b1e0`): VS = define gốc + `LIGHT_CALC_TYPE` ép 2 (giữ nếu 0) + `SHADOWMAP_TYPE=1`;
    **PS = như VS + `LUT_ENABLE=1`**;
  - địa hình (`FUN_180166280`): VS {SHADOWMAP_TYPE, LIGHT_CALC_TYPE=2}, PS {SHADOWMAP_TYPE, **LUT_ENABLE=1**, LIGHT_CALC_TYPE=2}.
- **Texture LUT = `luttex.png` trong `MaterialTemplates.zip`** (193 byte, PNG 16×16, sha256 `b0e1eebe02c21e1f…`,
  **giống hệt byte trong bản CY và bản GL**). CY OgreMain.dll dựng sẵn ba texture unit của engine trong
  `Ogre::SceneRenderProxy::initialize` @`180181ce0` (`re\cy_ogremain_luttex_xref.txt`):

  | Unit | Nguồn | Sampler | Lọc | Address |
  |---|---|---|---|---|
  | `shadow_buffer` | compositor `SceneRender` | s5 | mặc định | clamp |
  | **`luttex.png`** | tên texture | **s4** | **none (điểm)** | clamp |
  | `ssao_buffer` | compositor `SceneRender` | s12 | mặc định | clamp |

  `SceneRenderProxy::setPass` @`180182df0` chỉ gắn ba unit này khi pass dùng **chương trình nhận bóng**
  (`getShadowReceiverVertex/FragmentProgram`). Material địa hình của CY cũng ghi thẳng trong script:
  `texture luttex.png / tex_address_mode clamp / filtering none / sampler_index 4`
  (`Assets\CanonicalCY\Data\SceneFolder\FairyTerrainColorMapNormalSpec.material`).
- Công thức (`ShaderLib\Diffuse.inc`, `FairyTerrainColorMap.hlsl`): tra cứu **từng kênh** trên lưới 16×16 —
  `uv = (v*255 % 16 / 16, floor(v*255/16)/16)`, tức bảng 256 mức. `luttex.png` là đường cong S xám
  (0→0, 32→27, 64→67, 128→146, 192→201, 255→255): ép tương phản và nâng vùng trung gian.
- Phạm vi áp dụng: model chỉ đổi màu khi `imodel_userdata.x == 0` (`LUTCorrect`), tức **vật thể cảnh**; nhân vật/NPC
  (actor lighting = 1) giữ nguyên màu. Địa hình luôn áp (không có điều kiện).
- LUT này **khác** bộ lọc hậu kỳ `ColorLUT` (LUT 512² theo cảnh, `Scene_SetSceneLUTParam`/lệnh console `scenesetlut`,
  `LUT_00gao.png`, `LUT_bianjing1.png`, `LUT_congren.png`…). Mức `View_HumanLightmap = 2` của CY bật cả hai
  (`FUN_18002e100` gọi `FUN_18002db70(1, <tên LUT của cảnh>)`). Bảng tên LUT theo cảnh nằm trong Game.exe
  (`c60d20`…): **chưa làm** ở CY-Source (xem mục 5).

## 3. CY-Source làm gì (nhánh cy-look)

- `CysMaterialSystem` (`// CYS-LOOK:`):
  - `receiverLutEnabled()` = có define toàn cục `SHADOWMAP_TYPE` 1/2 + `mShadowReceiverLighting` + có `luttex.png`
    trong tài nguyên; tắt bằng `CYS_SHADOW_LUT=0` (A/B) và bằng `CYS_SHADOW_PROMOTE=0`.
  - `applyGlobalDefines`: PS nhận bóng của **model** (họ FAMILY_MODEL, pass có lighting) và của **địa hình** thêm
    `LUT_ENABLE=1`; VS không có (đúng như CY).
  - `bindEngineSamplers`: PS có `LUT_ENABLE=1` được gắn unit `luttex.png` ở **s4, filtering none, clamp**
    (thay cho ô trắng `CYS/Global/LUT` trước đây).
  - Điều kiện an toàn: chỉ thêm khi **s4 còn trống** trong pass (một số template dùng s4 cho việc khác).
- `CYSShadowHost::onSceneLoaded(sceneFile)` + hook `CRenderSystem::Scene_Load`: cảnh chọn/tạo nhân vật
  (`*chuangjian*`) tắt bóng; cảnh đăng nhập (`*erengu*`) đặt back-off caster 18000 như `setShadowDis(18000, 1000)`;
  các cảnh khác về 8000 và theo mức `View_HumanLightmap`.
- `CYSShadowSystem::setBackoff` (setter nhỏ) cho luật trên.

## 4. Số đo (Build\Logs\2026-09-14-cy-look\metrics)

Xem `metrics\lut_compare.tsv` và `viewer\` — luma/màu trung bình vùng địa hình và vùng công trình, ba cấu hình:
bóng tắt, bóng mức 2 không LUT (`CYS_SHADOW_LUT=0`), bóng mức 2 có LUT (như CY).

## 5. Chưa làm / chưa xác minh

- Bộ lọc hậu kỳ `ColorLUT` theo cảnh (bảng tên LUT trong Game.exe CY, lệnh `scenesetlut`, vtable 0x330).
- Lệnh console `setShadowDis/setShadowMapSize/setCascadeParam/...` và bảng ghi đè theo cảnh `DAT_140fb35b0`.
- INF: điều kiện chính xác để OgreMain CY chuyển sang chương trình nhận bóng (cờ GfxLayer +0x12) — CY-Source thay
  thẳng chương trình của pass nên không cần cờ này.
