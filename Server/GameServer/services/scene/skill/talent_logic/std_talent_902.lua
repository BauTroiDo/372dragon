local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_902 = class("std_talent_902", base)

-- [FIX] 902 执掌黄泉
-- skill 811（魂离魄散）击杀目标后，按 params[1]% 概率额外增加 params[2] 个命魂拘获数
-- 核心逻辑在 character.lua:soul_separated_kill_blindness(sender) 中实现
-- SectDesc params: 7;2 / 14;4 / 21;6 / 28;8 / 35;10
--   params[1] = 触发概率(%)
--   params[2] = 额外命魂拘获数

return std_talent_902
