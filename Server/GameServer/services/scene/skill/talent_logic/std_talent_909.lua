-- 君子剑：受到拥有心剑交融破绽状态的目标攻击时
-- 若没触发借力效果，则有20%概率恢复该伤害X%的血量
-- 实际逻辑在 std_impact_534:on_be_hit 中实现（借力未触发时直接检查天赋909并恢复血量）
-- 与天赋 930、931、968 的实现模式一致
-- 此文件保留作为天赋系统注册入口
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_909 = class("std_talent_909", base)

return std_talent_909
