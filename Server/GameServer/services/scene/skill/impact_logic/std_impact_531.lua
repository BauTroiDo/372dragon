-- 心剑交融状态
-- 继承011属性修正，扩展：攻击目标概率挂破绽，被攻击概率获得借力
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local impactenginer = require "impactenginer":getinstance()
local std_impact_011 = require "scene.skill.impact_logic.std_impact_011"
local std_impact_531 = class("std_impact_531", std_impact_011)

function std_impact_531:get_debuff_rate(imp)
    return imp.params["破绽触发概率"] or 0
end

function std_impact_531:get_debuff_id(imp)
    return imp.params["破绽效果ID"] or -1
end

function std_impact_531:get_borrow_rate(imp)
    return imp.params["借力触发概率"] or 0
end

function std_impact_531:get_borrow_id(imp)
    return imp.params["借力效果ID"] or -1
end

-- 攻击目标时概率挂破绽debuff
function std_impact_531:on_damage_target(imp, sender, target, damages, skill_id, damage_imp)
    local rate = self:get_debuff_rate(imp)
    if rate <= 0 then return end
    local debuff_id = self:get_debuff_id(imp)
    if debuff_id < 0 then return end
    local rand = math.random(100)
    if rand <= rate then
        impactenginer:send_impact_to_unit(target, debuff_id, sender, 0, false, 0, skill_id)
    end
end

-- 被攻击时概率给自己挂借力buff
function std_impact_531:on_be_hit(imp, obj, sender, skill)
    if not sender then return end
    if not sender:is_alive() then return end
    -- 仅敌对来源触发
    if not obj:is_enemy(sender) then return end
    local rate = self:get_borrow_rate(imp)
    if rate <= 0 then return end
    local buff_id = self:get_borrow_id(imp)
    if buff_id < 0 then return end
    local rand = math.random(100)
    if rand <= rate then
        impactenginer:send_impact_to_unit(obj, buff_id, obj, 0, false, 0)
    end
end

return std_impact_531
