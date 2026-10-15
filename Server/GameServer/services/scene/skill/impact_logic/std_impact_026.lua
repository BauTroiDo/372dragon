local class = require "class"
local define = require "define"
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_026 = class("std_impact_026", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_026:is_over_timed()
    return true
end

function std_impact_026:is_intervaled()
    return false
end

function std_impact_026:get_absorb_rate(imp)
    return imp.params["吸收率"]
end

function std_impact_026:get_ignore_rate(imp)
    return imp.params["免疫率"]
end

function std_impact_026:set_ignore_rate(imp, rate)
    imp.params["免疫率"] = rate
end

function std_impact_026:get_reflect_rate(imp)
    return imp.params["反射率"]
end

function std_impact_026:set_reflect_rate(imp, value)
    imp.params["反射率"] = value
end

function std_impact_026:get_reflect_activate_odds(imp)
    return imp.params["反射发生几率"]
end

function std_impact_026:get_reflect_damage_up_limit(imp)
    return imp.params["反射伤害上限"]
end

function std_impact_026:set_refix_damage_percent(imp, percent)
    imp.params["伤害修正%（0为无效）"] = percent
end

function std_impact_026:get_refix_damage_percent(imp)
    return imp.params["伤害修正%（0为无效）"] or 0
end

function std_impact_026:on_damages(imp, obj, damages, caster_obj_id)
	if damages and damages.damage_rate then
	
		local percent = self:get_ignore_rate(imp)
		if percent > 0 then
			if percent >= 100 then
				damages.flag_immu = true
				return
			end
			damages.imm_dmg_rate = (damages.imm_dmg_rate or 0) + percent
		end
		percent = self:get_reflect_rate(imp)
		if percent > 0 then
			local num = math.random(100)
			if num <= self:get_reflect_activate_odds(imp) then
				local idx = DAMAGE_TYPE_BACK[3]
				local max_damage = self:get_reflect_damage_up_limit(imp)
				if max_damage > 0 then
					table.insert(damages[idx],{rate = percent,max_damage = max_damage})
				else
					table.insert(damages[idx],{rate = percent})
				end
			end
		end	
		percent = self:get_refix_damage_percent(imp)
		if percent ~= 0 then
			for i,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + percent
			end
		end
		
	end



    -- -- local hp_damage = damages.hp_damage
	-- local ignore_rate = self:get_ignore_rate(imp)
	-- -- local reflect_rate = self:get_reflect_rate(imp)
    -- if ignore_rate > 0 then
		-- if damages and damages.damage_rate then
			-- for i,j in ipairs(DAMAGE_TYPE_RATE) do
				-- damages[j] = damages[j] - ignore_rate
			-- end
		-- end
        -- -- local damage = math.floor(hp_damage * (100 - self:get_ignore_rate(imp)) / 100)
        -- -- damages.hp_damage = damage
    -- elseif self:get_reflect_rate(imp) > 0 then
        -- local num = math.random(100)
        -- if num <= self:get_reflect_activate_odds(imp) then
			-- if damages and damages.damage_rate then
				-- local idx = DAMAGE_TYPE_BACK[1]
				-- table.insert(damages[idx],imp)
			-- end
		
            -- -- local damage = math.floor(hp_damage * self:get_reflect_rate(imp) / 100)
            -- -- print("std_impact_026:on_damages hp_damage =", hp_damage, ";self:get_reflect_rate(imp) =", self:get_reflect_rate(imp), ";damage =", damage)
            -- -- local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
            -- -- damage = damage > self:get_reflect_damage_up_limit(imp) and self:get_reflect_damage_up_limit(imp) or damage
            -- -- if attacker then
                -- -- attacker:health_increment(-1 * damage, obj, false)
            -- -- end
        -- end
    -- end
end

-- function std_impact_026:on_damage_target(imp, obj, target, damages)
    -- local percent = self:get_refix_damage_percent(imp)
    -- if percent ~= 0 then
		-- if damages and damages.damage_rate then
			-- for i,j in ipairs(DAMAGE_TYPE_RATE) do
				-- damages[j] = damages[j] + percent
			-- end
		-- end
        -- -- damages.hp_damage = 0
        -- -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- -- damages[i] = math.floor((damages[i] or 0) * (100 + percent) / 100)
            -- -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- -- end
    -- end
-- end
function std_impact_026:on_health_increment(imp,hp_modifys)
	local percent = self:get_ignore_rate(imp)
	if percent > 0 then
		if percent >= 100 then
			hp_modifys.flag_immu = true
			return
		end
		hp_modifys.imm_dmg_rate = hp_modifys.imm_dmg_rate + percent
	end
end


return std_impact_026