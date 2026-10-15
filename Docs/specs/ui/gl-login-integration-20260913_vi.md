# Tích hợp GL login, WSL test và icon — 13/09/2026

**bc363c3 đạt mốc đăng nhập bằng giao diện tới màn chọn nhân vật trống.** Game chạy offline 62,59 giây và WSL 62,37 giây; cả hai không fatal, lỗi Lua, UI Error hoặc missing host. Tạo nhân vật, chọn nhân vật hiện có và vào thế giới **chưa đạt**.

Tiếp tục từ 15523fa, giữ chỗ 902ecf8. Mọi đường dẫn Windows dưới đây tính từ CY-Source. Chỉ ghi trong dự án và clone WSL đã được người dùng duyệt `/home/ubuntu/cys-test-20260913`; client_GL, client, Reference và server gốc giữ nguyên. GPU RTX 2060 dùng chung; thời gian là số quan sát, không phải benchmark cô lập.

## Thay đổi chính

| Commit | Kết quả |
|---|---|
| a04bd18 | NetCore worker/socket riêng, main-thread pump, event sở hữu packet; 18 unit, 100.000 fuzz, 1.699 replay, 20 loopback |
| 9dff71d | Sửa writer heap CampAndStand: 16 camp, chặn ID bằng capacity; canary 11/11, mutant cũ 10/11 |
| fdc5342 | Ba cặp layout/Lua GL nguyên byte, metadata catalog, input/fade và CheckAccount đọc ô nhập thật qua NetCore |
| 3b09b6f | Ghi lỗi require trước khi ném, không bỏ lỗi Lua |
| c1cadec | Native FlashMe/Flash; handler đóng SelectServer đi hết tới Hide, 16/16 |
| 27ba618 / 28cd9dc | Checked DoString, phục hồi stack/metatable, ToggleWindow đúng scene gate; 73/73 Lua |
| 2b560a0 | Thêm đúng sound 2108 và cangshan.mp3; giữ toàn bộ byte bảng sound legacy |
| 8c32b4d | Marker VM không dùng lại được qua actual CloseWindow; checked 16/16 và hai child native |
| c348e40 | NetManager không xử lý socket legacy khi NetCore sở hữu kết nối |
| b9c7444 | TSGame.ico nguyên bản cho icon lớn/nhỏ; sửa hIcon tham chiếu nhầm dialog ID |
| 28cf7f4 | GetWindowSize native trả hai kích thước pixel truncate; 11/11, gồm SelectServerQuest thật |
| bc363c3 | GetCurSelectRole đọc state riêng, không dùng deletion index; 10/10, gồm SelectRole empty thật |

b9f40f3/a4a7103 bổ sung gate kiểm SelectRole_Frame/Create hiện và LogOn_ID/hộp chờ ẩn trước ảnh/PASS. Review phát hiện truy vấn Editbox không dùng được cho StaticText, nên bỏ đúng assert sai loại control trước khi chạy Game; không mở rộng API đọc ô nhập.

Spec chi tiết: `Docs/specs/lua/{gl-login,toggle-window,checked-execution}_vi.md`, `Docs/specs/ui/{gl-login-input,gl-login-heap-camp,window-size,role-selection-state}_vi.md`, `Docs/specs/net/{00-netcore,wsl-test}_vi.md`.

## Dữ liệu và tương thích

Profile cuối có **128 file offline / 131 file WSL**: 33 type, 31 look, 53 imageset, 3 font và 6 file GL đúng Canonical. Ba cặp được dùng là SelectServer, Logon, SoftKeyBoard; SelectRole và các UI chưa chuyển vẫn là legacy. Đây là profile hỗn hợp có kiểm phụ thuộc, chưa phải toàn DATA CY chạy được.

Dictionary GL là UTF-8, System_CodePage=65001. `NotoSansSC-Regular.ttf` giữ nguyên 10.559.284 byte, SHA256 `d45f67f0a7c0ca3f256950777ce6a61cc7ce5f9696d02900cbbaac25f8aa7d16`. StrFilter giữ header/schema: Canonical 134.959→0 rule đã chốt trước; stage 2.655→0 theo yêu cầu. GLResponsive không bật; byte khóa tài nguyên GBK không chuyển mã.

Hai descriptor MainMenuBar dùng atlas CysLegacy_CommonStaticImage để giữ ảnh legacy khi nạp atlas GL. SoundInfo giữ nguyên 26.276 byte rồi thêm đúng 42 byte dòng 2108; cangshan.mp3 giữ 1.568.768 byte, SHA256 `ad319cabe107c28ff7a58238375d4821d3f6796f9c667d7b1cc36b55d2fc1a1c`. Plan giữ lỗi schema mô tả tùy chọn ở dòng 2232 và lỗi dùng lại stage đã apply, không xóa evidence. Test đang mute, không chứng minh nghe được âm thanh.

Engine source là **OGRE 1.2.5 Dagon / CEGUI 0.4.1** cùng mở rộng TLBB đã port. Không dùng DLL GL làm dependency nhị phân; chưa chứng minh số phiên bản chính xác của DLL GL. Khả năng đọc DATA được kiểm theo schema, resource và hành vi, không suy từ số phiên bản.

## Runtime và đối chứng

Evidence gốc: `Build/Logs/2026-09-13-gpt-gl-login`.

| Lượt | Giây | Kết quả |
|---|---:|---|
| runtime-baseline15523fa | 8,72 | Heap corruption; PNG đầu hỏng, không đạt |
| offline-fdc5342 | 18,73 | Raw Unicode/focus đạt nhưng SelectServer che account; keyboard chưa mở |
| offline-3b09b6f | 19,29 | Soft keyboard failed, giữ 3 PNG |
| offline-28cd9dc | 8,64 | Sound 2108 thiếu gây native throw trước capture |
| offline-28cd9dc-sound | 62,24 | 17 layout, 4 PNG, input đủ và UI/Lua/missing 0 |
| offline-8c32b4d | 62,277947 | Cùng cổng đạt, không socket quan sát |
| wsl-8c32b4d | 19,559289 | Server auth flag0 một lần, nhưng client fatal trước connected/auth/list callback; 5 PNG |
| offline-bc363c3 | 62,588394 | 17 layout, 4 PNG hợp lệ, đủ input, không socket quan sát |
| wsl-bc363c3 | 62,372889 | 23 layout, 6 PNG hợp lệ, đúng một submit/auth/list0; 3 TX/4 RX, socket đóng |

Harness nhập “Tiếng Việt 中文” qua WM_CHAR vào HWND riêng và kiểm raw UTF-8; Tab/Enter đổi focus, bàn phím thật nhập một số rồi Back, kéo cửa sổ (-20,-40), đóng lại. Không di chuyển chuột desktop. Đã xem ảnh Unicode và bàn phím; vài nhãn/footer còn xuống dòng hoặc bị cắt.

Đã xem `wsl-bc363c3/cys-gl-86401234-character-selection.png`: panel chọn nhân vật hiện, Logon và hộp chờ đóng; không nhân vật. Artwork chữ Trung còn từ legacy, nhãn EnterGame bị cắt, nền đen vì stage chưa có scene/model nhân vật. Không nhận toàn UI hoặc skin v2 hoàn chỉnh. Static preflight kiểm 70 cặp ảnh trong 9 atlas, 11 mapping và hash 49 file, missing=[] tại `select-role-preflight.json`.

Oracle dùng ảnh cùng 1024×768, không resize, giữ _before/_after và heatmap. `images-28cd9dc-sound`: server SSIM 0,990271 / PSNR 30,33 dB; account 0,477720 / 13,18 dB; unicode 0,501257 / 13,98 dB do panel che đã được Hide. ROI cố định [32,64,110,700] đạt 1 ở server nhưng 0,914760 ở account/unicode; strip cũng chứa SelectServer bị ẩn. **Hai ROI này không gắn PASS; không đổi vùng để lấy kết quả xanh.** Hồi quy 28cd9dc-sound→8c32b4d và 8c32b4d→bc363c3: mỗi lượt cả 3 ảnh giống từng byte, full SSIM 1 / PSNR 99, ROI 1 / 0 pixel đổi. Xem `images-8c32b4d-regression` và `images-bc363c3-regression`.

## Lỗi mạng và xác nhận máy chủ

Base Tick chạy NetManager legacy trước PumpModernLogin. Trạng thái LOGIN_CONNECTING của NetCore khiến WaitConnecting dùng handle NULL/socket chưa tạo rồi ném SetSocket Error. Dump hậu-rethrow chỉ có 9 frame và MainLoop:756; WaitConnecting/chuỗi lỗi trong heuristic không được gọi là unwind stack. Luồng source và trạng thái xác định lỗi; c348e40 gate đúng chủ sở hữu socket, giữ base Tick/UI/time loop.

Lượt wsl-8c32b4d có đúng một server flag0 dù GUI chưa dispatch callback; không nhận là sai mật khẩu hay chưa auth server. Bằng chứng `review-wsl-after-8c32b4d`. Sau sửa, GUI bc363c3 nhận connected/authenticated/charlist0, mở SelectRole, đóng hộp chờ và sống đủ 60 giây.

Server window Unix [1789275153,1789275217) có **đúng một flag0**, tổng flag0 trước/sau 3→4, không cờ từ chối. Sáu service/16 listener giữ PID; test00 status0/right0/roles0, account_count1, abnormal0. Game log tăng 17.176 byte nhưng các counter error/traceback/baseline không tăng; ba log khác không đổi. Đây là keyword census, không khẳng định mọi dòng log đã sạch. Evidence `review-wsl-bc363c3/{pre-gui,post-gui,login-flags,delta}.json` và `report_vi.md`.

Clone giữ chạy Mongo 149465, MQTT 149651, Manager 149713, DataCenter 149735, Tool 149757, Game 149801. Login/game 15733/15734; Mongo 27018 và MQTT 1884 chỉ dùng bản test. Server gốc chỉ đọc; tlbb-game failed/5733 đóng là baseline. Không auth thêm hoặc sửa tài khoản sau lượt đạt. Runner kết thúc Game ở hạn 60 giây; socket login closed=1 đã xác nhận, chưa kiểm graceful Game shutdown/CGAskQuit trong world.

## Icon và kiểm chứng cuối

`TSGame.ico` giữ nguyên 161.100 byte, SHA256 `006db758cac046f6c572f64874638151e366a756902a7ba24587fc90d24b2f67`. Tám kích thước 32 bit: 16,24,32,40,48,64,128,256. Game.rc dùng cho IDI_GAME107/IDI_SMALL108; CMake theo dõi dependency ICO. Đã xem ảnh 256 lấy nguyên payload PNG của ICO.

`verify_icon.py` chỉ map exe như dữ liệu. `icon-before.json` có 3 kích thước 8 bit, không khớp nguồn mới; `icon-bc363c3.json` xác nhận 8/8 payload đúng ở cả hai group. `icon-runtime-bc363c3-wsl.json`: class WuXiaShiJie WndClass, PID27144, có hIcon/hIconSm. Lượt đọc offline trước đó tới sau khi Game đã thoát nên danh sách rỗng; giữ `icon-runtime-bc363c3.json`, không dùng làm bằng chứng thành công. Chưa suy Explorer cache đã cập nhật.

CI bc363c3 **38/38**, configure 1,8 giây, build 242,6 giây/488 edge/485 cảnh báo, chỉ hai loại cờ ngoại lệ D9025 đã có. Stage 34 file/23 PDB; smoke **6/6**, checks **3/3**: protocol 1.699, PathLib 488, scene 548. Census năm viewer không tăng so 3b09b6f. `final-evidence-bc363c3.json` và `Build/Logs/ci/bc363c3/{summary,smoke,checks}.json` là số đo cuối trên source này.

WindowSize11 + Flash16 + widget126 + font59 dùng lại với source và DLL thực sự import giữ SHA (212 ca, không gọi là chạy lại); Input23 được chạy lại trên DLL cuối vì Falagard đã đổi. Role10, Toggle73, checked16 + 2 child, camp11 và các test mạng có evidence riêng. Review hash và warning: `review-bc363c3.json`; test Input: `input-bc363c3`. Những lỗi cũ như sáu C4477 tại TDCrashReport không bị che; không xuất hiện trong build incremental này.

## Chạy lại và NEXT

Từ CY-Source, dùng thư mục mới và Windows PowerShell 5.1. Python luôn -B/PYTHONUTF8=1:

    powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/ci.ps1 -Jobs 5
    powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/stage.ps1
    python -B Build/Logs/2026-09-13-gpt-p1-1/prepare_game.py HEX_TAG
    python -B Tools/data/prepare_login_profile.py Build/gpt-p1-1-20260913/stage-HEX_TAG
    python -B Tools/data/prepare_gl_login_profile.py Build/gpt-p1-1-20260913/stage-HEX_TAG --apply --out Build/Logs/NEW-PROFILE
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_gl_login_smoke.ps1 -Stage Build/gpt-p1-1-20260913/stage-HEX_TAG -Mode Offline -OutDir Build/Logs/NEW-RUN -Seconds 60

WSL dùng stage riêng, thêm --wsl-test và Mode WSLTest. Runner preflight kiểm CI/hash/sáu file GL/font và cả bốn endpoint. Helper getpass `run_wsl_gui.py` truyền credential chỉ trong environment child; bỏ PSMODULEPATH kế thừa theo tên không phân biệt hoa/thường, chọn powershell.exe hệ thống, chặn echo fallback. Hai lỗi preflight TTY cũ xảy ra trước credential/Game; không ghi mật khẩu vào argv/file/log, không tự retry mật khẩu sai. Dump crash có thể chứa dữ liệu trong bộ nhớ: chỉ xem stack/symbol cần thiết, không xuất heap/payload.

Sau runtime chạy collect_gl_runtime.py, compare_gl_runtime.py, Tools/build/smoke.ps1 và checks.ps1. Commit tài liệu cuối chạy lại CI HEAD, không lặp Game/auth khi Src giữ nguyên.

**NEXT:** giữ session login tương tác (hiện đóng sau charlist), nối danh sách modern có nhân vật với GetRoleInfo/model/selection và UI tạo nhân vật; rồi mới gửi create thật, chọn GUID, chuyển socket game, nạp scene và kiểm di chuyển/CGAskQuit. Chi tiết dependency tại `review-wsl-bc363c3/report_vi.md`. Không dùng socket legacy hoặc trả dữ liệu giả. Toàn P1-2/3/5, P2-6, skin v2 và P0-3 parser/material vẫn chưa đạt.
