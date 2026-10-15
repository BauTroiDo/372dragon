local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_848 = class("std_talent_848", base)

function std_talent_848:is_specific_skill(skill_id)
    return skill_id == 523
end

function std_talent_848:get_odds(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

local HP_PCTS = {100, 200, 300, 400, 500}

function std_talent_848:on_critical_hit_target(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
        if math.random(100) <= self:get_odds(talent, level) then
            local max_hp = sender:get_max_hp()
            if max_hp > 0 then
                local pct = HP_PCTS[level] or 100
                local recover = math.ceil(max_hp * pct * 3 / 50000)
                if recover > 0 then
                    sender:health_increment(recover, sender)
                end
            end
        end
    end
end


return std_talent_848