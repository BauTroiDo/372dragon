local class = require "class"
local define = require "define"
-- local impact = require "scene.skill.impact"
-- local eventenginer = require "eventenginer":getinstance()
-- local impactenginer  = require "impactenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

local std_impact_505 = class("std_impact_505", base)
--该BUFF为项链雕纹专用  因有刻纹存在  所以单独给个逻辑  如果需要相同BUFF逻辑可以新开一个来用
function std_impact_505:is_over_timed()
    return true
end

function std_impact_505:is_intervaled()
    return false
end

function std_impact_505:get_def_increase_damage(imp)
    return imp.params["伤害增加"] or 0
end
function std_impact_505:get_increase_damage(imp)
    return imp.params["精绘伤害增加"] or 0
end

function std_impact_505:set_increase_damage(imp,value)
    imp.params["精绘伤害增加"] = value
end


function std_impact_505:get_def_increase_damage_percentage(imp)
    return imp.params["伤害增加百分比"] or 0
end

function std_impact_505:get_increase_damage_percentage(imp)
    return imp.params["精绘伤害增加百分比"] or 0
end

function std_impact_505:set_increase_damage_percentage(imp,value)
    imp.params["精绘伤害增加百分比"] = value
end


function std_impact_505:get_affect_skill_collection_id(imp)
    return imp.params["影响或生效的技能集合ID"]
end

function std_impact_505:on_active(imp, obj)
	if obj and obj:get_obj_type() == "human" then
		local equip = obj:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_NECKLACE)
		if equip then
			local equip_data = equip:get_equip_data()
			if equip_data:get_dur() > 0 then
				local dw_advance_level = equip_data:get_dw_jinjie_details()
				if dw_advance_level > 0 then
					local dw_jinjie_info = configenginer:get_config("dw_jinjie_info")
					dw_jinjie_info = dw_jinjie_info[dw_advance_level]
					if dw_jinjie_info then
						local collection_id = self:get_affect_skill_collection_id(imp)
						if collection_id == 121 then
							local increase_damage = self:get_def_increase_damage(imp)
							if increase_damage > 0 then
								self:set_increase_damage(imp,dw_jinjie_info.skill_value)
							end
						else
							local increase_damage = self:get_def_increase_damage_percentage(imp)
							if increase_damage > 0 then
								self:set_increase_damage_percentage(imp,dw_jinjie_info.skill // 10)
							end
						end
					end
				end
			else
				obj:on_impact_fade_out(imp)
				obj:remove_impact(imp)
			end
		end
	end
end

function std_impact_505:on_damage_target(imp, obj, target, damages, skill_id)
    local collection_id = self:get_affect_skill_collection_id(imp)
    if collection_id == define.INVAILD_ID then
		return
	elseif not skill_id or skill_id == define.INVAILD_ID then
		return
	end
	
	local in_collection = skillenginer:is_skill_in_collection(skill_id, collection_id)
    if not in_collection then
        return
	-- elseif damages.hp_damage <= 0 then
		-- return
    end
	if collection_id == 121 then
		local increase_damage = self:get_def_increase_damage(imp)
		if increase_damage > 0 then
			increase_damage = increase_damage + self:get_increase_damage(imp)
			if damages and damages.damage_rate then
				local key = DAMAGE_TYPE_POINT[7]
				damages[key] = (damages[key] or 0) + increase_damage
			end
			-- damages.hp_damage = damages.hp_damage + increase_damage
		end
	else
		local increase_damage_percentage = self:get_def_increase_damage_percentage(imp)
		if increase_damage_percentage > 0 then
			increase_damage_percentage = increase_damage_percentage + self:get_increase_damage_percentage(imp)
			if damages and damages.damage_rate then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = damages[key] + increase_damage_percentage
				end
				if collection_id == 122 then
					local direct_damage = damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] or 0
					if direct_damage > 0 then
						local key = DAMAGE_TYPE_POINT[7]
						damages[key] = (damages[key] or 0) + direct_damage * increase_damage_percentage / 100
					end
				end
			end
			-- increase_damage_percentage = increase_damage_percentage + 100
			-- local hp_damage = math.ceil(damages.hp_damage * increase_damage_percentage / 100)
			-- damages.hp_damage = hp_damage
		end
	end
end

return std_impact_505
