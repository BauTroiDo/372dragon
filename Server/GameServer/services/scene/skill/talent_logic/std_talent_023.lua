local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_023 = class("std_talent_023", base)
local impact_id = 63019 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
function std_talent_023:is_specific_skill(skill_id)
    return skill_id == 281
end

function std_talent_023:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_023:on_damage_target(talent, level, id, obj_me, target, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        if not target:impact_get_first_impact_of_specific_data_index(impact_id) then
            impactenginer:send_impact_to_unit(target, impact_id, obj_me, 0, false, 0)
        end
    end
end

return std_talent_023