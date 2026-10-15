local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_901 = class("std_talent_901", base)

-- [FIX] 901 向死而生
-- skill 801（向死而生）击杀目标后，按 params[1]% 概率回复施法者 2% 最大血量
-- 核心逻辑在 character.lua:toward_death_kill_heal(sender) 中实现
-- SectDesc params: 10 / 20 / 30 / 40 / 50
--   params[1] = 触发概率(%)
--   回血量固定为施法者最大血量的 2%

return std_talent_901
