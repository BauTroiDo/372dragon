local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_013 = class("std_impact_013", base)

function std_impact_013:is_over_timed()
    return true
end

function std_impact_013:is_intervaled()
    return false
end

function std_impact_013:get_refix_attrib_hit(imp, args)
    local value = imp.params["命中+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["命中+(%)"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_013:get_value_of_refix_attrib_hit(imp)
    return imp.params["命中+"] or 0
end

function std_impact_013:set_value_of_refix_attrib_hit(imp, value)
    imp.params["命中+"] = value
end

function std_impact_013:get_rate_of_refix_attrib_hit(imp)
    return imp.params["命中+(%)"] or 0
end

function std_impact_013:set_rate_of_refix_attrib_hit(imp, value)
    imp.params["命中+(%)"] = value
end

function std_impact_013:get_refix_attrib_miss(imp, args)
    local value = imp.params["闪避+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["闪避+(%)"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_013:get_value_of_refix_attrib_miss(imp)
    return imp.params["闪避+"] or 0
end

function std_impact_013:set_value_of_refix_attrib_miss(imp, value)
    imp.params["闪避+"] = value
end

function std_impact_013:get_rate_of_refix_attrib_miss(imp)
    return imp.params["闪避+(%)"] or 0
end

function std_impact_013:set_rate_of_refix_attrib_miss(imp, value)
    imp.params["闪避+(%)"] = value
end

function std_impact_013:get_refix_hp_max(imp, args)
    local value = imp.params["MAX_HP修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_013:get_refix_mind_attack(imp, args, obj)
    local value = imp.params["会心攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local trans = self:get_value_of_mind_defent_trans_to_mind_attack(imp, obj)
    if trans > 0 then
        args.point = args.point + trans
    end
end

function std_impact_013:get_value_of_refix_mind_attack(imp)
    return imp.params["会心攻击+"] or 0
end

function std_impact_013:set_value_of_refix_mind_attack(imp, value)
    imp.params["会心攻击+"] = value
end

function std_impact_013:get_skill_mind_attck_rate_up(imp)
    return imp.params["会心一击率+"] or 0
end

function std_impact_013:set_skill_mind_attck_rate_up(imp, value)
    imp.params["会心一击率+"] = value
end

function std_impact_013:get_critical_hit_limit(imp)
    return imp.params["会心次数限制"]
end

function std_impact_013:set_critical_hit_limit(imp, limit)
    imp.params["会心次数限制"] = limit
end

function std_impact_013:get_critical_hit_count(imp)
    return imp.params["会心次数"] or 0
end

function std_impact_013:set_critical_hit_count(imp, count)
    imp.params["会心次数"] = count
end

function std_impact_013:get_refix_mind_defend(imp, args, obj)
    local value = imp.params["会心防御+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    if obj:get_obj_type() == "human" then
        local rate = self:get_rate_of_mind_defend_trans_to_mind_attack(imp)
        if rate > 0 then
            args.point = args.point + math.ceil(obj:get_db():get_base_attrib("mind_defend") * (-1 * rate) / 100)
        end
    end
end

function std_impact_013:get_value_of_mind_defent_trans_to_mind_attack(imp, obj)
    local rate = self:get_rate_of_mind_defend_trans_to_mind_attack(imp)
    if rate > 0 then
        local mind_defend = obj:get_attrib("mind_defend")
        local trans = math.ceil(mind_defend * rate / 100)
        return trans
    end
    return 0
end

function std_impact_013:get_rate_of_mind_defend_trans_to_mind_attack(imp)
    return imp.params["会心防御转换会心攻击比率"] or 0
end

function std_impact_013:set_rate_of_mind_defend_trans_to_mind_attack(imp, rate)
    imp.params["会心防御转换会心攻击比率"] = rate
end

function std_impact_013:refix_critical_rate(imp, critical_rate)
    critical_rate = critical_rate + self:get_skill_mind_attck_rate_up(imp) / 100
    return critical_rate
end

function std_impact_013:refix_miss_rate(imp, obj_me)
    return self:get_value_of_refix_miss_rate(imp)
end

function std_impact_013:get_value_of_refix_miss_rate(imp)
    return imp.params["闪避率+"] or 0
end

function std_impact_013:set_value_of_refix_miss_rate(imp,value)
    imp.params["闪避率+"] = value
end

function std_impact_013:get_next_attack_hit_rate_increase(imp)
    return imp.params["下次攻击命中率增加"] or 0
end

function std_impact_013:set_next_attack_hit_rate_increase(imp,value)
    imp.params["下次攻击命中率增加"] = value
end

function std_impact_013:refix_skill(imp, obj, skill_info)
	local rate = self:get_next_attack_hit_rate_increase(imp)
	if rate > 0 then
		self:set_next_attack_hit_rate_increase(imp,0)
        local rate_up = skill_info:get_accuracy_rate_up()
        rate_up = rate_up + rate
        skill_info:set_accuracy_rate_up(rate_up)
    end
end

function std_impact_013:on_critical_hit_target(imp, obj)
    local limit = self:get_critical_hit_limit(imp)
    if limit then
        local count = self:get_critical_hit_count(imp)
        count = count + 1
        if count < limit then
            self:set_critical_hit_count(imp, count)
        else
            obj:remove_impact(imp)
            obj:on_impact_fade_out(imp)
        end
    end
end


return std_impact_013