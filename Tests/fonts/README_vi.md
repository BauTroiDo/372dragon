# Kiểm font Trung/Việt

Chạy `powershell -NoProfile -ExecutionPolicy Bypass -File Tests/fonts/run_font_tests.ps1` sau CI build. Dùng CEGUIBase và FreeType của `Build/cmake/ci-x64`; không cài phần mềm và không gọi server. Mỗi lượt biên dịch một nguồn bằng MSVC, chạy trong thư mục mới dưới Build, có log và SHA DLL/test. Renderer bộ nhớ chỉ kiểm lifecycle; ảnh D3D9 là kiểm chứng hiển thị riêng.

41 ca gồm chọn ngôn ngữ/backend, XML lỗi, cleanup/retry, 15 font Canonical, 140 probe glyph, NFC của90 chữ Việt có dấu, nhãn/danh sách, giữ nguyên ô nhập, tên window và mã điều khiển. Hai fixture UTF-8 `multilingual.layout.xml` (NFC) và `multilingual-nfd.layout.xml` (NFD) phải cho ảnh giống từng pixel sau khi ghép dấu. Dùng `CysUiViewer --strict-fonts` để kiểm engine thật.

Kết quả, lệnh render, cấu hình System_CodePage=65001 và giới hạn: `Docs/specs/ui/fonts_vi.md`. Test không khẳng định Game đã vào màn đăng nhập hoặc IME đã kiểm thực tế. Kết quả cuối41/41 tại `Build/Logs/2026-09-12-gpt-font/tests-20260912-233400-8505893`; CI runtimeff0d20e xanh33/33, smoke6/6,checks3/3.
