-- 借力打力：受到攻击触发借力效果时，对该伤害来源造成此次伤害X%的直接伤害
-- 实际逻辑在 std_impact_534:on_be_hit 中实现（借力触发时直接检查天赋913并对攻击者反伤）
-- 与天赋 930、931、968 的实现模式一致
-- 此文件保留作为天赋系统注册入口
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_913 = class("std_talent_913", base)

return std_talent_913
