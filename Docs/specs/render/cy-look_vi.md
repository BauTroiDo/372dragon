# Nhìn như CY 3.71.9609 — công trình tĩnh và LUT nhận bóng


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


  | Unit | Nguồn | Sampler | Lọc | Address |
  |---|---|---|---|---|
  | `shadow_buffer` | compositor `SceneRender` | s5 | mặc định | clamp |
  | **`luttex.png`** | tên texture | **s4** | **none (điểm)** | clamp |
  | `ssao_buffer` | compositor `SceneRender` | s12 | mặc định | clamp |


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
