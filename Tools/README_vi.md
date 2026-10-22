# Công cụ của 372 dragon

Các thư mục chính:

| Thư mục | Nội dung |
|---|---|
| `build/` | Cấu hình CMake, biên dịch, stage và kiểm thử client |
| `pipeline/` | Chuẩn bị, chuyển đổi và kiểm tra dữ liệu |
| `protocol/` | Sinh codec từ mô tả giao thức và mã Lua của server |
| `game/`, `server/` | Công cụ hỗ trợ chức năng client và server |
| `audit/` | Kiểm tra bản build, file và nguồn gốc binary được đóng gói |
| `perf/`, `render/` | Đo hiệu năng và kiểm tra hình ảnh của bản build |
| `reapply/` | Áp dụng lại các thay đổi dữ liệu có lưu vết |

Một số script phát triển còn dùng đường dẫn máy cũ. Đọc tham số và cấu hình trước khi chạy.
Hướng dẫn cho bản công khai: [build client](../Docs/guide/build-client.md),
[build server](../Docs/guide/server-setup.md) và [tải dữ liệu](../DATA_DOWNLOAD.md).
