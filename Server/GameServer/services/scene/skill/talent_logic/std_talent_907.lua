-- 岁岁年年：天增岁月(技能814)对自身释放时，额外增加自身X%血上限
-- refix_impact阶段直接修改已有impact的MAX_HP修正值，不额外创建buff
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_907 = class("std_talent_907", base)

function std_talent_907:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 814 and sender == reciver then
        if imp:get_logic_id() == 11 then
            local params = talent.params[level]
            local percent = params and params[1] or 0
            if percent > 0 then
                local logic = impactenginer:get_logic(imp)
                if logic then
                    local impact_hp = logic:get_increase_max_health(imp)
                    local sender_hp = sender:get_max_hp()
                    local bonus = math.ceil((sender_hp + impact_hp) * percent / 100)
                    imp.params["MAX_HP修正"] = impact_hp + bonus
                end
            end
        end
    end
end

return std_talent_907
