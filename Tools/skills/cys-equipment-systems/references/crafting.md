# Nhịp rèn và chế tác

## Quyết định người dùng đã khôi phục từ lịch sử

Chuỗi `1A 2A 3A 4C (Giảm 1 cấp, mất lượt cường hoá) 5B 6A` nghĩa là: thay thao tác cường hóa cũ, giữ bảng chỉ số hiện có, trừ phí khi bắt đầu, trượt giảm 1/mất lượt, thành công tự tiếp tục, không timeout chờ Space. Người dùng trả lời thêm **cả vàng và nguyên liệu**. Đây là thiết kế mới đã chọn; không gọi timing minigame là hành vi native CY.

[Đặc tả nhịp rèn](C:/TLBB/085/CY-Source/Docs/specs/forge-timing-20260923_vi.md): NPC Âu Dã Tử, Tô Châu(355,234) tại mốc khảo sát; UICommand 1002, script 809262. Xác minh tọa độ/script runtime nếu dữ liệu đã đổi.

- 9 cấp; thành công +1, trượt -1 sàn 0; đồ cũ >9 giữ nguyên. Phí từng lượt kể cả tự tiếp tục; chỉ đặt ô/báo giá chưa thu phí. Thứ tự giao tử/vàng giữ server.
- Độ rộng vùng trắng 30→6%, một chiều 2,6→1,0 giây, chuẩn bị 1 giây và nghỉ thành công 1,1 giây là tham số triển khai lịch sử; sửa ở nguồn luật, không rải giá trị trong UI.
- Server cấp challenge/nonce một lần, tính vị trí từ thời gian, không nhận bool client “thắng”. Space bắt cạnh xuống; giữ phím không tự thắng lượt sau. Dung sai 350 ms không chứng minh chống bot.
- Hủy/đóng/đổi scene/thoát giữa lượt đã triển khai như bỏ lượt, mất phí/giảm cấp. Đây là quy tắc triển khai được báo trong kết quả, không phải một lựa chọn riêng trong sáu câu hỏi. Lưu lượt dở, xử lý khi load lại; khóa item thật trên server, không dựa `Obj_Item::IsLocked()` cục bộ.
- `Tools/server/cys_forge.lua`, `deploy_forge.py`, `test_forge.lua`; `Tools/game/forge_layout.py`, `forge/EquipStrengthen.lua`; `Network/CysForge.cpp`. Script registry/UICommand routing phải đầy đủ, không broadcast phản hồi đến mọi cửa sổ.

## Thăng Linh và điêu văn

[Đặc tả chế tác](C:/TLBB/085/CY-Source/Docs/specs/equipcraft-20260924_vi.md), `Tools/server/cys_equipcraft.lua`, `test_equipcraft.lua`, `Tools/game/equipcraft_ui.py`, `stage_equipcraft.py`, `Network/CysEquipCraft.*`.

Mở Hành trang→Chế tác: Thăng Linh/Khắc/Nâng cấp/Tháo/Hợp thành/Chuyển. Giữ skin/nút/ô hiện có. Báo giá đầy đủ trước khi bật thực hiện, phụ liệu từ túi thật, không tự mua NB.

- Thăng Linh theo CY ZhiZunEquipRate: thường nhân vật 85, đồ cấp 80 và ít nhất 6 sao, kiểm loại và ngoại lệ từ nguồn. Chí Tôn 0–9→Vương Quyền 0–9→Thiên Đạo. Ngoại lệ Lưu Bác chưa xác định thì không tự mở.
- `&Wnn` trước `&ZF`, giữ creator, kiểm giới hạn 32 byte trước thu phí. Cộng `floor(extraAttr*rate/100)` trước tăng phúc, không nhân lại base/gem/diaowen. Bảng/tỷ lệ có bằng chứng CY; toàn công thức runtime GL độc lập chưa được chứng minh.
- Tháo trả viên cùng cấp +nguyên liệu đã tích lũy có khóa; cần đủ chỗ trước commit. Không dùng ô sắp tiêu hao như ô thưởng sẵn có. Có tinh khắc/EXP/effect thì chặn tháo; chuyển giữ toàn bộ metadata.
- Chuyển cần cùng vị trí, đồ cấp>=50, đích chưa có điêu văn; khóa đích. Tinh khắc là luồng riêng, không xem nút “Nâng cấp” là hoàn tất mọi dạng điêu văn.
- `990029:Action`, lối cũ 809272/880036 phải đăng ký AllowableScriptFunc; không tắt whitelist để chữa thiếu handler.

Gem: kiểm ID nguồn **và kết quả** trong GemInfo trước thu phí. Audit 23/09 tìm 30 công thức số học có đích thiếu; vá này không làm hoàn tất Gemcompose 4 đối số so với host 2 đối số, modern mapping hoặc CGUseGem 507. Kiểm lại từng tuyến Lua→native→server trước nói toàn hệ ngọc hoạt động.
