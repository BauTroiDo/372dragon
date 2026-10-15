# Cài mới: những gì bộ chuẩn bị cung cấp

**372dragon:** bắt đầu từ [hướng dẫn cài đặt](../Docs/guide/getting-started.md),
[build client](../Docs/guide/build-client.md) và [server](../Docs/guide/server-setup.md).
File này giữ các ghi chú kỹ thuật của bản xuất CY-Source.

Đây là hướng dẫn về bố cục và các bước cần nghiệm thu, chưa phải tuyên bố cài đặt tự động đã đạt.

1. Clone source và lấy phụ thuộc theo THIRD_PARTY.md. Nếu gói data đã được phép chia sẻ,
   kiểm SHA-256 rồi giải nén một ZIP64 ở root: Data ở `Assets/CanonicalCY/Data`,
   overlay ở `Play/Overlay`, scene/bảng server ở `Server`. DLL/SDK/runtime được lấy riêng.
2. Dùng `Setup-Play.ps1` nối `Play/Data` đến kho Data. Tên file Unicode/mojibake của
   tài nguyên phải giữ nguyên. Không đổi encoding GBK trong all.material, all.obj,
   all.effect, all.particle hoặc tên tài nguyên.
3. Trong một Linux/WSL dùng riêng, đặt server ở root dự kiến. Cài MongoDB 4.4.31 và
   Mosquitto theo hướng dẫn vận hành; giữ MongoDB trên loopback. Không phát hành nguyên
   file export WSL của người phát triển.
4. Mười cấu hình trong `Server` đã mang đuôi `.template`. `init_config.py` chỉ tạo
   cấu hình trong bản sao do người dùng chỉ định và sinh bí mật ngẫu nhiên mới;
   nó không tự tạo user MongoDB, cài service hay khởi động server.
5. Tạo user MongoDB cục bộ tương ứng với bí mật mới, thư mục db/log và tài khoản game
   mới qua đường đăng ký của server. Không dùng database/test character của người phát triển.
6. Kiểm lại thư viện ELF bằng `ldd`, Makefile và phụ thuộc framework. Source tree hiện có
   cần đối chiếu các thư viện như OpenSSL/jemalloc trước khi hứa build server sạch.
   Bản xuất không chứa `libjemalloc.so.2`; header cục bộ chưa xác định được phiên bản
   chính xác. Không coi thư mục header này là bộ source jemalloc hoàn chỉnh.
7. Các script `provision_test_wsl.py`/`cys_server.sh` cũ có đường dẫn root cố định.
   Chỉ dùng sau khi kiểm lại root; không chạy nhầm lên server chính.
8. Nghiệm thu tối thiểu trên máy mới: khởi động đủ dịch vụ, chờ scene nạp (khoảng 75 giây,
   có thể chờ tới 900 giây), đăng ký/đăng nhập, tạo nhân vật, Đại Lý, di chuyển, mua một
   vật phẩm, thoát sạch và đăng nhập lại. Chưa thực hiện bài này trong đợt đóng gói.

Cổng mặc định của CY: login 15733, game 15734, Mongo 27018, MQTT 1884.
Profile client hiện chỉ cho tên tài khoản `test00` đến `test15`; cần chỉnh allow-list
cho tài khoản của người cài. Đây là danh sách tên, không kèm mật khẩu.

Các phần không đóng gói công khai: `.local`, `.git` cũ, database `db`, backup DB,
dump tiến trình, log phiên chơi, account-created/provision records, bản export toàn WSL.
Các phần đó chứa trạng thái của máy phát triển, không phải bộ dữ liệu game tĩnh cần cho người chơi.

`Setup-Play.ps1` chỉ nối Data khi người cài đã tự dựng/chuẩn bị `Play/Bin64/Game.exe`.
Gói data không chứa Game.exe hoặc DLL runtime. Chưa tự động dựng đầy đủ Play trên
máy sạch, chưa tự khởi tạo user MongoDB hay tài khoản game trong đợt chuẩn bị này.

Bản xuất có đủ ba header Boost `preprocessor/debug/assert.hpp`, `error.hpp`, `line.hpp`
ở `Src/ThirdParty/boost/boost/`. CMake có đường dự phòng lấy chúng từ Reference khi bị
thiếu; bản xuất hiện tại không cần dự phòng đó. Notice của Boost giữ nguyên.
