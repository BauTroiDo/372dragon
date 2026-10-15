local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_471 = class("std_talent_471", base)
local impacts = {45931, 45932, 45933, 45934, 45935}
function std_talent_471:on_use_skill_success_fully(talent, level, skill_info, human)
    local target_mode = skill_info:get_targeting_logic()
    if target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_SELF or
        target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT or
        target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT_NEW or
        target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_POSITION then
            local impact_id = impacts[level]
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        end
end

return std_talent_471