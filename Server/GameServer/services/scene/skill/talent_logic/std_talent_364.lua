local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_364 = class("std_talent_364", base)
function std_talent_364:is_specific_skill(skill_id)
    return skill_id == 521
end

function std_talent_364:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_364:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
        if imp and imp:is_critical_hit() then
            local odd = self:get_refix_value(talent, level)
            local n = math.random(1, 100)
            if n <= odd then
                local data_index = 63049 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
                impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_364