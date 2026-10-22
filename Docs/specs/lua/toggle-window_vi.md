# ToggleWindow của GL — 13/09/2026

GL LogOn.lua:323 gọi ToggleWindow("SoftKeyBoard"); SoftKeyBoard_PreLoad đăng ký TOGGLE_WINDOW và handler tự Show/Hide theo IsVisible. CY trước chỉ có generated stub và chưa đăng ký tên sự kiện. Không thay Lua GL hoặc gọi Show trực tiếp để vượt lỗi.

## Thực hiện và kiểm thử

CysHostGlobals dùng scene service hiện có, kiểm gate trước argument, phát TOGGLE_WINDOW qua pushEvent. Đăng ký nil-only trước generated catalog. CY giữ C-string/number/UTF-8, từ chối giá trị không đổi được thành chuỗi. Thiếu service có Lua error rõ; không tự tạo cửa sổ hoặc lách scene gate. GE_TOGGLE_WINDOW thêm cuối enum, giữ toàn309 ID cũ; bản đồ tên thêm một mục (toggle-event-prefix.json).

Lệnh: powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-gl-login/toggle-tests-2 -Jobs 1.

Kết quả73/73 PASS, build/run0:6 ca mới gồm missing1→0/event thật, gate trước validation, C-string/UTF-8/numeric, thiếu dịch vụ/exception, giữ binding có sẵn, và nạp SoftKeyBoard.lua Canonical thật. Ca cuối xác nhận event nằm trong queue trước dispatch; handler Show lần1/Hide lần2, bỏ tên khác. Đây là kiểm Lua với service fixture; hình/nhập Game vẫn do GUI runner xác nhận.

Lượt toggle-tests-1 build0 nhưng process access violation, log buffered rỗng; không coi là testpass. Rerun cùng executable console và3 lượt redirect đạt72/73, lỗi kỳ vọng registration4 còn sót (nay5 do thêm ToggleWindow). Fixture mới còn giữ LuaObject globals của State u trong biến khai báo trước u, khiến destructor có thể dùng sentinel của LuaState đã hủy. Đã tách scope đúng lifetime, sửa expected số API và thêm stdout unbuffered/RUN marker. Không có dump lượt crash nên không khẳng định stack của lần đó; evidence toggle-old-rerun giữ các lượt đối chiếu. Không sửa production để né test.
