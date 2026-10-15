# Kiểm thử LuaApiGen, host globals và timer

Chạy bằng LuaPlus/Lua 5.0.1 của CY-Source, hoàn toàn offline. Bộ thử biên dịch riêng các đăng ký sinh tự động, bộ đếm và `CysHostGlobals`; không khởi chạy Game.exe hay renderer.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tests\luaapi\run_tests.ps1 -Jobs 3
```

Cần có `Build\cmake\ci-x64\bin\LuaPlus.dll` và `lib\LuaPlus.lib` do CI xây trước. Trình chạy dùng MSVC đã cài, đặt TEMP/TMP trong cây build riêng, giữ mọi lần chạy trong thư mục riêng và không xóa đầu ra cũ. `-BuildDir` và `-OutDir` chỉ chấp nhận đường dẫn bên trong `Build` của repo, không đi qua junction.

31 ca kiểm tra gồm:

- Đăng ký thật `RegisterAll`, lượt gọi lặp, mỗi tên chỉ ghi log lần đầu, phân biệt receiver, truy vấn không làm đổi bộ đếm, reset và các giá trị trả về trung tính.
- Sắp xếp theo số lượt giảm dần rồi tên tăng dần; mặc định 20 hàm, giới hạn 0/3/100 trên 25 hàm với 350 lượt gọi.
- Giữ hàm và giá trị đã đăng ký, kể cả hàm trong metatable của receiver.
- Format đóng gói byte theo helper B `Game.exe+0x619670`, không tra từ điển hoặc thay placeholder tại host: vector `#{K}`, `Q` trả `23 7B 4B 2A 01 06 2A 01 51 7D`; 15 tham số; độ dài metadata một byte; padding khi block tham số dài 56 byte; input/output theo C-string; UTF-8 được giữ nguyên trong payload.
- Giới hạn CY có chủ đích: từ chối template C-string rỗng trong nhánh có tham số và từ chối đầu ra vượt 1.024 byte tính cả NUL; kiểm tra sát biên 1.023/1.024 byte nội dung. Không sao chép lỗi tràn bộ đệm của B.
- Truyền sự kiện, dừng tham số ở nil/kiểu không hỗ trợ; đóng cửa sổ với cờ boolean; cô lập callback giữa hai Lua state.
- Thiếu dịch vụ hoặc callback ném ngoại lệ trở thành lỗi Lua bắt được bằng `pcall`.
- Cùng một đoạn Lua gọi ba hàm 5 lần: bản stub có 15 lượt thiếu và 3 dòng log; đăng ký host thật trước stub có 0 lượt thiếu, 0 dòng thiếu, đủ 10 tác dụng phụ event/close qua callback thử và kiểm đúng cả 5 chuỗi Format trả về.

`tests.log` ghi từng ca và dòng `BEFORE_AFTER`; `result.json` ghi mã thoát build/run, đường dẫn exe/log, số nguồn, mức song song và SHA-256 LuaPlus.dll. Phép đo trước/sau này là kiểm thử đơn vị offline, không thay cho số đo smoke của Game.exe. Các lỗi Lua trong ca dữ liệu sai là lỗi được chủ động kiểm tra; ca bình thường và đoạn Lua trước/sau phải không có lỗi.

Vector kỳ vọng được viết trực tiếp từ cấu trúc của helper B đã phục hồi, không gọi bộ đóng gói của implementation để sinh expected. Chưa chạy B để lấy kết quả động. Bộ thử host không xác nhận UI đã giải được metadata này; decoder của UI cần kiểm chứng riêng. Bằng chứng helper: `Build/re/luaapi/gpt-p1-2-helpers/decomp/140619670.c` và `Build/Logs/2026-09-12-gpt-p1-2/timers/recovered-helpers_vi.md`. Kết quả 26 ca cũ dùng callback từ điển chỉ là trạng thái thử trước khi phát hiện helper; không dùng làm bằng chứng tương đương B.

Kiểm thử riêng decoder UI, không biên dịch lại LuaApiGen:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tests\luaapi\run_packed_format_tests.ps1
```

34 ca dùng header `CysPackedFormat.h`: vector B, UTF-8 và GBK nguyên byte, metadata dài hơn 127, block length quay vòng, padding, dấu ngoặc trong tham số, biểu thức lồng, dữ liệu cắt cụt, lỗi giữ nguyên toàn bộ input, giới hạn sâu 16 tầng/4.096 biểu thức/1 MiB và 10.000 ca byte lỗi ngẫu nhiên với seed cố định. Decoder nhận `%s0`…`%s9`, `%sa`…`%sf`; token thiếu tham số được giữ nguyên; key không có chỉ làm mất nội dung envelope đó, còn các đoạn khác được giữ. Ca tích hợp gọi LuaPlus thật → `CysHostGlobals::Register` → `ScriptGlobal_Format('#{ZNDB_230215_157}',42)` → decoder → template Canonical 45 byte → output đúng 44 byte, giữ mã màu và tiếng Việt. Exe này chỉ biên dịch 2 nguồn cùng LuaPlus đã có, không cần 113 file stub. Đây là kiểm thử trước bước render UI, chưa phải ảnh hoặc smoke Game.exe.

Ba hành vi placeholder/unknown key trên được đối chiếu với body reader lịch sử `C:\TLBB\085\analysis\ghidra\resolver-out\resolver_FUN_180030640.c:2403` và dòng 2411–2427 (chỉ đọc). `%sa`…`%se` thay các tham số 10…14; `%sf` giữ nguyên với tối đa 15 tham số của host. `%%s0` thành `%` cộng tham số 0, chữ hoa `%sA` không đổi. Không có callback resolver là lỗi dịch vụ `missing-resolver`, khác với callback có nhưng trả “không tìm thấy key”.

Kiểm tra đường truyền owner của event trên x64:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tests\luaapi\run_event_owner_tests.ps1
```

5 ca dùng header thật: owner số 42, token có bit 40, địa chỉ heap và chữ ký `RegisterEventHandle` của cả interface lẫn lớp triển khai. Token đi qua `EVENT_DEFINE::REGISTER_STRUCT` và callback thật. Tùy chọn `-BeforeRoot` nhận cây snapshot header cũ để tái hiện lỗi; chế độ đó yêu cầu bản cũ trả rc1 và bản mới trả rc0. Không sửa hoặc liên kết lại các DLL của CI.

Kiểm thử timer và môi trường script bằng LuaPlus thật:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tests\luaapi\run_timer_tests.ps1 -Jobs 3
```

40 ca chính dùng `CysHostTimers` và `CysHostTimerLua::Execute` production. Backend giả chỉ cấp ID, ghi nhận thao tác OS hoặc điều khiển lỗi; state machine, Lua wrapper, chuyển/phục hồi environment và kiểm tra stack đều là mã thật. Runner biên dịch 5 nguồn: test, timer manager, checked helper và hai file generated Common/Globals; không tái dùng object cũ hoặc xây 113 file stub.

- Cùng một snippet gọi ClearAllTimer/SetTimer/KillTimer: 3 lượt thiếu và 3 tên trước → 0 sau; ID backend 37 được trả thật, hai Dispatch làm biến Lua tăng hai lần.
- Kiểu đối số và số giá trị trả về; C-string cắt NUL; ms cắt phần lẻ sang int32 rồi truyền bit UINT; NaN/vô cực/ngoài miền theo policy INT_MIN. Không mô phỏng FP exception/flags của B.
- ID 0 thất bại; ID `0x10000001234` bị từ chối nhưng được hủy đầy đủ 8 byte; giới hạn int32 dương. Hai timer trùng biểu thức cùng tồn tại; backend tái dùng ID vẫn giữ record cũ theo insert unique của B.
- Kill theo số giữ record/route để callback đã xếp hàng còn chạy; Kill theo chuỗi chỉ xóa match đầu tiên theo ID unsigned, không đổi hoa/thường, khoảng trắng, dấu `()` hay parse chuỗi số. Có ca timer chết ở ID nhỏ đứng trước timer sống cùng biểu thức.
- Callback tự hủy, Clear rồi thêm timer; Clear tiếp tục giải phóng các route khi backend báo lỗi; destructor không ném lỗi; closure yếu hết hiệu lực khi manager bị hủy; userdata sai loại không bị đọc như timer handle; đăng ký chỉ vào nil và cô lập hai Lua state.
- Production checked helper chọn `owner + '_Env'`, phục hồi tên/metatable cũ khi cần; giữ stack cả khi expression trả nhiều giá trị hoặc lỗi cú pháp/runtime. Kiểm tra select đã đổi metatable rồi báo lỗi, lỗi expression cùng lỗi restore, owner không có environment và tên cũ rỗng. Chỉ phase/status được báo ra, không đưa expression hoặc payload lỗi vào log.
- Hai ca Win32 trong exe riêng tạo timer 0/1 ms, pump thông điệp có giới hạn, xác nhận mỗi timer lặp ít nhất hai lần trên thread tạo timer, rồi clear/shutdown không còn gọi Lua. Ca lỗi đi qua `Execute` thật trước khi TimerProc bắt và ghi loại lỗi. Mỗi ca có giới hạn 2 giây; runner chặn cả process nếu quá 5 giây.

Một ca bổ sung chạy process riêng với `--native-exception-child`: C++ exception xuyên VM phải cho `stateUsable=false`, status -1 tại phase `expression-call`. Process thoát ngay bằng ExitProcess, không gọi lại Lua API hoặc destructor của LuaState đã hỏng. Kết quả này xác nhận chính sách ngừng sử dụng VM, không chứng minh VM có thể phục hồi.

`result.json` timer ghi mã build/run/process phụ, hash 8 nguồn/header và kiểm nguồn không đổi trong lượt chạy; log riêng giữ đủ 40 ca và ca ngoại lệ. Bằng chứng ngày 12/09/2026: `Build/Logs/2026-09-12-gpt-p1-2/tests/timers/run-20260912-220005-6174857/`: 40/40 + 1/1 đạt, build/run/child rc0, không warning; Windows 8 callback thường, 1 callback Lua lỗi được phục hồi và báo lỗi. Đây là kiểm thử offline trước tích hợp Game; không thay cho CI/renderer, không chạy binary B hoặc server.

## Phím tắt P1-2

`powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_hotkey_tests.ps1 -Jobs 3` chạy LuaPlus thật và 24 ca trên các thân hàm Game được trích nguyên từ source. Test doubles thay thiết bị/UI/đồ họa; chưa phải input OS hoặc smoke Game. Cùng Lua: missing 1→0 và thao tác F1 lúc bị khóa 1→0. Spec, giới hạn và manifest nguồn: [hotkeys_vi.md](../../Docs/specs/lua/hotkeys_vi.md).

Kiểm thử biến thoại CY (`$N $n $U $G $g $R $r`, header `Src\Client\CEGUISystem\CysDialogVars.h`, theo UI_CEGUI.dll CY `FUN_18004a5e0`), chỉ biên dịch một nguồn:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tests\luaapi\run_dialog_vars_tests.ps1
```

23 ca tổng hợp (tên mình/mục tiêu, giới tính nam/nữ/không rõ, thiếu khoá, biến lạ chỉ bỏ `$`, `$` cuối chuỗi, UTF-8, khoảng bảo vệ `#{_INFOMSG…}` / `#{…*?<độ dài>…}`) + 1 ca trên StrDictionary CanonicalCY thật. Đặc tả: `Docs\specs\net\npc-quest_vi.md` mục 7.
