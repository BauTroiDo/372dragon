# Đóng góp cho 372 dragon

[← Trang dự án](README.md)

Ưu tiên bản sửa có thể đọc, tái hiện và kiểm tra độc lập: tài liệu, build trên máy
mới, lỗi client/server, kiểm thử và nguồn gốc phụ thuộc. Mỗi PR giải quyết một vấn đề rõ ràng.

## Trước khi sửa

1. Đọc [kiến trúc](Docs/guide/architecture.md), [bản đồ source](Docs/guide/repository-map.md)
   và tài liệu của phần muốn thay đổi.
2. Dùng branch/môi trường thử riêng; kiểm đích trong script lịch sử.
3. Giữ copyright/notice/license code kế thừa. Chỉ gửi nội dung có quyền đóng góp.

## Quy tắc kỹ thuật

- Giữ encoding file cũ. Với `all.*`, model và khóa tài nguyên, kiểm round-trip byte;
  không đổi tên mojibake hay chuyển toàn data sang UTF-8.
- Với packet, nêu ID, kiểu/thứ tự trường và hành vi hai phía.
- Với ID nội dung, đối chiếu Registry và bảng client/server; cùng ID ở nguồn khác
  nhau không tự có cùng ý nghĩa.
- Với trạng thái/giao dịch, kiểm trước/sau và sau đăng nhập lại.
- Với UI, kiểm di chuyển/thao tác sau đóng cửa sổ; ảnh chụp chưa đủ.
- Với build, ghi target, toolchain/SDK và hash binary thực dùng.
- Không commit SDK/DLL ngoài phạm vi, data ngoài Git, database, mật khẩu, token,
  private key, log riêng hoặc cache build.

## Mô tả pull request

Nêu điều kiện gây lỗi, hành vi trước/sau, cách sửa và cách kiểm. Ghi kết quả thực,
phần chưa kiểm và rủi ro còn lại. Chỉ sửa tài liệu thì kiểm link, lệnh và nội dung;
không cần chạy lại toàn game.

File mới áp dụng license phù hợp [phạm vi dự án](LICENSE). Sửa thành phần có license
sẵn phải giữ điều khoản tương ứng; không tự áp PolyForm NC lên code LGPL/GPL hay
nội dung người khác.

## Những đóng góp có ích

- Hoàn thiện build client + Play trên máy Windows độc lập.
- Chốt source/version/notice dependency native server.
- Chuyển đường dẫn cố định thành cấu hình có kiểm tra đích.
- Bổ sung bài tái hiện và kết quả kiểm thử có môi trường cụ thể.
- Bổ sung nguồn/điều khoản thư viện và từng nhóm data.

Trao đổi tôn trọng và dựa trên bằng chứng. Thông tin nhạy cảm đi theo [SECURITY.md](SECURITY.md).
