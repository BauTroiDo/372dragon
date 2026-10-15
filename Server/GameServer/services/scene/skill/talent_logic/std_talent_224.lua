local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_221 = class("std_talent_221", base)
function std_talent_221:is_specific_skill(skill_id)
    return skill_id == 311
end

function std_talent_221:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_221:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= value then
            local data_index = 63035 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_221