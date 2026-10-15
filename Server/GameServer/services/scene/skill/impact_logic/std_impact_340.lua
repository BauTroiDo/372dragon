local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_340 = class("std_impact_340", base)
local ban_skills = {
    [22] = true,
    [63] = true,
    [75] = true
}
function std_impact_340:is_over_timed()
    return true
end

function std_impact_340:is_intervaled()
    return false
end

function std_impact_340:forbidden_this_skill(imp, skill_id)
    return ban_skills[skill_id] ~= nil
end

function std_impact_340:on_filtrate_impact(imp, obj_me, need_check_imp)
    local collection_id = 61
    if impactenginer:is_impact_in_collection(need_check_imp, collection_id) then
        return define.MissFlag_T.FLAG_IMMU
    end
end


return std_impact_340