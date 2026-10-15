-- [FIX] 天赋903（命不由天）：借力返施(skill 829)冷却时间固定为10秒
-- 钩子: refix_skill_cool_down_time
-- 被动天赋，1级固定效果，skill_id=-1（被动）
-- SectInfo第905行: talent_id=903, sect=12(慕容), skill=-1(被动)
-- SectDesc第905行: 参数 1（固定1级）
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_903 = class("std_talent_903", base)

local TARGET_SKILL_ID = 829  -- 借力返施
local FIXED_COOL_DOWN = 10000  -- 固定冷却10秒(ms)

-- [FIX] refix_skill_cool_down_time: 将借力返施(829)冷却时间固定为10秒
function std_talent_903:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info:get_skill_id() == TARGET_SKILL_ID then
        return FIXED_COOL_DOWN
    end
    return cool_down_time
end

return std_talent_903
