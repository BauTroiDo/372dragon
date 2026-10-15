local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_379 = class("std_talent_379", base)

-- [FIX] 弦歌不辍：玦音曲命中得花 + 消耗花时概率返花
-- SectDesc参数：params[1]=命中得花概率%, params[2]=返花概率%, params[3]=返花数量
local XUANYIN_SKILL_ID = 760  -- 玦音曲技能ID

function std_talent_379:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0, params[2] or 0, params[3] or 1
end

-- 钉子一：玦音曲命中时，按params[1]%概率得花1朵曼陀花
function std_talent_379:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == XUANYIN_SKILL_ID then
        local hit_chance = talent.params[level][1] or 0
        if math.random(100) <= hit_chance then
            sender:datura_flower_increment(1, sender)
        end
    end
end

-- 钉子二：使用消耗曼陀花的技能成功后，按params[2]%概率返回 params[3] 朵花
function std_talent_379:on_use_skill_success_fully(talent, level, skill_info, sender)
    local term = skill_info:get_deplete_by_type(define.ConditionAndDepleteID.CD_FLOWER_BY_VALUE)
    if term and term.params[1] and term.params[1] > 0 then
        local params = talent.params[level]
        local return_chance = params[2] or 0
        local return_count = params[3] or 1
        if math.random(100) <= return_chance then
            sender:datura_flower_increment(return_count, sender)
        end
    end
end

return std_talent_379