# P1-1: BeHit và UI đăng nhập offline — 13/09/2026

Mốc smoke P1-1 **ĐẠT theo DoD trong file giao việc** trên nguồn `bb67e6a`: Game.exe x64 tự vẽ màn nhập tài khoản, sống 61,20 giây, không có lỗi chết trong WXClient.log, có bộ đếm host thật. **Nội dung nhãn và toàn bộ UI chưa đạt**: bộ lọc 0.85 thay nhiều nhãn bằng câu cảnh báo màu đỏ. Đây không phải bản đã đăng nhập server hay hoàn tất P2-6.

## Phạm vi được giao

Người dùng mở phần UI cần cho đăng nhập: “Có, mở phần UI cần cho đăng nhập”. Ngoại lệ đã ghi trong Timeline §5; chỉ ghi trong CY-Source, thử offline. Dùng đúng `NotoSansSC-Regular.ttf`, CP65001. Không sửa client/client_GL, Reference, server, Assets hoặc cột khóa tài nguyên GBK. Không nhập tài khoản/mật khẩu, không cài phần mềm, không chạy binary B.

## Thay đổi và bằng chứng

| Nguồn | Kết quả |
|---|---|
| `2c62d58` | Đọc BeHit.txt 20 cột thay đường layout cũ khi scheme có TLBB_BeHitBoard; giữ nhánh legacy. |
| `48ede6f` | Bộ đếm lúc vào MainLoop và khi ném lại lỗi UI; ghi ngoại lệ phạm vi. |
| `4367d96` | Native Falagard/Star cho ChatFrame, chữ/nền/ảnh sao, vòng đời và reset. |
| `4b0d76e` | Native AnimateImage, AnimateButton, SafeIMEEditBox; DisableCopyPaste; Lua Play dùng cross-cast có kiểm tra. |
| `81557ef` | Cờ thử UI offline, chọn server giả qua hàm thật; sửa vòng lặp giảm giới hạn ô nhập. |
| `0b6e3eb` | 30 ca widget và bản đầu capture; **CI lỗi** thiếu include OGRE ở Game. Không dùng binary của commit này để chứng minh. |
| `bb67e6a` | Đặt capture ở Render.dll, giữ ranh giới plugin; CI và các cổng cuối đều xanh. |

### BeHit

- B UI_CEGUI.dll SHA256 `344628121ed7068a45a70dd4bf6732f4c68d01916cbb3a226ae0d7be10e93f73`, phân tích cục bộ read-only. Constructor RVA bd60 đọc DBC182; c550 chọn biến thể; cca0 tạo TLBB_BeHitBoard; d310 reset; d6b0 cập nhật. Disassembly và IAT/string annotations trong `Build/Logs/2026-09-13-gpt-p1-1/ui-behit-range.txt`, `behit-reset.txt`, `behit-update.txt`.
- Đọc typed 20 cột, yêu cầu ID cơ sở 0..8; reload lỗi giữ bảng trước. ID+100 là biến thể xen kẽ, không phải offset mảng +10. Dữ liệu Canonical có14 dòng; baseline thử Game có12 dòng. Giữ thời gian hold/fade, vận tốc/gia tốc, màu thường/chí mạng, scale chí mạng; tối đa100 cửa sổ hoạt động.
- 38/38 ca native: actual Canonical, golden chuyển động/alpha/scale, biến thể, hết thời gian, thời gian0, schema/số/màu/ID lỗi và reload nguyên tử. Chưa đo ảnh số sát thương trong combat thật.

### Widget đăng nhập

- Star là triển khai CY theo thuộc tính layout, **chưa chứng minh parity toàn bộ hiệu ứng B**. Giới hạn4096 hạt, kiểm số hữu hạn, khoảng/chu kỳ/số lượng; vẽ nền ba phần và chữ, phát ảnh sao, reset/hết thời gian. Không dùng một widget trống để vượt lỗi nạp.
- AnimateImage dùng StaticImage và tài nguyên AnimateManager; Play(false) xóa ảnh, Play(true) bắt đầu lại, alpha khung nhân với alpha gốc mà không tích lũy qua các lần vẽ. AnimateButton giữ nền nút và thao tác của FalagardAnimate. Khởi tạo alpha/timestamp của Animate cũ.
- SafeIMEEditBox kế thừa IME thật, che chữ và DisableCopyPaste mặc định. Ô tên đăng nhập cũng nhận thuộc tính DisableCopyPaste từ layout. IME kiểm thuộc tính trước cả copy/cut/paste; test không truy cập clipboard Windows.
- Giá trị nhập Trung–Việt và chuỗi NFD được giữ; con trỏ tính theo code point. Giới hạn vẫn dùng đơn vị `mbcs_length` lịch sử của TLBB, **không gọi đó là số byte UTF-8 hoặc số ký tự Unicode**. Chỉ sửa điều kiện vòng lặp khi hạ giới hạn, không đổi quy ước protocol.
- Lua animation gọi IFalagardAnimate bằng dynamic_cast: StaticImage và Button có vị trí base khác nhau. Test cross-cast qua DLL trên cả hai loại.
- Native widget **30/30**, build/run0, không cảnh báo: `Build/Logs/2026-09-13-gpt-p1-1/tests-20260913-005428-6756867`. Có kiểm quads/alpha thật, phát/hết hạn/reset, nhập `中ế`, caret2, giới hạn, masking và chính sách clipboard. Không thay kiểm thao tác trong thế giới bằng những ca này.

### Font và viewer

- Dùng đúng font người dùng đưa: SHA256 `d45f67f0a7c0ca3f256950777ce6a61cc7ce5f9696d02900cbbaac25f8aa7d16`. 41/41 ca font chạy lại trên CEGUIBase cuối, 140 probe glyph; log `Build/Logs/2026-09-12-gpt-font/tests-20260913-005437-4597761`. Noto/NFC và giữ nguyên ô nhập không thoái lui.
- CysUiViewer dùng **Canonical đầy đủ**, strict-fonts, no-dict, baseline none: ChatFrame35 cửa sổ/31 lỗi thuộc tính; LogOn74/26; MainMenuBar135/127. Cả3 có PNG, không fail load; trước Star/SafeIME/AnimateImage thiếu factory. `Build/Logs/2026-09-13-gpt-p1-1/viewer-4b0d76e/layouts.csv` và `shots/`.
- Viewer no-dict hiển thị khóa, đồng thời hiển thị các nhánh con phục vụ xem layout; không coi ảnh viewer là ảnh Game. Chưa chạy lại census1.214 layout, chưa nhận P2-6 đầy đủ.

## Game: trước và sau

| Phép đo | Trước | Sau bb67e6a |
|---|---|---|
| Nạp BeHit | ff0d20e: lỗi thiếu layout | BeHit.txt12 dòng nạp được |
| Host runtime | Chưa tới đăng ký host | 7 lượt/5 hàm thực sự được gọi |
| Màn tài khoản | 0 ảnh | 1 PNG1024×768 do Game vẽ; thêm1 ảnh chọn server |
| Lỗi chết | Dump13 frame tại BeHit | Không lỗi chết qua61,20 giây; harness chủ động dừng |
| Socket được quan sát | Offline | 0 |

Ảnh cuối: `Build/Logs/2026-09-13-gpt-p1-1/smoke-bb67e6a/cys-ui-46899109-1.png` (1.180.666 B, SHA256 `ac6872e73b23f47130b2f37b7ff2610eaa83cd0aa7eea4bb5d62dd8558efd1f7`). 213.308 màu, tỷ lệ màu phổ biến nhất0,588%; đã xem ảnh thủ công và xác nhận form tài khoản. Form còn nhãn đỏ sai như đã nêu.

Game thử bằng **baseline dữ liệu Reference của các lần trước**, chỉ overlay6 file font Canonical giữ đúng byte. Không coi đây là bằng chứng đã chuyển toàn Game sang Canonical. Game nạp15 layout, font4/4. Manifest19 binary có SHA, mọi exe là bản CI của chúng ta; riêng viewer dùng Canonical.

Các lần lỗi trung gian được giữ: `smoke-2c62d58` có exit c0000374 không tái hiện khi debugger; dump C++12 frame ở ChatFrame; `smoke-4367d96` thiếu AnimateImage trong MainMenuBar, dump sau rethrow chỉ còn9 frame (log xác định widget). Đều trong `Build/Logs/2026-09-13-gpt-p1-1`, kèm WXRender.log và stack. Không suy exit0 là thành công.

**Ảnh JPG của81557ef bị loại:** PrintScreen cũ dùng front buffer/desktop, không chứng minh Game. Bản cuối gọi Render.dll qua export C, update(false), đọc DDBACKBUFFER/GetRenderTargetData rồi Present, không dùng desktop. C export trả lỗi có log thay vì ném qua /EHc; caller thất bại smoke nếu lỗi.

## Top20 thật (chỉ có5 hàm khác nhau)

| Hạng | Hàm | Lượt |
|---|---|---|
|1|GameProduceLogin:GetServerAreaDis|2|
|2|_G:SetSoftKeyAim|2|
|3|DataPool:GetProvincesNum|1|
|4|Talk:HideContexMenu4Speaker|1|
|5|_G:OpenWindow|1|

Không thêm15 hàng giả. TSV: `Build/Logs/2026-09-13-gpt-p1-1/missing-host-top20.tsv`.

## CI cuối và lệnh chạy lại

Nguồn `bb67e6a`:33/33,5 bước/7,2s,1 cảnh báo cờ ngoại lệ đã có. Stage0, smoke6/6, checks3/3 (protocol1699, PathLib488, scene548);5/5 census viewer giữ nguyên. Loop dừng00:56:46. Các số thời gian có GPU dùng chung, không suy tăng hiệu năng. Log `Build/Logs/ci/bb67e6a`. Đợt81557ef build489 bước/228,3s xuất hiện6 C4477 trong TDCrashReport.cpp chưa sửa, bên cạnh2 thông báo cờ ngoại lệ; không giấu cảnh báo hoặc sửa phạm vi crashreport để làm đẹp thống kê.

Các lệnh dưới chạy từ gốc CY-Source; chọn OutDir mới mỗi lần:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_behit_tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_widget_tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/fonts/run_font_tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_game_offline_smoke.ps1 -Stage Build/gpt-p1-1-20260913/stage-bb67e6a -OutDir Build/Logs/game-offline-ui/recheck-NEW -Seconds 60
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/ci_loop.ps1 -IntervalMinutes 1 -IdleMinutes 0 -MaxHours 1
```

`run_game_offline_smoke.ps1` kiểm đường dẫn trong Build/không junction, SHA manifest, fake endpoint, CP65001, chỉ Game của CI; cờ `-fl -cys-offline-ui-smoke` tự chọn server0 qua hàm thật, không gọi xác thực. Cuối lượt kiểm sống đủ thời gian,2 ảnh và không fatal; **vẫn phải xem nội dung ảnh**. Pipeline smoke.ps1 vẫn báo Game SKIPPED theo thiết kế của nó; không gộp lượt Game riêng vào6/6.

Để tạo stage cho nguồn khác sau CI/stage xanh: `python -B Build/Logs/2026-09-13-gpt-p1-1/prepare_game.py <hash>`; helper giữ các stage cũ và ghi manifest/font SHA. Helper chỉ ở Build, đọc baseline đã giữ; xem code trước khi dùng cho mục tiêu Canonical khác.

## Việc làm tiếp

1. P1-2: theo top20 runtime trên; giữ việc factory/DBC/Exterior trước đây trong game-layer handoff. Các host này chưa được thay bằng tác dụng giả để làm bộ đếm đẹp.
2. UI nhãn đỏ: đã xác định root cause cục bộ — `_DBC_TALK_FILTER` chỉ đọc ID/STRING, trong khi StrFilter baseline6 cột có thêm4 cột quy tắc; loader áp tất cả lên mọi chuỗi trước markup. Quy tắc ID184 chứa byte41 (`A`), flags0/2/2/0, trúng khóa `#{INTERFACE_XML_135}`; nhiều chữ số cũng trúng. Canonical dùng3 cột,134.959 dòng. Evidence `Build/Logs/2026-09-13-gpt-p1-1/filter-schema-evidence.json`.
3. Chưa phục hồi nghĩa flags/ngữ cảnh B, nên không tự bỏ các dòng hoặc tắt bộ lọc. Hai hướng: (a) **khuyến nghị** phục hồi schema/ngữ cảnh và encoding từ B rồi reader có kiểu, kiểm nhãn/chat/tên; (b) tách nguồn chữ layout/từ điển đã tin cậy khỏi bộ lọc chat, nhưng phải kiểm các đường gọi và injection trước. Đây là đầu việc nội dung UI chưa đạt, không phải lỗi thiếu glyph Noto.
4. SafeIME hiện che chữ/clipboard/input đúng phạm vi đã kiểm; không tuyên bố mã hóa bộ nhớ, chống keylogger hoặc các thuộc tính bảo vệ khác của B. BeHit/Star chưa có ảnh combat/B parity. Không mở P0-3/parser material hoặc7 việc chờ quyết cũ.

Bằng chứng tổng hợp: `Build/Logs/2026-09-13-gpt-p1-1/final-evidence.json`. Handoff và Timeline là nơi nhận việc tiếp. Commit chốt chỉ tài liệu/runner; CI build-only kiểm HEAD cuối, không lặp runtime khi source không đổi sau bb67e6a.
