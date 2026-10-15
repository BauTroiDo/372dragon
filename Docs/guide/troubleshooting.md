# Xử lý lỗi thường gặp

[← Tài liệu](README.md) · [Gửi báo lỗi](../../SUPPORT.md)

| Triệu chứng | Kiểm trước | Bước tiếp |
|---|---|---|
| Hash ZIP khác manifest | Đúng gói, tải xong, không phải bản notice cũ | Tải lại; chưa giải nén gói chưa xác định |
| Drive yêu cầu quyền/quota | Link đúng trong DATA_DOWNLOAD | Báo thông báo và thời điểm qua mẫu tài liệu/data |
| Thiếu `Game.exe` sau giải nén | Data không có executable/DLL | Build và chuẩn bị Play |
| Wrapper không tìm Visual Studio | Đường dẫn Build Tools 2022 cố định | Developer Command Prompt + CMake, hoặc sửa wrapper |
| Không tìm FMOD | SDK 2.02.35, `api/core/inc`, `lib/x64` | Đặt SDK đúng chỗ, đúng kiến trúc |
| Thiếu `cg.dll` | `CYS_CG_DLL` trỏ đường dẫn cũ? | Cấu hình Cg thật trên máy |
| Thiếu DirectX/import library | Bản xuất không chứa `.lib` SDK | Bổ sung nguồn hợp lệ, đối chiếu x64 |
| Lỗi jemalloc | Thiếu dependency native phù hợp | Chốt source/version/notice trước thay allocator |
| Lỗi OpenSSL | `TLS_LIB`, header, ABI khác distro | Đối chiếu Makefile và môi trường |
| Setup-Play từ chối | Thiếu Data/Game.exe hoặc junction khác đích | Chuẩn bị đủ thành phần; script không ghi đè |
| init_config từ chối | Có file đích/record hoặc root bị bảo vệ | Dùng bản sao mới, giữ cấu hình hiện có |
| Không đăng nhập | IP/cổng, scene, allow-list profile | Đối chiếu hai phía, không gửi mật khẩu |
| Tài nguyên mất/sai | Encoding, tên mojibake, schema/ID | So manifest; không đổi tên/UTF-8 hàng loạt |
| UI mở nhưng mất điều khiển | Focus, sự kiện sau đóng UI | Kiểm trong game; ảnh chụp chưa đủ |
| Trạng thái mất sau đăng nhập | Lưu/đọc server, GUID và giao dịch | Ghi trước/sau, dùng tài khoản thử |

## Khi chưa rõ nguyên nhân

1. Ghi snapshot/commit và bước đầu tiên bắt đầu lỗi.
2. Xác nhận binary, data và config thực đang dùng.
3. Lấy log liên quan, bỏ bí mật/token/thông tin người chơi.
4. Phân biệt baseline và lỗi mới; giữ kết quả FAIL để đối chiếu.
5. Mở issue theo [SUPPORT.md](../../SUPPORT.md), không gửi cả dump/database.

Chưa có quy trình cài mới hoàn chỉnh được chứng nhận. Thiếu dependency trên máy mới
cần được ghi nhận để tái lập môi trường, không che bằng DLL/database ngẫu nhiên.
