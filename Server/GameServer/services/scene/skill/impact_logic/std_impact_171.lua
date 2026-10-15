-- skill-logic-3 (CY-Source 17/09/2026): logic impact 171 — TRẠNG THÁI CÓ HẸN GIỜ (计时 buff).
--
-- Vì sao cần: 13 dòng StandardImpact của server riêng mang 逻辑ID = 171 và `impactenginer.id_logic_module`
-- KHÔNG có ô 171 ⇒ `eventenginer:real_register_impact_event` thấy `imp_logic == nil` và **thoát ngay**
-- (lualib/eventenginer.lua:116) — buff không bao giờ lên người. 13 dòng đó đều là trạng thái đếm giờ:
--   5212 五绝计时 · 12931–12936 + 19515 + 57059 + 57107 + 57156 各式刃影 (二式 của 大理)
--   13058 九阳炽脉 (20 s, 互斥ID 2631) · 13059 九阴煞魄 (20 s, 互斥ID 151)
-- 2631 và 151 chính là nội dung tập 499 (回天术九阳状态) / 376 (斩情诀BUFF) — hai tập mà điều kiện
-- `C_UNIT_MUST_HAVE_IMPACT` của các chiêu ·九阳 / ·九阴 (SkillData 17472/17488/17504/17520, 17552…) đòi hỏi.
-- Không có logic 171 thì mọi chiêu ·九阳 của 峨嵋 báo "không dùng được" dù nhân vật đã học.
--
-- Cài đặt: trạng thái thuần — có thời lượng (总持续时间 của chính dòng), không nhịp, không tham số phụ.
--   * `is_over_timed` = true  → hết 总持续时间 thì tự rụng (giống `null_logic_buff`, logic 97);
--   * `is_intervaled` = false → không có nhịp.
-- CHƯA làm (ghi rõ, không đoán):
--   * `参数2说明 = 下发的CD` (13058: 4513; 12931: 4507; 5212: 4506) — CY đặt thêm một hồi chiêu khi trạng thái
--     bắt đầu; chưa có bằng chứng ID đó là 冷却ID hay ID kỹ năng nên không tự suy.
--   * `参数3说明 = 初始技能` + `参数4说明 = 替换技能` (12931: 463 少商剑 → 821 少商剑·刃影; 19515: 488 → 826;
--     57156: 469 → 822) — chính là cơ chế "đổi một ô kỹ năng" của CY, nằm trong IMPACT chứ không trong logic kỹ năng.
--     Không cài ở đây vì (a) hai dòng 13058/13059 của 峨嵋 KHÔNG có hai ô này (回天术 liệt kê bốn chiêu trong
--     SkillData của chính nó), (b) phía server cả chiêu gốc lẫn chiêu thay đều dùng được khi đủ điều kiện —
--     việc đổi biểu tượng trên thanh nhanh là của client, và sửa `human.skill_list` thì có rủi ro lưu nhầm
--     khi người chơi thoát game giữa chừng (xem mục 13.4 của Docs/specs/server/skill-logic_vi.md).
local class = require "class"
local base = require "scene.skill.impact_logic.base"

local std_impact_171 = class("std_impact_171", base)

std_impact_171.ID = 171

function std_impact_171:is_over_timed()
    return true
end

function std_impact_171:is_intervaled()
    return false
end

return std_impact_171
