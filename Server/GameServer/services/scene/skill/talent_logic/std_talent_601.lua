-- [FIX] 天赋601（春色撩人）：当曼陀花 < 2 朵时，玄音曲命中额外得花，概率 2/4/6/8/10%
-- on_damage_target 中检查技能属于玄音曲系列(collection 313)，且当前花朵 < 2，按概率 datura_flower_increment(1)
-- SectInfo第603行: skill_type=209, impact_id=-1
-- SectDesc第603行: 参数 2/4/6/8/10
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_601 = class("std_talent_601", base)

-- [FIX] 判断是否为玄音曲系列技能（collection 313）
function std_talent_601:is_xuanyinqu_skill(skill_id)
    return skillenginer:is_skill_in_collection(skill_id, define.MANTUO_XUANYINQV_COLLECTION_ID)
end

function std_talent_601:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- [FIX] on_damage_target: 玄音曲命中，花 < 2 时按概率额外得1朵花
function std_talent_601:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_xuanyinqu_skill(skill_id) then
        local datura_flower = sender:get_datura_flower()
        if datura_flower < 2 then
            local odd = self:get_odd(talent, level)
            if math.random(100) <= odd then
                sender:datura_flower_increment(1, sender)
            end
        end
    end
end

return std_talent_601
