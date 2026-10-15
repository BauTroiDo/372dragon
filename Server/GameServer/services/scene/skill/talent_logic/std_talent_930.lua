-- 静水深流：触发借力效果时，减少借力返施(829)X秒的冷却时间
-- 实际逻辑在 std_impact_534:on_be_hit 中实现（借力触发时直接检查天赋930并减少冷却）
-- 与天赋 931、968 的实现模式一致
-- 此文件保留作为天赋系统注册入口
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_930 = class("std_talent_930", base)

return std_talent_930
