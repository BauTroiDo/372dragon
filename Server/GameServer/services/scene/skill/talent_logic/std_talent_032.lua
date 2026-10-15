--[[
    天赋逻辑类：std_talent_032
    用于在拥有特定状态效果（ID为519）时，增加对目标造成的伤害
    该天赋会增加各种类型伤害的数值
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_032
local std_talent_032 = class("std_talent_032", base)

-- 伤害类型枚举
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

-- 触发天赋的状态效果ID
local impact_id = 519

-- 获取伤害增加值
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 伤害增加值
function std_talent_032:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 对目标造成伤害时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param id 技能ID
-- @param obj_me 执行者对象
-- @param target 目标对象
-- @param damages 伤害数据表
function std_talent_032:on_damage_target(talent, level, id, obj_me, target, damages)
    -- 如果执行者拥有特定状态效果，则增加伤害
    if obj_me:impact_have_impact_of_specific_impact_id(impact_id) then
        local value = self:get_value(talent, level)
        -- local percent = self:get_refix_value(talent, level)
		-- 增加各种类型的伤害
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + value
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * (100 + value) / 100)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

-- 返回std_talent_032类
return std_talent_032