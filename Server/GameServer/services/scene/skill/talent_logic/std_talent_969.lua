-- 吞花卧酒：自身存在借力状态时，如果再次触发借力状态
-- 则额外获得一个效果：使下次借力返施的最终伤害额外增加X%
-- 最多叠加3层，持续5秒，生效后消失
-- 实际逻辑在 std_impact_534:on_be_hit 中实现（借力触发时检查已有借力状态并叠加增伤buff）
-- 与天赋 930、931、968 的实现模式一致
-- 此文件保留作为天赋系统注册入口
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_969 = class("std_talent_969", base)

return std_talent_969
