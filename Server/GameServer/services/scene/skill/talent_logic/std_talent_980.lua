-- 南风知我意：公子无双(962)免疫控制时，减少彼行我释(825)和春光四沐(821)X秒的冷却时间
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_980 = class("std_talent_980", base)

function std_talent_980:on_be_hit(talent, level, human, sender, skill)
    -- 只在 962 免疫成功时触发
    if not human._962_immune_triggered then return end
    local params = talent.params[level]
    local reduce = (params[1] or 0) * 1000
    local template_825 = skillenginer:get_skill_template(825)
    if template_825 then
        human:update_cool_down_by_cool_down_id(template_825.cool_down_id, reduce)
    end
    local template_821 = skillenginer:get_skill_template(821)
    if template_821 then
        human:update_cool_down_by_cool_down_id(template_821.cool_down_id, reduce)
    end
end

return std_talent_980
