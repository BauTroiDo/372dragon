# MeshWindow BackgroundName — 13/09/2026

Lượt `integration-5d5ece4` còn bốn lỗi property `BackgroundName` khi nạp PetZhengYou/PetFriendSearch. Giá trị đến từ `Data/Interface/Schema/TLBBLook_Frame.looknfeel.xml`, look `TLBB_Look_MeshWindow`: `Common/MeshBack.dds`. Đây là tên texture nền của ảnh nhân vật, không phải tile `WorldMap`.

## Đường nối CY

`FalagardMeshWindow/Properties` bổ sung property và event đúng hợp đồng trên. `UILuaControl::SetFakeObject` gửi chuỗi UTF-8 và kích thước qua export của Game `CysFakeObjOnUIHook`. Game giữ lookup/unhook như cũ, rồi gửi renderer/entity/camera/size/background qua `CysFakeObjCreateWithBackground` của Render. `CysUiMeshBridge.h` chỉ có typedef tham số POD và con trỏ mượn trong thời gian gọi; không thêm slot hoặc đổi chữ ký hàm ảo của `tFakeObjSystem`/`CRenderSystem`. Đường `OnUIHook` cũ vẫn có default 256×512 và nền rỗng.

Nếu module thiếu export, caller báo lỗi rõ, không bỏ qua background. CY từ chối kích thước UI không hữu hạn, âm hoặc trên 2^30 trước phép đổi kiểu/lũy thừa; đây là kiểm tra phòng vệ CY, không phải hằng số phục hồi từ B. Backend Render được triển khai và kiểm riêng cùng batch; chỉ property hết lỗi chưa đủ để xác nhận nền đã hoạt động.

Gán `BackgroundName` sau khi object đã bind chỉ phát `MeshShown`, giống B. Nền được lấy lúc `SetFakeObject`; không tự thay texture/material đang bind bằng setter. Kiểm thử RTT khi visible và vòng đời tài nguyên là yêu cầu trước khi đánh xong phần renderer.

## Kiểm chứng

Build native UI `Build/Logs/2026-09-13-gpt-login-remaining/mesh-ui-build-1`: **8/8 edges, exit 0**, link CEGUIFalagard/UI_CEGUI thành công, max 2 jobs. Giữ các warning nền `/EHc` và thông báo Boost compiler; không gọi đây là build không warning.

`mesh-widget-tests-1`: **126/126 PASS**, compile/run 0, runner không có warning/error. Tám ca Mesh mới kiểm factory thật, default, event khi visible/gán lặp, ẩn chính nó/ẩn cha, chuỗi rỗng và giữ đúng ảnh RTT đã bind qua render cache stretch. SHA CEGUIBase `8cf9b51a0fd1d0132135a76c507121f9b6ecaeeeaa6f7a861a91c66bf5d67109` (đối chiếu `result.json`); SHA CEGUIFalagard `c453e5245e479bf9ece86875199b0c75b6a0a4aa6970b0b6fa2642b9198453ff`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_widget_tests.ps1 -OutDir Build/Logs/mesh-widget-NEW -NativeTree Build/cmake/gpt-login-ui-props
```

Native widget không chứng minh đường Game/RTT; kết quả probe renderer riêng nằm ở mục tiếp theo. Build/GPU do root điều phối.

## Backend và probe D3D9

`CysUiMeshBackground.h` là implementation production dùng chung bởi manager và probe: quad Rectangle2D phủ RTT, clone/reuse material, texture, queue 0, visibility 4, bounding box vô hạn và child scene node. `RFFakeObjectManager` truyền kích thước RTT, bật nền cùng object trong `SetActiveObject`, tắt ở post viewport, tháo listener/viewport/camera/texture và nền khi destroy/release. Export POD trong `RenderSystem.cpp` giữ nguyên vtable và có static_assert đối chiếu typedef bridge. Backend từ chối kích thước 0 hoặc trên 4096 và renderer chưa hoạt động; đây là giới hạn CY để tránh cấp phát RTT bất thường. Tên object đã có vẫn dùng lại RTT như B.

Khác biệt vòng đời có chủ ý: CY xóa material clone do chính background tạo khi destroy, nên destroy/recreate cùng tên có thể dùng texture mới. Material tồn tại từ trước được mượn, giữ nguyên texture và không bị xóa. B giữ clone trong resource manager. Empty background hoặc thiếu base material vẫn không tạo rectangle như B.

`Tests/ui/mesh_background_probe.cpp` dùng trực tiếp helper production, OgreMain và plugin D3D9 native; owner HWND ẩn, không chạy Game. Kết quả `Build/Logs/2026-09-13-gpt-netbot/mesh-background-3`: **26/26 PASS**, compile/run 0. Bảy lượt readback, mỗi lượt 8192 pixel, đều mismatch 0: clear alpha 0, nền thứ nhất trên RTT 128×64, nền thứ hai trên RTT 64×128, mask world loại nền, tắt sau viewport, destroy/recreate cùng tên và giữ material mượn. Hai node được quan sát gắn/tháo thật; 32 vòng create/destroy giữ nguyên số material resource và scene child. Process heap hợp lệ sau kiểm tra.

Probe còn load/render hai texture thật qua material production, đều 256×256: stage `Build/gpt-p1-1-20260913/stage-5d5ece4/Data/Material/Common/MeshBack.dds` là DDS RGBA, SHA256 `FD0FA56C26BB218B786DC9A111F326815F10292C77A512C137D0095980A03DEE`; Canonical `Assets/Canonical/Data/MaterialFolder/Common/MeshBack.dds` là DXT1, SHA256 `FE9C8EEFF62B23987F6F13761E5B10C89EF404297856253DCE1A53DDD5903C09`. Hai file khác nhau; kiểm tra này không kết luận nguồn hoặc thời điểm đổi codec. Fixture được copy vào thư mục output riêng, không sửa nguồn. Ogre log có cảnh báo VSync tắt và hai texture màu tổng hợp không có loader phục hồi device; probe không kiểm device reset.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_mesh_background_probe.ps1 -OutDir Build/Logs/mesh-background-NEW -MeshBack Build/gpt-p1-1-20260913/stage-5d5ece4/Data/Material/Common/MeshBack.dds
# Chạy sau khi root điều phối GPU; không biên dịch lại.
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_mesh_background_probe.ps1 -OutDir Build/Logs/mesh-background-NEW -RunOnly
```

Giới hạn: probe xác nhận quad/material/visibility/lifecycle của helper production trên GPU. Nó tự tạo camera/RTT và gọi active trực tiếp, chưa đi qua `CFakeObjectManager`, listener, export Game/Render hoặc Lua/UI binding. Full build và Game runtime của batch cần kiểm riêng; chưa xác nhận đăng nhập GUI, nhân vật trong world hoặc điều khiển game.


## Tích hợp Game/CI

30a9611: CI 36/36, build 16,4 giây/24 bước; widget 126/126 chạy lại trên DLL CI. Game offline 61,41 giây/28 layout/hai PNG, BackgroundName 4→0 và toàn bộ UI Error 8→0, missing/Lua/fatal đều 0. `Build/Logs/2026-09-13-gpt-wsl-ui/integration-30a9611` và spec tích hợp ghi lệnh/ảnh. Không có nhân vật đang bind trong lượt offline; chưa lấy Error 0 thay cho kiểm manager/listener cùng nhân vật Game thật.
