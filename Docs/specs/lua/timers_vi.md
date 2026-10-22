# Lua host timers: SetTimer, KillTimer, ClearAllTimer


## Bằng chứng B và miền đã xác nhận


|---|---|---|

Các tên `timer-*.txt` dưới đây tính từ `Build/Logs/2026-09-12-gpt-p1-2/timers/`.


## SetTimer

`SetTimer(owner, expression, milliseconds) -> number`, đúng một return; argument dư bị bỏ qua.

- Owner và expression nhận Lua string hoặc number theo `lua_isstring`; số được chuyển sang chuỗi. Interval phải có kiểu Lua number thật; `"1000"` là sai kiểu. Sai bất kỳ kiểu bắt buộc nào trả **-1**, không tạo timer. Đầu vào C-string cắt ở NUL đầu tiên, kể cả API C++ Manager::Set.
- Interval cắt phần thập phân về int32 rồi chuyển bit sang UINT. Đơn vị **mili giây**. Win32 nhận giá trị này và clamp vào `[10, 0x7fffffff]`: 0/1 ms thành 10; -1 thành UINT lớn rồi clamp về mức tối đa. Không nhân 1000 trong adapter. Nguồn: [Microsoft SetTimer](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-settimer); hằng số cục bộ ở `C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/um/WinUser.h:7070`.
- OS cấp ID qua `SetTimer(NULL,0,ms,TimerProc)`; **0** là thất bại tạo timer. Trong miền int32 dương, trả nguyên ID này dưới dạng Lua number. Adapter không tự cấp ID hay trả hằng thành công. `timer-backend-disasm.txt:185–201` xác nhận lời gọi và nhánh zero.
- Cùng owner/expression được Set nhiều lần sẽ tạo nhiều timer. Map B có khóa unsigned ID; dữ liệu là expression và owner. Chèn unique: khi OS tái sử dụng ID còn record cũ, record mới bị bỏ và record cũ giữ nguyên. Chứng cứ `timer-map-insert-disasm.txt:87–101`, RVA0x461420; caller Set không đọc cờ inserted. CY giữ hành vi này bằng `map::emplace`.
- Chuỗi owner/expression rỗng vẫn tạo timer nhưng callback không chạy biểu thức. Không kiểm owner có cửa sổ đang hiện hoặc environment đã tồn tại trước khi tạo.
- Timer lặp qua message pump. WM_TIMER ưu tiên thấp, không đảm bảo chạy chính xác mỗi 1000 ms trong lúc thread bận; adapter không chạy vòng bù tick. [Microsoft WM_TIMER](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-timer).

Source: `CysHostTimers.cpp:62` chuyển số; dòng 145 gọi Win32; dòng 278 kiểm Lua arguments; dòng 380 quản lý record và trả ID.

## KillTimer

`KillTimer(id_or_expression) -> boolean`, đúng một return.

| Kiểu argument | Thao tác | Return |
|---|---|---|
| Number thật | Cắt về int32, tìm ID; nếu có gọi platform Kill. **Giữ record và route**. | true kể cả ID không có / Win32 không còn timer |
| String | Cắt NUL, so sánh expression đầy đủ; duyệt ID unsigned tăng dần và kill/erase **một match đầu tiên**, không xét owner. | true kể cả không có match |
| Thiếu, nil, boolean, table, function, userdata | Không gọi platform. | false |

Không trim, casefold, bỏ `()` hoặc parse chuỗi số thành ID. Ví dụ `KillTimer("123")` tìm expression chuỗi `123`; `KillTimer(123)` tìm ID số. Dữ liệu `Biwuzhaoqin_Tips.lua:29,39,45` có tên có/không có `()`; adapter không tạo alias sửa ngầm dữ liệu.


Khác biệt giữa hai nhánh hủy được giữ đúng B: Windows không xóa WM_TIMER đã xếp hàng khi KillTimer được gọi. Sau Kill(ID), record còn nên một callback đã xếp hàng vẫn tìm được biểu thức; sau Kill(expression), record/route bị xóa nên callback đó bị bỏ qua. Timer đã chết do numeric Kill cũng có thể được chọn đầu tiên bởi Kill(expression), trong khi timer trùng expression khác vẫn sống. Đây là hệ quả từ `timer-backend-disasm.txt:322–347,468–532` và quy tắc [Microsoft KillTimer](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-killtimer); không phải phép đo động B.

Source: `CysHostTimers.cpp:293` dispatch theo kiểu Lua; dòng 408 giữ record theo ID; dòng 414 xóa expression đầu tiên; dòng 445 dispatch record.

## ClearAllTimer và vòng đời

`ClearAllTimer() ->` **0 giá trị**. Hủy toàn bộ ID của manager và xóa record/route. B Clear virtual0x460180 duyệt hai map native/Lua; CY manager này chỉ sở hữu các timer Lua do chính nó tạo, nên không hủy timer Windows khác của game. B destructor gọi Clear tại `timer-backend-disasm.txt:73`.

`Manager::Create(shared_ptr<Backend>)` liên kết backend bằng weak_ptr; closure Lua giữ weak_ptr trong userdata có `__gc`. Finalizer kiểm đúng metatable trước đọc userdata, có cờ ngăn giải phóng weak_ptr hai lần. Chủ sở hữu C++ quyết định vòng đời manager. Khi manager đã được giải phóng, gọi global timer báo Lua error cố định `timer manager is unavailable`; không giữ pointer treo hoặc biến mất thành thành công giả. Đăng ký chỉ điền nil, không override hàm đã có; register lần hai trả0 nếu cả ba global đã tồn tại. Gọi Register trước `LuaApiGen::RegisterAll`.

Destructor gọi Clear và không để exception thoát. Cleanup vẫn xử lý các record khác khi một backend Kill/Forget lỗi, ghi lỗi theo phase/category rồi phát lại lỗi đầu tiên cho lời gọi Clear trực tiếp; destructor bắt lỗi này. Không giữ con trỏ UI, không tự hủy theo owner khi cửa sổ ẩn/destroy. Script vẫn gọi KillTimer trong OnHiden như `Assets/Canonical/Data/InterfaceFolder/BuLaoDianTime/BuLaoDianTime.lua:153–154`.

Tạo, dùng và hủy Windows backend trên thread chạy message pump. Backend kiểm thread ở Bind/Start/Kill/Forget/Evaluate. Route weak_ptr nằm theo thread; mỗi entry có identity backend, nên timer ID tái sử dụng bởi manager khác không bị manager cũ Kill/Clear nhầm. Map route có shared ownership: TLS giữ shared_ptr và mỗi backend giữ thêm shared_ptr, nên global manager destructor vẫn dọn được map nếu TLS đã bị giải phóng lúc process exit. TimerProc giữ shared_ptr cục bộ trong khi Dispatch và xóa route/kill timer nếu owner hết hiệu lực. Destructor backend dọn route còn thuộc nó; không dùng singleton heap bị bỏ quên.

Source: `CysHostTimers.cpp:244` userdata; dòng 342 đăng ký từng global; dòng 366 Create; dòng 374 destructor; dòng 429 Clear; dòng 466 Register. Hook game đặt manager trước RegisterAll và reset trước ScriptSystem Release; không thêm Tick hay thread.

## Interface để kiểm thử và tích hợp

- Backend bắt buộc: `Start(uint32_t milliseconds)->uintptr_t`, `Kill(uintptr_t id)`, `Evaluate(owner,expression)`.
- Backend tùy chọn: `Bind(weak_ptr<Manager>)`, `Forget(id)` để bỏ route khi record bị erase, `ReportError(message) noexcept`.
- Manager: `Set(owner,expression,double)`, `KillId(double)`, `KillExpression(string)`, `Clear()`, `Dispatch(id)`.
- Windows factory: `MakeWindowsBackend(WindowsCallbacks{evaluate,reportError})`. TimerProc catches exception; reporter chỉ nhận phase/category hoặc mã lỗi Windows dạng số, không nhận owner/expression hay nội dung exception. Reporter thiếu hoặc tự lỗi có fallback stderr/OutputDebugString. Dispatcher gọi trực tiếp trong test vẫn phát lỗi Evaluate để phép thử quan sát được.

Dispatch copy owner/expression và giữ backend trước Evaluate, cho phép callback tự Kill/Clear/Set mà không giữ iterator hay chuỗi của record đã bị xóa. Chuyển/phục hồi environment nằm trong callback Evaluate của game: B nối owner + `_Env`, lưu environment cũ rồi phục hồi nếu tên cũ không rỗng. Chứng cứ `timer-backend-disasm.txt:856–890`, `timer-env-guard-disasm.txt`, `GMScriptSystm.cpp:33,1851`. Manager chỉ chuyển hai chuỗi nguyên nghĩa, không thực thi trên environment ngẫu nhiên.

## Thực thi Lua và đường lỗi trong Game

`CysHostTimerLua::Execute` là helper production được `CScriptSystem::EvaluateTimer` gọi với LuaState và trường tên active hiện có; method mới không virtual, chỉ build khi `CYS_HAVE_LUAAPIGEN`. Mỗi phase dùng LoadBuffer + PCall, tránh DoString gọi `_ALERT` không protected. Chuỗi chọn environment dùng biểu thức owner + `_Env` như B, nhưng buffer động thay MAX_PATH. Cập nhật tên active chỉ sau chọn/phục hồi thành công; trả cả lỗi chính và lỗi phục hồi riêng, không trả nội dung script/Lua error ra log.

Lỗi Lua thông thường phục hồi stack và environment cũ nếu tên cũ không rỗng; tên cũ rỗng giữ lựa chọn như B. CY còn thử phục hồi sau lỗi chọn environment vì setter Lua có thể đã đổi metatable trước khi báo lỗi; ca test kiểm metatable thật, không chỉ tên C++. Các lựa chọn checked error/buffer động/phục hồi lỗi này là phòng vệ CY, không phải hành vi trả lỗi đã đo động B.

Lua 5.0.1 hiện dùng setjmp trong `src/ldo.c:81–91`: một native binding tự ném C++ exception qua VM có thể bỏ qua cleanup của Lua. Helper nhận diện `stateUsable=false`, không gọi thêm Lua API, kể cả SetTop hoặc restore. Callback Game ghi phase/status đã loại payload, detach/clear timer và đặt cờ lỗi. MainLoop kiểm cờ ngay sau DispatchMessageW, ném lỗi cố định vào đường xử lý fatal có sẵn tại `WXClient.cpp:85` trước message/Tick tiếp theo. Exception không vượt biên TimerProc, không cố chạy Release/Lua destructor trên VM đã bị bỏ qua. Không khẳng định khôi phục được Lua VM sau native exception.

Test native exception chạy trong process test riêng rồi ExitProcess; test Game fatal/dump chưa chạy vì font P1-1. Ca callback lỗi Lua thông thường đã chạy qua Win32 → manager → Execute thật, phục hồi Old_Env và ghi đúng một báo lỗi cố định.

## Khác biệt CY có chủ ý

1. **Số ngoài miền và NaN:** `ToInt32` kiểm finite, truncate, kiểm miền int32 rồi cast. NaN/infinity/giá trị sau truncate ngoài miền → INT_MIN. B dùng `cvttsd2si` tại RVA0x460768 và0x460860; giá trị invalid với exception được mask là INT_MIN, nhưng CY không tái tạo FP flags/exception hoặc phụ thuộc MXCSR. Nguồn instruction: `timer-set-wrapper-disasm.txt:99`, `timer-wrapper-disasm.txt:27`; [Intel SDM, CVTTSD2SI](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-2a-manual.pdf).
2. **ID ngoài int32 dương:** backend giữ `uintptr_t`/UINT_PTR đầy đủ. Nếu OS trả ID > INT32_MAX, CY Kill chính ID đầy đủ đó, Forget route, log cố định và trả0. B cắt 32 bit và assert `nID > 0`; CY không tái tạo truncation ID có thể làm hủy nhầm tài nguyên. Không tạo ID thay thế.
3. **Vòng đời và lỗi callback:** weak ownership, route identity và cleanup phòng UAF là cơ chế CY. TimerProc không cho exception C++/Lua đi qua biên Win32; lỗi có log đã loại payload. Lua service errors chỉ có loại lỗi hoặc thông báo owner hết hiệu lực; không in expression/argument. Win32 Kill trả FALSE vẫn không đổi boolean Lua vì nhánh B báo true theo kiểu đầu vào.
4. **Miền sở hữu:** Clear chỉ hủy timers của manager hiện tại, không tác động timer native có sẵn ngoài adapter. Không thêm auto-cancel owner; stale records, queued callbacks và unique insertion được giữ theo B trong miền ID hợp lệ.

## Kiểm chứng

Các ca bắt buộc và 21 nhóm hành vi nằm trong báo cáo `Build/Logs/2026-09-12-gpt-p1-2/timers/implementation-plan_vi.md`; agent test sở hữu `Tests/luaapi/timer_tests.cpp` và `run_timer_tests.ps1`. Phải kiểm bằng LuaPlus thật, manager production và backend điều khiển callback; thêm Win32 smoke độc lập có message pump. Environment integration phải kiểm riêng trong CScriptSystem; mock Evaluate không thay thế bằng chứng này.

Kiểm thử cuối tại `Build/Logs/2026-09-12-gpt-p1-2/tests/timers/run-20260912-220005-6174857`: **40/40 ca chính + 1/1 native-exception child PASS**, build/run/child rc0, 0 cảnh báo, source hashes giữ nguyên. Cùng snippet 3 → 0 missing calls/3 → 0 dòng thiếu, ID37 và 2 tác dụng Lua; Win32 8 callback cùng thread, delay đầu31 ms, toàn phép đo203 ms/0 lỗi bình thường. Bộ thử chỉ compile 5 nguồn mới, không reuse object hay build 113 stub. CI source commit `cdf99a3` đã đạt33/33, stage rc0/smoke6/6/checks3/3; build13,5 s/17 bước, 15 cảnh báo cũ/0 loại mới; census5/5 không tăng (`Build/Logs/ci/cdf99a3`, `Build/Logs/2026-09-12-gpt-p1-2/timers-ci/comparison.json`); Game runtime vẫn bị chặn ở font P1-1. Không chạy B/client/server để kiểm timer.
