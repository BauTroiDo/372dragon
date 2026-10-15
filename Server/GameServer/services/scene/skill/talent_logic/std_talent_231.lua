local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_231 = class("std_talent_231", base)

function std_talent_231:get_skill_config(skill_id)
    local config = self.skills[skill_id]
    return config
end

function std_talent_231:is_specific_skill(skill_id)
    return skill_id == 313
end

function std_talent_231:get_send_impact()
    local impact_id = 44311
    return impact_id
end

function std_talent_231:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_231:on_critical_hit_target(talent_config, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local p = self:get_refix_p(talent_config, level)
        local n = math.random(100)
        if n < p then
            local impact_id = self:get_send_impact(level)
            if impact_id ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_231