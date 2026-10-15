-- 独立不惧：自身血量低于50%时，心剑交融(828)触发借力效果的概率提高X%
-- 被动效果：已在 std_impact_060:calc_borrow_rate 中读取此武道
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_968 = class("std_talent_968", base)

return std_talent_968
