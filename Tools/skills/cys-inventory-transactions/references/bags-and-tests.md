# Túi, kho phụ, shortcut và công cụ

## Vùng dữ liệu

`prop_bag_list` trong BSON chứa cả vùng đồ/nguyên liệu/nhiệm vụ:

| Vùng | Index client | Key BSON tương ứng |
|---|---|---|
| Đồ | 0–99 | 1–100 |
| Nguyên liệu | 100–199 | 101–200 |
| Nhiệm vụ | từ 200 theo cấu hình hiện tại | Không chiếm bằng mở rộng túi đồ |

Không suy tab từ tên field Mongo. Wuhun dùng tiêu hao GL theo vùng nguyên liệu; một fixture class 2 đặt sai vùng đồ có thể được hàm count tìm thấy nhưng `del_available_item` không tiêu được. Chữa fixture theo schema, không nới handler cho dữ liệu sai. Kho Thiên cơ cẩm nang là 120 ô độc lập, không phải phần mở rộng túi 100.

## Các tuyến đã có

- `Tools/server/round2_swap.py`: gộp/đổi và `item_operator:move_item`, revalidate sau config yield.
- `Tools/server/round2_basic.py`, `test_round2.lua`, `round2_live_fixture.py`: stack/túi/EXP/loot.
- `Tools/game/round2_tembank.py`: giao diện kho phụ; backend/packet hiện tại tra từ báo cáo đợt 2, đừng nối Bank:AskTemBankList vào kho thường.
- `Tools/server/cys_equipcraft.lua`: quote/revision, cấp thưởng trước commit, kiểm slot thưởng. Học mẫu này khi cần giao dịch mới, giữ khác biệt từng hệ.
- Phím tắt item lưu **loại item** để tìm lại stack/vị trí mỗi lần dùng. Cạn stack xóa action/count tạm nhưng giữ loại shortcut, để tìm chồng khác. Không tạo item ảo hoặc tái dùng con trỏ object đã xóa.
- Nhặt tất cả duyệt GUID thực của bọc, giữ ô rỗng xen kẽ; request lặp không được sinh thêm vật phẩm.

## Ca thử đã tìm lỗi thật

249+1 phải 250, không 251 khi replay; tách 100/150 rồi gộp bảo toàn; ô cuối index 99 hợp lệ, index 100 là vùng khác; túi đầy/khóa/bound/khác GUID/đổi đích trong yield. Live loot 250→251 hợp lệ **khi bọc có đúng một item**, khác hẳn lỗi gộp 249+1→251. Không dùng một ngưỡng số chung để kết luận dupe.

Kho phụ: cất/rút item +2, cùng GUID sau relogin, revision stale từ chối. Shortcut: kéo thuốc→đổi ô→dùng 3→2→1→0→chuyển stack khác→bấm khi hết; đối chiếu số tiêu thật trên server.

Fixture sao lưu toàn BSON khi actor đã offline; scan serial trên mọi túi khi cấp dữ liệu test. `restore` phải khôi phục cả trạng thái nhiệm vụ/skill/settings, không chỉ đồ được thêm. Không sửa tài khoản người chơi ngoài phạm vi kiểm tra đã được giao.

Nguồn: [gameplay đợt 2](C:/TLBB/085/CY-Source/Docs/specs/gameplay-round2-20260923_vi.md), [shortcut](C:/TLBB/085/CY-Source/Docs/specs/actions-equipment-audit-20260923_vi.md), [giao dịch chế tác](C:/TLBB/085/CY-Source/Docs/specs/equipcraft-20260924_vi.md).
