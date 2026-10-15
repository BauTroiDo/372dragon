# Phương án công bố 372dragon — 15/10/2026

Tên công bố của CY-Source là **372dragon**. Xem [README.md](README.md),
[hướng dẫn](Docs/guide/README.md) và [thiết lập GitHub](Publication/GITHUB-SETUP.md).

Quyết định mới nhất: GitHub cho source và tài liệu; một file data ZIP64 riêng ở Google Drive;
DLL/SDK có điều khoản riêng lấy từ nguồn hợp lệ. Chỉ cấp phép phần thuộc quyền của dự án.

| Phạm vi đã đo | Dung lượng trước nén |
|---|---:|
| Cây CY Windows (không đi theo junction) | 258,710 GiB |
| Build: cache, stage cũ, log, công cụ RE, worktree | 216,010 GiB |
| Source client + công cụ/tài liệu chọn cho Git | 132.284 MiB |
| Source server và cấu hình mẫu | 59.436 MiB |
| Tổng source ứng viên | 191.719 MiB |
| Data CanonicalCY sau loại backup | 20,017 GiB |
| Client runtime/overlay của phương án cũ | 2,236 GiB |
| Scene/bảng server | 0,250 GiB |
| FMOD SDK cục bộ (không đưa vào Git) | 0,222 GiB |
| Reference gốc (không gộp vào repo source) | 3,118 GiB |

Đây là logical bytes; hardlink có thể được tính nhiều lần trong tổng workspace. Một junction
UI editor ở dưới Data được khôi phục thành file thật khi đóng gói. Không quy dung lượng
258 GiB thành dung lượng cần thiết để clone hoặc tải về.

Gói data mới: 11.540 GiB (12.391 GB) sau nén, 126,212 file, SHA-256 `d4e177afbd72933bff9394a29f41b93fcbc3c87ea90c11c2906c31ec2158c260`.

Tổng source trong bảng là các tệp được chọn từ cây gốc. Bản xuất còn có tài liệu và
công cụ phát hành mới, cùng thay đổi template; số chính xác của bản xuất nằm trong
`source-manifest.json` cạnh ZIP source. Thư viện ELF `libjemalloc.so.2` được giữ ngoài
repo, trong thư mục kiểm tra dependency cục bộ; không bị coi là source chỉ vì có đuôi `.2`.

Source snapshot gồm 521 mục thay đổi/chưa theo dõi ở client và 855 mục ở server theo kiểm kê.
Tạo một lịch sử Git mới từ bản xuất; không push .git cũ hoặc toàn bộ worktree. Kho Git cũ có
998 commit; riêng commit cuối không chứa đầy đủ phiên làm việc đã phát hành.

Giấy phép: PolyForm Noncommercial chỉ cho đóng góp có quyền cấp phép; LGPL/MIT và notice
thư viện giữ nguyên; data ngoài license dự án. DATA_DOWNLOAD.md đã có [liên kết Google Drive do chủ dự án cung cấp](https://drive.google.com/file/d/1FG-BSvarnmCeezwr4PqqC0zHMf7syia4/view?usp=sharing).
DATA_NOTICE.md và thông báo trong ZIP nêu mục đích kiểm tra code gốc, cung cấp data
theo hiện trạng và giới hạn trách nhiệm trong phạm vi pháp luật cho phép.
Các thư mục Reference/Canonical cũ/Staging/Imported và archive thử nghiệm có manifest giữ lại,
không xóa bản gốc. Nếu muốn chia sẻ thêm, từng nhóm cần kiểm nguồn gốc và dữ liệu riêng.

Đã làm: kiểm kê client/server thật; xuất source riêng; thay mật khẩu cấu hình bằng template;
chuẩn bị license scope, bảng nguồn data và tài liệu DLL; ghi nhận liên kết Drive do chủ dự án cung cấp và kiểm tra trang file không đăng nhập.
Source snapshot được công bố tại [372dragon trên GitHub](https://github.com/ts4m97/372dragon), nhánh `main`.

Chưa làm: xác minh quyền phân phối lại của từng nguồn data; hoàn tất phạm vi
đóng góp CY lịch sử; bổ sung mọi notice phụ thuộc; nghiệm thu cài mới và clean build trên máy khác.
Bản công bố source chưa được nghiệm thu như một bộ cài sẵn sàng vận hành độc lập.

Giới hạn GitHub đã đối chiếu: file Git trên 100 MiB bị chặn; nên giữ repo nhỏ. Data ở Drive
làm repo nhẹ. Nếu sau này phát hành binary qua GitHub Releases, mỗi asset phải dưới 2 GiB.
Git LFS không được chọn cho bộ data này vì quota lưu trữ và băng thông phát sinh.
Google Drive cá nhân có tối đa 15 GB miễn phí dùng chung Gmail/Photos; cần xem dung lượng
trống thực tế, không mặc định gói data sẽ vừa quota còn lại.

Nguồn chính thức: [GitHub large files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github),
[Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases),
[LFS](https://docs.github.com/en/billing/concepts/product-billing/git-lfs),
[Google storage](https://support.google.com/drive/answer/9312312),
[PolyForm](https://polyformproject.org/licenses/noncommercial/1.0.0).
