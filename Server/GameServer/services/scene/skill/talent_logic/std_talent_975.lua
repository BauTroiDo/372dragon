-- 托体同山阿（武道975）天赋
-- 功能1：虹吸之线（impact 19181 / logic 545）连线期间每秒吸取目标20点怒气（目标-20，自身+20）
-- 功能2：目标在连线期间死亡，自身额外恢复X点怒气（X由等级参数决定：40/80/120/160/200）
-- 实现位置：std_impact_545.lua（on_interval_over + on_die）
--   on_interval_over 中检查施法者是否学习了该天赋，是则执行怒气吸取
--   on_die          中检查施法者是否学习了该天赋，是则执行额外怒气恢复
-- 本文件无需额外回调，逻辑已在底层 impact 层实现
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_975 = class("std_talent_975", base)

return std_talent_975
