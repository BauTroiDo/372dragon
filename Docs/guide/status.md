# Trạng thái bản công bố

[← Tài liệu](README.md)

Mốc **15/10/2026**. Tên công bố **372dragon**; tên nội bộ/lịch sử CY-Source.
Source được công bố tại [ts4m97/372dragon](https://github.com/ts4m97/372dragon),
nhánh `main`. Đây là source snapshot; chưa có release binary hoặc tag ổn định.

## Đã chuẩn bị và kiểm tra

| Phạm vi | Bằng chứng/phạm vi kiểm tra |
|---|---|
| Source export | Client/server và tài liệu riêng; không nhập Git history cũ |
| Cấu hình | 10 template; thử trong bản sao tạm, kiểm quyền Linux và từ chối ghi đè |
| Data | 126.212 file; kiểm toàn gói và hash/CRC thành viên trước cập nhật notice |
| Notice data | Cập nhật notice, kiểm vùng dữ liệu/member metadata giữ nguyên và hash toàn ZIP mới |
| Drive | Mở trang file không đăng nhập, đúng tên; chưa tải lại toàn ZIP để kiểm hash |
| Git/source ZIP | Kiểm byte Git index, file lớn và CRC source trong các bước đóng gói |

Kiểm bí mật dựa trên giá trị cấu hình đã biết và dấu hiệu file nhạy cảm, không
chứng nhận mọi bí mật, lỗi bảo mật hoặc vấn đề giấy phép đều đã được phát hiện.

## Chưa nghiệm thu trên máy mới

- Build client đầy đủ SDK/runtime trong môi trường độc lập.
- Dựng đầy đủ Play, launcher, plugin/config và kết nối server từ bản xuất.
- Build server sạch, chốt source/phiên bản jemalloc và OpenSSL phù hợp.
- Cài dịch vụ, user MongoDB và tài khoản game bằng quy trình cài mới hoàn chỉnh.
- Hoàn tất nguồn gốc đóng góp lịch sử và notice phụ thuộc.

Không hiển thị badge “build passing” hoặc nhận là release ổn định khi các bước này chưa đạt.

## Bài nghiệm thu cài mới

Ghi môi trường, snapshot/commit, SDK, cấu hình và kết quả từng mục:

- [ ] SHA-256 data đúng; tên/encoding giữ nguyên sau giải nén.
- [ ] Client build x64; ghi hash executable/DLL thực dùng.
- [ ] Native server build; `ldd` không còn dependency thiếu.
- [ ] Cấu hình riêng, dịch vụ và tài khoản mới; MongoDB loopback.
- [ ] Cổng login/game đúng; scene nạp xong.
- [ ] Đăng ký/đăng nhập, tạo nhân vật, vào Đại Lý và di chuyển.
- [ ] Đóng UI rồi tiếp tục điều khiển bình thường.
- [ ] Một giao dịch được lưu đúng sau thoát sạch/đăng nhập lại.
- [ ] Ghi lỗi còn tồn tại, log đã loại thông tin riêng và phần chưa kiểm.

## Mốc lịch sử

| Ngày | Ý nghĩa |
|---|---|
| 24/09/2026 | Kiểm toán source/build/provenance client tại thời điểm đó |
| 01/10/2026 | Runtime repairs cuối được ghi trong bàn giao |
| 04/10/2026 | Tạm lưu CY, chuyển trọng tâm sang dự án GL riêng |
| 15/10/2026 | Công bố source snapshot và nhận diện 372dragon; data tải riêng |

Đây không phải tag SemVer hay chứng minh bản cài hiện tại đã đạt mọi phép thử.
