# State GetCurSelectRole — 13/09/2026

`GameProduceLogin:GetCurSelectRole()` đọc slot lựa chọn được lưu riêng trong `CGamePro_CharSel`. Nó trả một số nguyên theo chỉ số bắt đầu từ 0, không phải số nhân vật và không đọc `m_iCurSelRoleDel`. Khi CharSel chưa tồn tại, binding báo lỗi native cố định, không trả kết quả thành công giả.

Mốc này phục hồi host cần thiết để Lua mở màn hình chọn nhân vật với danh sách trống. GUI WSL bc363c3 đã sống62,372889 giây và hiện SelectRole với charlist0,UI/Lua/missing0; xem spec gl-login-integration-20260913_vi.md. Regression bên dưới không chạy Game, không mở socket và không tạo nhân vật.

## Bằng chứng B

Target chỉ đọc: `../client_GL/Bin64/Game.exe`; identity đầy đủ tại `Build/Logs/2026-09-13-gpt-gl-login/role-selection-identity.json`. Các RVA dưới đây dùng image base `0x140000000`.

| Đường thực thi | Bằng chứng |
| --- | --- |
| Singleton CharSel | `+0x3dfd77` cấp `0x4d8` byte, `+0x3dfd8e` gọi ctor `+0x3f68e0`, `+0x3dfd98` lưu pointer vào `0x1409c1418`. |
| Khởi tạo danh sách trống | Ctor đặt `r12d=0` tại `+0x3f6919`; count `+0x30` nhận 0 tại `+0x3f6a38`, selected slot `+0x460` nhận 0 tại `+0x3f6a6d`. Do đó empty ban đầu là **0**, không phải -1. |
| Getter Lua | `+0x294bd0`: đọc singleton trên; `+0x294be3` lấy int `+0x460`, chuyển sang Lua number, push và return 1. Không suy ra từ count. |
| Chỉ số xóa khác state chọn | `SetCurSelect`, `+0x295e40`, đọc arg2 rồi ghi int vào singleton `+0x0c`; không ghi `+0x460`. |
| Khôi phục lựa chọn | Entry `+0x3e7256` gọi `+0x3f56d0`: đọc `Game_Account`, `Login_ServerName`, key `Idx` qua VariableSystem virtual `+0x100`; `atoi`, clamp âm về 0 rồi ghi selected tại `+0x3f5836`. Đường này không clamp theo count. |
| Khởi tạo hiển thị | `+0x3f31e0`: sau tạo thành công, count dương chọn `count-1` tại `+0x3f3244`; nhánh đọc `Idx` kiểm range và chọn 0 khi không hợp lệ, ghi tại `+0x3f33b2`. |
| Thao tác chọn | `+0x3f5270` nhận kết quả hit test, bỏ -1 và slot không đổi, phát event/camera rồi ghi tại `+0x3f52f4`. `+0x3f55c0` kiểm slot 0..2, actor hiện tại/đích và trạng thái camera; có pending/previous state `+0x464/+0x468`, ghi selected tại `+0x3f56ab`. |

Disassembly có annotation import: `role-getter.txt`, `role-delete-setter.txt`, `role-state-singleton.txt`, `role-state-construct.txt`, `role-state-entry.txt`, `role-state-ctor.txt` (hàm khởi tạo hiển thị, không phải ctor đối tượng), `role-state-select.txt`, cùng thư mục evidence trên. Dùng LLVM cục bộ; không sửa binary B hoặc tải lên bên ngoài.

## Phần đã triển khai và giới hạn

- `GamePro_CharSel.h/.cpp`: field `m_iCurSelectRole`, accessor nonvirtual `GetCurSelectRole`, `RestoreRoleSelection` clamp âm như B, `SelectRoleIndex` chỉ nhận index hợp lệ theo count và tối đa 3. Constructor khởi tạo slot 0; field độc lập hoàn toàn với deletion index.
- CY reset slot 0 khi gán account cho phiên chọn nhân vật, khi quay về account và khi nhận danh sách modern trống. Hook modern nằm ngay sau `m_iCharacterCount=0`, trước mở SelectRole. Đây là chính sách khởi tạo phiên hiện tại; chưa đọc dữ liệu `Idx` lưu theo account/server vì CY VariableSystem chưa có API tương ứng của B.
- `SelectRoleIndex` là API cập nhật **state native**, chưa nối với Lua `MoveToCharacter`, camera hay hit test. Không đăng ký stub `MoveToCharacter`. Pending animation/camera của B và chọn nhân vật modern có sẵn còn ngoài mốc này.
- `GMGameInterface_Script.h`, `GMGameinterface_Script_GameProduceLogin.cpp`, `GMScriptSystm.cpp`: declaration, binding và registration thật. Không thay vtable. Getter không sửa selection hoặc deletion.
- Không sửa Lua/layout Canonical; không thay StrFilter/font/dictionary. Mật khẩu không được đọc bởi phần này.

## Regression

Chạy từ gốc CY-Source:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_role_selection_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-gl-login/role-selection-1 -Jobs 1
```

Kết quả `role-selection-1/result.json`: **10/10 PASS**, build/run 0, source hashes không đổi, không warning. Runner dùng LuaPlus CI có sẵn, một TU, một compiler, process timeout 5 giây; output trong Build, kiểm ancestor junction, bỏ biến credential khỏi môi trường child.

Test trích xuất nguyên declaration CharSel (chỉ bỏ hai include phụ thuộc Game), ctor/state/accessors, binding và hai dòng registration từ production; manifest ghi SHA source và đoạn trích. Renderer/base procedure được thay bằng test double, không chứng minh runtime Game. Các case kiểm empty 0, đổi state 2→1 không phụ thuộc deletion, clamp âm, count độc lập, reject index ngoài range, đổi account, binding trả đúng một giá trị và báo lỗi nếu thiếu procedure.

Case cuối nạp **nguyên file** `Assets/Canonical/Data/InterfaceFolder/SelectRole/SelectRole.lua`, gọi PreLoad/OnLoad và event mở/đóng bằng LuaPlus thật. Với count 0 và selected 0, code đi tới `this:Show()` rồi `this:Hide()`; không có host `GetRoleInfo` trong fixture, nên truy cập nhầm nhân vật sẽ làm test fail. Các widget và AxTrace là double; test không chứng minh pixel, input GUI, tạo nhân vật hoặc vào thế giới.
