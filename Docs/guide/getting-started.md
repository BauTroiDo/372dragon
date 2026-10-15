# Bắt đầu với 372 dragon

[← Tài liệu](README.md) · [Build client →](build-client.md)

372 dragon cung cấp source để nghiên cứu và phát triển client TLBB x64 cùng server
Skynet/Lua. Quy trình cài trọn bộ trên máy mới chưa được nghiệm thu. Bạn có thể đọc
code ngay mà không tải 12,39 GB data.

## 1. Lấy đúng các thành phần

| Thành phần | Cách lấy | Khi nào cần? |
|---|---|---|
| Source | Git clone bằng URL trong nút **Code**, hoặc **Download ZIP** | Phát triển |
| Data | [Một file Google Drive](../../DATA_DOWNLOAD.md) | Nạp tài nguyên/chạy thử |
| SDK/runtime | [Danh mục bên thứ ba](../../THIRD_PARTY.md) | Build/chạy thành phần tương ứng |
| Database/tài khoản | Khởi tạo riêng trong môi trường của bạn | Chạy server |

Gói source chuẩn bị riêng có tên `372dragon-source-2026-10-15.zip`, chứa thư mục
`372dragon/` và `SOURCE-FILES.json`. ZIP tải trực tiếp từ GitHub có thể mang tên
theo branch; đó là cách đóng gói khác của repository.

## 2. Chuẩn bị máy

| Phạm vi | Yêu cầu đã xác định |
|---|---|
| Client | Windows x64; MSVC 2022 và Windows SDK; CMake ≥ 3.25, Ninja, Python 3 |
| Server | Linux/WSL2; compiler C/C++, make; MongoDB 4.4.31 và Mosquitto |
| SDK | FMOD Core 2.02.35, Cg, DirectX phù hợp; xem hướng dẫn client |
| Lưu trữ | Source khoảng 192 MiB; ZIP data 12,39 GB; data trước nén 24,12 GB |

Giữ cả ZIP và data đã giải nén cần khoảng **36,51 GB** chỉ cho hai phần đó.
Chừa thêm chỗ cho SDK, compiler, object/PDB, database và log; chưa có số đo tối
thiểu RAM/GPU hay tổng dung lượng build trên máy mới.

## 3. Kiểm data trước khi giải nén

Từ root source, thay đường dẫn file đã tải trong lệnh:

```powershell
python Publication/verify_test_data.py --archive "D:\Downloads\cy-test-data-2026-10-15.zip" --manifest Publication/test-data-manifest.json --full
```

Kết quả cần có `status: PASS`. `--full` kiểm hash từng file ngoài checksum toàn ZIP;
công cụ không giải nén hay chạy nội dung. Đọc [hướng dẫn tải](../../DATA_DOWNLOAD.md)
để xem checksum, phạm vi và thông báo data.

Giải nén bằng công cụ hỗ trợ ZIP64 vào **root của bản source**. Giữ nguyên tên Unicode,
tên file có ký tự trông lạ và encoding tài nguyên. Không để thành hai lớp
`372dragon/372dragon/` hoặc `Assets/Assets/`.

## 4. Bố cục sau giải nén

```text
372dragon/
├── Src/
├── Publication/
├── Assets/CanonicalCY/Data/   Tài nguyên client
├── Play/Overlay/              Overlay client
└── Server/
    ├── GameServer/            Source server
    ├── Game_2/                Script và scene
    ├── configs/               Bảng dữ liệu tĩnh
    └── confs/                 Cấu hình mẫu
```

`Play/Bin64/Game.exe`, DLL runtime, cấu hình Play và launcher chưa được tạo khi giải
nén data. `Publication/Setup-Play.ps1` chỉ tạo liên kết `Play/Data` khi đã có
`Play/Bin64/Game.exe`; nó không xây dựng một bộ client chạy hoàn chỉnh.

## 5. Đi tiếp theo mục tiêu

- **Đọc code:** [kiến trúc](architecture.md) và [bản đồ source](repository-map.md).
- **Build client:** [build-client.md](build-client.md), chuẩn bị SDK trước CMake.
- **Dựng server:** [server-setup.md](server-setup.md), dùng một bản cài Linux riêng.
- **Chạy phiên hoàn chỉnh:** làm [bài nghiệm thu](status.md) sau build/cấu hình.

Tài liệu lịch sử có chữ “PASS” chỉ chứng minh phép thử đã mô tả ở thời điểm đó;
nó không thay cho kiểm tra trên môi trường mới.
