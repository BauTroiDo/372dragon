-- 震激风雷：使用门派技能解除自身控制状态时，恢复自身X点怒气
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_924 = class("std_talent_924", base)

-- 控制类 collection_id 集合
local control_collections = {40,41,42,43,44,130,131,132,133,134,135,137,321,332}

function std_talent_924:on_use_skill_success_fully(talent, level, skill_info, human)
    local sid = skill_info:get_skill_id()
    if sid == 821 or sid == 825 then
        -- 释放前记录自身是否有控制状态
        local had_control = false
        local list = human:get_impact_list()
        for i = #list, 1, -1 do
            local imp = list[i]
            if impactenginer:is_impact_in_collection_ex(imp, control_collections) then
                had_control = true
                break
            end
        end
        if had_control then
            local params = talent.params[level]
            local rage = params[1] or 0
            if rage > 0 then
                human:rage_increment(rage, human)
            end
        end
    end
end

return std_talent_924
