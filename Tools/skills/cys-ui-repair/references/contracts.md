# Các hợp đồng dễ nhầm của UI

## SelfEquip và ô nhỏ

- `TLBB_ActionButton` có `BackgroundImage` và `BackImage` ô trống. Không thêm nền vào mọi control trong suốt. Yêu cầu riêng thanh Alt dùng `TLBB_ActionButtonNULL`, bỏ BackImage; icon/hover/cooldown/kéo thả còn nguyên. Không giảm alpha toàn nút.
- `BaoShiCheckRed/Green` là nút đổi ngọc, không phải độ bền. Thanh độ bền riêng rộng 3 px lấy `dam/dam_max`, ở trong `ActionArea` với inset 2 px, đỏ dưới 10%, ẩn khi không có dữ liệu. Không dùng điểm độ bền như phần trăm.
- `ShowDurability` chỉ bật cho SelfEquip/TargetEquip. Item bị hủy phải xóa tỷ lệ cũ. Viền Chí Tôn/Vương Quyền/Thiên Đạo dựa metadata được xác minh, không dựa riêng sao hoặc chỉ số cao.
- Mốc SelfEquip rộng 756 thay 820 là bố cục đã thử, không là kích thước bắt buộc cho mọi màn hình. Giữ vùng số cộng xuất hiện/ẩn không đè giá trị.

Nguồn: [nền/độ bền](C:/TLBB/085/CY-Source/Docs/specs/cell-skin-durability-20260923_vi.md), [bố cục và action](C:/TLBB/085/CY-Source/Docs/specs/actions-equipment-audit-20260923_vi.md), [Alt trong suốt](C:/TLBB/085/CY-Source/Docs/specs/progression-200-20260924_vi.md).

## Tooltip và inspect

- SuperTooltips_Cmp1/Cmp2 phải có receiver/metatable đúng, không đọc nhầm tooltip chính. So sánh bằng Alt giữ/nhả thật; xét hai slot nhẫn/hộ phù và cạnh viewport.
- Tooltip giữ ID action rồi tìm lại object đang sống, không giữ con trỏ action cũ sau refresh. Metadata từng item dùng GUID đầy đủ; xem công thức trong `CysEquipmentTooltipFormat.h`.
- Scroll từ tọa độ đầu tài liệu, không cộng dồn vị trí âm qua PixelAligned: lỗi cũ lệch 44 px sau cuộn nhiều lần ở đáy. Giữ phần tên người chế tạo/mô tả và tooltip so sánh trong viewport.
- Inspect ràng buộc serverID/clientID/GUID của người được xem. Chặn reply cũ/sau đóng và không lấy ngoại hình người đang đăng nhập. Gói sparse/mask sai phải xử lý an toàn.
- Profile server không gửi điểm chiến đấu/thiết bị hoặc thông tin cá nhân thì hiện `--`/trống, không dựng dữ liệu giả. Một lượt hai client 23/09 không chứng minh công thức trang bị thêm 24/09 đã được thử lại trên hai người.

## Hội thoại, tên và input

- Icon hội thoại lấy kích thước cell imageset (mốc khảo sát 25×25), không ép 16×16. Icon nằm trước lựa chọn cần hover/click cùng hàng; đối chiếu bảng 32 mã thay vì thay ảnh theo trí nhớ.
- Tên/danh hiệu NPC đo font thật, cộng padding/dấu tiếng Việt, wrap khi quá dài; đẩy danh hiệu theo chiều cao tên. Mốc 23/09: giới hạn ngang 600 px và cao tối thiểu32 px. Kiểm cả tên ngắn để tránh khung rộng thừa.
- SystemColour CY đã xác minh: NPC hòa bình chữ `FFFFFF`, viền `2727FF`; quái chủ động `FF0000`/`880000`; thụ động `FFFF00`/`888800`. Người dùng nhớ NPC vàng là câu hỏi đối chiếu, không phải yêu cầu ép đổi bảng. Quan hệ/đang bị đánh dùng dòng riêng.
- Map CY đăng ký `MouseLButtonClick`, widget cũ từng phát `MouseLClick`. Test click thật trên Alt+M tới AutoRunToTarget và tọa độ nhân vật, không gọi trực tiếp setter vị trí.
- Esc giữ thứ tự xử lý edit/chat/khung. Đóng được UI nhưng bị bắt input bởi parent trong suốt vẫn là lỗi.

Nguồn: [nameboards](C:/TLBB/085/CY-Source/Docs/specs/npc-nameboards-20260923_vi.md), [gameplay đầu](C:/TLBB/085/CY-Source/Docs/specs/gameplay-fixes-20260923_vi.md).
