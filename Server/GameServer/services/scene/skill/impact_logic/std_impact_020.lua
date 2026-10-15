local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_020 = class("std_impact_020", base)

function std_impact_020:is_over_timed()
    return true
end

function std_impact_020:is_intervaled()
    return false
end

function std_impact_020:get_hp_recover_rate(imp)
    return imp.params["复活后的HP%"] / 100
end

function std_impact_020:set_rate_of_hp_recover(imp, rate)
    imp.params["复活后的HP%"] = rate
end

function std_impact_020:get_rate_of_hp_recover(imp)
    return imp.params["复活后的HP%"] or 0
end

function std_impact_020:get_mp_recover_rate(imp)
    return imp.params["复活后的MP%"] / 100
end

function std_impact_020:get_rage_recover_rate(imp)
    return imp.params["复活后的Rage%"] / 100
end

function std_impact_020:get_cool_down_value(imp)
    return imp.params["减少技能冷却"] or 0
end

function std_impact_020:set_cool_down_value(imp,value)
    imp.params["减少技能冷却"] = value
end

function std_impact_020:on_die(imp, obj)
    local relive_info = {}
	local value = self:get_cool_down_value(imp)
	if value > 0 then
		relive_info.hp_recover_rate = math.ceil(self:get_hp_recover_rate(imp) / 2)
		relive_info.mp_recover_rate = math.ceil(self:get_mp_recover_rate(imp) / 2)
		relive_info.rage_recover_rate = math.ceil(self:get_rage_recover_rate(imp) / 2)
		relive_info.sceneid = obj:get_scene_id()
		relive_info.world_pos = obj:get_world_pos()
		obj:set_relive_info(true, relive_info)
		local cool_downs = obj:get_cool_downs()
		local cd_value
		for id,cd in pairs(cool_downs) do
			cd_value = math.ceil(cd * value / 100)
			obj:set_cool_down(id, cd_value)
		end
	else
		relive_info.hp_recover_rate = self:get_hp_recover_rate(imp)
		relive_info.mp_recover_rate = self:get_mp_recover_rate(imp)
		relive_info.rage_recover_rate = self:get_rage_recover_rate(imp)
		relive_info.sceneid = obj:get_scene_id()
		relive_info.world_pos = obj:get_world_pos()
		obj:set_relive_info(true, relive_info)
	end
end

return std_impact_020