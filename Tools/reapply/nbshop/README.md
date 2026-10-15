# Tái áp danh mục shop nguyên bảo của CY

Bản sửa chỉ dành cho clone `/home/ubuntu/cys-test-20260913`. Server gốc là nguồn
tham khảo chỉ đọc. Công cụ không khởi động lại server, không ghi Mongo và không
đổi dữ liệu nhân vật. Chạy từ WSL; mặc định chỉ kiểm tra, cần `--apply` mới ghi.

```sh
python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/nbshop/apply_catalog.py
python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/nbshop/apply_catalog.py --apply
```

Sau bản catalog, lời gọi phụ từ `YuanbaoShop_Show` của CY cần áp thêm:

```sh
python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/nbshop/apply_catalog.py --part jiyuan
python3 /mnt/c/TLBB/085/CY-Source/Tools/reapply/nbshop/apply_catalog.py --part jiyuan --apply
```

`jiyuan.patch` thêm `OpenJiYuanShop` vào script 888902, chuyển tới
`DispatchJiYuanShopInfo` giống NPC sống `odali_shenmishangren.lua:46`. Helper
server trả `GCJiYuanShopInfo` từ `human.jiyuan_shop_info`, giữ target và không sửa
dữ liệu. Có gate cấp15 khi gọi từ minimap. Nguồn nhu cầu là
`YuanbaoShop.lua:1254`; log live lúc16:50:42 ngày20/09 chứng minh lời gọi trước
sửa bị `func NOT FOUND`. `test_jiyuan.lua` kiểm3 hợp đồng minimap/NPC/cấp14 bằng
mock, còn `test_catalog.lua` kiểm lại22 hợp đồng catalog trên Lua mới. Chưa tuyên
bố tính năng mua riêng của JiYuan hoạt động; phần này sửa request metadata khi
mở shop thường. Mỗi part khóa hash đầu vào riêng, vì vậy catalog phải áp trước
jiyuan và hoàn tác theo thứ tự ngược lại từ backup tương ứng.

Công cụ kiểm SHA-256 cả hai đầu vào và patch, thử áp trong thư mục tạm bằng GNU
patch với fuzz=0, kiểm SHA-256 đầu ra rồi kiểm encode/decode nguyên byte: Lua UTF-8,
ShopTable GBK. Khi ghi, nó sao lưu đầy đủ hai file vào
`backups/nbshop-<UTC>/` trước khi sửa, và khôi phục cả cặp nếu ghi thất bại. Đầu vào
khác phiên bản đã review hoặc trộn cũ/mới bị từ chối. Đầu ra đã đúng cả hai hash
được báo `ALREADY APPLIED` và không ghi thêm.

Payload tái áp chuẩn nằm trong `*.patch.b64`; `.patch` để review nội dung. Bản
base64 có hash bytes gốc trong manifest, vì patch lồng trong một patch Git khác
có thể mất CR ở cuối dòng. Công cụ decode nghiêm ngặt và kiểm hash cả khi đầu ra
đã áp. Nhờ vậy chuyển LF/CRLF của file nguồn không làm hỏng patch GBK/CRLF bên
trong, và không phải nới kiểm tra hash hoặc fuzz để áp dữ liệu.

Bản đã áp ngày 20/09/2026 được điều phối viên lưu tại
`/home/ubuntu/cys-test-20260913/backups/nbshop-20260920T092636122297Z`.
Để hoàn tác, khi điều phối viên đã dừng clone, chép đúng hai đường dẫn tương đối
trong `manifest.json` từ một thư mục backup về clone và xác nhận hash `before`.
Không chép backup của clone sang server gốc. Việc restart và kiểm 16 cổng/198 scene
thuộc điều phối viên để không đụng lượt game của nhánh khác.

`yuanbaoshop.patch` ánh xạ 87 ô menu thường, nguyên bảo khóa và lối tắt tìm kiếm
theo tên/nội dung/tiền tệ của bảng CY. Ví dụ dãy đá cấp 3/4/5/6 là
150/307/308/178; không kế thừa số shop GL một cách máy móc. Tọa độ menu sai trả
thông báo thay vì index nil. Giá và điều kiện cấp 15 giữ nguyên.

`ShopTable.patch` chỉ sửa dòng shop 182: bỏ 9 mã class 5 không tồn tại trong
GemInfo, dồn 102 nhóm sáu cột còn hợp lệ, đặt Num=102 và đệm -1 phần dư. Factory
thật `GameServer/lualib/item.lua:2259` chọn riêng gem_info cho class 5;
`cfghelper.lua:1985` nạp GemInfo. Client `Obj_Item.cpp:181` cũng chỉ chọn bảng gem.
Đã kiểm cột PID, không nhầm giá/tên. Bảng CY tham khảo tại
`C:/TLBB/085/Tools/DATA NEW/CYHJ091026/Config/ShopTable.txt` không có 9 nhóm sai đó; chi tiết
hash và vị trí nằm trong `item182-evidence.json`. Các nhóm giữ lại nguyên sáu cột
và các dòng shop khác nguyên byte.

`catalog-validation.json` giữ 87 ánh xạ, tiền tệ 5/9 và mẫu tên item đã đối chiếu.
`test_catalog.lua` kiểm 22 hợp đồng dispatch của script bằng mock, không dùng
server/DB. Chạy với đường dẫn Lua đề xuất hoặc Lua đã áp:

```sh
lua /mnt/c/TLBB/085/CY-Source/Tools/reapply/nbshop/test_catalog.lua /home/ubuntu/cys-test-20260913/Game_2/Script/scripts/event/prize/yuanbaoshop.lua
```

Đây là nghiệm chứng tĩnh. Chưa thay thế việc đo client gửi yêu cầu, nhận hàng,
hộp xác nhận, hủy/mua và số dư UI. Các nhánh VIP, quà tặng, lễ kim, JiYuan và lịch
sử mua của giao diện CY chưa được tuyên bố hỗ trợ bởi bản vá này. Xem hồ sơ
`Timeline/handoff/unequip-nbshop-resume_vi.md` để biết phạm vi và nghiệm thu live.
