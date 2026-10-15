local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_559 = class("std_talent_559", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_559:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_559:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if skill_id == 461 then
		if damages and damages.damage_rate then
			local cold = sender:get_attrib("att_cold")
			local fire = sender:get_attrib("att_fire")
			local light = sender:get_attrib("att_light")
			local poison = sender:get_attrib("att_poison")
			if cold > reciver:get_attrib("att_cold")
			and fire > reciver:get_attrib("att_fire")
			and light > reciver:get_attrib("att_light")
			and poison > reciver:get_attrib("att_poison") then
				local min_index = 0
				local min_value = 2100000000
				if cold < min_value then
					min_index = 3
					min_value = cold
				end
				if fire < min_value then
					min_index = 4
					min_value = fire
				end
				if light < min_value then
					min_index = 5
					min_value = light
				end
				if poison < min_value then
					min_index = 6
					min_value = poison
				end
				local key = DAMAGE_TYPE_RATE[min_index]
				if key then
					local percent = self:get_refix_value(talent, level)
					damages[key] = damages[key] + percent
				end
			end
        end
    end
end


return std_talent_559