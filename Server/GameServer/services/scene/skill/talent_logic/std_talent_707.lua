local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_707 = class("std_talent_707", base)

function std_talent_707:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_707:refix_skill_info(talent, level, skill_info, human)
    local params = human:get_targeting_and_depleting_params()
    local target_obj_id = params:get_target_obj()
    local scene = human:get_scene()
    local reciver = scene:get_obj_by_id(target_obj_id)
    if reciver and reciver:impact_get_first_impact_of_specific_data_index(63067) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        local rate_up = skill_info:get_mind_attack_rate_up()
        local value = self:get_refix_value(talent, level)
		if value > 0 then
			rate_up = rate_up + (value / 10)
			skill_info:set_mind_attack_rate_up(rate_up)
		end
    end
end

return std_talent_707