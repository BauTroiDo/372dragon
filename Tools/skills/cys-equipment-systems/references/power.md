# Võ hồn, Thú hồn, Thần đỉnh, Tu luyện

Đọc [power 24/09](C:/TLBB/085/CY-Source/Docs/specs/power-systems-20260924_vi.md). Nguồn CY/GL và server riêng quyết định bảng, không suy tính năng từ số icon.

- Võ hồn: phân biệt số ô thuộc tính đã học và số ô mở. Growth grade 0–4. Script CY 790076 thiếu trên server: tuyến đã port dùng CGKfsOperate/op 3, hai món cùng cấp, hợp thành<=7, phí 10000 theo quy tắc ví server. Học thuộc tính chỉ tiêu 1 sách trong chồng 250; kiểm trùng/ô trống/khóa trước phí. Không tự mua NB.
- Thú hồn là class 7/type 1, không ép vào trang bị người class 1. Độ thọ `pet_equip_unknow_8`, không dùng hai byte durability vốn 0. TIPS thuộc tính 15–22: `floor(value/10)/10`, một chữ số thập phân; 0–14 số nguyên.
- Thú hồn nâng 1–100 theo bảng, huyết mạch 6 mức; đúng loại Hồn ngọc 20 EXP, loại khác hợp lệ 10. Tẩy tạo kết quả chờ Nhận, bảo vệ GUID/revision; giữ counter MD505/MD509 cho menu thưởng. Kết quả chưa nhận chỉ tồn tại trong phiên; khóa dòng/khóa màu chưa có trong UI gộp.
- Trang bị/tháo Thú hồn qua CGPetUseEquip/CGPetUnEquip, kiểm sở hữu/khóa/giao dịch/xuất chiến/dung hồn/cấp/slot; túi đầy phải giữ item. Vân Thâm Thâm/Tô Châu mở các UICommand 80012701/02/08.
- Thần đỉnh hai nhánh 45 đan/9 phẩm, trích chi phí/điểm từ script CY. Nạp Dược Trần tiêu vật phẩm thật; điểm cộng tham gia human_attrib, không chỉ sửa nhãn. Revision chặn replay; tổng điểm phân phối không vượt số có.
- Tu luyện thường 11 bí kíp, hai bộ, nhân vật 70; bộ 2 có điều kiện bộ 1. CY XiuLianDetail 2416×63, packet 1014 đồng bộ 15 cấp/15 giới hạn; cap 150 riêng với cap nhân vật 200. Bốn kinh mạch tiến giai thiếu hiệu quả server: HasActived=0 và không thu phí.

Điểm vào lịch sử: VH/Vô Nhai Tử Đại Lý~140,195; TL/Tảo Địa Thần Tăng 242,31; TĐ ở SelfEquip; Thú hồn/Vân Thâm Thâm Tô Châu~177,240. Tọa độ cần đối chiếu scene hiện tại, chưa là bằng chứng đã đi đến mọi NPC.

`Tools/server/test_power.lua` dùng bảng/lớp thật với transport giả lập; live probe mode 1 là thao tác thật, mode 2 là relogin. Cần cả hai đúng hash nếu thay trạng thái bền vững. Ảnh preview đẹp không thay thế số tiền/item/chỉ số server. Riêng huyễn hóa và KFSObj đã bổ sung 25/09; dùng tài liệu Wuhun mới thay audit cũ “chưa hiện”.
