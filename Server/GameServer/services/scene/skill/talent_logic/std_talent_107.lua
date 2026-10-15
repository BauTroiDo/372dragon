local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_107 = class("std_talent_107", base)
function std_talent_107:is_add_damage_skill(skill_id)
    return skill_id == 404
end

function std_talent_107:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_107:on_damage_target(talent, level, id, sender, _, damages, skill_id)
    if self:is_add_damage_skill(skill_id) then
        local odd = self:get_refix_value(talent, level)
        local num = math.random(100)
        if num <= odd then
            local target_skill_id = 421
            local template = skillenginer:get_skill_template(target_skill_id)
            local cool_down_id = template.cool_down_id
            sender:update_cool_down_by_cool_down_id(cool_down_id, 30 * 1000)
        end
    end
end

return std_talent_107