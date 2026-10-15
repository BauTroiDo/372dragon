local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_317 = class("std_impact_317", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_317:is_over_timed()
    return true
end

function std_impact_317:is_intervaled()
    return false
end

function std_impact_317:get_lose_hp_rate(imp)
    return imp.params["损失生命值百分比"] or 0
end

function std_impact_317:set_lose_hp_rate(imp, rate)
    imp.params["损失生命值百分比"] = rate or 0
end

function std_impact_317:get_give_self_impact(imp)
    return imp.params["获得效果"] or define.INVAILD_ID
end

function std_impact_317:set_cur_lose_hp(imp, value)
    imp.params["当前损失生命值"] = value
end

function std_impact_317:get_cur_lose_hp(imp)
    return imp.params["当前损失生命值"] or 0
end

function std_impact_317:get_refix_mind_defend(imp, args)
    local value = imp.params["会心防御修正%(0为无效)"] or 0
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
	-- value = imp.params["会心防御+"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value
end

function std_impact_317:set_value_of_refix_mind_defend(imp, rate)
    imp.params["会心防御修正%(0为无效)"] = rate
end

-- function std_impact_011:set_refix_mind_defend(imp, value)
    -- imp.params["会心防御+"] = value
-- end


function std_impact_317:on_damages(imp, reciver, damages)
	if damages and damages.damage_rate then
		local idx = DAMAGE_TYPE_BACK[1]
		table.insert(damages[idx],imp)
	end

		
    -- local hp_damage = damages.hp_damage
    -- local cur_lose = self:get_cur_lose_hp(imp)
    -- print("std_impact_317:on_damages hp_damage =", hp_damage, ";cur_lose =", cur_lose)
    -- cur_lose = cur_lose + math.abs(hp_damage)
    -- print("std_impact_317:on_damages cur_lose =", cur_lose)
    -- local lose_rate = (cur_lose / reciver:get_max_hp())
    -- local need_lose_rate = (self:get_lose_hp_rate(imp) / 100)
    -- print("std_impact_317:on_damages =", lose_rate, need_lose_rate)
    -- if lose_rate > need_lose_rate then
        -- local data_index = self:get_give_self_impact(imp)
        -- print("std_impact_317:on_damages data_index =", data_index)
        -- impactenginer:send_impact_to_unit(reciver, data_index, reciver, 0, false, 0)
        -- reciver:remove_impact(imp)
        -- reciver:on_impact_fade_out(imp)
    -- else
        -- print("std_impact_317:on_damages set_cur_lose_hp =", cur_lose)
        -- self:set_cur_lose_hp(imp, cur_lose)
    -- end
end

function std_impact_317:on_damages_back(imp, obj, damage_value)
    local hp_damage = damage_value
    local cur_lose = self:get_cur_lose_hp(imp)
    cur_lose = cur_lose + math.abs(hp_damage)
    local lose_rate = (cur_lose / obj:get_max_hp())
    local need_lose_rate = (self:get_lose_hp_rate(imp) / 100)
    if lose_rate > need_lose_rate then
        local data_index = self:get_give_self_impact(imp)
		if data_index ~= define.INVAILD_ID then
			impactenginer:send_impact_to_unit(obj, data_index, obj, 0, false, 0)
		end
        obj:remove_impact(imp)
        obj:on_impact_fade_out(imp)
    else
        self:set_cur_lose_hp(imp, cur_lose)
    end
	return 0
end

return std_impact_317