# Tài liệu 372 dragon

[← Trang dự án](../../README.md)

Đây là bộ hướng dẫn dành cho bản công bố 372 dragon. Các tài liệu khác trong `Docs/`
ghi quá trình phát triển dự án; đọc ngày tháng và phạm vi trước khi áp dụng.

| Thứ tự | Hướng dẫn | Kết quả cần có |
|---:|---|---|
| 1 | [Bắt đầu](getting-started.md) | Hiểu gói source/data, yêu cầu và bố cục cài đặt |
| 2 | [Tải data](../../DATA_DOWNLOAD.md) | ZIP đúng SHA-256, giải nén đúng đường dẫn |
| 3 | [Build client](build-client.md) | Toolchain, SDK và cây build x64 riêng |
| 4 | [Dựng server](server-setup.md) | Bản sao Linux riêng, cấu hình và dịch vụ của bạn |
| 5 | [Trạng thái và nghiệm thu](status.md) | Phân biệt kiểm tra đã đạt và việc còn lại |

Để đọc và sửa code:

- [Kiến trúc](architecture.md): vai trò từng lớp, luồng giao thức và data.
- [Bản đồ repository](repository-map.md): tìm đúng thư mục và tài liệu.
- [Xử lý lỗi](troubleshooting.md): triệu chứng, kiểm tra và bước tiếp theo.
- [Đóng góp](../../CONTRIBUTING.md): trình bày bản sửa và bằng chứng kiểm thử.

Để hiểu việc phân phối:

- [Giấy phép](../../LICENSING.md), [thành phần bên thứ ba](../../THIRD_PARTY.md),
  [thông báo data](../../DATA_NOTICE.md).
- [Thiết lập repository GitHub](../../Publication/GITHUB-SETUP.md): tên, mô tả,
  topics, ảnh chia sẻ và đưa source lên GitHub.
- [Số đo và phương án đóng gói](../../PUBLICATION.md).

Các lệnh có đường dẫn mẫu cần được thay theo bản cài của bạn. Script lịch sử có
thể còn đường dẫn máy phát triển; bộ hướng dẫn không tự cài SDK hay chạy dịch vụ.
