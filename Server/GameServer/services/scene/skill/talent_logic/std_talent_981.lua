-- 顺意而回：彼行我释(技能825)冷却时间减少X秒
-- 升至5级后蓄气状态可被覆盖（覆盖优先级：封穴>失明>散功>围困>昏睡>定身）
-- 覆盖逻辑在 std_impact_533.lua 的 try_override_xuqi() 和 has_981_lv5() 中实现
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_981 = class("std_talent_981", base)

function std_talent_981:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info:get_skill_id() == 825 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        cool_down_time = cool_down_time - reduce
    end
    return cool_down_time
end

return std_talent_981
