# Từ điển UTF-8 và StrFilter cho đăng nhập — 13/09/2026

`CUIStringSystem::Init` trước đây ép mọi dòng `StrDictionary.txt` thành `_DBC_STRING_DICT` ba cột. Canonical có hai cột STRING/STRING, còn stage Reference có ba cột INT/STRING/STRING và chữ GBK. Khi chọn `System_CodePage=65001`, giá trị GBK cũ bị bộ lọc UTF-8 loại byte; ép cấu trúc ba cột vào dữ liệu mới còn có thể đọc nhầm con trỏ.

`CysUiDictionary.h` đọc raw resource `StrDictionary.txt` theo hai profile rõ ràng: hai cột = UTF-8, ba cột = CP936. Chỉ chuyển **giá trị hiển thị** sang code page UI; giữ nguyên byte key và markup/placeholder. Không thử GBK khi profile UTF-8 lỗi. Dữ liệu NUL, sai cột, sai ID, encoding lỗi hoặc vượt giới hạn bị từ chối; resource luôn được trả lại provider khi parse lỗi. Dòng trùng giữ lần cuối, giống hành vi map cũ. Giới hạn phòng vệ CY: 64 MiB/file, 64 KiB/dòng, 200.000 dòng; không coi đây là hằng số phục hồi từ B.

## Dữ liệu và kiểm chứng

- Canonical: SHA-256 `4871562253b9a4f86ec53cc33c45cb3852b1aa48b0d45a3c29c0868e9f1171ce`; **77.582 dòng**, 2 key trùng, UTF-8. Ba dòng key/value rỗng vẫn là record hai cột; phép đếm sơ bộ dùng `strip()` đã bỏ nhầm chúng và ra 77.579. Test cuối đếm theo byte và cấu trúc cột, không sửa dữ liệu để khớp test.
- Stage legacy: SHA-256 `1a2badfbb5f809c070c317257b25e33cc46d22a01600a3770805b68143032cb1`; **10.572 dòng**, 26 key trùng, CP936.
- **23/23** tại `Build/Logs/2026-09-13-gpt-wsl-ui/dictionary-3`: cả hai corpus thật, Việt/Trung, NFC/NFD, key giữ byte, markup, last-wins, BOM/CRLF/comment, malformed UTF-8 không fallback, GBK cắt cụt, sai schema/header/ID, NUL và giới hạn. Hai lần đầu corpus fail vì phép đếm sơ bộ bỏ ba dòng rỗng; log được giữ.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/fonts/run_dictionary_tests.ps1 -OutDir Build/Logs/dictionary-NEW -LegacyDictionary Build/gpt-p1-1-20260913/stage-d1b2c16/Data/Config/StrDictionary.txt
```

## Dữ liệu stage theo yêu cầu người dùng

Người dùng yêu cầu để trống StrFilter. `Tools/data/empty_strfilter.py` giữ nguyên hai dòng schema/header, xóa các rule và lưu backup byte cùng hash trong `Build/Logs/strfilter-empty`. File 0 byte sẽ làm DBC loader thất bại. Canonical đã đổi **134.959 → 0 rule**, backup `Build/Logs/strfilter-empty/20260913-072651-039807`; stage cũ **2.655 → 0**, backup `20260913-072812-685484`. Không thay bộ lọc của client thật hoặc dữ liệu server.

`Tools/data/prepare_login_profile.py` chỉ ghi vào một stage có `Bin64/offline_stage.json` bên dưới Build, không traversal/junction. Nó chép từ điển Canonical, fixture server offline đã kiểm, làm rỗng StrFilter và sửa đúng ba descriptor `ChannelBkg` của ChatFrame từ `dir:CommonFrame set:Chat` thành các slot `left/middle/right set:CommonFrame`. `image:CommonEditBoxBK` giữ nguyên, cùng ảnh của HoverChannelBkg liền kề. Reader B chỉ nhận ba direction này; xem bằng chứng native ở spec login-properties. Mỗi file có backup/hash trước/sau, không sửa Reference/client_GL.

```powershell
python -B Tools/data/prepare_login_profile.py Build/gpt-p1-1-20260913/stage-COMMIT
```

Font vẫn là `NotoSansSC-Regular.ttf`, UI code page 65001. Unit parser không thay cho ảnh Game thật; kết quả build/runtime cuối được ghi trong handoff và Timeline. Mã màu mới như `#g` cần bằng chứng và xử lý riêng, không tự coi là lỗi font.


## Mã màu #g và #l — batch 2


`CEGUIBase.dll` Font::drawTextLine `0x4ad30` dùng bảng nhảy `0x4c9c8`/`0x4c994`: D0 → `0x4c68c`. Ba hex cao là RGB444 phía trên, ba hex thấp là RGB444 phía dưới; mỗi nibble nhân 17 thành RGB888. Do đó `#gFF0FA0` là **trên #FFFF00, dưới #FFAA00**. Nhánh normal `0x4c098` và blink `0x4bba2` truyền `ColourRect(top,top,bottom,bottom)` vào Image::draw. Alpha lấy từ text colour; blink thay alpha và giữ RGB hai đầu. Hai đầu giống nhau dùng màu chữ phẳng hiện tại theo B. `#c` đổi màu phẳng nhưng giữ gradient; `#e` xóa cả hai đầu gradient; mỗi outer draw mới khởi tạo hai đầu bằng 0. Vì vậy không quy `#g` thành `#c`, cũng không tự tắt gradient khi gặp `#l` trả về mã màu phẳng.

CY triển khai `CysTextColour.h` dùng chung cho UIString và kiểm thử; renderer `CEGUIFontBase.cpp` thêm D0 và truyền gradient thật đến quad. Bộ đếm scope giữ màu qua xuống dòng/wrap lồng nhau, đồng thời tránh rò gradient sang lần vẽ độc lập kế tiếp. Không đổi ABI. Giữ nguyên font `NotoSansSC-Regular.ttf`, UTF-8 và NFC cho chữ hiển thị. Các mã markup khác ngoài phạm vi c/e/g/l và preset đã có không được bổ sung theo suy đoán.

Bằng chứng tĩnh: `Build/Logs/2026-09-13-gpt-login-remaining/ui-followup_vi.md`, `ui-followup-identity.json`, `runtime-color-g.txt`, `runtime-color-init.txt`, `ui-color.txt`, `font-d0-branch.txt`, `font-gradient-draw.txt`, `font-gradient-normal-draw.txt`. Hash DLL và từng khoảng byte được ghi trong identity JSON. Không chạy B để lấy kết quả.

Bộ font test giữ 41 ca Noto/UTF-8 cũ và thêm 14 ca parser/renderer: màu và bốn góc glyph Noto qua addQuad thật, alpha, đủ kênh RGB444, equal endpoints, c giữ/e xóa gradient, lần vẽ độc lập, newline/wrap và adjustQuad khi blink. Kiểm thử parser gọi đúng helper production; module UIString được kiểm bằng build UI_CEGUI và Game ở CI/runtime của root.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/fonts/run_font_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-login-remaining/gradient-tests-NEW -NativeTree Build/cmake/gpt-login-ui-props
```

Kết quả **55/55 PASS**, build/run exit 0, warning 0 tại `Build/Logs/2026-09-13-gpt-login-remaining/gradient-tests-1`. Dùng DLL của builder chung `Build/cmake/gpt-login-ui-props` (build-7, native build exit 0, gồm UI_CEGUI); SHA-256 CEGUIBase được test là `089a943fc0f45f08af05c14698467267396f9afcc8e781c511e1e229d492562d`. Không có lần gradient test fail. `gradient-source-identity.json` ghi SHA source/helper/test và DLL native. `git diff --check` sạch, giữ BOM/LF gốc. Game runtime/CI cuối do root kiểm sau khi ghép batch UI.
