local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_040 = class("std_talent_040", base)

function std_talent_040:get_target_skill_id()
    return 293
end

function std_talent_040:get_trigger_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_040:on_be_hit(talent, level, human, sender, skill)
    -- 调试输出已屏蔽
    -- print("0 std_talent_040:on_critical_hit_target")
    local percent = self:get_trigger_percent(talent, level)
    local n = math.random(100)
    if n <= percent then
        local template = skillenginer:get_skill_template(self:get_target_skill_id())
        local cool_down_id = template.cool_down_id
        local cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
        -- 调试输出已屏蔽
        -- print("1 std_talent_040:on_critical_hit_target cool_down_time =", cool_down_time, ";cool_down_id =", cool_down_id)
        human:update_cool_down_by_cool_down_id(cool_down_id, 2000)
        cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
        -- 调试输出已屏蔽
        -- print("2 std_talent_040:on_critical_hit_target cool_down_time =", cool_down_time, ";cool_down_id =", cool_down_id)
    end
end

return std_talent_040