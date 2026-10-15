# Font Noto Sans SC và UTF-8 trong CY-Source

Theo yêu cầu ngày 12/09/2026: “Dùng font này để hiển thị vừa tiếng trung vừa tiếng việt NotoSansSC-Regular.ttf utf8”. Mốc font hoàn tất; P1-1 tới màn đăng nhập vẫn chưa đạt.

Font người dùng cung cấp ở gốc repo và bản runtime `Assets/Canonical/Data/InterfaceFolder/Schema/NotoSansSC-Regular.ttf` giống toàn bộ byte: 10.559.284 B, SHA256 `d45f67f0a7c0ca3f256950777ce6a61cc7ce5f9696d02900cbbaac25f8aa7d16`. Giữ font nhị phân ngoài git như các tài nguyên Assets. Không tải/cài font khác, không sửa client_GL hoặc server.

## Cấu hình và đường nạp

Trong `WXSystem.cfg` của bản chạy CY, đặt:

```ini
[Variable]
System_CodePage=65001
```

Các khai báo `.font` Canonical đã có biến thể `CodePage="65001" Type="FreeType" Filename="Schema/NotoSansSC-Regular.ttf"`. Giữ tên mà layout đang gọi (SongTiBmp12, YouYuan…, GLFit…), để tất cả 15 tên dùng cùng Noto ở cỡ tương ứng. Không bật GLResponsive. Cỡ lẻ vẫn theo cách đọc số nguyên của engine cũ; đợt này không sửa kích thước/bố cục.

- `4e65ff8`: FontManager đọc cả `<Font>` cũ và `<Fonts>` có nhiều ngôn ngữ, chọn **một** CodePage trước khi tạo backend. Type trong biến thể đã chọn quyết định Bitmap/FreeType; điều này cần cho SongTiBmp12 dù scheme ghi Bitmap. Thiếu biến thể, trùng biến thể, tên không nhất quán hoặc XML sai phải báo lỗi; không tự chọn ngôn ngữ khác.
- UI truyền System_CodePage vào FontManager trước loadScheme; viewer dùng cùng code page với văn bản. Setter không reload font đang tồn tại. Callsite cũ thiếu cấu hình vẫn giữ mặc định 936; bản chạy UTF-8 phải giữ cấu hình trên.
- FreeType chọn charmap Unicode rõ ràng và dọn face an toàn sau lỗi. Font chưa tạo xong không được đăng ký trong manager.
- `ff0d20e`: Noto này thiếu glyph dấu rời U+0302,0303,0306,0309,031B,0323. Nhãn hiển thị và mục danh sách ghép Unicode về NFC bằng Windows NormalizeString trước khi tìm glyph. Các mã điều khiển 32-bit của TLBB được giữ nguyên và ngăn cách đoạn chuẩn hóa. Không sửa byte tài nguyên, tên window hoặc cột khóa GBK.
- Giá trị Editbox/MultiLineEditbox giữ nguyên, gồm mật khẩu và vị trí con trỏ. Kiểm tra này dành cho **hiển thị** nhãn/danh sách; chưa chứng minh gõ/IME trong Game hoặc hỗ trợ mọi dấu Unicode đứng riêng. Chữ Việt NFC và chữ Trung dùng trực tiếp Noto.

## Kết quả kiểm chứng

`Build/Logs/2026-09-12-gpt-font/final-evidence.json` tổng hợp bằng chứng. Mã nguồn cuối `ff0d20e`:

| Kiểm tra | Trước → sau |
|---|---|
| Viewer strict, không adapter | 0/15 → 15/15 font nạp thật; 15 → 0 thất bại |
| Lỗi khởi tạo CEGUI của viewer | 32 → 2; còn lỗi tooltip và ảnh đã có, không che giấu |
| Ảnh NFC, 1024×768 | Giống từng pixel với baseline viewer dùng adapter; SSIM=1, PSNR=99 dB |
| Ảnh NFD | Trước sai/ô vuông → sau giống từng pixel với NFC; SSIM NFD trước/sau=0,935811, PSNR=20,50 dB |
| Vùng ngoài các hàng chữ Việt | 525.132 pixel giữ nguyên, SSIM≈1 ≥0,99 |
| Unit engine | 41/41; build/run0,0 cảnh báo; Expat/FontManager/FreeType thật, renderer bộ nhớ |
| Unicode | 140 lần dò glyph đạt; 90 chữ có dấu U+1EA0–1EF9 chuyển NFD→NFC đúng; metadata TLBB và astral giữ nguyên |
| CI tích hợp | 33/33, 19 bước/11,5 s, 2 cảnh báo cờ ngoại lệ cũ/0 loại mới; stage0, smoke6/6, checks3/3, census5/5 giữ nguyên |

Unit cuối: `tests-20260912-233400-8505893/{result.json,tests.log,build.log}`. Fixture Editbox chỉ thay phần hit-test hình học và dùng factory DefaultWindow có sẵn; kiểm giá trị gọi thân Editbox/Window thật, không phải thử IME. Lần đầu 35/36 phát hiện dấu rời thiếu; vì vậy thêm xử lý NFC và ca NFD tương đương, không tuyên bố font có glyph dấu rời. Lỗi biên dịch fixture abstract Editbox và lần 40/41 thiếu factory vẫn giữ log, đã sửa fixture trước kết quả cuối.

Ảnh thật từ D3D9: `multilingual-after-ff0d20e/shots/multilingual.png` và `multilingual-nfd-after-ff0d20e/shots/multilingual-nfd.png`; bản trước trong `before-adapted-3`, `before-strict-3`, `nfd-before-4e65ff8`. Lượt thử layout chưa đúng ở các thư mục trước đó không dùng làm chứng cứ đạt.

## Game offline và điểm chặn kế tiếp

Cặp stage riêng `Build/gpt-font/stage-baseline` / `stage-after` dùng cùng dữ liệu baseline Reference và cùng byte font Canonical; cùng cấu hình UTF-8, Game.exe của CY với `-fl`, login giả 127.0.0.1:14400. Không phải bản di chuyển đầy đủ dữ liệu UI. Bản baseline `a21f831` dừng ở `<Fonts>` (7,045 s); bản `ff0d20e` nạp đủ **4/4 font startup**, xác nhận UI code page65001, rồi dừng ở `Schema/BeHit.layout.xml` (7,089 s). Cả hai rc0 nhưng có exception/0 ảnh đăng nhập; không nhận rc0 là thành công.

`BeHit.layout.xml` không có trong Interface Canonical hoặc Reference đã tìm. Dump cuối được unwind bằng DbgHelp/llvm-symbolizer local, 13 frame, PC thuộc module dump và SP tăng hợp lệ: `WindowManager::loadWindowLayout` → `CBeHitBoardManager` → `CUICreatureBoardSystem::Initial` → `CUISystem::Initial`. Evidence `baseline-stack-after-ff0d20e.{json,txt}`, `smoke-after-ff0d20e/tmp/dmp104.tmp`; DLL/PDB đúng ở stage-after. Font không còn trên đường lỗi.

Lượt có tên `smoke-font-before` thực tế đã dùng4e65ff8 vì CI stage cập nhật trước khi sao chép; manifest ghi đúng SHA và **không dùng nó làm baseline**. Baseline hợp lệ được chạy lại bằng a21f831. Top20 Lua Game vẫn UNAVAILABLE vì khởi tạo UI chưa xong. Bước sau cần chốt đường nạp/layout BeHit theo UI hiện đại và xử lý phụ thuộc tiếp; không bỏ lỗi để báo login đạt.

## Chạy lại

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/fonts/run_font_tests.ps1
# Chạy từ Build/Client/Bin64 sau CI stage, dùng Out mới để giữ chứng cứ:
.\CysUiViewer.exe --ui C:/TLBB/085/CY-Source/Assets/Canonical/Data/InterfaceFolder --ui C:/TLBB/085/CY-Source/Tests/fonts --data C:/TLBB/085/CY-Source/Assets/Canonical/Data --layout multilingual.layout.xml --strict-fonts --size 1024x768 --no-dict --out C:/TLBB/085/CY-Source/Build/Logs/font-recheck-nfc
# Đổi layout thành multilingual-nfd.layout.xml và dùng Out khác để kiểm dấu rời.
```

So ảnh bằng `Tests/oracle/compare.py`; tổng hợp lại bằng `Build/Logs/2026-09-12-gpt-font/verify_final.py`. Stage/smoke/unwind riêng có script và manifest trong cùng thư mục log. Không chạy viewer khi đang link DLL. CI nguồn ff0d20e đã hoàn tất; commit tài liệu/test fixture cuối chỉ cần ci.ps1 build-only vì không đổi nguồn runtime.
