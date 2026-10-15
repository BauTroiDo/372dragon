--[[
    天赋逻辑类：std_talent_010
    用于在特定技能（ID为347）造成伤害时，增加伤害百分比
    该天赋会增加技能造成的各种类型伤害
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_010
local std_talent_010 = class("std_talent_010", base)
 
-- 检查是否为特定技能（ID为347）
-- @param skill_id 技能ID
-- @return boolean 是否为特定技能
function std_talent_010:is_specific_skill(skill_id)
    return skill_id == 347
end

-- 获取伤害增加百分比
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param segment 段数索引
-- @return number 伤害增加百分比
function std_talent_010:get_damage_add_percent(talent, level, segment)
    local params = talent.params[level]
    return params[segment] or 0
end

-- 对目标造成伤害时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param id 技能ID
-- @param _ 保留参数
-- @param target 目标对象
-- @param damages 伤害数据表
-- @param skill_id 技能ID
function std_talent_010:on_damage_target(talent, level, id, _, target, damages, skill_id)
    -- 如果是特定技能，则增加伤害
    if self:is_specific_skill(skill_id) then
        local segment = 3
        local percent = self:get_damage_add_percent(talent, level, segment) - 100
		-- 如果增加百分比大于0，则增加各种类型的伤害
		if percent > 0 then
			if damages and damages.damage_rate then
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] + percent
				end
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * percent / 100)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

-- 返回std_talent_010类
return std_talent_010