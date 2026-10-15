-- 奉雪掬霜：触发蓄气时，有X%概率使该控制效果的来源获得对应的彼行我释控制效果
-- 同时清除自身的蓄气状态。本效果每30秒最多触发一次
--
-- 实际逻辑位于 std_impact_533:try_982_counter
-- 触发时机：蓄云欲雨(impact 533)的 on_be_skill 检测到控制类技能命中并给予蓄气时
-- CD 管理：通过 obj._982_last_trigger 字段（os.time()）控制30秒CD
-- 此文件保留作为天赋系统注册入口
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_982 = class("std_talent_982", base)

return std_talent_982
