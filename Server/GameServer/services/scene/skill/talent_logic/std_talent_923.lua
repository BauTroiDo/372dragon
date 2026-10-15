-- 厚德载物：15米范围内受到七霞映日效果的队友被控制时
-- 有X%概率使该控制目标变为自己，并减少20秒春光四沐冷却
-- TODO: 需要新增"队友被控制"战斗事件广播，改动面较大，暂未实现
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_923 = class("std_talent_923", base)

return std_talent_923
