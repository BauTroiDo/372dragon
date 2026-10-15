-- [FIX] 天赋460（流荧难缚）：怒火连斩(impact 335)命中期间，免疫定身概率 10/20/30/40/50%
-- refix_impact 阶段检查 impact_id==335 且 logic_id==14（定身类），按概率将速度修正值清零以取消定身效果
-- SectInfo第462行: skill=152, impact_id=335
-- SectDesc第462行: 参数 10/20/30/40/50
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_460 = class("std_talent_460", base)

function std_talent_460:is_specific_impact(impact_id)
    return impact_id == 335
end

function std_talent_460:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- [FIX] refix_impact: impact 335 命中时，按概率免疫定身（logic_id=14，清零速度修正值）
function std_talent_460:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 14 then
            local odd = self:get_odd(talent, level)
            if math.random(100) <= odd then
                local logic = impactenginer:get_logic(imp)
                if logic then
                    logic:set_value_of_refix_speed(imp, 0)
                end
            end
        end
    end
end

return std_talent_460
