local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_529 = class("std_talent_529", base)

function std_talent_529:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_529:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    local imp = sender:impact_get_first_impact_of_specific_impact_id(3865)
    if imp then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local percent = logic:get_curennt_add_damage_percent(imp)
            if percent >= 10 then
                local data_indexs = { 45970, 45971, 45972, 45973, 45974}
                local data_index = data_indexs[level] or define.INVAILD_ID
                impactenginer:send_impact_to_unit(sender, data_index, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_529