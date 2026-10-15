# Combat, shortcut, progression và phần còn mở

## Kỹ năng và phím tắt

SkillData CY mô tả ở cột 1, GL cột 3; paraPair 11 có thể rỗng. Công thức `{A:...}` chưa có evaluator đầy đủ thì dùng mô tả dự phòng đã có, không bịa số. Catalog 15 phái đã kiểm không thay thế live mọi chiêu.

50 ô shortcut, ba trang F, Alt+số 30..39. Transport tag 128..177 ánh xạ settings 2..51; tránh chat legacy 22..29. `SetMenuBarPageNumber` phải có handler, login restore toàn 50. Alliance chat 112 vượt 96 record của server riêng tại mốc khảo sát: không ghi tràn để giả lưu. Item shortcut cần tra stack thực mỗi lần (xem skill inventory).

## Tuyệt Tình và delayed impact

Skill CY 4515 khác GL 5723; tra mapping/phái CY 14→GL 16. Donor action 11088/line 7012–7013 có HitTime 0.2; biến thể CY từng-1 nên phát đạn muộn. Port hiện có mốc 700 ms và travel distance/15 m/s của Bullet 305; đã đo chạm đạn trước EXP 485 ms trên ca 11,69 m. Đây là phép đo một ca và có suy luận tương thích, không phải bảo đảm tuyệt đối mọi ping/skill.

`eventenginer` từng nhận nhưng bỏ delaytime. Callback phải lưu caster/logic phù hợp và kiểm target sống, còn cùng object/scene khi áp impact. Skill khác giữ behavior nếu không có bằng chứng cần đổi. Đòn auto tiếp theo không nên chờ hết clip 2,4 s; animation idle không ghi đè flight/action chuyển tiếp.

Nếu sửa all.skill, giữ closure EffectFolder đầy đủ all.effect/all.particle/all.skill và chỉ mount archive thay thế cần thiết; mount chồng script Pre/Canonical/Post có thể đăng ký trùng template. Kiểm cfg thực tế, không chỉ file overlay đã sinh.

## EXP và cấp 200

Server source là chuẩn cho bảng cấp: từng có mismatch level 81 3.604.920 so với client 7.676.775. Cap tích lũy `floor(3.5 * expNeed(currentLevel))`, thông báo đúng phần nhận; giữ EXP cũ nếu đã vượt cap thay vì tự cắt mất. uint32→64-bit/Lua number, kiểm 3.000.000.000 không âm.

Server dùng 201 làm cận trên loại trừ để cho lên 200. Nối CGReqLevelUp/GCLevelUp/GCLevelUpResult, giữ yêu cầu môn phái/tâm pháp ở 90/100/110. AttrLevelUpTable đã nối chu kỳ 10 cấp tới 200, không tự sáng tác đường cong mới. Cap tâm pháp/tu luyện độc lập.

`Tools/server/progression_200.py`, `test_progression.py`, `cys_battle_assist.lua`; [progression 24/09](C:/TLBB/085/CY-Source/Docs/specs/progression-200-20260924_vi.md).

## Tự chiến đấu và GM

UI CY `IsWorking()` so sánh chuỗi `"true"`/`"false"`, không bool Lua. Server thực thi qua normal AI/skill/item handler, không sửa HP/EXP bằng lối riêng. Bắt đầu cấp 50/có phái/sống/không theo đội; kiểm đã học/cooldown/target/visibility. Thuốc lựa chọn 0 là **không dùng**, không chọn thuốc thay thế.

11 mảng cấu hình Begin/Chunk/Commit revision và timeout; persist cấu hình, không persist đang chạy. Chết/di chuyển/chuyển cảnh/theo đội phải dừng. Tự thăng cấp đến mức chọn không có nghĩa dừng đánh khi đạt cấp đó. Võ ý thiếu counter thì vô hiệu điều kiện; auto chuỗi phó bản FB chưa làm.

Yêu cầu cấp GM chỉ áp 16 tài khoản test00–test15 hiện có của private ở mốc 24/09, quyền 98 qua GmCeshi. Giữ quyền server, thử từ chối tài khoản ngoài danh sách. Không suy mọi account chứa chữ “test”, mọi account tương lai hoặc server chính đều được GM.

## Thiên phú và portal

Tông môn CY (ZongMenSkill, ZongmenTalent 255×37, bí bảo 23, hai bộ điểm, script 998633) khác Võ đạo GL (Talent.lua, SectInfo/SectDesc, CGSectOper/GCSectDetail). Native LuaFnGet/SetZongMenData thiếu, donor 38 cột/cơ chế điểm khác. Lịch sử chưa có câu trả lời chọn hệ; chưa hoàn thiện Thiên phú.

Portal: đối chiếu scene CY/script/runtime, giữ điều kiện quest/sect; không thay tất cả thành teleport vô điều kiện. Đợt 2 áp 203 đường/108 file, live Lạc Dương↔Đôn Hoàng; chưa đi toàn 203.

Nguồn: [action 23/09](C:/TLBB/085/CY-Source/Docs/specs/actions-equipment-audit-20260923_vi.md), [gameplay đợt 2](C:/TLBB/085/CY-Source/Docs/specs/gameplay-round2-20260923_vi.md).
