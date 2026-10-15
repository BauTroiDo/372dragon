--[[
    天赋逻辑类：std_talent_056
    用于在受到伤害时，根据生命值百分比给自身施加不同的状态效果
    生命值越低，施加的状态效果越强
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_056
local std_talent_056 = class("std_talent_056", base)

-- 不同生命值百分比对应的状态效果ID
local std_impact_1 = 50031  -- 生命值<=80%时施加
local std_impact_2 = 50032  -- 生命值<=50%时施加
local std_impact_3 = 50033  -- 生命值<=20%时施加

-- 受到伤害时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param damages 伤害数据
-- @param obj_me 执行者对象
function std_talent_056:on_damages(talent, level, damages, obj_me)
    -- 计算当前生命值百分比
    local max_hp = obj_me:get_max_hp()
    local hp = obj_me:get_hp()
    local rate = math.floor(hp / max_hp * 100)
    
    -- 获取第三档生命值阈值（默认20%），可通过天赋713修正
	local lv3 = 20
	local refix_lv3 = obj_me:have_talent(713)
	if refix_lv3 > lv3 then
		lv3 = refix_lv3
	end
	
    -- 根据生命值百分比施加不同的状态效果
    if rate <= lv3 then
        -- 生命值<=20%，施加最强状态效果
        if obj_me:impact_get_first_impact_of_specific_data_index(std_impact_3) == nil then
            impactenginer:send_impact_to_unit(obj_me, std_impact_3, obj_me, 0, false, 0)
        end
    elseif rate <= 50 then
        -- 生命值<=50%，施加中等状态效果
        if obj_me:impact_get_first_impact_of_specific_data_index(std_impact_2) == nil then
            impactenginer:send_impact_to_unit(obj_me, std_impact_2, obj_me, 0, false, 0)
        end
    elseif rate <= 80 then
        -- 生命值<=80%，施加较弱状态效果
        if obj_me:impact_get_first_impact_of_specific_data_index(std_impact_1) == nil then
            impactenginer:send_impact_to_unit(obj_me, std_impact_1, obj_me, 0, false, 0)
        end
    end
end

-- 返回std_talent_056类
return std_talent_056