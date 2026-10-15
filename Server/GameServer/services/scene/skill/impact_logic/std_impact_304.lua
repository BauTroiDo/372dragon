local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local skillenginer = require "skillenginer":getinstance()
local std_impact_304 = class("std_impact_304", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_304:is_over_timed()
    return true
end

function std_impact_304:is_intervaled()
    return false
end

function std_impact_304:get_damage_rate(imp, i)
    local key = string.format("第%d次伤害比率", i)
    return imp.params[key]
end

function std_impact_304:set_damage_rate(imp, i, rate)
    local key = string.format("第%d次伤害比率", i)
    imp.params[key] = rate
end

function std_impact_304:get_sputtering_rage(imp)
    return imp.params["溅射范围"]
end

function std_impact_304:get_skill_id(imp)
    return imp.params["技能ID"] or -1
end

function std_impact_304:set_linked_buff(imp, value)
	imp.params["关联BUFF"] = value
end

function std_impact_304:on_damage_target(imp, sender, reciver, damages, skill_id)
    if skill_id ~= self:get_skill_id(imp) then
        return
    end
	if damages and damages.damage_rate then
		local up = self:get_damage_rate(imp, 1) - 100
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] + up
		end
		local key = DAMAGE_TYPE_BACK[1]
		table.insert(damages[key],imp)
	end
	
    -- local hp_damage = damages.hp_damage
    -- damages.hp_damage = 0
    -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
    -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
        -- damages[i] = math.floor((damages[i] or 0) * self:get_damage_rate(imp, 1) / 100)
        -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
    -- end
    -- local targets = { }
    -- local sputtering_rage = self:get_sputtering_rage(imp)
    -- if sender then
        -- local position = reciver:get_world_pos()
        -- local radious = sputtering_rage / 1000
        -- local operate = {obj = sender, x = position.x, y = position.y, radious = radious, target_logic_by_stand = 1, check_can_view = true}
        -- local nearbys = reciver:get_scene():scan(operate)
        -- for _, nb in ipairs(nearbys) do
            -- if nb:is_character_obj(nb) then
               -- if sender:is_enemy(nb) and nb:is_alive() and nb ~= reciver then
                   -- table.insert(targets, nb)
               -- end
            -- end
        -- end
    -- end
    -- for i = 1, 4 do
        -- local hp_modify_rate = self:get_damage_rate(imp, i + 1)
        -- local hp_modify = -1 * math.ceil(hp_damage * hp_modify_rate / 100)
        -- local o = targets[i] or reciver
        -- o:health_increment(hp_modify, sender)
    -- end
end
function std_impact_304:on_damages_back(imp, reciver, damage_value,sender)
	if damage_value <= 0 then
		return
	end
    local targets = { }
    local sputtering_rage = self:get_sputtering_rage(imp)
	local mind_attack = 0
	local position = reciver:get_world_pos()
    if sender then
        local radious = sputtering_rage / 1000
        local operate = {obj = sender, x = position.x, y = position.y, radious = radious, target_logic_by_stand = 1, check_can_view = true}
        local nearbys = reciver:get_scene():scan(operate)
        for _, nb in ipairs(nearbys) do
            if nb:is_character_obj(nb) then
               if sender:is_enemy(nb) and nb:is_alive() and nb ~= reciver then
                   table.insert(targets, nb)
               end
            end
        end
		mind_attack = sender:get_mind_attack()
    end
	local skill_id = self:get_skill_id(imp)
	local hits = {}
    for i = 1, 3 do
        local hp_modify_rate = self:get_damage_rate(imp, i + 1)
        local hp_modify = -1 * math.ceil(damage_value * hp_modify_rate / 100)
        local o = targets[i] or reciver
		local mind_defend = o:get_mind_defend()
		mind_defend = mind_defend == 0 and 1 or mind_defend
		local critical_rate = mind_attack / (mind_defend * 20)
		local rand = math.random(100)
		local is_critical = false
		if rand <= critical_rate * 100 then
			is_critical = true
			hp_modify = hp_modify * 2
		end
		table.insert(hits,o:get_obj_id())
        o:health_increment(hp_modify,sender,is_critical,imp,skill_id)
    end
	if skill_id ~= -1 and sender then
		self:broadcast_skill_hit_message(sender,hits,skill_id,position)
	end
end

function std_impact_304:on_fade_out(imp, obj)
	local buffid = imp.params["关联BUFF"] or -1
	if buffid ~= -1 then
		obj:impact_cancel_impact_in_specific_impact_id(buffid)
	end
end

return std_impact_304