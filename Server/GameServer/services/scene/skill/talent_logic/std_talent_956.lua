-- 飞剑逐踪：破天式(834)召唤的飞剑索敌范围减少为X米，并优先追击玩家目标
-- 被动效果：在飞剑创建时通过 create_extra_sword 的 opts 传入标志
-- 由 std_impact_096:create_sword 检查角色是否拥有此武道
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_956 = class("std_talent_956", base)

return std_talent_956
