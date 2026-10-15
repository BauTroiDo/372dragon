-- 物外光阴：使用星河虹吸(技能832)后，减少探营取将(技能817)X秒的冷却时间
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_979 = class("std_talent_979", base)

function std_talent_979:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 832 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        local template = skillenginer:get_skill_template(817)
        if template then
            human:update_cool_down_by_cool_down_id(template.cool_down_id, reduce)
        end
    end
end

return std_talent_979
