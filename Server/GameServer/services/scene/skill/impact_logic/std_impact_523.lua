local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_523 = class("std_impact_523", base)

function std_impact_523:is_over_timed()
    return true
end

function std_impact_523:is_intervaled()
    return true
end

-- function std_impact_523:get_refix_att_cold(imp, args)
    -- local value = imp.params["冰系攻击修正"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value

    -- local rate = imp.params["冰系攻击修正%"] or 0
    -- rate = math.floor(rate)
    -- args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
-- end
-- function std_impact_523:get_refix_att_fire(imp, args)
    -- local value = imp.params["火系攻击修正"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value

    -- local rate = imp.params["火系攻击修正%"] or 0
    -- rate = math.floor(rate)
    -- args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
-- end
-- function std_impact_523:get_refix_att_light(imp, args)
    -- local value = imp.params["电系攻击修正"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value

    -- local rate = imp.params["电系攻击修正%"] or 0
    -- rate = math.floor(rate)
    -- args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
-- end
-- function std_impact_523:get_refix_att_poison(imp, args)
    -- local value = imp.params["毒系攻击修正"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value

    -- local rate = imp.params["毒系攻击修正%"] or 0
    -- rate = math.floor(rate)
    -- args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
-- end

-- function std_impact_523:get_refix_reduce_def_cold(imp, args)
    -- local value = imp.params["减少对方冰抗"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value
-- end
-- function std_impact_523:get_refix_reduce_def_fire(imp, args)
    -- local value = imp.params["减少对方火抗"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value
-- end
-- function std_impact_523:get_refix_reduce_def_light(imp, args)
    -- local value = imp.params["减少对方玄抗"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value
-- end
-- function std_impact_523:get_refix_reduce_def_poison(imp, args)
    -- local value = imp.params["减少对方毒抗"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value
-- end

function std_impact_523:get_refix_def_cold(imp, args)
    local value = imp.params["冰系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end
function std_impact_523:get_refix_def_fire(imp, args)
    local value = imp.params["火系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end
function std_impact_523:get_refix_def_light(imp, args)
    local value = imp.params["电系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end
function std_impact_523:get_refix_def_poison(imp, args)
    local value = imp.params["毒系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_523:get_value_of_refix_def_cold(imp)
    return imp.params["冰系抗性修正"] or 0
end
function std_impact_523:set_value_of_refix_def_cold(imp, value)
    imp.params["冰系抗性修正"] = value
end
function std_impact_523:get_value_of_refix_def_fire(imp)
    return imp.params["火系抗性修正"] or 0
end
function std_impact_523:set_value_of_refix_def_fire(imp, value)
    imp.params["火系抗性修正"] = value
end
function std_impact_523:get_value_of_refix_def_light(imp)
    return imp.params["电系抗性修正"] or 0
end
function std_impact_523:set_value_of_refix_def_light(imp, value)
    imp.params["电系抗性修正"] = value
end
function std_impact_523:get_value_of_refix_def_poison(imp)
    return imp.params["毒系抗性修正"] or 0
end
function std_impact_523:set_value_of_refix_def_poison(imp, value)
    imp.params["毒系抗性修正"] = value
end

function std_impact_523:get_value_of_reduce_def_cold(imp)
    return imp.params["减少对方冰抗"] or 0
end
function std_impact_523:set_value_of_reduce_def_cold(imp, value)
    imp.params["减少对方冰抗"] = value
end
function std_impact_523:get_value_of_reduce_def_fire(imp)
    return imp.params["减少对方火抗"] or 0
end
function std_impact_523:set_value_of_reduce_def_fire(imp, value)
    imp.params["减少对方火抗"] = value
end
function std_impact_523:get_value_of_reduce_def_light(imp)
    return imp.params["减少对方玄抗"] or 0
end
function std_impact_523:set_value_of_reduce_def_light(imp, value)
    imp.params["减少对方玄抗"] = value
end
function std_impact_523:get_value_of_reduce_def_poison(imp)
    return imp.params["减少对方毒抗"] or 0
end
function std_impact_523:set_value_of_reduce_def_poison(imp, value)
    imp.params["减少对方毒抗"] = value
end

function std_impact_523:set_interval_mana_cost(imp, value)
    imp.params["间隙耗蓝"] = value
end
function std_impact_523:get_interval_mana_cost(imp)
    return imp.params["间隙耗蓝"] or 0
end
function std_impact_523:set_linked_buff(imp, value)
	imp.params["关联BUFF"] = value
end

function std_impact_523:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
	local sender_id = imp:get_caster_obj_id()
	local sender = obj:get_scene():get_obj_by_id(sender_id)
	if sender then
		local mp_modify = self:get_interval_mana_cost(imp)
		if mp_modify < 0 then
			obj:mana_increment(mp_modify, sender)
		end
	end
end

function std_impact_523:on_fade_out(imp, obj)
	local buffid = imp.params["关联BUFF"] or -1
	if buffid ~= -1 then
		obj:impact_cancel_impact_in_specific_impact_id(buffid)
	end
end

return std_impact_523