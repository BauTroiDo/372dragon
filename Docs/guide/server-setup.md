# Chuẩn bị server Linux/WSL2

[← Tài liệu](README.md) · [Trạng thái và nghiệm thu →](status.md)

Server ở `Server/`, dùng Skynet/Lua và module C/C++. Nó không được build bởi CMake
client. Chưa có bộ provision/cài dịch vụ hoàn chỉnh được nghiệm thu trên máy mới.

## 1. Bố cục và phụ thuộc

| Đường dẫn | Nội dung |
|---|---|
| `Server/GameServer/framework` | Skynet, Lua, service và module native |
| `Server/GameServer` | Logic server, native module riêng và Makefile |
| `Server/Game_2/Script` | Gameplay/scene script |
| `Server/Game_2/Scene` | Scene lấy thêm từ data |
| `Server/configs` | Bảng tĩnh lấy thêm từ data |
| `Server/confs/publish_yu` | Cấu hình mẫu |

Chuẩn bị compiler C/C++, make, Python 3, MongoDB **4.4.31** và Mosquitto.
Giữ MongoDB trong giai đoạn tương thích này; chưa xác nhận đổi major. OpenSSL,
jemalloc và native module phải phù hợp source/Makefile hiện có.

## 2. Dùng root Linux riêng

Ghép source/data đúng bố cục, đặt bản cài ở root của bạn, ví dụ `~/372dragon/Server`.
Ví dụ dưới giả định root đó đã tồn tại. Không chạy script quản lý lên server khác
đang phục vụ người dùng. Từ root source trong Linux:

```bash
python3 Publication/init_config.py --server-root "$HOME/372dragon/Server"
```

Công cụ tạo **10 cấu hình** từ `.template`, sinh bí mật ngẫu nhiên và lưu tại
`.local/setup-secrets.json` của server root, quyền file `0600` trên Linux.
Nếu file đích đã tồn tại, thao tác bị từ chối. Công cụ chỉ thay placeholder đã biết;
rà lại các đường dẫn, IP và tài khoản còn lại theo bản cài.

Công cụ không cài dịch vụ, tạo user database/tài khoản game hay khởi động server.
Không đưa file bí mật, cấu hình đã sinh, database hoặc log phiên chơi vào Git.

## 3. Build native: những điểm phải giải quyết

| Vị trí | Cần đối chiếu |
|---|---|
| `GameServer/framework/Makefile` | Yêu cầu `3rd/jemalloc/lib/libjemalloc_pic.a`; bản xuất chưa có bộ source/dependency jemalloc hoàn chỉnh |
| `GameServer/framework/platform.mk` | Có target `linux`, `linux_nojemalloc`; thay allocator cần kiểm riêng |
| `GameServer/framework/Makefile` | `TLS_LIB=/usr/lib64/openssl` cần khớp distro/ABI thực tế |
| `GameServer/Makefile` | Các module `gbk`, `map`, `lnavmesh`, `laiscript`, `lprofile` và module khác |

Lệnh tham khảo chỉ áp dụng **sau khi** giải quyết đúng phụ thuộc/đường dẫn; chạy từ server root:

```bash
make -C GameServer/framework linux
make -C GameServer
```

Đây là lệnh từ Makefile, chưa phải xác nhận build sạch đạt. Không đổi sang
`linux_nojemalloc` để bỏ qua lỗi rồi kết luận tương đương. Dùng `ldd` trên
executable/module đã build để kiểm thư viện còn thiếu.

## 4. Dịch vụ và kết nối

| Thành phần | Cổng profile CY | Phạm vi |
|---|---:|---|
| Login | 15733 | Client truy cập được địa chỉ quảng bá |
| Game | 15734 | Client truy cập được địa chỉ quảng bá |
| MongoDB | 27018 | Loopback; không mở trực tiếp ra LAN |
| MQTT | 1884 | Theo cấu hình bản cài riêng |

Đây là cổng profile, không phải khẳng định dịch vụ đã lắng nghe. Tạo user MongoDB
phù hợp bí mật mới, thư mục lưu trữ/log và quyền truy cập trước khi khởi động.
Phân biệt IP nội bộ WSL/loopback với IP client nhìn thấy. Chỉ cấu hình khu 1 cho lần dựng đầu.

Các script `Tools/server/provision_test_wsl.py` và `cys_server.sh` còn giả định root
của máy phát triển. Đọc, điều chỉnh rõ đích trước khi dùng. Không nhập nguyên
database hay bản export WSL của người khác để thay bước cài đặt.

## 5. Phiên chạy đầu tiên

1. Kiểm MongoDB, MQTT và process game của **bản cài mới**.
2. Kiểm cổng thực và địa chỉ client dùng.
3. Theo dõi log scene: trước đây nạp khoảng 75 giây, có cửa sổ chờ tới 900 giây.
4. Tạo tài khoản mới qua đường đăng ký server; kiểm allow-list profile client
   lịch sử (`test00`–`test15`) nếu tài khoản bị từ chối.
5. Đăng nhập, tạo nhân vật, vào Đại Lý, di chuyển, giao dịch một lần, thoát sạch
   và đăng nhập lại để kiểm lưu trạng thái.

Ghi rõ lỗi baseline và lỗi mới. Xem [trạng thái](status.md), [xử lý lỗi](troubleshooting.md)
và [ghi chú cài đặt](../../Publication/INSTALL-NOTES.md).
