# 372dragon — tải data kiểm thử

[← Trang dự án](README.md) · [Hướng dẫn bắt đầu](Docs/guide/getting-started.md)

372dragon là tên công bố của CY-Source. Tên ZIP và thông báo `DATA-NOTICE.txt` giữ
nguyên để khớp gói đã chia sẻ; đổi tên dự án không thay nội dung hay checksum data.

**Google Drive:** [Tải cy-test-data-2026-10-15.zip](https://drive.google.com/file/d/1FG-BSvarnmCeezwr4PqqC0zHMf7syia4/view?usp=sharing).
Liên kết do chủ dự án cung cấp. Đã mở trang file không đăng nhập và xác nhận đúng
tên gói ngày 15/10/2026; chưa tải lại toàn bộ file trên Drive để đối chiếu hash.

**Tên gói:** `cy-test-data-2026-10-15.zip` — ZIP64, một file.

Gồm `Assets/CanonicalCY/Data`, `Play/Overlay`, bảng/scene tĩnh server. Không gồm
database người chơi, mật khẩu, log riêng, SDK hay DLL/EXE runtime.
Gói đã chuẩn bị có dung lượng **12.391 GB** (12,391,009,560 byte; khoảng 11.54 GiB),
chứa 126,212 file dữ liệu, khoảng 24.116 GB trước nén.
Dung lượng và SHA-256 chính xác ở `Publication/test-data-manifest.json`.
SHA-256 của gói đã chuẩn bị:

```text
d4e177afbd72933bff9394a29f41b93fcbc3c87ea90c11c2906c31ec2158c260
```

Trong ZIP có `DATA-FILES.json` chứa hash từng file và `DATA-NOTICE.txt`.

## Mục đích kiểm thử và giới hạn trách nhiệm

Bộ data chỉ được dự án giới thiệu để đối chiếu và kiểm tra mã nguồn gốc, bản build
từ source và các thay đổi của CY-Source có hoạt động đúng hay không; phục vụ tái hiện
lỗi, kiểm tra việc tải tài nguyên và khả năng tương thích client/server.

Đọc [DATA_NOTICE.md](DATA_NOTICE.md) trước khi sử dụng. Thông báo này được đính kèm
nguyên văn trong `DATA-NOTICE.txt` bên trong ZIP: dữ liệu được cung cấp theo hiện trạng;
miễn trừ bảo đảm, bao gồm bảo đảm không xâm phạm quyền bên thứ ba, và giới hạn trách
nhiệm trong phạm vi pháp luật cho phép. Người sử dụng phải xác định quyền và tuân thủ
điều khoản áp dụng đối với hành vi của mình. Mục đích kiểm thử và thông báo miễn trừ
không tự tạo quyền phân phối hoặc loại bỏ trách nhiệm pháp lý bắt buộc của bên cung cấp.

## Thông báo bản quyền

> Dữ liệu kiểm thử được tổng hợp từ nhiều nguồn trên internet. Bản quyền và các quyền
> liên quan thuộc tác giả hoặc chủ sở hữu tương ứng. CY-Source không tuyên bố sở hữu
> và không cấp lại giấy phép cho dữ liệu này. Giấy phép phần mềm của dự án không áp dụng
> cho gói dữ liệu. Việc sử dụng và phân phối lại phải tuân thủ điều khoản của nguồn và
> chủ sở hữu tương ứng.

Nguồn được ghi tại `Publication/asset-provenance.json`. Tên bộ data cục bộ không được
coi là danh tính tác giả hoặc chứng cứ quyền phân phối. Chỗ thiếu được đánh dấu chưa xác minh.
Chủ dự án cho biết có quyền phân phối và sẽ cung cấp căn cứ; bảng này chừa chỗ để ghi
nguồn, điều khoản hoặc sự cho phép tương ứng, chưa tự coi nội dung trên internet là được phép chia sẻ lại.

Tải file từ liên kết trên, kiểm SHA-256 rồi giải nén ở root bản cài;
giữ nguyên tên file và encoding tài nguyên. Hash trong manifest dùng để đối chiếu
file tải về với gói đã chuẩn bị tại máy phát triển.

Lệnh kiểm: `python Publication/verify_test_data.py --archive PATH_TO_ZIP
--manifest Publication/test-data-manifest.json --full`.

Đặt file trên Drive không thay quyền phân phối so với GitHub. Với phần chưa có căn cứ,
giữ cục bộ và chỉ cung cấp hướng dẫn tự chuẩn bị hoặc liên kết phân phối hợp lệ của tác giả.
