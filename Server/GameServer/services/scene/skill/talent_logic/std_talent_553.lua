local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_553 = class("std_talent_553", base)
function std_talent_553:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_553:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if skill_id == 463 then
        if imp and imp:is_critical_hit() then
            local data_indexs = { 46023, 46024, 46025, 46026, 46027}
            local data_index = data_indexs[level] or define.INVAILD_ID
            impactenginer:send_impact_to_unit(sender, data_index, sender, 0, false, 0)
        end
    end
end

function std_talent_553:is_specific_impact(impact_data_index)
    return impact_data_index >= 46023 and impact_data_index <= 46027
end

function std_talent_553:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:check_attr(imp, reciver)
        end
    end
end
return std_talent_553