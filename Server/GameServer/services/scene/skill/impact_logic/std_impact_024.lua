local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_024 = class("std_impact_024", base)

function std_impact_024:is_over_timed()
    return true
end

function std_impact_024:is_intervaled()
    return false
end

function std_impact_024:get_odds(imp)
    return imp.params["生效几率"]
end

function std_impact_024:get_immuno_impacts_by_index(imp, i)
    local key = string.format("可以免疫的效果集合%d", i)
    return imp.params[key] or define.INVAILD_ID
end

function std_impact_024:on_filtrate_impact(imp, obj_me, need_check_imp)
    local odd = self:get_odds(imp)
    local num = math.random(100)
    if num > odd then
        return
    end
    for i = 1, 4 do
        local collection_id = self:get_immuno_impacts_by_index(imp, i)
        if impactenginer:is_impact_in_collection(need_check_imp, collection_id) then
            return define.MISS_FLAG.FLAG_ABSORB
        end
    end
end

return std_impact_024