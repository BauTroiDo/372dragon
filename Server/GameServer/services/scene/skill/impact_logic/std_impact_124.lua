local class = require "class"
local define = require "define"
local impactenginer  = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local skynet = require "skynet"
local base = require "scene.skill.impact_logic.base"
local std_impact_124 = class("std_impact_124", base)

function std_impact_124:is_over_timed()
    return true
end

function std_impact_124:is_intervaled()
    return false
end

function std_impact_124:get_affect_radious(imp)
    return imp.params["扫描半径"]
end

function std_impact_124:get_affect_target_count(imp)
    return imp.params["影响目标人数"]
end

function std_impact_124:get_target_select_stand(imp)
    local stand = imp.params["目标选择标记：-1:敌人,0:中立,1:友好,2:友好+队友;"]
    if stand == -1 then
        return 1
    elseif stand == 2 then
        return 0
    end
end

function std_impact_124:get_is_affect_self(imp)
    return imp.params["是否影响自己：0不影响，1影响；"] == 1
end

function std_impact_124:get_impact_stand(imp)
    return imp.params["受到影响的类型：-1:负面,0:中性,1:增益;"]
end

function std_impact_124:get_is_damage_use_combat_rule(imp)
    return imp.params["伤害是否使用战斗计算规则"] == 1
end

function std_impact_124:get_alive_impact(imp, index)
    local key = string.format("存活效果%d", index)
    return imp.params[key] or define.INVAILD_ID
end

function std_impact_124:get_dead_impact(imp, index)
    local key = string.format("死亡效果%d", index)
    return imp.params[key] or define.INVAILD_ID
end

function std_impact_124:get_talent_802_value(imp)
	return imp.params["武道802效果"] or 0
end

function std_impact_124:set_talent_802_value(imp, value)
	imp.params["武道802效果"] = value
end

function std_impact_124:on_die(imp, obj)
    -- 20 秒内目标死亡：走死亡分支，并清理 BUFF 显示
    obj:on_impact_fade_out(imp)
    obj:remove_impact(imp)
end

function std_impact_124:on_fade_out(imp, obj)
    local radious = self:get_affect_radious(imp)
    local affect_count = self:get_affect_target_count(imp)
    local position = obj:get_world_pos()
    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    if not sender then
        return
    end
    local scaner = obj or sender
    local target = obj
    local operate = {
        obj = sender,
        scaner = scaner,
        x = position.x,
        y = position.y,
        radious = radious,
        target_logic_by_stand = self:get_target_select_stand(imp) or 1,
    }
    local nearbys = obj:get_scene():scan(operate)
    local count = 0
    for _, nb in ipairs(nearbys) do
        if nb:is_character_obj() then
            local is_enemy = sender:is_enemy(nb)
            local is_alive = nb:is_alive()
            if is_enemy and is_alive and nb ~= target then
                for i = 1, 2 do
                    local value
                    if obj:is_alive() then
                        -- 20 秒到期且目标仍存活：仅传播存活效果（失明）
                        value = self:get_alive_impact(imp, i)
                    else
                        -- 20 秒内目标死亡：传播死亡效果（伤害 + 失明）
                        value = self:get_dead_impact(imp, i)
                    end
                    if value ~= define.INVAILD_ID then
                        impactenginer:send_impact_to_unit(nb, value, sender, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
                    end
                end
                count = count + 1
                if count >= affect_count then
                    break
                end
            end
        end
    end
    local value = self:get_talent_802_value(imp)
    if value < 0 and count > 0 then
        --value = value * count
        local reduce_ms = math.floor(math.abs(value) * count)
        local cool_down_id = skillenginer:get_skill_template(435, "cool_down_id")
        if cool_down_id then
            --sender:update_cool_down_by_cool_down_id(cool_down_id, value)
            local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
			sender:update_cool_down_by_cool_down_id(cool_down_id, reduce_ms)
        end
        cool_down_id = skillenginer:get_skill_template(454, "cool_down_id")
        if cool_down_id then
            local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
			sender:update_cool_down_by_cool_down_id(cool_down_id, reduce_ms)
            --sender:update_cool_down_by_cool_down_id(cool_down_id, value)
        end
        local max_hp = sender:get_max_hp()
        local hp_modify = max_hp * 0.02 * count
        sender:health_increment(hp_modify, sender)
    end
end

return std_impact_124
