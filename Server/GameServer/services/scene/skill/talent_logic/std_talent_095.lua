local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_095 = class("std_talent_095", base)
function std_talent_095:is_specific_skill(skill_id)
    return skill_id == 424
end

function std_talent_095:get_target_skill_id()
    return 426
end

function std_talent_095:get_trigger_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_095:on_use_skill_success_fully(talent, level, skill_info, human)
    -- 调试输出已屏蔽
    -- print("0 std_talent_095:on_use_skill_success_fully")
    if self:is_specific_skill(skill_info.id) then
        local percent = self:get_trigger_percent(talent, level)
        local n = math.random(100)
        if n <= percent then
            local template = skillenginer:get_skill_template(self:get_target_skill_id())
            local cool_down_id = template.cool_down_id
            local cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
            -- 调试输出已屏蔽
            -- print("1 std_talent_095:on_use_skill_success_fully cool_down_time =", cool_down_time, ";cool_down_id =", cool_down_id)
            human:update_cool_down_by_cool_down_id(cool_down_id, 2000)
            cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
            -- 调试输出已屏蔽
            -- print("2 std_talent_095:on_use_skill_success_fully cool_down_time =", cool_down_time, ";cool_down_id =", cool_down_id)
        end
    end
end

return std_talent_095