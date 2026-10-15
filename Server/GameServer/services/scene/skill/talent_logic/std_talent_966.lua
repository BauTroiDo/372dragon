-- 又逢君：借力返施(技能829)冷却时间减少X秒
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_966 = class("std_talent_966", base)

function std_talent_966:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info:get_skill_id() == 829 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        cool_down_time = cool_down_time - reduce
    end
    return cool_down_time
end

return std_talent_966
