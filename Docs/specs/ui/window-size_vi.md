# GetWindowSize native — khung thông báo đăng nhập

Ngày: 2026-09-13. Phạm vi: Lua → cửa sổ CEGUI; không sửa Lua/layout, không kết nối mạng.

## Lỗi và hợp đồng

Stage GL dùng `SelectServerQuest.lua` gọi `SelectServerQuest_InfoWindow:GetWindowSize()` trong `LoginSelectUpdateRect`, rồi đặt chiều cao khung bằng `23 + 25 + height`. Native common metatable thiếu phương thức; generated `UI_Window.GetWindowSize` chỉ là stub. Đây là lỗi tiếp theo sau khi tách modern login khỏi socket legacy, không phải nguyên nhân crash `WaitConnecting` trước đó.


Bằng chứng LLVM: `Build/Logs/2026-09-13-gpt-gl-login/get-window-size-b.txt`. Ánh xạ nguồn: `CEGUI::Window::getAbsoluteSize()` trả `d_pixelSize`, tức kích thước pixel đã chịu giới hạn của native window, không phải kích thước tương đối hay kích thước chữ đo lại.

## Triển khai

- `Src/Client/CEGUISystem/UILuaControl.h`: member `Window::GetWindowSize` đọc `getAbsoluteSize()`, truncate từng chiều sang `INT`, push 2 số nguyên và trả 2.
- `Src/Client/CEGUISystem/UILuaControl.cpp`: đăng ký trên `MetaTable_Control_Window` trước khi tạo các metatable control kế thừa. Generated registrar giữ implementation thật theo cơ chế `IsMissing` hiện có.
- Không đổi layout, trạng thái visibility, hệ tọa độ, min/max hoặc quy tắc căn pixel của CEGUI.

## Hồi quy

Lệnh PowerShell, thư mục làm việc CY-Source:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_window_size_tests.ps1 -NativeTree C:/TLBB/085/CY-Source/Build/cmake/ci-x64 -OutDir C:/TLBB/085/CY-Source/Build/Logs/2026-09-13-gpt-gl-login/window-size-tests-3
```

Kết quả **11/11 PASS**, compile/run `0`. Test include chính inline member production; không chép lại phép tính getter. CEGUI và LuaPlus lấy từ cây CI `c348e40`. Source/binding/script/DLL hashes nằm trong `result.json` của lượt test. Lượt này kiểm member và đường Lua; native DLL registration được kiểm tiếp bằng CI/runtime của batch chứa thay đổi.

Các ca gồm thứ tự và số lượng kết quả, căn pixel của native, truncate float lưu trong cửa sổ, relative→absolute, resize cha, min/max, cửa sổ ẩn, zero và tham số dư. Cặp hồi quy chạy nguyên `Assets/Canonical/Data/InterfaceFolder/SelectServerQuest/SelectServerQuest.lua`: bỏ method làm handler dừng trước Show; nối member thật thì `Falagard/SelfFitWindow` cao 25 tạo khung 73 pixel, ẩn hai nút, và cập nhật chiều cao thật 63 thành khung 111 pixel.

`window-size-tests-1` giữ lỗi compile fixture do kiểu `LuaStackObject`/tên factory; `window-size-tests-2` giữ hai kỳ vọng sai về subpixel vì `setSize` đã căn pixel. Đã sửa fixture để tách phép căn pixel native khỏi truncate getter, không đổi production để qua test. Không chạy Game/GUI/WSL trong lượt này.

## Xác nhận Game trong batch bc363c3

GUI WSL chạy62,372889 giây,23layout/6PNG,UI/Lua/missing0; thông báo chờ đã đóng và SelectRole hiện sau auth/list0. Registration native được chạy thật. 11 ca được dùng lại theo source/DLL import trùngSHA, không gọi là rerun. Xem `Docs/specs/ui/gl-login-integration-20260913_vi.md` và evidence `review-bc363c3.json`.
