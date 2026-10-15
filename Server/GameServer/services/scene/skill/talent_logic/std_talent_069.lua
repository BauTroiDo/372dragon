local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_069 = class("std_talent_069", base)

function std_talent_069:is_add_mp_rate_skill(skill_id)
    return skill_id == 376
end

function std_talent_069:get_extra_add_mp_rate_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_069:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_add_mp_rate_skill(skill_id) then
        -- 天罡北斗阵当前使用 STD_IMPACT_012，气上限走 MAX_MP修正率。
        if imp:get_logic_id() == 12 then
            local percent = self:get_extra_add_mp_rate_value(talent, level) or 0
            if percent > 0 then
                imp.params["MAX_MP修正率"] = (imp.params["MAX_MP修正率"] or 0) + percent
            end
        end
    end
end

return std_talent_069