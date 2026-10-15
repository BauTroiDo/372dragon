# Tìm code và tài liệu

[← Tài liệu](README.md)

| Cần tìm | Điểm vào |
|---|---|
| Build client | [Src/CMakeLists.txt](../../Src/CMakeLists.txt), [CYSCommon.cmake](../../Src/cmake/CYSCommon.cmake) |
| Thành phần build | [Src/cmake/components](../../Src/cmake/components) |
| Ứng dụng/game client | [Src/Client](../../Src/Client) |
| Engine/render/đường đi | [Src/Engine](../../Src/Engine) |
| Common/packet client | [Src/Shared](../../Src/Shared) |
| Thư viện kèm source | [Src/ThirdParty](../../Src/ThirdParty) |
| Skynet/native framework | [Server/GameServer/framework](../../Server/GameServer/framework) |
| Logic server | [Server/GameServer](../../Server/GameServer) |
| Script gameplay | [Server/Game_2/Script](../../Server/Game_2/Script) |
| Cấu hình mẫu | [Server/confs/publish_yu](../../Server/confs/publish_yu) |
| Build/kiểm thử | [Tools/build](../../Tools/build), [Tests](../../Tests) |
| Tài nguyên | [Tools/pipeline](../../Tools/pipeline), [Tools/data](../../Tools/data) |
| Sổ ID/giao thức/ABI/nguồn | [Registry](../../Registry) |
| Kiểm data/sinh cấu hình | [Publication](../../Publication) |

## Ba lớp tài liệu

1. **Hướng dẫn bản công bố:** [Docs/guide](README.md), README, DATA_DOWNLOAD,
   CONTRIBUTING và các file root giải thích cách tiếp cận repository.
2. **Tư liệu lịch sử:** tài liệu đánh số trong `Docs/`, spec và evidence giữ ngày
   tháng, giả định và đường dẫn của CY-Source lúc viết.
3. **Metadata đóng gói:** manifest data, phạm vi license và nguồn data ở `Publication/`.
   Chúng không thay source SDK hay chứng nhận runtime.

`README_vi.md` và `PAUSED-READ-FIRST.txt` là ghi chép cây phát triển gốc. Đường dẫn
tuyệt đối trong đó có thể chỉ tồn tại trên máy tác giả. Điểm bắt đầu hiện tại là
[README.md](../../README.md) và bộ hướng dẫn này.

## Data ngoài Git

Sau tải data mới có đủ `Assets/CanonicalCY/Data`, `Play/Overlay`, `Server/configs`
và scene `Server/Game_2`. Cây Build/Reference lịch sử, WSL export, database và SDK
nhị phân không được nhập nguyên khối vào repository.

Script tên `test`, `stage` hoặc `publish` vẫn có thể ghi data, gọi dịch vụ hoặc
thao tác database. Đọc tham số, đích và phạm vi trước khi dùng trong bản cài riêng.
