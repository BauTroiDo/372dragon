# Camera cảnh 3D tự do, bầu trời và cảnh xa (theo CY 3.71)

Cập nhật: 14/09/2026, agent camera3d, nhánh `camera3d`.
Nguồn chuẩn: **CY 3.71** ("C", `Tools\DATA NEW\CY Game\Bin64`, DataCY). client_GL ("B") chỉ để đối chiếu; mọi chỗ lệch B được ghi rõ.
Ký hiệu: **[D]** dữ kiện đọc thẳng từ mã dịch ngược/dữ liệu, **[S]** suy luận, **[?]** chưa kiểm.

## 1. Bằng chứng dùng

| Thứ | Đường dẫn | Ghi chú |
|---|---|---|
| C Game.exe | sha256 `9278c7f3…cc5b` | bản sao Ghidra `Build\re\camera3d\projCG` |
| C Render.dll | sha256 `e6e67de4…cec7` | bản sao `Build\re\camera3d\projCR` |
| B Game.exe / Render.dll | project cũ `0bf34493…` / `fda12053…` | `projB`; bản trên đĩa đã vá sau nên địa chỉ B chỉ để đối chiếu |
| C System.cfg | `Tools\DATA NEW\CY Game\Bin\System.cfg` | khối `# Camera` và `View_*` |
| C SpecialSceneCamera.txt, SceneDefineEx.txt | `Tools\DATA NEW\DataCY31-08-26\Config` | |
| Dump decompile | `Build\re\camera3d\out\C_*.txt`, `B_*.txt` | disassembly C: `Build\re\camera3d\tmp\c_game.dis` |

## 2. Tham số (System.cfg của C)

```
Camera_MinDistance=6.0   Camera_MaxDistance=27.5   Camera_Zoom=1.0
Camera_Pitch=40.0        Camera_FOV=35.0           Camera_Smooth=1
Camera_RestoreView=0     Camera_Pitch_Min=-40.0    Camera_Pitch_Max=60.0
Camera_Pitch_Moving=40.0 Camera_MoveSpeed_Auto=30.0
View_DefaultCamera=1     View_EnableFog=1          View_VisibleRangeLevelNew=2
```

B (`client_GL\Bin64\System.cfg`): Min 4, Max 27.5, Pitch_Min −10, Pitch_Max 50, thêm `View_UseSkyCamera=1`. **Lệch C.**

- **Dấu và đơn vị [D].** Cấu hình tính bằng độ. Bên trong, pitch = −độ·π/180 (quy ước 0.85: âm là nhìn xuống). Mắt camera = điểm nhìn + (−sin(dir)·cos(−p)·d, sin(−p)·d, −cos(dir)·cos(−p)·d), với C Render `FUN_180003d00`.
  - `Camera_Pitch 40` = nhìn xuống 40°.
  - `Pitch_Min −40` = ngẩng lên tối đa 40°.
  - `Pitch_Max 60` = cúi xuống tối đa 60°.
- **Giới hạn pitch và khoảng cách [D].** C Game.exe `FUN_1406be820` (CScene::EnterScene) đọc dòng `SpecialSceneCamera.txt` theo ID cảnh; không có thì lấy dòng 1 (Type 0, FOV 55, dist 2–25, ZoomStep 0.1, SmoothStep 0.01, pitch −40/60).
  - Nếu `View_DefaultCamera != 0` và cảnh Type 0, giới hạn lấy từ System.cfg.
  - Pitch: kiểm −90…90 và min ≤ max.
  - Khoảng cách: ≤ 0 thì dùng 6 / 27.5, và max ≥ min + 0.1 (`FUN_140647430`).
  - Range và FOV được truyền qua Render vtable +0x1c8 / +0x1e0.
  - Đại Lý (ID 2) không có dòng riêng nên rơi về dòng 1, Type 0. CY đặt `View_DefaultCamera=1`, nên hiệu lực là 6–27.5 m, FOV 35°, pitch −40…60.
- **Khoảng cách cổ điển của B [D].** Ở B, `View_DefaultCamera=1` ("经典视距") kẹp Max về 17.5. C không kẹp.
- **Camera_Zoom [D].** Giá trị t ∈ [0,1]: distance = Min + (Max − Min)·t (Render `FUN_18002b520`). `Camera_GetZoom` của C trả t (`FUN_18002b270`); bản 0.85 trả khoảng cách.
- **Camera_RestoreView, Camera_Pitch_Moving, Camera_MoveSpeed_Auto [D].** Khi RestoreView = 1 và nhân vật đang chạy, pitch tiến về Pitch_Moving với tốc độ MoveSpeed_Auto độ/giây (tick `FUN_14064a0a0`). CY để 0, nên **chưa port** (xem NEXT).
- **View_UseSkyCamera ("天空视角") — chỉ có ở B [D].**
  - Chuỗi này không có trong C: C luôn cho pitch tự do (cờ `this+0x164 = 1` ở constructor `14064d325`).
  - **Đính chính 15/09 (scene-change-fix) [D, đo bộ nhớ CY].** Với System.cfg của CY, kéo chuột phải dọc 160 px và lăn chuột KHÔNG đổi pitch: luôn = `Camera_Pitch` 40° (`Build/Logs/2026-09-15-scene-change-fix/oracle-1-luoyang` cam-a0/a1/a3; cy-oracle run-18..21). Nhánh đổi pitch ở ProcessInput không chạy trong cấu hình này. CY-Source: `View_UseSkyCamera` mặc định 0 = pitch khoá đúng `Camera_Pitch`; 1 chỉ cho driver chụp ảnh 3D.
  - B với giá trị 0: pitch khoá trong [30°, 43.5°] nhìn xuống và kéo chuột không đổi pitch.
  - B tự tắt khoá này khi Render vtable+0x478 < 50 (không rõ đo gì). CY-Source không port điều kiện tự tắt đó.
  - Controller Lua GL `ViewSetup.lua` có checkbox `tksj` cho khoá này. DataCY `ViewSetup_Setup.lua` cũng gọi `View_SetData("tksj", 0)` ("đóng góc nhìn trời" khi tối ưu), nhưng C Game.exe không có chuỗi `View_UseSkyCamera` [S: khoá được map ở Lua/SystemSetup].

## 3. Chuột và phím (C `FUN_14064bd70` ProcessInput) [D]

| Thao tác | C | CY-Source |
|---|---|---|
| Giữ chuột phải, kéo ngang | `AddDirection(−dx/300)`; bắt đầu kéo khi \|dx\| > 4 px | giữ `Camera_AddDirection(−dx/300)` của 0.85; ngưỡng 4 px do sự kiện RDRAG của 0.85 |
| Giữ chuột phải, kéo dọc | tĩnh: `p = GetPitch() − dy/300` rad/px; **đo thực tế: pitch không đổi** (xem mục 2) | `Camera_AddPitch` bị bỏ qua khi `View_UseSkyCamera=0` (mặc định) |
| Giữ chuột giữa, kéo dọc | `p += −dy·0.25°` | `Camera_AddPitch(−dy·0.25°)` |
| Lăn chuột (Smooth = 1) | đích zoom ∓= ZoomStep (0.1), kẹp [0,1] | `Camera_ZoomStep` |
| Lăn chuột (Smooth = 0) | `Camera_SetZoom(up, 2)` = ±0.1 ngay | như C |
| Phím ←/→, ↑/↓ | 0.85: xoay ±0.04 / zoom | giữ 0.85 |
| B: Home/End + Alt | pitch ±0.5° mỗi khung | chưa port (chỉ có ở B) |

`GetPitch` của C trả `STATIC_PITCH`, tức pitch người chơi chọn, không phải pitch sau va chạm (`FUN_18002b1c0`). `SetPitch` chỉ nhận |p| < 1.553343 rad (89°) (`FUN_18002b420`).

## 4. Nội suy [D]

- **Zoom.** Mỗi khung, nếu \|zoom − đích\| > SmoothStep (0.01) thì zoom tiến một bước SmoothStep, ngược lại gán bằng đích. C không nhân dt; CY-Source cũng tính theo khung (`CRenderSystem::Camera_Tick`, gọi trong `RenderFrame`).
- **Pitch và hướng** không được nội suy riêng. Pitch vẫn "mượt" nhờ va chạm kiểu 0.85: khi mắt hợp lệ, pitch hiện tại tiến về `STATIC_PITCH` 1° mỗi lần Update. Hạ pitch xuống thì nhảy ngay.
- Phạm vi mỗi khung được ghi vào log `CYS camera:` (pitch hiện tại và pitch người chơi).

## 5. Va chạm [D]

- **Chỉ với địa hình.** Hình cầu bán kính = near clip được kiểm với hộp bao của ≤ 4 ô heightmap dưới mắt (`FUN_1800040e0` / `FUN_180004c50`). **Không có** tia cắt công trình. Chuỗi "Core/CameraClip" chỉ là overlay debug in near/far (`FUN_1800938e0`).
- **Chế độ theo cột Type của SpecialSceneCamera** (`DAT_1803b4cec`):
  - **0 — nâng pitch** (`FUN_1800048c0` = `_GetValidPitch` 0.85). Mắt không hợp lệ thì hạ pitch 1°/bước tới −89.9°. Hợp lệ thì trả pitch về `STATIC_PITCH` 1°/Update. Mắt ngoài địa hình được coi là hợp lệ.
    - Hệ quả: ngẩng lên −40° ở khoảng cách lớn thì mắt trượt sát mặt đất và vẫn nhìn thấy trời.
    - Đại Lý dùng chế độ này.
  - **≠ 0 — rút ngắn khoảng cách** (`FUN_180004540`). Không hợp lệ thì trừ 1.0 đơn vị/bước tới MIN_DISTANCE. Có chỗ thì +10, không vượt khoảng cách mong muốn (`DAT_1803b01f4`, do `SetDistance` ghi khi mắt hợp lệ), rồi lùi 0.1/bước tới khi hợp lệ.
    - Mắt ngoài địa hình bị coi là không hợp lệ.
- **CY-Source:** `CCamera_Scene::COLLIDE_BY_DISTANCE` + `_GetValidDistance`, đúng hằng số của C. Cảnh Type ≠ 0 cần bảng SpecialSceneCamera (chưa có trong Canonical, xem NEXT); hiện luôn là Type 0.
- **Che khuất bởi công trình:** C không xử lý ở camera; có tuỳ chọn `View_Transparency` ("遮挡半透") làm vật che trong suốt, CY mặc định 0. CY-Source thêm `Camera_CountOccluders` (RaySceneQuery hộp bao Entity), **chỉ dùng cho driver replay** để chọn góc chụp. Không đổi hành vi camera.

## 6. Near/far clip, sương, bầu trời

- **Constructor camera C [D].** Addheight 0.7, pitch `STATIC_PITCH`, distance 17.5, dir 3.1416, `+0x50` = 15000 (far), `+0x54` = 5 (near). Mỗi Update đặt lại near/far (`FUN_180003d00`).
- **Theo cảnh [D].** C Game.exe `1406be4ff..1406bec17`:
  - `CScene+0x8c` = (float) dòng SceneDefineEx `+0x58` = **cột 15**; `CScene+0x90` = `+0x5c` = **cột 16**.
  - Rồi gọi Render vtable `+0x1f8` (far) và `+0x208` (near).
  - Sau đó `+0x380(5000 hoặc 10000 / far, 5.0)` [S: độ sâu cull vật tĩnh theo khoảng cách, "Set camera distance cull depth"].
  - DataCY: 521/679 cảnh 15000/10, Đại Lý 15000/10.
  - Canonical (bố cục client_GL) có cùng cột 15/16 (`Registry/abi/dbc_columns_gl.tsv` offset 88/92): 430/547 cảnh 15000, còn lại 8000–60000.
  - CY-Source: `_DBC_SCENE_DEFINE::nCameraFarClip/nCameraNearClip`, `CScene::EnterScene` → `Camera_SetClip`. Log `[CYS] camera3d: scene camera clip far=15000 near=10`.
- **Đơn vị.** Render: 1 m = 100 đơn vị, nên far 15000 = 150 m.
- **Bầu trời.** Không có camera trời riêng [D]. SkySphere/EnScene đi theo camera, vẽ trước cảnh, không ghi depth (`CYSSkyRenderer`), nên phía sau far clip là trời, không có vùng đen. Đại Lý: `dali.skysphere`, fog tuyến tính 3000–9000 (`dali.Scene`), HeightFog hậu kỳ mặc định (`CysPostFX: HeightFog enabled`).
- **TlbbViewer khác Game.exe:** viewer đặt far = max(50·d, 30000), nên thấy thêm núi/nhà rất xa trong sương. Game.exe theo C là 15000, nên các bóng núi ngoài 150 m bị cắt. Ảnh so sánh ở mục 8.

## 7. Cài đặt trong CY-Source (hook `// CYS:`)

- `Src/Engine/WXRender/Camera/Camera_Scene.{h,cpp}`: `COLLIDE_BY_DISTANCE`, `DESIRED_DISTANCE`, `NEAR_CLIP`, `FAR_CLIP`, `_GetValidDistance`, `SetDistance` kiểu C, mắt ngoài địa hình theo chế độ, near/far mỗi Update.
- `Src/Engine/WXRender/RenderSystem.{h,cpp}`:
  - Pitch và chế độ: `Camera_SetPitch/AddPitch/GetPitch`, `Camera_SetFreeMode/IsFreeMode` (View_UseSkyCamera).
  - Zoom: `Camera_ZoomStep/SetZoomTarget/Tick`.
  - Cấu hình: `Camera_ApplyVariables` (khi khởi động và khi có `VARIABLE_CHANGED` của khoá `Camera_*`, `View_UseSkyCamera`, `View_DefaultCamera`, `View_VisibleRangeLevelNew`).
  - Near/far và tiện ích: `Camera_SetClip`, `Camera_CountOccluders`, `Camera_Describe`.
  - `Camera_GetZoom` trả t như C.
- `Src/Client/WXClient/Procedure/GamePro_Main.cpp`: kéo chuột phải dọc, chuột giữa, lăn chuột. Bỏ qua input thật khi `CysWorldReplay::AutoDriving()`.
- `Src/Client/WXClient/World/Scene.cpp` và `Src/Engine/Interface/TDDBC_Struct.h`: far/near theo cảnh.
- `Tools/game/stage_game.py`: `apply_cy_camera_keys` ghi khối camera của C vào `Bin64/WXSystem.cfg` của stage, thêm `View_UseSkyCamera=1` (test `CameraKeys`).
- **Click-to-move ở mọi góc:** không cần sửa. `CObjectManager::GetMouseOverObject` dùng `Camera_GetWindowToViewportRay` và `AX_SCREEN → AX_PLAN` (`WX::System::getTerrainIntersects`) theo camera Ogre hiện tại. Nhìn lên trời thì tia không cắt đất nên không đi (đúng). Driver kiểm bằng cách chiếu điểm đích lên màn hình rồi pick lại: sai số 0.007–0.035 m ở pitch 20°.

## 8. Chứng minh

- Stage: `Build\world-gui\stage-289d98ft7-camera3d`, dựng từ commit 3240682. Game.exe sha256 `3a20538c…1efd3`.
- Lượt: `Build\Logs\2026-09-14-camera3d\replay-run-7`: PASS 26/26, 82.4 s, exit 0, 0 socket, 0 dump, `quit_flag=0 decode_failures=0`.
- Ảnh trong lượt đó:
  - `…-world-1.png` — góc cổ điển: pitch 40°, 27.5 m.
  - `…-cam-sky-low.png` — 3D thấp, pitch 5°: trời, mây, cung điện xa trong sương.
  - `…-cam-yaw90.png` — xoay +90°.
  - `…-cam-zoom-far.png` — 35°, 27.5 m, zoom mượt từ 0.55 tới 1.0.
  - `…-move-running.png` — sau click qua tia camera ở pitch 20°, yaw 225°.
- So cùng góc bằng TlbbViewer: `Build\Logs\2026-09-14-camera3d\viewer\viewer-dali-run7-cam-{sky-low,yaw90,zoom-far}.png`. Bố cục trùng khớp; viewer thấy xa hơn (far 30000).
- Chưa có ảnh CY thật cùng góc, vì client CY cần server chính thức.

## 9. Việc còn mở

1. Nhập `SpecialSceneCamera.txt` (DataCY, DBC 0x204) vào Canonical + struct DBC, rồi áp theo cảnh: Type, FOV, khoảng cách, ZoomStep/SmoothStep, pitch, AddHeight (vtable +0x1e8, cột 9 = 1.5 [S]), Direction/Pitch/Zoom khi Type ≠ 0.
2. `Camera_RestoreView` + `Pitch_Moving` + `MoveSpeed_Auto` (CY mặc định tắt).
3. `View_Transparency`: vật che bán trong suốt.
4. Cull tầm xa `+0x380` (5000/10000 chia far) và `View_VisibleRangeLevelNew`.
5. Kiểm checkbox `tksj` của ViewSetup GL gọi được `View_UseSkyCamera` qua host API SystemSetup.
6. Ảnh CY thật cùng góc để so fog và tầm xa.

## 10. CỐ Ý KHÁC CY — camera tự do trong bản chơi (17/09/2026)

**Đây là ngoại lệ duy nhất của luật "mọi thứ như CY" ở tầng camera. Đừng "sửa lại cho giống CY".**

| | |
|---|---|
| Quyết định | Người dùng, 17/09/2026: *"đổi mặc định luôn, ghi rõ chỗ cố ý khác CY"* |
| Thay đổi | `Tools\game\stage_game.py` ghi **`View_UseSkyCamera=1`** vào `WXSystem.cfg` của mọi bản chơi (trước là `0`) |
| Hệ quả | Kéo chuột phải dọc đổi được pitch trong khoảng **−40°…60°** (`Camera_Pitch_Min/Max`), thay vì bị ghim ở `Camera_Pitch = 40°` |
| Quay về đúng CY | đổi **một** khoá đó về `'0'` trong `stage_game.py`; không cần dựng lại gì khác |

**CY thật thì KHÔNG như vậy** — phần này giữ nguyên để người sau khỏi đo lại: đo camera CY 3.71 từ bộ nhớ
(`Build\Logs\2026-09-15-scene-change-fix\oracle-1-luoyang` cam-a0/a1/a3, `cy-oracle` run-18..21) cho thấy với
`System.cfg` của CY, **kéo chuột phải dọc 160 px và lăn chuột 4 nấc không đổi pitch**; pitch luôn bằng
`Camera_Pitch` (40° nhìn xuống), chỉ kéo ngang mới đổi yaw. CY không có khoá `View_UseSkyCamera` — khoá này là
của client_GL (B).

**Mặc định của ENGINE vẫn là 0 (đúng CY).** `RenderSystem.cpp` `Camera_ApplyVariables` đọc
`_CysCamInt("View_UseSkyCamera", 0)`, nên mọi công cụ đo đối chứng không đi qua bản chơi
(`cy-oracle`, `d3d9-trace`, `TlbbViewer`, `OgreSmoke`) vẫn dựng bằng **camera cố định của CY** — nếu đổi mặc định
engine thì các phép so ảnh với CY sẽ lệch mà không ai biết. Chỉ bản chơi mới bật camera tự do.

**Bẫy:** `Bin64\WXSystem.cfg` bị chính game ghi lại lúc thoát, nên sửa tay trong lúc game đang chạy sẽ bị mất.
Sửa khi game đã đóng, hoặc dựng lại bản chơi bằng `stage_game.py` (nay đã mặc định 1).
