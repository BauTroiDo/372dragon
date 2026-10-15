# Khảo sát huyễn hóa và ngoại hình Võ hồn — 25/09/2026

Đây là khảo sát **trước sửa** của binary `e83e8856…`. Phần triển khai và
bằng chứng kiểm tra tiếp theo nằm trong
[wuhun-appearance-fix-20260925_vi.md](wuhun-appearance-fix-20260925_vi.md).

## Bản được kiểm tra

Play: `Build/world-gui/stage-play-21`. SHA-256 Game:
`e83e88560eb4b41a84bfe72b743660ab552108e7b543dfb5a87225367c8d876f`.
Trùng binary của lượt GUI `Build/Logs/2026-09-25-wuhun-scale/live-02`.
Test15 có Võ hồn 10156001 được trang bị; lượt đó kiểm tra tháo/lắp thực tế,
chụp màn chọn nhân vật, thế giới, SelfEquip và tab Võ hồn.

## Kết quả

| Phần | Trạng thái hiện tại |
|---|---|
| Xem riêng Võ hồn trong tab VH | Đã có mô hình đúng, phóng lớn, tháo/lắp cập nhật đúng |
| Đổi ngoại hình / huyễn hồn qua giao diện | Chưa hoàn thiện; chưa có kiểm chứng giao dịch đầu-cuối |
| Võ hồn đi cùng mô hình nhân vật ngoài thế giới | Chưa được nối vào lớp hiển thị trang bị |
| Võ hồn đi cùng mô hình nhân vật trong SelfEquip | Chưa hiển thị |
| Võ hồn trong màn chọn nhân vật | Chưa hiển thị; dữ liệu ngoại hình mở rộng còn thiếu |
| Nút ẩn/hiện Võ hồn | Lua hiện gọi host stub, chưa có hành vi thực |

## Bằng chứng mã nguồn

1. `Src/Client/WXClient/Network/CysInventoryNet.cpp::OnCharEquipment` nhận
   `GCCharEquipment` nhưng chỉ cập nhật vũ khí, mũ, giáp, tay, giày và thời
   trang. Không dùng hai trường `wuhun_item_id` / `wuhun_visual` dù decoder
   trong `PgPackets_misc.h` đã chứa chúng.
2. `Src/Client/WXClient/Object/Character/Obj_PlayerOther.cpp::UpdateEquip`
   chưa có nhánh trang bị Võ hồn. Đây là đường dùng chung cho nhân vật thật
   và fake avatar; chỉ chép item ID vào dữ liệu không tạo được ngoại hình.
3. `Src/Client/WXClient/Procedure/CysCreateRoleGame.cpp` đưa equip vào avatar
   màn chọn, sau đó cập nhật thời trang, vũ khí huyễn và phụ kiện; chưa có
   bước cập nhật ngoại hình Võ hồn riêng.
4. Server riêng `GameServer/services/login/packet.lua` ghi các trường
   `kfsgrade`, `WeaponID (WHWG)`, `WeaponLv (WHWG)` bằng 0. Không thể coi dữ
   liệu ngoại hình huyễn hồn ở màn chọn đã đầy đủ.
5. `LuaApiGen_SystemSetup.cpp` vẫn dùng stub cho `GetShowWuhunObj` và
   `SetShowWuhunObj`; `LuaApiGen_DataPool.cpp` vẫn dùng stub cho
   `LuaFnCastChangeWGSkill`. Không thấy bản thay thế trong nguồn client.
6. `CysHost_MeshWin.cpp::UpdateWuhunModel` vẫn lấy `WuhunModelId(item, 0)`.
   Việc duyệt 10 mô hình trong probe là kiểm tra dựng tài nguyên trực tiếp,
   không chứng minh server đã thực hiện huyễn hóa hay lựa chọn biến thể.

## Đối chiếu với bản có sẵn

Client GL có `WuhunJian`, `WuhunTupuActive`, `WuhunTupuStudy`,
`WuhunTupuJinjie` và các hàm `Wuhun_OpenWGChange`, `Wuhun_ChangeYY`,
`Wuhun_SendShowState` gọi script 888800. Bộ Wuhun hiện dùng trong CY-Source
không có đầy đủ luồng đó.

Server riêng đã có `Game_2/Script/scripts/event/equip/huanhun.lua` và
`GameServer/services/scene/human.lua::get_wuhun_visual`: chọn ngoại hình theo
huyễn hồn Càn/Khôn, hoặc theo Võ hồn thường khi không có huyễn hồn. Server
cũng phát `GCCharEquipment` khi thay đổi. Sự tồn tại của các hàm này chưa
thay thế kiểm thử kích hoạt, trừ nguyên liệu, thay ngoại hình và đăng nhập lại.

## Phạm vi cần hoàn thiện

Nối dữ liệu ngoại hình từ server tới nhân vật thật, avatar SelfEquip và avatar
màn chọn; sau đó nối giao diện huyễn hồn và ẩn/hiện theo GL, kiểm tra đầy đủ
thay ngoại hình, tháo/lắp, chuyển bản đồ và đăng nhập lại. Giữ riêng mô hình
trong tab Võ hồn để không tái phát lỗi dựng cả nhân vật trong tab VH.
