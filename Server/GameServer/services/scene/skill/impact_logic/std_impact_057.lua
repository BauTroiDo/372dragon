local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local impact = require "scene.skill.impact"
local ModifyHpMpRageStrikePointByValue_T = require "scene.skill.impact_logic.std_impact_004"
local eventenginer = require "eventenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local std_impact_057 = class("std_impact_057", base)

function std_impact_057:is_over_timed()
    return false
end

function std_impact_057:is_intervaled()
    return false
end

function std_impact_057:get_damage_rate(imp)
    return imp.params["伤害百分率"]
end

function std_impact_057:get_transfer_rate_for_hp(imp)
    return imp.params["生命转换百分率"]
end

function std_impact_057:get_transfer_rate_for_mp(imp)
    return imp.params["魔法转换百分率"]
end

function std_impact_057:get_sub_impact(imp)
    return imp.params["子效果ID(转换到主人的效果，用STD_IMPACT_004)"]
end

function std_impact_057:on_active(imp, obj)
    if obj:get_obj_type() ~= "pet" then
        return
    end
    local damage_rate = self:get_damage_rate(imp)
    local rate_for_hp = self:get_transfer_rate_for_hp(imp)
    local rate_for_mp = self:get_transfer_rate_for_mp(imp)

    local damage = math.ceil(obj:get_hp() * damage_rate / 100)
    local for_hp = math.ceil(damage * rate_for_hp / 100)
    local for_mp = math.ceil(damage * rate_for_mp / 100)

    local master = obj:get_my_master()
    if master then
        obj:health_increment(-damage, obj, false)
        local new_imp = impact.new()
        impactenginer:init_impact_from_data(self:get_sub_impact(imp), new_imp)
        if for_hp > 0 then
            ModifyHpMpRageStrikePointByValue_T:set_hp_modify(new_imp, for_hp)
        end
        if for_mp > 0 then
            ModifyHpMpRageStrikePointByValue_T:set_mp_modify(new_imp, for_mp)
        end
        eventenginer:register_impact_event(master, obj, new_imp, 0, define.INVAILD_ID)
    end
end

return std_impact_057