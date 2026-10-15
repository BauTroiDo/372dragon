local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_081 = class("std_impact_081", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_081:is_over_timed()
    return true
end

function std_impact_081:is_intervaled()
    return false
end

function std_impact_081:get_damage_gradually_strengthen(imp)
    return imp.params["是否逐步加强"] or 0
end

function std_impact_081:get_hit_trigger_effect(imp, obj)
    return imp.params["命中时触发"]
end

function std_impact_081:get_refix_damage_percent(imp)
    return ((imp.params["伤害加强百分率"] or 0)) / 100
end

function std_impact_081:get_refix_damage_times(imp)
    return imp.params["伤害加强次数"]
end

function std_impact_081:get_skill_mind_attck_rate_up(imp)
    return imp.params["会心一击率+"] or 0
end

function std_impact_081:set_skill_mind_attck_rate_up(imp, value)
    imp.params["会心一击率+"] = value
end

function std_impact_081:set_fobidden_heal(imp)
    imp.params["禁止治疗"] = true
end

function std_impact_081:get_fobidden_heal(imp)
    return imp.params["禁止治疗"] or false
end

function std_impact_081:get_immunity_control_rate_up(imp)
    return imp.params["免控率+"] or 0
end

function std_impact_081:set_immunity_control_rate_up(imp, value)
    imp.params["免控率+"] = value
end

function std_impact_081:set_free_chain_attack_prob(imp, value)
    imp.params["不消耗怒火连斩次数机率"] = value
end

function std_impact_081:get_free_chain_attack_prob(imp)
    return imp.params["不消耗怒火连斩次数机率"] or 0
end

function std_impact_081:on_be_heal(imp, obj_me, sender, health, skill_id)
    if self:get_fobidden_heal(imp) then
        health.hp_modify = 0
    end
end

function std_impact_081:on_use_skill_success_fully(imp)
	-- if self:get_refix_damage_times(imp) then
		local count = imp:get_use_skill_success_fully_count()
		count = count + 1
		imp:set_use_skill_success_fully_count(count)
	-- end
end

function std_impact_081:on_hit_target(imp, obj)
    local count = imp:get_hit_target_count()
    count = count + 1
    imp:set_hit_target_count(count)
    local value = self:get_hit_trigger_effect(imp)
	value = value or -1
	if value == -1 then return end
	impactenginer:send_impact_to_unit(obj, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
end

function std_impact_081:on_damage_target(imp, obj, target, damages)
	if damages then
		damages.imm_recover_hp = damages.imm_recover_hp or self:get_fobidden_heal(imp)
	end
	local hit_count = imp:get_hit_target_count()
	if imp:is_critical_hit() then
		local rate = self:get_free_chain_attack_prob(imp)
		if rate > 0 then
			if math.random(100) <= rate then
				hit_count = hit_count - 1
				if hit_count < 1 then
					hit_count = 1
				end
				imp:set_hit_target_count(hit_count)
				return
			end
		end
	end
	local gradually_strengthen = self:get_damage_gradually_strengthen(imp)
	local refix_times = self:get_refix_damage_times(imp)
	if not refix_times then
		refix_times = hit_count
	end
	if refix_times >= hit_count then
		local damagerate = imp.params["伤害加强百分率"] or 0
		if damagerate == 0 then
			obj:on_impact_fade_out(imp)
			obj:remove_impact(imp)
			return
		end
		if gradually_strengthen == 1 then
			local hit_rate = hit_count / refix_times
			damagerate = damagerate * hit_rate
		end
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] * (100 + damagerate) / 100
			end
		end
		-- local damagerate = self:get_refix_damage_percent(imp)
		-- if damagerate == 0 then
			-- return
		-- end
		-- local refix_damage_percent = 1
		-- if gradually_strengthen == 0 then
			-- refix_damage_percent = refix_damage_percent + damagerate
		-- else
			-- local hit_rate = hit_count / refix_times
			-- refix_damage_percent = refix_damage_percent + damagerate * hit_rate
		-- end
        -- local hp_damage = math.ceil(damages.hp_damage * refix_damage_percent)
		-- if hp_damage < 0 then
			-- hp_damage = 0
		-- end
		-- damages.hp_damage = hp_damage
	else
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
	end
		

    -- local count = imp:get_use_skill_success_fully_count()
    -- print("std_impact_081:on_damage_target count =", count)
	-- local isflag = false
	-- local refix_times = self:get_refix_damage_times(imp)
	-- if not refix_times then
		-- refix_times = count
		-- isflag = true
	-- end
    -- -- local refix_times = self:get_refix_damage_times(imp) or 1
    -- if refix_times == nil or count <= refix_times then
        -- local hit_count = imp:get_hit_target_count()
        -- print("std_impact_081:on_damage_target hit_count =", hit_count)
        -- local hit_rate = hit_count / refix_times
        -- local refix_damage_percent = 1 + self:get_refix_damage_percent(imp) * hit_rate
        -- print("std_impact_081:on_damage_target refix_damage_percent =", refix_damage_percent)
        -- local hp_damage = math.ceil(damages.hp_damage * refix_damage_percent)
        -- print("std_impact_081:on_damage_target hp_damage =", hp_damage, ";damages.hp_damage =", damages.hp_damage)
        -- damages.hp_damage = hp_damage
    -- else
        -- obj:on_impact_fade_out(imp)
        -- obj:remove_impact(imp)
    -- end
end

function std_impact_081:refix_critical_rate(imp, critical_rate)
    critical_rate = critical_rate + self:get_skill_mind_attck_rate_up(imp) / 100
    return critical_rate
end


return std_impact_081