-- 归一剑：白羽流星效果召唤的飞剑不会立即飞出
-- 当破天式结束时，所有飞剑合为1把并优先追击当前选择的敌对目标
-- 一段时间后爆炸，对周围7米最多5个目标造成飞剑数*普通攻击X%的伤害
local skynet        = require "skynet"
local class         = require "class"
local impactenginer = require "impactenginer":getinstance()
local base          = require "scene.skill.talent_logic.base"
local std_talent_972 = class("std_talent_972", base)

-- 各等级对应的 Impact ID（19160~19164）
local IMPACT_IDS = {63095, 63094, 63093, 63092, 63091} -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

-- 破天式（skill_id=834）释放成功时投递监听 Impact
-- Impact 543 会持续追踪飞剑数量，破天式消失后自动触发爆炸伤害
function std_talent_972:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() ~= 834 then
        return
    end

    local impact_id = IMPACT_IDS[level]
    if not impact_id then
        skynet.error("[TALENT_972] on_use_skill_success_fully: no impact_id for level=", level)
        return
    end

    if not human then
        skynet.error("[TALENT_972] ERROR: human is nil")
        return
    end

    skynet.error("[TALENT_972] delivering impact_id=", impact_id, " level=", level)

    impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
end

return std_talent_972
