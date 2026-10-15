local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local base = require "scene.skill.impact_logic.base"
local std_impact_507 = class("std_impact_507", base)

function std_impact_507:ctor()

end

function std_impact_507:is_over_timed()
    return true
end

function std_impact_507:is_intervaled()
    return true
end

function std_impact_507:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
	local caster_obj_id = imp:get_caster_obj_id()
	local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
	if sender and sender:get_obj_type() == "human" then
		local level = imp.params["层数"] or 0
		local att_rate = imp.params["最高属性攻击%"] or 0
		if level > 0 and att_rate > 0 then
			local att_max = math.max(
			sender:get_attrib("att_cold"),
			sender:get_attrib("att_fire"),
			sender:get_attrib("att_light"),
			sender:get_attrib("att_poison"))
			if att_max > 0 then
				local hp_modify = att_max * att_rate / 100 * level
				local damages = {hp_damage = hp_modify}
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = 100
				end
				for _,key in ipairs(DAMAGE_TYPE_POINT) do
					damages[key] = 0
				end
				for _,key in ipairs(DAMAGE_TYPE_BACK) do
					damages[key] = {}
				end
				for _,key in pairs(DAMAGE_TYPE) do
					damages[key] = 0
				end
				damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = hp_modify
				obj:on_damages(damages, caster_obj_id, nil, -1, imp)
			end
		end
	end
end


return std_impact_507