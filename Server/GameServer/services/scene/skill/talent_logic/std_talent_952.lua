-- 奋烈有时：使用化气式(833)时，有X%概率清除化气式的冷却时间
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_952 = class("std_talent_952", base)

function std_talent_952:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 833 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            local template = skillenginer:get_skill_template(833)
            if template then
                human:set_cool_down(template.cool_down_id, 0)
            end
        end
    end
end

return std_talent_952
