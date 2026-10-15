# Áp lại bản sửa túi và toàn vẹn vật phẩm — 22/09/2026

Chỉ áp vào server riêng `/home/ubuntu/cys-test-20260913`. Không sửa các cây gốc
`/home/ubuntu/GameServer`, `/home/ubuntu/Game_2`, client, client_GL hoặc CY Game.
Thực hiện sau `equipment_skills.py` và bản sửa sư môn nếu dựng lại từ backup cũ:
chúng có các tệp chung với đợt này. Công cụ biến đổi từng hàm, giữ phần còn lại,
kiểm tính lặp lại và ghi manifest SHA256 cùng backup trước khi ghi.

## Lập plan và kiểm trước khi áp

Tại `C:/TLBB/085/CY-Source`:

```powershell
python -B Tools/server/inventory_integrity.py --out Build/Logs/inventory-plan
wsl -d TLBB -u root -- lua5.4 /mnt/c/TLBB/085/CY-Source/Tools/server/inventory_integrity_tests.lua /mnt/c/TLBB/085/CY-Source/Build/Logs/inventory-plan/GameServer /mnt/c/TLBB/085/CY-Source/Tools/server/inventory_guard.lua
```

Hiện có 63 ca. Chúng thực thi các hàm/container thật được trích từ plan; đối tượng
vật phẩm, GUID, tiền và giao tiếp là fixture. Hai ca kiểm thứ tự thông báo/chi tiết
chống hồi quy đã gặp ở lượt live đầu. Kiểm này không thay thế lượt chơi thật.
Mười ca bổ sung kiểm nhặt đồ/hái lượm: chồng nhiều món, đầy túi, khóa, binding,
metadata và giả mạo loại đối tượng hộp. Lượt kiểm nhặt đồ này là offline.
Chạy `luac5.4 -p` riêng từng tệp Lua trong manifest; không truyền nhiều tệp vào
một lần gọi parser. Tệp `item_container.lua` trong plan là phụ thuộc chỉ đọc,
không nằm trong danh sách triển khai.

## Triển khai

Giữ khe Game bằng `Tools/perf/game_slot.ps1`, ghi đủ NHAN/TRA trong
`Build/game-slot-queue.txt`; không còn client kết nối trước khi restart.

```powershell
python -B Tools/server/inventory_integrity.py --out Build/Logs/inventory-deployed --apply
wsl -d TLBB -u root -- bash /mnt/c/TLBB/085/CY-Source/Tools/server/cys_server.sh restart --confirm-root /home/ubuntu/cys-test-20260913
```

Chờ nạp scene. Kiểm 6 dịch vụ riêng, 16 cổng riêng và log mới; đừng suy từ trạng
thái ngay khi vừa tạo tiến trình rằng server đã nạp xong. Bản vá gồm 7 tệp, trong
đó `cys_inventory_guard.lua` là module mới. Đường backup chính xác nằm trong
manifest của chính lần chạy. Không khôi phục tệp chung từ backup cũ sau khi đã có
bản sửa mới của nhánh khác.

## Kiểm trong game

Client cần build các thay đổi `CysInventoryNet`, `CysModernHandlers` và probe.
Probe mặc định tắt. Khi kiểm có chủ ý, dùng runner private và tài khoản test15:

- `CYS_INVENTORY_INTEGRITY_LIVE=1`: đeo/đổi/tháo hành nang, 20/24/40 ô,
  nguyên liệu, chuyển ô mở rộng, từ chối thu nhỏ có đồ, gói sai, sắp xếp, chia chồng.
- `CYS_BAG_PACK_OLD=1`: đối chứng âm, cố tình không gửi yêu cầu sắp xếp.
- `CYS_INVENTORY_INTEGRITY_LIVE=2`: đăng nhập lại, đối chiếu 40/40 ô và số lượng.
- `CYS_BAG_LIVE=1` + `CYS_BAG_SHOP_LIVE=1`: đi tới NPC thật, mua ô mới,
  mua chồng, bán chồng, kiểm widget/tiền và di chuyển sau đóng khung.

`inventory_fixture.py` chỉ nhận GUID200016. `seed` bắt buộc backup mới;
`--full` lấp 20 ô cho đối chứng mua khi túi đầy. Luôn thoát phiên, xử lý cache
server đúng trước khi thay fixture, rồi `restore` và đối chiếu mọi trường đã sao
lưu. Backup dữ liệu nhân vật thuộc Build và không đưa vào git. Không dùng test09
hoặc test13.

Sau `restore`, dùng `verify` để đọc và so lại toàn bộ7 trường với backup, không
ghi lại DB. Nếu lượt trước thoát bất thường, restart private trước khi sửa DB
để tránh trạng thái nhân vật còn trong RAM ghi đè bản đã khôi phục.

Phát hành dùng `Tools/game/publish_inventory_client.py` với bốn đối số
`--negative`, `--expanded`, `--relogin`, `--shop` là thư mục bằng chứng của cùng
binary đang stage. Công cụ yêu cầu feature marker,20/20 world/move/quit và
manifest khớp, sao lưu Play21, giữ profile và xóa các cờ probe trong launcher.

## Giới hạn

Thiên Cơ Cẩm Nang vẫn thiếu tuyến host/gói/dịch vụ riêng. Bản vá này không giả
lập nó bằng kho NPC. Chưa chứng nhận mọi đường giao dịch, bày bán, thư, hạn mức
shop toàn server hoặc phục hồi sau mất điện. Sắp xếp hiện giữ nguyên từng stack
và GUID; chưa khẳng định quy tắc tự gộp và thứ tự ưu tiên giống hoàn toàn CY.

Kết quả và các lỗi phép kiểm được ghi ở
`Timeline/handoff/inventory-integrity-22-09_vi.md`.
