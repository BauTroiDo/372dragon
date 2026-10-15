# Server riêng, fixture và phiên GUI

## Vận hành

Từ gốc CY-Source, xem trợ giúp/current implementation của `Tools/server/provision_test_wsl.py`. Các lệnh đã dùng cho server riêng:

```powershell
wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py status
wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py stop --confirm-root /home/ubuntu/cys-test-20260913
wsl -d TLBB -u root -- python3 /mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py start
```

Chỉ stop/start khi cần cho công việc đã được giao, thông báo trước và xử lý kết nối người chơi đang có; không dùng `Stop-TLBB.cmd` của hệ chính để restart CY. Các deploy tool mới kiểm PID/root, hash và kết nối trước khi ghi. Trạng thái process vừa lên nhưng port chưa nghe có thể là đang nạp scene (~75 giây, giới hạn vận hành 900 giây). Kiểm cổng và log mới, không chỉ PID cũ.

Theo AGENTS, khi cần kiểm hệ chính thì dùng script vận hành của hệ chính và IP LAN Windows hiện tại; IP ghi trong báo cáo cũ chỉ là ảnh chụp tại thời điểm đó. `tlbb-game` từng failed dù status.sh còn thấy PID: không báo healthy từ một nguồn đơn lẻ, không tự sửa baseline ngoài nhiệm vụ. Không ghi credential Mongo/MQTT/game vào log hoặc tài liệu.

## Fixture và tính toàn vẹn

- test15/GUID 200016 là fixture lịch sử phổ biến, không là quyền mặc định sửa mọi tài khoản. Kiểm đúng môi trường, tài khoản, GUID; dùng backup toàn BSON của **đợt hiện tại** trước khi seed.
- `wuhun_appearance_fixture.py`, `equipment_tooltip_fixture.py`, `equipcraft_fixture.py`, `power_live_fixture.py`, `progression_live_fixture.py` và `round2_live_fixture.py` đã có; đọc chế độ/điều kiện từng tool thay vì tự viết SQL/Mongo cập nhật lẻ.
- Không ghi đè backup gốc khi chạy lại. `reset` về seed khác với `restore` toàn BSON gốc. Sau thử, xác nhận equality toàn bản ghi, không chỉ tiền/level.
- Không còn TCP chưa chắc actor cache đã offline sau crash. Cache server có thể ghi đè fixture Mongo. Chẩn đoán session; thoát bằng giao thức hoặc phục hồi tiến trình riêng thuộc tác vụ trước khi reset.
- `prop_bag_list` chứa nhiều vùng: index client 0–99 → khóa BSON 1–100 cho đồ; 100–199 → 101–200 cho nguyên liệu; vùng nhiệm vụ riêng. Hàm đếm có thể thấy item sai vùng nhưng hàm tiêu hao GL không thấy. Lỗi seed sai tab phải sửa fixture, không sửa luật tiêu hao để che lỗi.

## Bộ chạy GUI

`Tools/game/run_world_gui_live.ps1` có probe chuyên biệt. Đọc tham số hiện tại, dùng child environment và cấu hình credential cục bộ; không in nội dung `.local`. Giữ PID được tạo, không kill mọi `Game.exe`, không lấy input desktop của người dùng làm dữ liệu thử. Probe input phải đi qua cầu input của chính game, không đặt thẳng kết quả server.

- Có hai hạn: `Seconds` bên ngoài và world deadline bên trong `CysGlLoginSmoke`. Probe Wuhun 36 model dùng `CYS_WORLD_SMOKE_TIMEOUT_MS=260000` trong miền cho phép 180000–600000. Chỉ tăng khi thời lượng chức năng cần, không che treo thật.
- Mã exception `E06D7363` là C++ throw, chưa đủ kết luận model/mesh crash. Lượt Wuhun từng là `std::runtime_error` do deadline. Dùng minidump/PDB cùng binary; nếu helper symbolizer rỗng, kiểm stderr/CLI thay vì suy không có symbol.
- Flag đăng nhập 8 là phiên còn online trong nguồn server đã khảo sát, flag 21 liên quan hàng đợi thoát. Đọc log/handler trước khi thử mật khẩu hoặc login liên tục.
- `WXClient.log` append; archive log cũ và ghi hash trước run để tránh marker cũ làm PASS giả. Không sửa/xóa lỗi của lượt thất bại.
- Screenshot là yêu cầu có thời điểm: chụp và ẩn cửa sổ ngay cùng phase có thể tạo ảnh thế giới mang tên SelfEquip. Xem ảnh thật trước kết luận.
- Marker riêng phải kết thúc, errors=0 và không có FAIL/Lua/packet/crash liên quan. Một lần đăng nhập thành công không chứng minh wheel, giao dịch hoặc render đã đúng.

Nguồn ca cụ thể: [Wuhun cuối](C:/TLBB/085/CY-Source/Docs/specs/client/wuhun-appearance-fix-20260925_vi.md), [bay cao](C:/TLBB/085/CY-Source/Docs/specs/server/mount-high-flight-20260924_vi.md), [cấp 200](C:/TLBB/085/CY-Source/Docs/specs/progression-200-20260924_vi.md). Đường backup/hash trong đó là mốc lịch sử.
