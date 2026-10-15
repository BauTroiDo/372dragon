local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_100 = class("std_talent_100", base)

function std_talent_100:is_specific_impact(impact_id)
    return impact_id == 199
end

function std_talent_100:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_100:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local collection_id = 281
        local is_in_collection = reciver:impact_get_first_impact_in_specific_collection(collection_id)
        if is_in_collection then
            local impact_id = 63021 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(reciver, impact_id, reciver, 0, false, 0)
        else
            local impact_id = 63022 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(reciver, impact_id, reciver, 0, false, 0)
        end
        if imp:get_logic_id() == 92 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                do
                    local value = logic:get_value_of_refix_monster_damage_percent(imp)
                    value = value - 2
                    logic:set_value_of_refix_monster_damage_percent(imp, value)
                end
                do
                    local value = logic:get_value_of_refix_human_damage_percent(imp)
                    value = value - 2
                    logic:set_value_of_refix_human_damage_percent(imp, value)
                end
            end
        end
    end
end

return std_talent_100