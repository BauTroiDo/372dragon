---
name: cys-gameplay-state
description: "Sửa logic gameplay CY-Source/Skynet: kỹ năng và phím tắt, môn phái, nhịp đánh/đạn/EXP, khinh công, cổng bản đồ, cấp 200, tự chiến đấu và ranh giới Thiên phú. Dùng khi UI, animation và trạng thái server không khớp."
---

# Trạng thái gameplay CY

Gốc `C:/TLBB/085/CY-Source`; sửa server riêng `/home/ubuntu/cys-test-20260913` nếu tác vụ cần. Học đúng client CY/GL và server hiện có trước sửa. ID skill/phái/action/cột bảng giữa các nhánh không tương đương chỉ vì cùng số.

## Lần theo sự kiện thực

Theo input → action/AI → request → server skill/item engine → packet trạng thái → animation/UI. Phân biệt danh mục, đã học, đủ điều kiện và đang thi triển. Không cấp quyền dùng chiêu bằng cách hiện icon hoặc cập nhật chỉ số/EXP chỉ ở client.

- Khinh công cơ bản 34: các action 168/169/170. Chỉ `OnAnimationEnd` tiến giai đoạn; `FreshAnimation` do đổi đồ/idle không là kết thúc động tác. Khóa tới hết tiếp đất, bỏ lệnh chen vào thay vì xếp chờ; có recovery cho actor ngoài màn hình thiếu callback.
- Wardrobe chờ mãi từng do GCUICommand chung nuốt catalog 990021: dispatch chuyên biệt trước chung, kiểm phản hồi đủ 8 nhóm; không bỏ xác nhận server.
- Môn phái: danh mục 8 tâm pháp phủ learned state từ wire. Skill CY nhận raw templateID, không ID×100+level legacy. Chiêu mượn Mộ Dung 788–800 không là danh mục học cố định.
- Starter gear: kiểm sức chứa **cả lô** NPC+vũ khí trước nhập phái; thất bại phải dừng scriptNPC, không đổi phái/cấp nửa lô. Chặn nhập lại nhận quà trùng. Điểm theo bảng phái/hệ số chiến đấu, không chỉnh số cho khác nhau chỉ để có vẻ đặc trưng.

Đọc [combat/progression](references/combat-progression.md) khi sửa đạn, shortcut, auto, EXP/level hoặc Thiên phú. Bay cao mount có giao thức/nav riêng trong `cys-mount-flight`.

## Đo đúng và kết thúc

Đặt timestamp phát đạn/chạm/impact/chết/EXP, kiểm mục tiêu còn đúng instance và scene lúc callback chạy. Server trao EXP thực nhận và client tổng phải khớp. Không hủy viên đã phóng chỉ để cắt animation, nhưng dừng vòng đánh tiếp khi target chết/biến mất.

Thử bằng giao diện/input thật, invalid state, relogin và di chuyển sau UI. Số lượng catalog/tuyến portal quét tĩnh không là số lượng đã chơi thử. Giữ công thức tham khảo và ghi riêng phần port có suy luận. Thiên phú chưa rõ hệ thì hỏi lựa chọn, tiếp tục phần độc lập; không gắn điểm GL vào ID CY.
