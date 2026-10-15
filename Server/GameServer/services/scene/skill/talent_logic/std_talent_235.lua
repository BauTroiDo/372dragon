local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_235 = class("std_talent_235", base)
function std_talent_235:is_specific_skill(skill_id)
    return skill_id == 311
end

function std_talent_235:get_sestannd_impact()
    local impact_id = 63036 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
    return impact_id
end

function std_talent_235:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_235:on_critical_hit_target(talent_config, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local p = self:get_refix_p(talent_config, level)
        local n = math.random(100)
        if n < p then
            local impact_id = self:get_sestannd_impact(level)
            if impact_id ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(sender, impact_id, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_235