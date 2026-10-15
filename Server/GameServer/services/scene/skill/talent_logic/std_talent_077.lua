local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_077 = class("std_talent_077", base)
local skills = {
    [77] = 378,
    [80] = 372,
    [81] = 379,
    [83] = 395,
    [4] = 343,
    [15] = 361,
    [17] = 342,
    [37] = 301,
    [42] = 293,
    [58] = 313,
    [47] = 312,
    [94] = 413,
    [115] = 433,
    [130] = 451,
    [637] = 789,
    [79] = 808,
    [732] = 364,
    [765] = 409,
    [796] = 435,
    [804] = 469,
    [847] = 533,
    [875] = 777,
}
function std_talent_077:is_refix_cool_down_time_skill(talent_id, skill_info)
    return skills[talent_id] == skill_info.id
end

function std_talent_077:get_reduce_count(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_077:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if self:is_refix_cool_down_time_skill(talent_id, skill_info) then
        local reduce_count = self:get_reduce_count(talent, level)
        reduce_count = reduce_count * 1000
        cool_down_time = cool_down_time - reduce_count
    end
    -- print("refix_skill_cool_down_time skill_id =", skill_info.id, ";cool_down_time =", cool_down_time)
    return cool_down_time
end

return std_talent_077