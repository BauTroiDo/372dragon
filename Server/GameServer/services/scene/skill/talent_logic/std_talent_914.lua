-- 俯仰自得：使用柳拂衣(技能812)时，减少彼行我释(825)和春光四沐(821)冷却时间2秒
-- 会心时额外减少1秒
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_914 = class("std_talent_914", base)

function std_talent_914:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 812 then
        local reduce = 2000
        -- [FIX] 水连天(976)：增强冷却减少量
        local val_976 = human:have_talent(976)
        if val_976 and val_976 > 0 then
            reduce = reduce * (1 + val_976 / 100)
        end
        local template_825 = skillenginer:get_skill_template(825)
        if template_825 then
            human:update_cool_down_by_cool_down_id(template_825.cool_down_id, reduce)
        end
        local template_821 = skillenginer:get_skill_template(821)
        if template_821 then
            human:update_cool_down_by_cool_down_id(template_821.cool_down_id, reduce)
        end
    end
end

function std_talent_914:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 812 then
        local extra_reduce = 1000
        -- [FIX] 水连天(976)：增强会心额外冷却减少量
        local val_976 = sender:have_talent(976)
        if val_976 and val_976 > 0 then
            extra_reduce = extra_reduce * (1 + val_976 / 100)
        end
        local template_825 = skillenginer:get_skill_template(825)
        if template_825 then
            sender:update_cool_down_by_cool_down_id(template_825.cool_down_id, extra_reduce)
        end
        local template_821 = skillenginer:get_skill_template(821)
        if template_821 then
            sender:update_cool_down_by_cool_down_id(template_821.cool_down_id, extra_reduce)
        end
    end
end

return std_talent_914
