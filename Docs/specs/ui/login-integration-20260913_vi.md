# Tích hợp UI, Noto và WSL — 13/09/2026

## Phạm vi và dữ liệu

Người dùng cho phép sửa lỗi UI cần cho đăng nhập, để trống StrFilter, tạo tài khoản `test00`, test WSL và nhân bản server độc lập. Đã dùng ba agent với phạm vi nguồn riêng; root quản lý commit, CI, stage và GPU. Chỉ ghi trong CY-Source, ngoại trừ bản server test riêng đã được cho phép tại `/home/ubuntu/cys-test-20260913` trên WSL TLBB. Client GL, client gốc và Reference chỉ đọc.

Bản dịch GL đã được dùng: `Assets/Canonical/Data/ConfigFolder/StrDictionary.txt` và bản stage cùng SHA256 với `../client_GL/Data/ConfigFolder/StrDictionary.txt`: `4871562253b9a4f86ec53cc33c45cb3852b1aa48b0d45a3c29c0868e9f1171ce`. Reader nạp 77.582 dòng, hai khóa trùng theo chính sách dòng cuối thắng, source/display CP65001. Font là đúng NotoSansSC-Regular.ttf người dùng cung cấp; không dịch lại từ đầu hoặc chuyển toàn bộ tài nguyên GBK sang UTF-8.

Engine nguồn hiện là **CEGUI 0.4.1 có phần mở rộng TLBB**, **OGRE 1.2.5 Dagon x64**. Xem `Src/ThirdParty/CEGUI-0.4.1/CEGUI/include/CEGUIVersion.h`, `Src/Engine/OGRE/OgreMain/include/OgrePrerequisites.h`. GL/CY hiện đại dùng nhánh Fairy tùy biến; trùng số phiên bản hoặc định dạng mesh không chứng minh tương thích widget, Lua, vtable, material và DBC. EquipBase GL/server có 101 cột, DATA CY có 103; bằng chứng `Docs/01-HIEN-TRANG-VA-NGUON-LUC_vi.md`.

Chưa xác nhận được số phiên bản OGRE cụ thể của binary GL bằng bằng chứng độc lập; không gán số 1.2.5 của nguồn CY-Source cho GL. Tương thích hiện được xác minh theo từng định dạng và hành vi, chưa thể kết luận toàn bộ DATA CY dùng nguyên trạng.

Đối chiếu riêng ba cặp layout/Lua LogOn, SelectServer, SoftKeyBoard: cả sáu file Canonical trùng byte với GL. Lát cắt GL cần nạp đúng look/imageset/font và cặp layout–Lua đồng bộ; phục hồi capability/input/CapsLock, tuple danh sách server và StartFade. Ví dụ GetAreaLoginServerInfo hiện trả hai giá trị, Lua GL đọc bốn và dùng RecommendLevel để so số; chỉ chép XML chưa đủ. GetServerAreaDis đã có adapter trước RegisterAll, không còn là stub thực tế. QR/WeGame vốn ẩn ở layout GL nên không phải yêu cầu dựng dịch vụ ngoài để test đường tài khoản WSL. Báo cáo đối chiếu có file:dòng và SHA: `Build/Logs/2026-09-13-gpt-ui-properties/gl-login-gap_vi.md`.

Canonical là dữ liệu đích theo GL cộng các phần CY/HJ đã chọn. Game smoke riêng vẫn dùng layout/Lua Reference, sáu file font Canonical, từ điển GL và fixture danh sách server UTF-8; đây là profile kiểm tương thích từng phần, chưa phải chuyển toàn bộ giao diện GL vào Game. Chữ Việt/Trung đã vẽ được nhưng nhiều nhãn trong khung legacy còn bị cắt. Không xem số Error=0 hoặc có ảnh là chứng minh bố cục hoàn thiện hay điều khiển thế giới đã đạt.

## Kết quả tích hợp đã đo

Mọi thư mục ngắn trong bảng nằm dưới `Build/Logs/2026-09-13-gpt-wsl-ui`.

| Mốc | Kết quả Game | UI Error / missing host | Bằng chứng |
|---|---|---|---|
| `filter-only`, nguồn d1b2c16 | 62,42 giây, hai PNG | 573 / 3 | Baseline StrFilter rỗng nhưng từ điển legacy còn GBK |
| b636cd0 | Dừng 8,68 giây khi chuyển trang tài khoản, fatal thiếu MapImage | 23 / có sáu lượt GetDictionaryString mới | `integration-b636cd0`; dump và stack giữ nguyên |
| 3570203 | Dừng 8,63 giây, 0xC0000374 tại capture đầu | 0 / 0 nhưng mới nạp 11 layout | `integration-3570203`; PNG toàn zero không hợp lệ |
| 2a05b22, bật chẩn đoán capture | 60,44 giây, hai PNG, 28 layout | 9 / 0 | `integration-2a05b22`; chưa có bản sửa atlas |
| 5d5ece4, capture bình thường | **60,85 giây, hai PNG, 28 layout, không fatal/Lua error** | **8 / 0** | `integration-5d5ece4`; không quan sát socket |

Không xóa dấu vết lỗi trung gian. `f65e0a2` CI thất bại 35/36 do header chẩn đoán gọi logger chưa khai báo; `2a05b22` sửa bằng Win32 WriteFile và CI 36/36. Stage tạm có cờ CI FAIL đã bị prepare_game từ chối, không được chạy Game từ stage đó.

Stack 3570203 có 25 frame unwind: heap CRT → windowscodecs → WICImageCodec::encodeTo/WriteSource → Image::save → capture Render.dll. `debug-3570203-context` giữ dump gốc và context thread bị dừng; bản with-context chỉ thêm stream exception từ context đã ghi. `baseline-stack-3570203.{txt,json}` tách rõ unwind thật và địa chỉ phỏng đoán. Ba ảnh tổng hợp WIC 1024×768 (phẳng, gradient, random) được ghi rồi giải mã khớp từng byte trong tiến trình sạch: `Build/Logs/2026-09-13-gpt-login-remaining/wic-clean-3570203/result.json`, 3/3. Không thay codec vì vị trí phát hiện heap không chứng minh codec tạo lỗi.

Noto tái hiện riêng lỗi atlas có trước: U+1EA0 cao 16 tại cursor (32,241), chiều cao hàng trước 15; bản cũ ghi vượt **10 pixel canary**. Bản sửa kiểm cả hai chiều trước mọi bitmap và giữ glyph trên atlas mới, canary thay đổi **0 pixel**. Font **59/59**, widget **105/105** trên cùng DLL native; `Build/Logs/2026-09-13-gpt-ui-properties/{atlas-before,atlas-after,tests-12}`. CI 5d5ece4 **36/36**, 5,7 giây/5 bước, một cảnh báo cờ cũ. Lượt Game bình thường sau sửa đã đạt; đây là bằng chứng regression, không suy rằng mọi nguy cơ heap đã được loại bỏ.

Guard ComboBox sửa đúng caller ZhengyouSearch.lua chọn index 10 từ lúc list mới có một item. Native chỉ chọn khi đủ item, giữ nguyên Lua và Listbox core. Lỗi Listbox runtime **1→0**; không ghi nhận đã kiểm tay thao tác combo trong game. Spec `Docs/specs/lua/login-remaining_vi.md`.

Hai ảnh 5d5ece4 đã được kiểm nội dung. So baseline filter-only: server SSIM **0,8203**, PSNR **16,67 dB**; account **0,8472 / 19,76 dB**. Chữ và màu UI thay đổi có chủ đích; vùng vách núi độc lập `[32,64,110,700]` chọn trước ảnh cuối giữ nguyên từng pixel, **SSIM 1** ở cả hai trang. Ảnh trước/sau/heatmap và số đo: `images-5d5ece4`, `runtime-comparison-5d5ece4.json`. Bàn phím ảo xáo trộn ký tự giữa các lượt nên không dùng toàn ảnh làm chuẩn bất biến.

## StrFilter và máy chủ test

`Tools/data/empty_strfilter.py` giữ hai dòng schema và bỏ toàn bộ quy tắc: Canonical **134.959→0**, stage legacy **2.655→0**. Không dùng file zero byte vì DBC vẫn cần header. Có backup và SHA trước/sau trong `Build/Logs/strfilter-empty`; profile tạo lại bằng `Tools/data/prepare_login_profile.py` với endpoint giả 127.0.0.1:14400, không sửa Lua để né host.

Clone WSL chạy riêng Mongo 27018, MQTT 1884 và bốn service Skynet; login/game 15733/15734, chỉ khu 1. Không sao chép database live. Tài khoản `test00` mới có uuid100001, quyền0, chưa có nhân vật. Mật khẩu người dùng cung cấp chỉ đi qua bộ nhớ, không lưu vào báo cáo. Sáu service và 16 listener đã xác minh; status đọc bảng socket kernel nên không tạo request trống làm bẩn log.

**Đã xác thực thật và lấy danh sách nhân vật rỗng bằng CysNetBot của CI b636cd0:** flag0, 32 ms, 3 TX/4 RX, decode0, retry0, byte dở0, socket đóng. `netbot-ci-wsl/result.json`; probe độc lập trước đó 14 ms tại `Build/Logs/2026-09-13-gpt-netbot/wsl-1`. Cùng bot CI: unit **27/27 + 100.000 đầu vào fuzz**, loopback/path guard **15/15**, không rò credential fixture. Lifecycle mock **21/21**; start thật lặp lại giữ nguyên cả sáu PID. Không thử stop server đang chạy.

Server gốc có baseline tlbb-game failed và login5733 đóng từ trước; mongod/mosquitto vẫn active. Không thay đổi server gốc. Clone còn lỗi MySQL baseline ở cổng13306 do máy gốc không cài MySQL; không che log hoặc cài thêm để làm xanh. Snapshot mới `wsl-evidence-final.json` không có lỗi/traceback mới ở bốn log Skynet so với snapshot trước. Chi tiết nguồn, lệnh và cách dừng riêng bản test ở `Docs/specs/net/wsl-test_vi.md` và `Timeline/handoff/net.md`.

## Lệnh kiểm lại và phần còn dở

Từ CY-Source, dùng một commit nguồn đã CI xanh và một thư mục evidence mới:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/ci.ps1 -Sha 30a9611 -Jobs 5
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/stage.ps1 -Clean
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_game_offline_smoke.ps1 -Stage Build/gpt-p1-1-20260913/stage-30a9611 -OutDir Build/Logs/game-offline-ui/NEW -Seconds 60
wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py status
```

Stage Game riêng được tạo bởi `Build/Logs/2026-09-13-gpt-p1-1/prepare_game.py` rồi `Tools/data/prepare_login_profile.py`; script kiểm SHA và CI trước khi chạy. Không tự trỏ Game cũ tới WSL: Game vẫn dùng header/ID/body 0.85, bot dùng ProtocolGen modern. **Chưa đăng nhập WSL bằng GUI, chưa tạo nhân vật/vào thế giới, chưa hoàn tất P1-3/P1-5**. Bước tiếp theo có thiết kế tại `Build/Logs/2026-09-13-gpt-netbot/game-wsl-next_vi.md`: contract CheckAccount, NetCore thread/pump, ba gói login modern và state danh sách nhân vật.

Tại mốc 5d5ece4 còn tám Error. a2e565c phục hồi bốn thuộc tính MultiColumnList; 30a9611 nối BackgroundName từ UI qua Game tới Render bằng các export bổ sung, giữ vtable. Kết quả tích hợp cuối bên dưới.


## Mốc tích hợp cuối — 13/09/2026 09:38

**30a9611 — ĐẠT mốc sửa lỗi nạp UI và probe WSL; toàn bộ UI/NetCore chưa đạt.** Game chạy 61,41 giây, nạp 28 layout, có hai PNG hợp lệ; UI Error 573→0, missing host 3→0, không fatal/Lua error và không quan sát socket. CI 36/36, stage 33 file/22 PDB, smoke 6/6, checks 3/3; census của năm viewer không tăng. Font 59/59 và widget 126/126 chạy lại trên DLL CI; probe nền D3D9 đạt 26/26, đối chiếu 57.344 pixel không sai khác.

Bằng chứng: `Build/Logs/2026-09-13-gpt-wsl-ui/final-evidence-30a9611.json`, `integration-30a9611`, `images-30a9611`, `runtime-comparison-30a9611.json`; CI tại `Build/Logs/ci/30a9611/{summary.txt,smoke.json,checks.json}`. Spec/lệnh: `Docs/specs/ui/login-integration-20260913_vi.md`, `Docs/specs/ui/login-properties_vi.md`, `Docs/specs/ui/login-mesh_vi.md`, `Docs/specs/net/wsl-test_vi.md`.

CI 30a9611: build 16,4 giây/24 bước, 14 cảnh báo thuộc một thông báo cờ ngoại lệ cũ; không có loại mới. Checks: protocol 1.699/1.699, PathLib 488/488, scene 548/548. Lượt gọi smoke trực tiếp bằng PowerShell 7 thất bại trước GPU do thiếu System.Drawing.Bitmap; giữ `smoke-pwsh7-startup.txt`. Chạy lại bằng Windows PowerShell đã đạt 6/6. Đây là lỗi môi trường gọi runner; không sửa engine để che lỗi.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/checks.ps1
```

Game chạy 61,40925 giây với capture bình thường; tám lỗi thuộc tính còn lại giảm 8→0. Hai PNG đã xem: tiếng Việt/Trung vẽ được, nhưng khung legacy còn cắt nhãn. So baseline filter-only: trang server SSIM 0,8150/PSNR 16,30 dB; trang tài khoản 0,8472/19,75 dB. Vùng vách núi độc lập đã chọn trước giữ nguyên từng pixel, SSIM 1. Đây là kiểm vùng không liên quan, không phải xác nhận toàn bộ giao diện GL đã đạt. Màu nút/khung ảnh động và bàn phím xáo trộn có thể khác giữa các lượt.

Probe nền Mesh kiểm helper production/GPU, chưa kiểm manager/listener cùng nhân vật Game thật. Lượt Game offline không bind nhân vật; Error 0 không thay thế phép kiểm hành vi đó.

Snapshot WSL cuối `wsl-evidence-closure.json`: sáu PID giữ nguyên, 16 listener, một tài khoản, không nhân vật và không bản ghi abnormal packet. Bốn log không có error/traceback mới so snapshot 08:20. Mongo 149465, MQTT 149651, Manager 149713, DataCenter 149735, Tool 149757, Game 149801; giữ chạy bản test để tiếp tục.

Nhãn Việt còn bị cắt trong khung legacy. Game smoke dùng layout/Lua Reference với dictionary GL và Noto; chưa dùng toàn bộ UI GL. Canonical đã có ba cặp layout/Lua GL đúng byte. **NEXT:** lập profile tài nguyên GL cho đăng nhập, khớp hợp đồng host server/input, rồi nối NetCore/CheckAccount để GUI xác thực WSL. Bot xác thực riêng không chứng minh GUI, tạo nhân vật, vào thế giới hoặc điều khiển. P0-3/material và các yêu cầu ngoài phạm vi UI/test vẫn chờ quyết định như Timeline mục 5.

Ba agent đã bàn giao nguồn. Giữ chạy sáu service WSL clone được ghi trong handoff net; không sửa server gốc. Commit cuối chỉ cập nhật tài liệu; chạy CI lại trên HEAD và kiểm tiến trình trước khi kết thúc, không lặp runtime nếu Src giữ nguyên.
