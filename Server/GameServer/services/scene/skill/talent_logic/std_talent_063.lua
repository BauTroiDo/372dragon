local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_063 = class("std_talent_063", base)
function std_talent_063:is_specific_skill(skill_id)
    return skill_id == 311
end

function std_talent_063:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_063:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    -- 调试输出已屏蔽
    -- print("0 std_talent_063:on_critical_hit_target")
    if self:is_specific_skill(skill_id) then
        local value = self:get_value(talent, level)
        human:rage_increment(value, human)
    end
end

return std_talent_063