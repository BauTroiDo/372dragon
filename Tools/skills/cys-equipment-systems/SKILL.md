---
name: cys-equipment-systems
description: "Sửa trang bị CY-Source: SuperTooltip, cường hóa nhịp rèn, tư chất, khắc minh, Thăng Linh, điêu văn/ngọc và hệ Võ hồn–Thú hồn–Thần đỉnh–Tu luyện. Dùng khi cần nối dữ liệu, công thức và thao tác thật theo GL/CY/server."
---

# Trang bị và hệ tăng trưởng CY

Gốc `C:/TLBB/085/CY-Source`, server thử `/home/ubuntu/cys-test-20260913`. Đối chiếu GL/CY tại chỗ trước sửa; giữ nguồn tham khảo nguyên trạng. Server quyết định điều kiện, chi phí và kết quả; client trình bày dữ liệu từng instance.

## Chọn nhánh cần đọc

- Hiển thị/số liệu/màu: [tooltip và metadata](references/tooltip.md).
- Nhịp rèn, Thăng Linh, điêu văn: [chế tác và luật đã chốt](references/crafting.md).
- Võ hồn, Thú hồn, Thần đỉnh, Tu luyện: [các hệ tăng trưởng](references/power.md).
- Model/huyễn hóa Võ hồn: dùng `cys-appearance-assets`, không chữa bằng công thức tooltip.

## Luồng sửa

Theo dấu item/packet → `CysInventoryNet`/`CysEquipmentTooltipData` → object/host Lua → layout. Xác định template so với instance, class item, GUID, byte mask và lưu–nạp trước khi đổi formatter. Có nút Lua nhưng host stub/script không đăng ký thì phải nối backend thực hoặc báo chưa hỗ trợ.

Sửa cả generator/catalog và nơi dùng khi ánh xạ sai; không tự nghĩ phần trăm hoặc chi phí. Dữ liệu hiển thị đã được server cộng không được cộng lại. Giữ khác biệt khắc minh, tên người chế tạo, Thăng Linh, khế hợp và tăng phúc.

Thao tác tiêu hao cần kiểm item/GUID/revision/tiền/nguyên liệu trước commit và sau mọi lời gọi có thể nhường luồng. Xem `cys-inventory-transactions` khi thay giao dịch. Không mở đường mua nguyên bảo tự động chỉ vì donor có tùy chọn đó.

Kiểm hợp lệ/không hợp lệ, thiếu phí, item đổi ô, gửi lặp, túi đầy và giới hạn cấp theo phần sửa. Có GUI thật, nhận packet thật, số lượng/tiền và đăng nhập lại thì mới báo hoàn tất giao dịch. Unit mọi cấp không đồng nghĩa đã bấm mọi cấp trong game. Phục hồi fixture toàn BSON.
