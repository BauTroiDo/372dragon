local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_517 = class("std_impact_517", base)

function std_impact_517:is_over_timed()
    return true
end

function std_impact_517:is_intervaled()
    return false
end

function std_impact_517:get_refix_att_cold(imp, args)
    local value = imp.params["冰系攻击修正"]
	if value then
		value = value // 100
		args.point = (args.point or 0) + value
	end
    local rate = imp.params["冰系攻击修正%"]
	if rate then
		rate = rate // 100
		args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
	end
	
end

function std_impact_517:get_refix_att_fire(imp, args)
    local value = imp.params["火系攻击修正"]
	if value then
		value = value // 100
		args.point = (args.point or 0) + value
	end
    local rate = imp.params["火系攻击修正%"]
	if rate then
		rate = rate // 100
		args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
	end
end

function std_impact_517:get_refix_att_light(imp, args)
    local value = imp.params["电系攻击修正"]
	if value then
		value = value // 100
		args.point = (args.point or 0) + value
	end
    local rate = imp.params["电系攻击修正%"]
	if rate then
		rate = rate // 100
		args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
	end
end

function std_impact_517:get_refix_att_poison(imp, args)
    local value = imp.params["毒系攻击修正"]
	if value then
		value = value // 100
		args.point = (args.point or 0) + value
	end
    local rate = imp.params["毒系攻击修正%"]
	if rate then
		rate = rate // 100
		args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
	end
end

-- function std_impact_517:continuance_refix(imp, value)
    -- local continuance = imp:get_continuance()
    -- continuance = continuance + value
    -- imp:set_continuance(continuance)
-- end

return std_impact_517