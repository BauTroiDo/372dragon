local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_019 = class("std_impact_019", base)

function std_impact_019:is_over_timed()
    return true
end

function std_impact_019:is_intervaled()
    return false
end

function std_impact_019:get_activate_times(imp)
    return imp.params["激活次数，-1是无限次"] or define.INVAILD_ID
end

function std_impact_019:get_target_impact_collection(imp)
    return imp.params["目标效果集合ID"] or define.INVAILD_ID
end

function std_impact_019:get_power_percent_refix(imp)
    return imp.params["威力修正率"] or 0
end

function std_impact_019:set_value_of_power_percent_refix(imp, value)
    imp.params["威力修正率"] = value
end

function std_impact_019:get_continuance_refix(imp)
    return imp.params["持续时间修正率"] or define.INVAILD_ID
end

function std_impact_019:get_mind_attack_rate_up(imp)
    return imp.params["会心一击率+"] or 0
end

function std_impact_019:set_value_of_mind_attack_rate_up(imp, value)
    imp.params["会心一击率+"] = value
end

function std_impact_019:get_refix_mind_attack(imp, args, obj)
    local rate = imp.params["会心攻击百分比+"] or 0
    args.rate = (args.rate or 0) + rate
end

function std_impact_019:set_value_of_mind_attack_value_up(imp, rate)
    imp.params["会心攻击百分比+"] = rate
end

function std_impact_019:refix_impact(imp, obj_me, need_refix_imp)
    if imp:get_activate_times() == 0 then
        return
    end
    if not impactenginer:is_impact_in_collection(need_refix_imp, self:get_target_impact_collection(imp)) then
        return
    end
    local logic = impactenginer:get_logic(need_refix_imp)
    if logic == nil then
        return
    end
    local activate_times = imp:get_activate_times()
    local ret = false
    local refix_power_percent = self:get_power_percent_refix(imp)
    if refix_power_percent then
        ret = ret or logic:refix_power_by_rate(need_refix_imp, refix_power_percent)
    end
    if ret then
        if activate_times > 0 then
            activate_times = activate_times - 1
            if activate_times == 0 then
                obj_me:on_impact_fade_out(imp)
                obj_me:remove_impact(imp)
            end
            imp:set_activate_times(activate_times)
        end
    end
end

function std_impact_019:refix_skill(imp, obj_me, skill_info)
    if imp:get_activate_times() == 0 then
        return
    end
    local activate_times = imp:get_activate_times()
    local ret = false
    local refix_mind_attack_rate_up = self:get_mind_attack_rate_up(imp)
    if refix_mind_attack_rate_up > 0 then
        ret = true
        local mind_attack_rate_up = skill_info:get_accuracy_rate_up()
        skill_info:set_accuracy_rate_up(mind_attack_rate_up + refix_mind_attack_rate_up)
    end
    if ret then
        if activate_times > 0 then
            activate_times = activate_times - 1
            if activate_times == 0 then
                obj_me:on_impact_fade_out(imp)
                obj_me:remove_impact(imp)
            end
            imp:set_activate_times(activate_times)
        end
    end
end

return std_impact_019