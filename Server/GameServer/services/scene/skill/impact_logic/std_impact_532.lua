-- 借力状态
-- 参考524，释放借力返施技能集合中的技能时必会心，命中后自动消耗
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_532 = class("std_impact_532", base)

function std_impact_532:is_over_timed()
    return true
end

function std_impact_532:is_intervaled()
    return false
end

function std_impact_532:get_skill_collection_id(imp)
    return imp.params["借力返施技能集合ID"] or -1
end

-- 释放借力返施技能时必会心，并消耗自身
function std_impact_532:refix_critical_rate(imp, critical_rate, skill_info, obj)
    if skill_info then
        local collection_id = self:get_skill_collection_id(imp)
        -- collection_id == -1 表示任意技能都触发必暴
        if collection_id == -1 or skillenginer:is_skill_in_collection(skill_info.id, collection_id) then
            critical_rate = 100
            obj:on_impact_fade_out(imp)
            obj:remove_impact(imp)
        end
        return critical_rate
    end
    return critical_rate
end

return std_impact_532
