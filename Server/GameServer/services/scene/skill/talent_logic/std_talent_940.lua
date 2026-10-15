-- 流水无定：气定六合(技能813)每命中1个目标，减少气定六合X秒冷却
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_940 = class("std_talent_940", base)

function std_talent_940:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 813 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        local template = skillenginer:get_skill_template(813)
        if template then
            sender:update_cool_down_by_cool_down_id(template.cool_down_id, reduce)
        end
    end
end

return std_talent_940
