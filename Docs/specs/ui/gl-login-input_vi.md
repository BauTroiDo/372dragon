# Input và fade cho GL LogOn — 13/09/2026

Nhánh source từ `902ecf8`, trong phạm vi UI cần cho đăng nhập đã được mở. Không sửa Lua/layout Canonical hay bật GLResponsive. Dữ liệu GL và lượt Game/WSL do nhánh tích hợp kiểm chứng riêng.

## Contract và nguồn thực thi

| API | Hành vi native |
|---|---|
| `GetActiveInput()` | Tên UTF-8 của ô nhập trong IME focus stack; không có ô nhập trả chuỗi rỗng. Window rời stack khi bắt đầu hủy và trước destructor để tránh đọc con trỏ đã giải phóng. |
| `GetCaplockStatus()` | Lua number 0 hoặc 1, lấy bit toggle của `GetKeyState(VK_CAPITAL)`. Không dùng bit phím đang giữ. |
| `CAPLOCK_CHANGED` | `GMInputSystem` lấy mẫu khi nhận Caps Lock keydown/keyup, khi nhận focus và khi active lại; chỉ phát event khi bit toggle thay đổi. Không phát lặp do key repeat. |
| `Window:StartFade(from,to,seconds)` | Chỉ nhận ba Lua number thật; sai type giữ nguyên như B. Lưu transition, update alpha sau `updateSelf` và trước children. Alpha đi tuyến tính theo delta, clamp đầu/cuối về [0,1], giữ target khi xong. Chỉ bước thời gian khi window visible. |


Lua globals nằm trong `Src/Client/LuaApiGen/CysHostInput.*`, đăng ký nil-only và giữ bản sao descriptor callbacks. Root nối callback trước generated stubs và thêm ba tên event `CAPLOCK_CHANGED`, `QRCODE_MESSAGE`, `QRCODE_SCANQR_SUCCESS`. Hai tên QR chỉ được nhận diện; nhánh này không tạo dịch vụ QR hay giả event trả kết quả.

Fade dùng `CEGUIWindow` và adapter `CysUiFadeBinding.h`; `UILuaControl` đăng ký vào base Window trước khi tạo metatable dẫn xuất. Không dùng scheduler toàn cục hoặc callback sống ngoài window. **Có thêm data member vào Window; phải rebuild đồng bộ toàn bộ module dùng CEGUI**, dù không thêm virtual slot.

## Cổng DLL cho Game và harness

`Src/Engine/Interface/CysUiInputBridge.h` khai báo POD `__cdecl`; `UI_CEGUI.cpp` export ba hàm và kiểm tra function-pointer type khi biên dịch. Chỉ gọi trên GUI thread:

- `CysUiGetActiveInputName`: con trỏ tên mượn, dùng ngay trước lần GUI thay đổi tiếp theo.
- `CysUiCopyWindowTextUtf8(name,out,capacity)`: chỉ editbox/multiline editbox sống; lấy raw text kể cả SafeIME. Trả số byte không gồm NUL khi thành công; -1 đối số/control sai, -2 buffer thiếu. Không truncate; failure đặt `out[0]=0` nếu có chỗ. Không log nội dung ô nhập.
- `CysUiGetWindowRectUtf8(name,out[4])`: trả 1 khi control tồn tại và visible kể cả tổ tiên; xuất pixel tuyệt đối `left,top,width,height` từ `getPixelRect`, chưa clip. Trả 0 nếu thiếu/ẩn/đối số sai; zero output khi buffer có sẵn.

## Kiểm thử

Native tree `Build/cmake/gpt-login-ui-props`, targets `cys_ceguifalagard cys_uisystem`: build thành công. Lượt incremental thêm rect bridge: `Build/Logs/2026-09-13-gpt-gl-input/native-build-2.log`. `llvm-readobj --coff-exports` xác nhận đủ ba export.

- `Tests/ui/run_gl_input_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-gl-input/tests-4 -NativeTree Build/cmake/gpt-login-ui-props`: **23/23 PASS**, compile/run 0. Kiểm IME focus/lifetime, raw UTF-8 Trung–Việt, buffer guard, rect/ancestor visibility, service lỗi, Caps Lock thật trong keyboard state riêng của thread, và alpha quad native cho fade/restart/hidden/invalid/destroy. Keyboard state được khôi phục bằng RAII; không SendInput hay GPU.
- `Tests/ui/run_widget_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-gl-input/widget-1 -NativeTree Build/cmake/gpt-login-ui-props`: **126/126 PASS**, compile/run 0. Giữ cả teardown và widget selection/render regressions.
- Cả hai dùng CEGUIBase SHA-256 `28c21244ac6430910a11dc655048048bdfc2cfa4999956e09bec69114ea27a9e`. `result.json` giữ thêm hash test, Falagard, Lua host và UI_CEGUI.

Giữ các lượt lỗi runner/fixture trước đó: tests-1 dùng tên biến PowerShell trùng hệ thống; tests-2 gặp macro Win32 `near`; cả hai đã sửa trước tests-3 (21/21), rồi thêm rect cases thành tests-4 (23/23). Các ca trên kiểm production helper và native DLL; tuyến event Win32 → Game → Lua, StartFade trên layout GL và thao tác đăng nhập thật còn cần lượt tích hợp Game. Heap corruption của baseline GL dùng DLL cũ đang được điều tra riêng; không coi bộ unit xanh là bằng chứng đã sửa heap đó.
