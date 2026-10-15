-- 乘月返真：使用星河虹吸(832)后获得一个10秒的状态
-- 受到部分控制效果时，减少该效果1秒持续时间，最多减少至2秒
-- 并有X%概率直接免疫该控制效果，免疫效果最多生效1次
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_984 = class("std_talent_984", base)
local impacts = {19108, 19109, 19110, 19125, 19126}

function std_talent_984:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 832 then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        end
    end
end

return std_talent_984
