# Thiết lập repository 372 dragon

[← Trang dự án](../README.md)

Repository chính: **[ts4m97/372dragon](https://github.com/ts4m97/372dragon)**,
công khai trên nhánh `main` từ ngày **15/10/2026**. File này ghi cấu hình hiển thị
và cách duy trì bản source đã công bố. Chưa tạo release binary hoặc tag phiên bản.

## Tên và phần About

| Thuộc tính | Giá trị |
|---|---|
| Repository name | **372dragon** |
| Tên hiển thị trong tài liệu | **372 dragon** |
| Default branch | `main` |
| Owner | `ts4m97` |
| Visibility | Public |
| Website | Để trống khi chưa có trang dự án thật |
| Social preview | `Docs/assets/372dragon-social.png` |

Description có thể dán vào About:

```text
TLBB x64 client and Skynet/Lua server source, development tools and technical documentation. Test data is distributed separately; licenses apply by component.
```

Topics:

```text
tlbb mmorpg game-client game-server cpp lua skynet ogre3d direct3d9 windows x64 source-available research
```

Giá trị có cấu trúc nằm trong [project.json](project.json). Không gắn badge build
passing hoặc gọi toàn repo là MIT/open-source; scope giấy phép hiện là hỗn hợp.

## Trang repository đã chuẩn bị

- `README.md`: banner, điều hướng, giới thiệu, tải data, bản đồ source, license, English overview.
- `Docs/guide/`: hướng dẫn bắt đầu, client/server, kiến trúc, xử lý lỗi và trạng thái.
- `.github/ISSUE_TEMPLATE/`: ba mẫu báo lỗi, đề xuất và tài liệu/data.
- `.github/PULL_REQUEST_TEMPLATE.md`: mô tả thay đổi, kiểm tra và nguồn đóng góp.
- `CONTRIBUTING.md`, `SUPPORT.md`, `SECURITY.md`, `CHANGELOG.md`.
- Banner SVG tự chứa và ảnh social preview PNG 1280 × 640; không cần dịch vụ badge bên ngoài.

## Xuất một snapshot hoặc fork mới

Repo chính đã có lịch sử. Các bước dưới đây chỉ áp dụng khi tạo một repository
trống mới từ bản xuất; cập nhật repo chính bằng commit tiếp theo và push thông thường.

1. Trên tài khoản/tổ chức bạn chọn, tạo repository trống tên **372dragon**. Không để
   GitHub tự sinh README, `.gitignore` hoặc license khác vì các file đã có trong bản chuẩn bị.
2. Dùng **thư mục source đã chuẩn bị**, không dùng cả workspace, private-audit,
   thư mục data, Git history cũ hay ZIP 12,39 GB. Trong máy chuẩn bị đó là `review-candidate`;
   gói source riêng giải nén thành `372dragon/`.
3. Nếu dùng thư mục `review-candidate`, Git mới đã được tạo và staging theo file đã kiểm.
   Nếu dùng source ZIP, tạo Git mới ở thư mục `372dragon` và stage nội dung, kể cả `.github`.
4. Kiểm diff và các file trước commit. Dùng danh tính Git của bạn; có thể dùng email
   noreply do GitHub cung cấp nếu không muốn công khai email cá nhân.
5. Thêm remote bằng URL **repo thật vừa tạo**, rồi push branch `main`.

Với Git đã được khởi tạo và staged trong bản chuẩn bị, các lệnh tham khảo PowerShell:

```powershell
git status --short
git diff --cached --stat
git commit -m "Prepare 372dragon source snapshot"
git branch -M main
$RepoUrl = Read-Host "Paste the actual URL of your new 372dragon repository"
git remote add origin $RepoUrl
git push -u origin main
```

Nếu remote đã có, kiểm đích hiện tại trước khi thay. Không dùng force push để
giải quyết một repo có lịch sử khác. Remote của repo chính là
`https://github.com/ts4m97/372dragon.git`.

## Hoàn thiện phần hiển thị

1. Điền About/Topics theo giá trị phía trên.
2. Trong **Settings → Social preview**, chọn `Docs/assets/372dragon-social.png`.
3. Bật Issues để dùng các form; Discussions chỉ cần khi muốn có diễn đàn trao đổi.
4. Nếu muốn nhận báo lỗi nhạy cảm qua GitHub, bật private vulnerability reporting
   và xác nhận lại hướng dẫn trong SECURITY.md.
5. Sau push, thử README, link tương đối, sơ đồ Mermaid, các form và link Drive
   bằng một phiên không đăng nhập. Giữ `Publication/project.json` khớp repo thật.

README và link tương đối dùng các khả năng [GitHub hỗ trợ chính thức](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes).
Sơ đồ dùng [Mermaid](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams);
mẫu issue theo [cú pháp GitHub](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms).
Ảnh chia sẻ 1280 × 640 PNG, dưới 1 MB, theo [hướng dẫn social preview](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview).

## Trước khi gọi là bản phát hành chạy được

Hoàn thành [bài nghiệm thu](../Docs/guide/status.md), chốt dependency và bổ sung
notice/nguồn gốc còn thiếu. Việc công bố source không tự chứng minh clean build hay
một bộ client/server cài tự động đã hoạt động trên máy mới.
