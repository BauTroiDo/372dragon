-- [FIX] 861 无处遁形
-- 核心逻辑在 std_impact_525:on_fade_out 中实现：
-- impact 525 到期时，施法者有该天赋则按概率对目标施加禁位移+破隐身（持续5秒）
-- 本文件为壳脚本，满足 talentenginer.lua 注册要求
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_861 = class("std_talent_861", base)

return std_talent_861
