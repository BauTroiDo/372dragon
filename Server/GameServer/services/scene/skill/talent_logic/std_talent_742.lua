local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_742 = class("std_talent_742", base)

-- 酌酒归元：千里横行(342)每个连击段恢复自身血上限N%的血量
-- SectInfo params: 4/8/12/16/20 => 对应 0.4%/0.8%/1.2%/1.6%/2%
-- 计算公式：max_hp * value / 1000

function std_talent_742:is_specific_skill(skill_id)
    return skill_id == 342
end

function std_talent_742:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_742:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_refix_value(talent, level)
        if value > 0 then
            local max_hp = sender:get_max_hp()
            local recover_hp = math.ceil(max_hp * value / 100)
            if recover_hp > 0 then
                sender:health_increment(recover_hp, sender, false, nil)
            end
        end
    end
end

return std_talent_742
