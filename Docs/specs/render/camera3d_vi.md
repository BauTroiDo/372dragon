# Camera cảnh 3D tự do, bầu trời và cảnh xa (theo CY 3.71)


## 1. Bằng chứng dùng

| Thứ | Đường dẫn | Ghi chú |
|---|---|---|
| B Game.exe / Render.dll | project cũ `0bf34493…` / `fda12053…` | `projB`; bản trên đĩa đã vá sau nên địa chỉ B chỉ để đối chiếu |
| C System.cfg | `Tools\DATA NEW\CY Game\Bin\System.cfg` | khối `# Camera` và `View_*` |
| C SpecialSceneCamera.txt, SceneDefineEx.txt | `Tools\DATA NEW\DataCY31-08-26\Config` | |

## 2. Tham số (System.cfg của C)

```
Camera_MinDistance=6.0   Camera_MaxDistance=27.5   Camera_Zoom=1.0
Camera_Pitch=40.0        Camera_FOV=35.0           Camera_Smooth=1
Camera_RestoreView=0     Camera_Pitch_Min=-40.0    Camera_Pitch_Max=60.0
Camera_Pitch_Moving=40.0 Camera_MoveSpeed_Auto=30.0
View_DefaultCamera=1     View_EnableFog=1          View_VisibleRangeLevelNew=2
```

B (`client_GL\Bin64\System.cfg`): Min 4, Max 27.5, Pitch_Min −10, Pitch_Max 50, thêm `View_UseSkyCamera=1`. **Lệch C.**


## 4. Nội suy [D]

- **Zoom.** Mỗi khung, nếu \|zoom − đích\| > SmoothStep (0.01) thì zoom tiến một bước SmoothStep, ngược lại gán bằng đích. C không nhân dt; CY-Source cũng tính theo khung (`CRenderSystem::Camera_Tick`, gọi trong `RenderFrame`).
- **Pitch và hướng** không được nội suy riêng. Pitch vẫn "mượt" nhờ va chạm kiểu 0.85: khi mắt hợp lệ, pitch hiện tại tiến về `STATIC_PITCH` 1° mỗi lần Update. Hạ pitch xuống thì nhảy ngay.
- Phạm vi mỗi khung được ghi vào log `CYS camera:` (pitch hiện tại và pitch người chơi).

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


**Bẫy:** `Bin64\WXSystem.cfg` bị chính game ghi lại lúc thoát, nên sửa tay trong lúc game đang chạy sẽ bị mất.
Sửa khi game đã đóng, hoặc dựng lại bản chơi bằng `stage_game.py` (nay đã mặc định 1).
