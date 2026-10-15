local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_021 = class("std_impact_021", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_021:is_over_timed()
    return true
end

function std_impact_021:is_intervaled()
    return false
end

function std_impact_021:get_target_impact_collection(imp)
    return imp.params["目标技能集合ID, 无效值：-1"] or define.INVAILD_ID
end

function std_impact_021:get_power_refix(imp)
    return imp.params["威力值修正，无效值: 0"] or 0
end

function std_impact_021:get_power_percent_refix(imp)
    return imp.params["威力%修正，无效值: 0"] or 0
end

function std_impact_021:get_deplete_percent_refix(imp)
    return imp.params["消耗%修正，无效值: 0"] or 0
end

function std_impact_021:get_continuance_refix(imp)
    return imp.params["引导时间%修正，无效值: 0"] or 0
end

function std_impact_021:get_mind_attack_damage_up_rate(imp)
    return imp.params["会心一击伤害+(%)"] or 0
end

function std_impact_021:set_mind_attack_damage_up_rate(imp, rate)
    imp.params["会心一击伤害+(%)"] = rate
end
function std_impact_021:get_refix_mind_attack(imp, args, obj)
    local value = imp.params["会心攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["会心攻击+(%)"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end
function std_impact_021:set_value_of_refix_mind_attack(imp, value)
    imp.params["会心攻击+"] = value
end
function std_impact_021:set_value_of_refix_mind_attack_rate(imp, value)
    imp.params["会心攻击+(%)"] = value
end

function std_impact_021:refix_skill(imp, obj, skill_info)
    local continuance_refix = self:get_continuance_refix(imp)
    local continuance = skill_info:get_channel_time()
    continuance = math.ceil(continuance * (100 + continuance_refix)/ 100)
    skill_info:set_channel_time(continuance)
end

-- function std_impact_021:refix_impact(imp, obj_me, need_refix_imp)
    -- local activate_times = imp:get_activate_times()
    -- if imp:get_activate_times() == 0 then
        -- return
    -- end
	-- local have_collection = self:get_target_impact_collection(imp)
	-- if have_collection ~= define.INVAILD_ID then
		-- if not impactenginer:is_impact_in_collection(need_refix_imp,have_collection ) then
			-- return
		-- end
	-- end
    -- local logic = impactenginer:get_logic(need_refix_imp)
    -- if logic == nil then
        -- return
    -- end
    -- local ret = false
    -- local refix_power_percent = self:get_power_percent_refix(imp)
    -- if refix_power_percent then
        -- ret = ret or logic:refix_skill_power_by_rate(need_refix_imp, refix_power_percent)
    -- end
    -- print("std_impact_021:refix_impact ret =", ret)
    -- if ret then
        -- if activate_times > 0 then
            -- activate_times = activate_times - 1
            -- if activate_times == 0 then
                -- obj_me:on_impact_fade_out(imp)
                -- obj_me:remove_impact(imp)
            -- end
            -- imp:set_activate_times(activate_times)
        -- end
    -- end
-- end

function std_impact_021:on_damage_target(impact, attacker, target, damages, skill_id, imp)
    local activate_times = impact:get_activate_times()
	if activate_times == 0 then
		attacker:on_impact_fade_out(impact)
		attacker:remove_impact(impact)
		return
	end
	local collection = self:get_target_impact_collection(impact)
	if collection ~= define.INVAILD_ID then
		local in_col = imp and impactenginer:is_impact_in_collection(imp, collection)
		if not in_col then
			return
		end
	end
    local rate_up = self:get_mind_attack_damage_up_rate(impact)
    if rate_up ~= 0 then
		if imp and imp:is_critical_hit() then
			if damages and damages.damage_rate then
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] * (100 + rate_up) / 100
				end
				activate_times = activate_times - 1
			end
		end
    end
	rate_up = self:get_power_percent_refix(impact)
    if rate_up ~= 0 then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] * (100 + rate_up) / 100
			end
			activate_times = activate_times - 1
		end
	end
	if activate_times == 0 then
		attacker:on_impact_fade_out(impact)
		attacker:remove_impact(impact)
	else
		impact:set_activate_times(activate_times)
	end
end

return std_impact_021