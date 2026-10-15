local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_505 = class("std_talent_505", base)
function std_talent_505:is_specific_impact(impact_data_index)
    return impact_data_index >= 2939 and impact_data_index <= 2954
end

function std_talent_505:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_505:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local mp_max = sender:get_max_mp()
            local percent = self:get_refix_value(talent, level)
            local recover_mp = math.ceil(mp_max * percent / 100)
            local ori_recover_mp = logic:get_mp_modify(imp)
            ori_recover_mp = ori_recover_mp + recover_mp
            logic:set_mp_modify(imp, ori_recover_mp)
        end
        local skill_id = 409
        local template = skillenginer:get_skill_template(skill_id)
        local cool_down_id = template.cool_down_id
        sender:set_cool_down(cool_down_id, 0)
    end
end

return std_talent_505