# Tooltip, màu và công thức

Nguồn: [tooltip 24/09](C:/TLBB/085/CY-Source/Docs/specs/equipment-tooltips-20260924_vi.md), [bổ sung Thăng Linh/màu](C:/TLBB/085/CY-Source/Docs/specs/equipcraft-20260924_vi.md). Tài liệu sau thay thế hạn chế “Thăng Linh chưa làm” của lượt trước, nhưng không tạo ra tên người khắc vốn chưa được server lưu.

| Trường | Hợp đồng |
|---|---|
| Cường hóa | `ItemInfo_bos.enhancement_level`, bảng ItemEnhance của server; tên `(+N)` và phần cộng |
| Khắc minh | `status & 0x40`, cộng 10% thuộc tính cơ bản làm tròn xuống; không phải tên người khắc |
| Tư chất | 6 byte qualifications là index tra hệ số, không phải % trực tiếp |
| creator | Tên + mã `&SQ`, `&ZF`, `&Wnn`; tách metadata, không để tên chèn mã màu/điều khiển |
| Khế hợp | `&SQnnn`, giá trị khế hợp nnn%100; server đã sửa thuộc tính, không nhân lại |
| Thăng Linh | `&Wnn`, khác `&SQ`; phần mở rộng theo bảng ZhiZunEquipRate |
| Ngọc | 4 vị trí list_2, giữ lỗ trống xen kẽ, GemInfo quyết định tên/icon/thuộc tính |
| Điêu văn | ID đầy đủ `diaowen_id * 8 + (dmc & 7)`; tinh khắc lấy dw_advance_level/dw_rankexp |
| Tẩy luyện | reshuffle_count cần được loader nạp lại, không chỉ serialize |

Thứ tự base B: `E=floor(B*enhance/100)`, `K=floor(B*10/100)` nếu khắc minh, `Q=floor(((B+E+K)*aptRate+50)/100)`, rồi tăng phúc theo công thức/loại trừ của server. Byte tư chất có thứ tự ngoại công, ngoại phòng, nội công, nội phòng, chính xác, né tránh; thứ tự cột client khác. Mẫu 117/117,+9,khắc minh,tư chất 100/200,tăng phúc 3 cho 499/537 là ca regression, không là công thức hardcode.

`Tools/game/equipment_tooltip_data.py` sinh bảng C++ từ hệ số server, tên/icon GL. `CysEquipmentTooltipFormat.h` dùng chung cho tooltip chính/Alt. Cache dùng world/server/serial GUID +itemID; gói mới thay toàn metadata, invalid mask/count xóa cũ. Giữ khi chuyển scene, xóa khi phiên login mới; shop template không mượn metadata item trong túi.

Màu GL đã đối chiếu: tên theo **phẩm chất**, không số sao; các giá trị `C8C8C8`/`00FF00`/`00CCFF`/`FF53FF`. Thuộc tính mở rộng `FFCC00`, tên ngọc `B3DB35`; cường hóa/tăng phúc theo Lua/SystemColour. Không gán toàn tooltip cùng màu hoặc bỏ tag mã màu trước khi phân loại.

Kiểm hai item cùng mã nhưng GUID/+N khác nhau, một món thường, GCItemInfo refresh, lỗ ngọc gián đoạn, SelfEquip, Alt, cuộn tới cuối nhiều lần và sát viewport. Với inspect thêm từ chối reply sai người/đã đóng. Chưa có bằng chứng chat item link đầy đủ hoặc tất cả viền bậc cao: chỉ kết luận phần đã thử.
