local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_009 = class("std_talent_009", base)
function std_talent_009:is_specific_skill(skill_id)
    return skill_id == 347
end

function std_talent_009:get_add_damage(talent, level, seg)
    local params = talent.params[level]
    return params[seg]
end

function std_talent_009:get_impact_segment(imp)
    local data_index = imp:get_data_index()
    return math.floor((data_index - 875) / 12 ) + 1
end

function std_talent_009:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local segment = self:get_impact_segment(imp)
        local add_damage = self:get_add_damage(talent, level, segment) or 0
        local logic = impactenginer:get_logic(imp)
        if logic then
            local old_damage = logic:get_damage_direct(imp)
            logic:set_damage_direct(imp, old_damage + add_damage)
        end
    end
end

return std_talent_009