--[[
    天赋逻辑类：std_talent_071
    用于在特定技能（ID为377，天魔飞斧）造成伤害时
    如果目标拥有特定状态效果（ID为133），则增加各种类型的伤害
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_071
local std_talent_071 = class("std_talent_071", base)

-- 伤害类型枚举
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
 
-- 触发天赋的状态效果ID
local impact_id = 133

-- 检查是否为天魔飞斧技能（ID为377）
-- @param skill_id 技能ID
-- @return boolean 是否为天魔飞斧技能
function std_talent_071:is_tianma_feipu_skill(skill_id)
    return skill_id == 377
end

-- 获取伤害增加百分比
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 伤害增加百分比
function std_talent_071:get_damage_add_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 对目标造成伤害时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param id 技能ID
-- @param _ 保留参数
-- @param target 目标对象
-- @param damages 伤害数据表
-- @param skill_id 技能ID
function std_talent_071:on_damage_target(talent, level, id, _, target, damages, skill_id)
    -- 如果是天魔飞斧技能，且目标拥有特定状态效果，则增加伤害
    if self:is_tianma_feipu_skill(skill_id) then
        if target:impact_get_first_impact_of_specific_impact_id(impact_id) then
            local percent = self:get_damage_add_percent(talent, level)
			-- 增加各种类型的伤害
			if damages and damages.damage_rate then
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] + percent
				end
			end
			-- local hp_damage = 0
            -- for i = 0, 6 do
                -- damages[i] = math.floor(damages[i] * ( 100 + percent) / 100)
                -- hp_damage = hp_damage + damages[i]
            -- end
            -- hp_damage = math.floor(hp_damage)
            -- hp_damage = hp_damage < 1 and 1 or hp_damage
            -- damages.hp_damage = hp_damage
        end
    end
end

-- 返回std_talent_071类
return std_talent_071