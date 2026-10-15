# DataPool:SetCanUseHotKey — P1-2, 12/09/2026

## Contract và bằng chứng

`DataPool:SetCanUseHotKey(value)` nhận NUMBER ở đối số 2, cắt phần lẻ về int32, trả 0 giá trị. Thiếu đối số, nil, boolean, chuỗi số và kiểu khác đều không làm gì. Giữ giá trị số nguyên, chỉ 0 là khóa; mọi giá trị khác 0 là mở. B: wrapper Game.exe RVA `0x26d540`, field DataPool `+0x7b2d0`, reader `0x43416f` kiểm bằng 0 trước nhánh Escape/dispatch. Các điểm init/reset của B và giới hạn suy luận được ghi trong `Build/Logs/2026-09-12-gpt-p1-2/next-hosts/followup-plan_vi.md`, mục 4. Không có lần chạy binary B mới trong đợt này.

`CysHostHotKeys` đăng ký trước `LuaApiGen::RegisterAll`, chỉ điền method nil của metatable riêng trên userdata DataPool đã có. Không thay receiver, metatable, __index hoặc method non-nil. Descriptor callback được sao vào closure; adapter Game tra CInputSystem đang sống, cùng luồng chính. Lỗi thiếu service hoặc ngoại lệ dịch vụ thành Lua error cố định sau C++ unwind, không ghi payload. NaN/Inf/ngoài miền chuyển thành INT_MIN theo chính sách phòng vệ CY đã dùng cho timer/query; không mô phỏng FP flags của B.

## Nối vào mã Game hiện tại

- Trạng thái thuộc `CInputSystem`, khởi tạo bằng 1. Không thêm field vào struct DBC, không đổi vtable/interface hoặc packet.
- `CGamePro_Main::ProcessInput_Keybord` hỏi gate cho cả keydown và keyup trước switch gameplay, sau các gate renderer/death và sau routing UI/capture trong `CInputSystem::Tick`. Khóa áp cho thanh F1–F10, các shortcut cửa sổ, camera, Escape và các thao tác bàn phím của procedure Main.
- `Tick` vẫn đưa input cho UI trước và vẫn gọi phần chuột; nhánh ICS_UI/ICS_GAME, event đã xử lý, first-active giữ nguyên. Code `CEGUIIme.cpp` xử lý WM_CHAR/WM_KEYDOWN/WM_KEYUP và đường chụp màn hình WM_KEYUP/VK_SNAPSHOT không bị sửa. Việc gửi chat/Escape của procedure Main bị khóa cùng shortcut; đây không phải khóa nhập ký tự toàn cục.
- Đặc điểm nguồn 0.85: `MainMenuBar_DoAction(index, FALSE)` **thực thi** action, không phải chỉ dọn trạng thái nhấn. Vì vậy khi khóa giữa một lần nhấn, `MainMenuBar_CancelPrepare` chỉ gọi `DoActionPrepare(FALSE)`. Gate giữ dấu lần thả bị chặn kể cả khi mở khóa trước khi thả; lần nhấn mới hoạt động bình thường. Chốt toàn bộ dấu thả trước callback để ngoại lệ hủy không làm lọt action. Đây là biện pháp tương thích với đường thực thi lúc thả của CY, không khẳng định B có cùng cơ chế latch.

Không triển khai một phần `EnterQuitWait`, `CancelQuitWait`, `AskRet2SelServer` chỉ để giả reset. Chúng vẫn là stub và cần state machine/giao thức riêng. Trạng thái mặc định được tạo lại khi CInputSystem được tạo; khi dựng luồng thoát/đăng nhập lại thật phải nối các reset đã có bằng chứng B. Không tự reset mỗi frame/scene vì sẽ vô hiệu hóa hộp thoại đang giữ khóa.

## Kiểm chứng

Chạy `powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_hotkey_tests.ps1 -Jobs 3` từ gốc CY-Source.

Runner lấy **nguyên thân hàm** dispatcher bàn phím, Tick, setter, gate adapter và hai hàm ActionSystem từ source hiện tại bằng `extract_hotkey_dispatch.py`, rồi biên dịch với test doubles của các dịch vụ. Cả enum phím/input cũng lấy từ header thật; manifest ghi SHA256 nguồn và phần trích. Không sửa source để chèn chế độ test, không viết lại switch bàn phím trong test. LuaPlus và wrapper là mã thật, backend đồ họa/UI/action object/thiết bị là doubles.

24/24 ca đạt, build/run rc0, 0 warning; bằng chứng `Build/Logs/2026-09-12-gpt-p1-2-resume/tests/run-20260912-230701-6312409/{result.json,tests.log,build.log}`. Cùng Lua `DataPool:SetCanUseHotKey(0)` và cùng cặp nhấn/thả F1: đăng ký stub → missing 1, dòng thiếu 1, action thực thi 1; đăng ký host thật trước stub → cả ba bằng 0. Các ca khác kiểm đủ 10 phím F, khóa giữa nhấn/thả, mở lại, giá trị âm/lẻ/biên, kiểu sai, Escape, camera repeat, capture, IME focus/modifier, chết, first-active, non-override, ngoại lệ callback và thiếu service.

**Giới hạn:** đây là kiểm thử source với dịch vụ thay thế, không phải Game.exe render, input OS hoặc gõ tiếng Việt thực tế. Game smoke P1-1 vẫn bị font chặn; không nhận kết quả này là đã vào thế giới hoặc đã hoàn tất toàn P1-2. CI/build, stage, viewer smoke và ba cổng tích hợp được ghi theo commit trong Timeline.
