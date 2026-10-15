local class = require "class"
local combat_core = require "scene.skill.combat_core"
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_086 = class("std_impact_086", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_086:is_over_timed()
    return true
end

function std_impact_086:is_intervaled()
    return true
end

function std_impact_086:get_affect_radious(imp)
    return imp.params["扫描半径"]
end

function std_impact_086:get_affect_target_count(imp)
    return imp.params["影响目标人数"]
end

function std_impact_086:set_affect_target_count(imp, count)
    imp.params["影响目标人数"] = count
end

function std_impact_086:set_skill_miss_count(imp, count)
    imp.params["闪避次数"] = count
end

function std_impact_086:get_skill_miss_count(imp)
    return imp.params["闪避次数"] or 0
end

function std_impact_086:get_target_select_stand(imp)
    local stand = imp.params["目标选择标记：-1:敌人,0:中立,1:友好,2:友好+队友;"]
    if stand == -1 then
        return 1
    elseif stand == 2 then
        return 0
    end
end

function std_impact_086:get_is_affect_self(imp)
    return imp.params["是否影响自己：0不影响，1影响；"] == 1
end

function std_impact_086:get_impact_stand(imp)
    return imp.params["受到影响的类型：-1:负面,0:中性,1:增益;"]
end

function std_impact_086:get_is_damage_use_combat_rule(imp)
    return imp.params["伤害是否使用战斗计算规则"] == 1
end

function std_impact_086:get_sub_impact(imp, index)
    local key = string.format("子效果%d", index)
    return imp.params[key] or -1
end

function std_impact_086:get_talent_740_rate(imp)
	return imp.params["武道740概率"] or 0
end

function std_impact_086:set_talent_740_rate(imp,value)
	imp.params["武道740概率"] = value
end

function std_impact_086:on_interval_over(imp, obj)
    -- print("std_impact_086:on_interval_over")
	-- local targetId = imp:get_caster_obj_id()
	-- if not targetId or targetId == -1 then
        -- obj:on_impact_fade_out(imp)
        -- obj:remove_impact(imp)
		-- --skill_info error!!
		-- return
	-- end
	
	
	
    local radious = self:get_affect_radious(imp)
    local affect_count = self:get_affect_target_count(imp)
    local target_logic_by_stand = self:get_target_select_stand(imp)
    local is_affect_self = self:get_is_affect_self(imp)
    local position = obj:get_world_pos()
    local operate = {obj = obj, x = position.x, y = position.y, radious = radious, target_logic_by_stand = target_logic_by_stand, count = affect_count}
    local nearbys = obj:get_scene():scan(operate)
	local dmg_rate = 0
	if #nearbys == 1 then
		if math.random(1,100) <= self:get_talent_740_rate(imp) then
			dmg_rate = 155
		end
	end
	local scene = obj:get_scene()
	local tartype
	local objtype = obj:get_obj_type()
    for _, nb in ipairs(nearbys) do
       -- print("nb.classname =", nb.classname)
        if nb:is_character_obj() then
           if obj:is_enemy(nb) and nb:is_alive() then
				if objtype == "human" then
					tartype = nb:get_obj_type()
					if tartype == "human" then
						if not nb:is_attackers(obj) then
							nb:on_be_hostility_skill(obj)
						end
					elseif tartype == "pet" then
						local reciver = nb:get_owner()
						if reciver and reciver:get_obj_type() == "human" then
							if not reciver:is_attackers(obj) then
								reciver:on_be_hostility_skill(obj)
							end
						end
					end
				end
                for i = 1, 3 do
                    local value = self:get_sub_impact(imp, i)
					if value ~= -1 then
						local imp_new = impact.new()
						imp_new:clean_up()
						impactenginer:init_impact_from_data(value, imp_new)
						if imp:is_critical_hit() then
							imp_new:mark_critical_hit_flag()
						end
						imp_new:set_skill_id(imp:get_skill_id())
						imp_new:set_skill_level(imp:get_skill_level())
						if dmg_rate > 0 then
							for _,key in ipairs(DAMAGE_TYPE_RATE) do
								imp_new:add_rate_params(key,dmg_rate)
							end
						end
						if imp_new:get_logic_id() == DI_DamagesByValue_T.ID then
							local co = combat_core.new()
							co:get_result_impact(obj, nb, imp_new)
						end
						local eventenginer = scene:get_event_enginer()
						eventenginer:register_impact_event(nb, obj, imp_new, 0, imp:get_skill_id())
					end
				end
						-- self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
						-- impactenginer:send_impact_to_unit(nb, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp), imp:get_skill_id())
					-- end
                -- end
           end
        end
    end
end

return std_impact_086