local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_155 = class("std_talent_155", base)
function std_talent_155:is_specific_skill(skill_id)
    return skill_id == 491
end

function std_talent_155:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_155:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_refix_odd(sender)
        local num = math.random(100)
        if num <= odd then
            impactenginer:send_impact_to_unit(sender, 63027, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

local talent_refix = { 17, 19, 21, 23, 25}
function std_talent_155:get_refix_odd(sender)
    local level = sender:get_talent_level_by_id(561)
    local refix = talent_refix[level]
    if refix then
        return refix
    end
    return 15
end

return std_talent_155