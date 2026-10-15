local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_054 = class("std_impact_054", base)

function std_impact_054:is_over_timed()
    return true
end

function std_impact_054:is_intervaled()
    return false
end

function std_impact_054:get_hp_recover_rate(imp)
    return imp.params["复活后的HP%"] / 100
end

function std_impact_054:set_hp_recover_rate(imp, rate)
    imp.params["复活后的HP%"] = rate
end

function std_impact_054:get_mp_recover_rate(imp)
    return imp.params["复活后的MP%"] / 100
end

function std_impact_054:set_mp_recover_rate(imp, rate)
    imp.params["复活后的MP%"] = rate
end

function std_impact_054:get_rage_recover_rate(imp)
    return imp.params["复活后的Rage%"] / 100
end

function std_impact_054:on_active(imp, obj)
    local relive_info = {}
    relive_info.hp_recover_rate = self:get_hp_recover_rate(imp)
    relive_info.mp_recover_rate = self:get_mp_recover_rate(imp)
    relive_info.rage_recover_rate = self:get_rage_recover_rate(imp)
    relive_info.sceneid = obj:get_scene_id()
    relive_info.world_pos = obj:get_world_pos()
    obj:set_relive_info(true, relive_info)
end

return std_impact_054