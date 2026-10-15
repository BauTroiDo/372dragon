# Hợp đồng danh sách GL và gửi tài khoản — 2026-09-13

Phạm vi: `GameProduceLogin`, parser danh sách UTF-8, procedure đăng nhập và nhánh NetCore thử nghiệm. Mọi đường dẫn tính từ CY-Source. Không sửa Lua/layout GL, không chạm client hoặc WSL sống. Các thay đổi nguồn cần CI Game và kiểm thử GUI của root trước khi đánh dấu kết nối Game đạt.

## Bằng chứng B

Binary đối chiếu chỉ đọc `../client_GL/Bin64/Game.exe`; SHA256 `ce0c4fec` là tiền tố của SHA đã ghi ở bộ registration. Bằng chứng LLVM tại `Build/Logs/2026-09-13-gpt-gl-login/`: `catalog-hosts.txt`, `catalog-search.txt`, `catalog-page.txt`, `catalog-recommend.txt`, `catalog-string-search.txt`, `check-account.txt`. Parser gốc: `Build/Logs/2026-09-13-gpt-login-areas/parse-list.txt`, `group-normal-area.txt`. Không chạy Ghidra mới và không thay DLL B vào Game.

| Host | RVA B | Hợp đồng phục hồi |
|---|---|---|
| GetAreaLoginServerInfo | 0x293ae0 | Trả **5**: name, status, recommendLevel, isNew số 0/1, provider. GL đọc 4 giá trị đầu. Giá trị thứ 5 không phải serverId. Server không tồn tại trả `"",0,0,0,-1`; double -1 xác minh ở RVA 0x6e6240. |
| GetServerAreaRecommendLevel | 0x293950 → 0x3ec260 parser | Số ở area+0x48, mặc định 0; section RECOMMENDAREA gồm `areaName,level`, clamp âm về 0, tên khu không tồn tại không làm phát sinh khu; bản ghi trùng lấy lần cuối. |
| SetCurrentServerPage | 0x294140 → 0x3eaa80 | Chuyển số kiểu int32 rồi lưu page tại procedure, trả 0 giá trị; không tự đổi chỉ số area/server. |
| SetLoginServerKeyword | 0x293c70 → 0x3e57c0 | Xóa kết quả trước đó, tìm tên phân biệt hoa thường, bỏ status10, loại trùng cùng area và cùng tên; keyword rỗng trả 0. |
| GetKeywordLoginServerInfo | 0x293d70 | Trả **8**: name, status, recommendLevel, isNew, rowOrdinal, normalAreaIndex, serverId, serverIndex. Sai index trả chuỗi rỗng và 7 số 0. |
| CheckAccount | 0x294460 | Kiểm trạng thái nhập tài khoản trước kiểm tham số. Arg2 là hậu tố; đọc LogOn_ID và LogOn_PassWord thật, nối hậu tố vào ID rồi gửi. B local path dùng LoginLogOn; không lấy mật khẩu từ chuỗi mask. |
| IsYunGameMobileClient / IsWeGameClient | 0x2936c0 / 0x293520 | Kiểu lần lượt boolean / number. Build CY hiện là local desktop không tích hợp hai SDK, nên trả false / 0 theo capability của build. |

Server record B: +0 rowOrdinal toàn danh sách, +4 normalAreaIndex, +0x10 name, +0x30 provider (cột2), +0x34 serverId (cột3), +0x38 status (cột4), +0x3c recommendLevel (cột5), +0x40 isNew (cột6). Row ordinal vẫn tính hàng chỉ thuộc group2 dù normal catalog không chứa hàng đó. Chỉ số nhóm/search bắt đầu 0. CYS giữ quy tắc profile nghiêm: status hợp lệ 0..4 hoặc 10; không tự đổi một số sai thành server hợp lệ. Parser B clamp status>4 về10 và có cơ chế GBK cặp byte; CYS dùng substring UTF-8 đã xác thực để không áp thuật toán cặp GBK lên chữ Việt/Trung.

## Nguồn và trạng thái thực

- `CysLoginList.*` giữ metadata cột thật; đọc recommendation tail theo schema thay vì bỏ qua. `LoginDataStructDef.h` thêm metadata cuối các struct nội bộ. Với INI legacy không có trường modern: recommendation/new mặc định0; provider lấy MERCHANT, serverId là số LOGINn và rowOrdinal n−1.
- `GamePro_Login.*` chép metadata sang catalog đang dùng. Search lưu cặp index rồi đọc server hiện tại, không giữ con trỏ qua reload; reload xóa cache. Chọn server kiểm cả chỉ số âm và status10. Sửa SetIpAddr copy đúng độ dài+NUL thay vì đọc dư 64 byte từ c_str ngắn.
- `CysHostQueries.*` cài 6 host GL nil-only, giữ receiver/metatable và host có sẵn. Lua numeric index dùng quy tắc int32 đã có; lỗi service có thông báo cố định, không đưa dữ liệu nội bộ vào Lua error.
- `GMGameinterface_Script_GameProduceLogin.cpp` dùng tuple writer chung và binding CheckAccount chung đã kiểm thử. Một tham số (kể cả hậu tố rỗng) đọc hai native editbox qua `CysUiCopyWindowTextUtf8`; hai tham số giữ đường account/password legacy. Bộ đệm 1024 byte không truncate; lỗi lookup/type/capacity làm Lua error và không submit. Secret copy được xóa bằng ghi volatile/SecureZeroMemory khi rời scope; không ghi tài khoản/mật khẩu vào log.
- `LOGIN_INPUT_ACCOUNT` được thêm cuối enum để giữ số trạng thái legacy; mở account đặt trạng thái trước phát event. Submit ngoài trạng thái này không bắt đầu kết nối. Root cần dùng cùng trạng thái khi Back từ CharSel và trong harness GL/offline.

## Nhánh Game → NetCore thử nghiệm

Chỉ bật bởi biến môi trường **của tiến trình** `CYS_WSL_LOGIN_TEST=1`; không ghi persistent setting. Trước gọi NetCore kiểm server được chọn là `127.0.0.1:15733` và tài khoản `test00`. Mật khẩu lấy từ editbox, không đặt trong tài liệu, lệnh hay profile. Khi không build target NetCore mà bật opt-in, UI báo thiếu transport thay vì rơi sang legacy.

`LoginClient` owned bởi procedure; worker chỉ socket/strict decoder, `Tick` pump event trên luồng chính. Connected → ACCOUNT_REQUESTING, Authenticated giữ procedure tới khi nhận list thật, Refused/Error quay lại INPUT_ACCOUNT và hiện lỗi; thời gian chờ do Refused trả về được giữ bằng deadline GetTickCount64 kể cả khi Back. Không retry tự động. Back/mở account/Release cancel rồi reset client: destructor có bound poll25ms theo test NetCore; reset tránh giữ Cancelled trong queue khiến lần start mới Busy vĩnh viễn.

CharacterList được kiểm dynamic type và số lượng. Danh sách **0 role thật** xóa model, đặt count0/camp−1, FirstLogin, mở CharSel và phát refresh. `ChangeToCharacterSel(false)` không gửi gói CLAskCharList legacy lần nữa; login socket đã đóng bởi NetCore trước event. Danh sách có role hiện báo rõ chưa có adapter PG → DB_CHAR_BASE_INFO/model và giữ account; không thay bằng danh sách trống. Chưa triển khai tạo role, game socket hoặc vào world trong lát cắt này.

Log chỉ ghi marker cố định (`started`, `connected`, `authenticated`, `charlist count=... tx=... rx=... closed=...`, `empty character selection opened`) và mã lỗi/số chờ. Runner root kiểm manifest/hash/endpoint trước khi bật opt-in; cờ offline cũ vẫn yêu cầu endpoint14400 và không bị nới bởi nhánh này.

## Kiểm thử

Lệnh đã chạy (Jobs2, compiler đã release):

`powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_login_area_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-gl-login/tests-3 -Jobs 2 -ReferenceList Build/Logs/2026-09-13-gpt-login-areas/reference-list.bin`

Kết quả **51/51 PASS**, build0/run0, source hashes không đổi; `tests-3/result.json`, `build.log`, `tests.log`. 29 baseline gồm reference + 21 ca GL/account + 1 ca load toàn bộ **Canonical LogOn.lua thật** và gọi LogOn_CheckAccount: chuỗi hiển thị password là dấu mask, nhưng submit nhận raw text từ production binding và hậu tố rỗng theo Lua GL. Test không sửa Lua và không kết nối socket. Bao phủ recommend/live page, 5/8 tuple, search multi-area/duplicate/hidden/UTF-8/no-match/index sai, capability types, nil-only registration, state gate, legacy2args, lỗi input và redaction exception.

Giữ `tests-1` FAIL để truy vết: fixture cũ dùng dòng `ignored` trong recommendation tail, trước đây parser bỏ qua. Sửa fixture thành schema `North,2`; không nới parser để giấu lỗi. `tests-2` 50/50 PASS trước bổ sung test Canonical. Kiểm NetCore loopback/replay do agent wsl_client ghi riêng `Docs/specs/net/00-netcore_vi.md`; các test đó không thay thế CI/link Game và GUI gửi tài khoản tới WSL thật do root kiểm.


## Harness GL qua input native

`CysGlLoginSmoke.h` dùng HWND Unicode của chính Game để gửi WM_CHAR; Tab/Back/Enter gửi cả WM_CHAR vì SendMessage WM_KEYDOWN không tự chạy TranslateMessage. Đây đi qua MessageProc của Game → CUISystem::MessageProc → ImeMsgProc → CEGUI injectChar/injectKeyDown. Mouse WM_LBUTTON đơn thuần không đủ: CInputSystem chỉ ghi tọa độ, MouseTick đọc GetAsyncKeyState nên không có button event từ SendMessage. Export POD **CysUiSmokePointer** đưa move/down/up vào đúng System::injectMouse* mà CUISystem::InjectInput dùng. Export chỉ chạy trên GUI thread khi có cờ `-cys-gl-login-smoke` và envprocess `CYS_GL_LOGIN_SMOKE=1`; không sửa cursor/async state của desktop.

Harness chọn SelectServer_Server1 rồi SelectServer_Accept bằng hit test native nếu account chưa mở; không gọi Lua hoặc đổi procedure giả. Sau đó kiểm chữ Việt/Trung WM_CHAR → raw UTF-8; select-all/backspace; Tab hai chiều và Enter chuyển focus; mở soft keyboard, click cell số ngẫu nhiên thật và kiểm raw password1 chữ số, click Back và kiểm rỗng; kéo title (-20,-40) và kiểm rect, đóng keyboard. WSL mode mới nhận secret từ CYS_BOT_PWD trong bộ nhớ và xóa env/buffer, gửi Return vào GL TextAccepted đúng một lần, chờ CharSel thật.

Runner `Tests/ui/run_gl_login_smoke.ps1` có Mode Offline/WSLTest (14400/15733), OutDir mới mặc định dưới Build/Logs, CiBin mặc định Build/cmake/ci-x64/bin và ValidateOnly. Trước launch kiểm mọi file offline_stage manifest, các binary ours trùng CI, không có exe phụ; gl_login_profile applied/files; sáu Lua/layout trùng Canonical và manifest; Noto trùng Canonical; codepage65001; config không có key trùng; endpoint của cả fallback INI và mọi slot modern đều loopback/port đúng. Runner không sửa profile và không đọc/log giá trị secret, chỉ chuyển môi trường vào tiến trình con. Sau runtime yêu cầu marker input/softkeyboard/WSL nếu bật, Game sống đủ thời hạn, không UI Error/missinghost, lưu ảnh/log/socket/JSON. Các lần chạy ValidateOnly và parser PowerShell không thay thế kiểm GUI của root.


## Đóng SelectServer: FlashMe và Flash native

Runtime `offline-fdc5342` đã nhận WM_CHAR Việt/Trung và Tab/Enter nhưng ảnh còn SelectServer che LogOn; `offline-3b09b6f` xác định soft keyboard không mở. Tại Canonical `SelectServer/SelectServer.lua:488`, close event gọi `NotFlashAreaBtnAll()` trước `this:Hide()`. Hàm tại dòng1251 gọi `FlashMe(0)` rồi `SetCheck(0)` trên16 khu thường và16 khu thử. Mapping `TLBB_ButtonCheckForServer` → `Falagard/CheckBox` → native `LUA_CONTROL::CheckButton` chưa đăng ký FlashMe. Gán LuaObject metatable native từ Window giữ bảng native khác bảng generated ImageCheckbox; vì vậy generated stub không được gọi, missing counter0 không chứng minh script thành công. DoString cũ bỏ returncode Lua nên nil method dừng handler âm thầm trước Hide. Sửa báo lỗi thực thi Lua do agent khác phụ trách.

B `UI_CEGUI.dll+0x15270` kiểm arg2 có Lua type number; `cvttsd2si` truncate int rồi chỉ int1 đặt property `Flash="1"`, số khác `"0"`, nonnumber không đổi; trả0 giá trị. CYS dùng khoảng [1,2) tương đương phép truncate==1, tránh cast số nonfinite/out-of-range. Native `FalagardButton` B constructor+0x1600 đăng ký Flash và khởi tạo mode0/counter0/direction giảm; getter+0x30b0, setter+0x3470 chỉ lưu integer không reset pha. Update+0x3540 bỏ qua hidden; BtnAnimation enabled ưu tiên, không chạy Flash. Flash khác0 tăng/giảm counter theo elapsed, clamp từng đầu [0,0.6] giây, đảo chiều rồi setAlpha(counter/0.6). Mode0 đặt alpha1 ở update tiếp theo. B bắt đầu counter0/direction giảm nên tick đầu clamp0 rồi mới đi lên. Setter không tự đổi alpha, disable/re-enable giữ pha; không timer/callback ngoài lifetime window. Window fade chạy sau updateSelf nên giữ thứ tự với StartFade. Native render dùng alpha thực, không thêm hiệu ứng giả hoặc bỏ lệnh của GL.

Nguồn: `Src/Client/CEGUISystem/{CysFlashBinding.h,UILuaControl.cpp,UILuaControl.h}`, `Src/ThirdParty/CEGUI-0.4.1/CEGUI/WidgetSets/Falagard/{include/FalButton.h,src/FalButton.cpp}`. Bằng chứng LLVM `Build/Logs/2026-09-13-gpt-gl-login/{flashme,flash-ctor,flash-update-full,flash-render}.txt`; B chỉ đọc, không dùng DLL B trong build. Thêm state ở class native; phải rebuild các DLL phụ thuộc FalButton trước chạy, không trộn DLL với ABI cũ.

`Tests/ui/flash_tests.cpp` dùng production helper, native FalagardCheckButton và callback Renderer nhận quad alpha. Test nạp toàn bộ Canonical SelectServer.lua không đổi; fixture điền32 native controls vào hai local array có sẵn qua debug upvalues và nối `this:Hide` vào native Window::hide. Negative case tháo FlashMe chứng minh actual close handler báo lỗi và native getTargetWindow vẫn nhận server; positive case nối helper thật chứng minh32 Flash0/SelectedFalse, server hidden và hit target đổi sang account. Đây là kiểm thử handler/native, chưa thay thế run Game của root. Không dùng mock Hide chỉ đếm số lần.

Lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_flash_tests.ps1 -NativeTree Build/cmake/gpt-login-ui-props -OutDir Build/Logs/2026-09-13-gpt-gl-login/flash-tests-3`. Kết quả **16/16 PASS**, build0/run0; hashes source/DLL/Canonical trong result.json. Builder native max2 jobs `build-flash-1.log` đạt22/22 edges rc0. Giữ `flash-tests-1` compile FAIL (thiếu include và API Lua5.1 không có trên Lua5.0); `flash-tests-2`14PASS/2FAIL do fixture dùng select/math.huge không có trên Lua5.0, đã sửa fixture, không nới production. Compiler và native builder đã release.


## Phụ thuộc âm thanh GL

Lượt offline28cd9dc dừng8,64giây trước ảnh: checked DoString báo native failure trong LoginSelectServer_Env. First-chance dump xác nhận23 frame đi từ Sound:PlaySound qua CSoundSystemFMod::Buffer_Create đến TDThrow, không phải FlashMe. SelectServer.lua:450 yêu cầu ID2108, trong khi stage legacy chỉ có637 dòng/max2046. Bằng chứng Build/Logs/2026-09-13-gpt-gl-login/{offline-28cd9dc,debug-28cd9dc-native,baseline-stack-native-1.txt}. Exception lúc parse TerrainTypeConfig là fallback đã biết; access violation trong TDCrashReport khi xử lý fatal là lỗi báo cáo thứ cấp, không gán thành writer của Lua.

prepare_gl_login_profile.py nay thu ID số từ Sound:PlaySound trong ba Lua GL, giữ nguyên26.276byte SoundInfo legacy rồi thêm đúng42byte dòng2108 từ Canonical (GBK, CRLF), và sao nguyên music/cangshan.mp3 (1.568.768byte, SHA256ad319cabe107c28ff7a58238375d4821d3f6796f9c667d7b1cc36b55d2fc1a1c). Không sửa Lua, không thay âm thanh bằng file khác, không bỏ callback để tránh lỗi. Schema INT/STRING/STRING; mô tả cuối có thể vắng như dòng2232 Canonical. ID trùng/xung đột, chèn sai thứ tự, path không an toàn, tài nguyên thiếu hoặc EOL khác đều bị từ chối. Phạm vi chỉ login ID2108; không tuyên bố closure mọi sound UI/world.

Plan kiểm trong RAM trên stage30a9611 đạt128file offline (trước126),131file WSL (thêm3config),6file GL giữSHA, số byte SoundInfo trước được giữ trọn. Lần plan đầu từ chối dòng2232 thiếu mô tả; sửa đúng optional trailing field. Lần kế tiếp dùng stage GL đã apply bị chặn xung đột look; đổi về baseline legacy để kiểm, không sửa stage cũ. Evidence sound-profile-check.json. Runtime sau bổ sung phải được root ghi trong báo cáo tích hợp; chưa suy ra nghe được âm thanh vì cấu hình thử đang mute.
