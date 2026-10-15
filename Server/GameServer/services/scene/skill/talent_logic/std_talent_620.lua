local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_620 = class("std_talent_620", base)
function std_talent_620:is_specific_impact(data_index)
    return data_index >= 21431 and data_index <= 21446
end

function std_talent_620:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_620:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local odd = self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= odd then
            imp:set_continuance(0)
            local data_index = 63059 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_620