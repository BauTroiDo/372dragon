-- 剑吞日月：破天式(834)飞剑每对1个目标造成伤害，减少破天式X秒的冷却时间
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_951 = class("std_talent_951", base)

function std_talent_951:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 834 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        local template = skillenginer:get_skill_template(834)
        if template then
            sender:update_cool_down_by_cool_down_id(template.cool_down_id, reduce)
        end
    end
end

return std_talent_951
