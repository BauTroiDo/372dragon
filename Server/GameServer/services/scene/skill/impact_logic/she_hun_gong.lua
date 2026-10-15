local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local she_hun_gong = class("she_hun_gong", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function she_hun_gong:is_over_timed()
    return true
end

function she_hun_gong:is_intervaled()
    return false
end

function she_hun_gong:cal_dist(p1, p2)
    return math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))
end

function she_hun_gong:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function she_hun_gong:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function she_hun_gong:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

function she_hun_gong:on_damage_target(imp, obj, target, damages, skill_id)
	if skill_id and skill_id ~= -1
	and damages and damages.damage_rate then
		if skillenginer:get_skill_template(skill_id,"is_shenbing_skill") then
			-- local dist = obj:get_scene():cal_dist(obj:get_world_pos(),target:get_world_pos())
			local dist = self:cal_dist(obj:get_world_pos(),target:get_world_pos())
			if dist < 5 then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = damages[key] - 8
				end
			elseif dist > 10 then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = damages[key] + 8
				end
			end
		end
	end
end
return she_hun_gong