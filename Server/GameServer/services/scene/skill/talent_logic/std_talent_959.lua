-- 晚夜何长：破天式(834)飞剑命中时，有50%概率使麻痹时间增加X秒
-- 被动效果：通过 std_impact_096 的 apply_talent_flags 注入 _paralyze_extend 参数
-- 飞剑命中时由 SpecialObj 逻辑读取此参数
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_959 = class("std_talent_959", base)

return std_talent_959
