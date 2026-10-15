-- 虹吸之线：星河虹吸(832)触发的tether效果
-- 贴在目标身上，持续15秒，每秒检查与施法者距离
-- 距离超过10米时：对目标施加散功3秒，并移除自身
-- 武道975（托体同山阿）扩展：
--   每秒吸取目标20点怒气（目标-20，施法者+20）
--   目标死亡时，施法者额外恢复X点怒气（由天赋参数决定）
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local base = require "scene.skill.impact_logic.base"

local std_impact_545 = class("std_impact_545", base)
local SANGONG_IMPACT_ID = 63016  -- 散功效果ID -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
local BREAK_DIST = 10            -- 断线距离（米）
local TALENT_975_ID = 975        -- 武道天赋：托体同山阿
local RAGE_DRAIN_PER_SEC = 20    -- 每秒吸取怒气量

-- 辅助：获取施法者天赋975的配置参数，返回 params 表或 nil
local function get_talent_975_params(sender)
    if not sender or not sender.get_talent then return nil end
    local talent = sender:get_talent()
    if not talent or not talent.study then return nil end
    for _, t in ipairs(talent.study) do
        if t.id == TALENT_975_ID then
            local sect_desc = configenginer:get_config("sect_desc")
            if not sect_desc then return nil end
            local cfg = sect_desc[TALENT_975_ID]
            if cfg and cfg.params then
                local lv = (t.level == 0) and 1 or t.level
                return cfg.params[lv]
            end
            return nil
        end
    end
    return nil
end

function std_impact_545:is_over_timed()
    return true
end

function std_impact_545:is_intervaled()
    return true
end

-- 每秒(interval在StandardImpact中配置为1000ms)检查一次距离
function std_impact_545:on_interval_over(imp, obj)
    local caster_obj_id = imp:get_caster_obj_id()
    local scene = obj:get_scene()
    if not scene then
        obj:remove_impact(imp)
        return
    end
    local sender = scene:get_obj_by_id(caster_obj_id)
    -- 施法者已离线或死亡，移除tether
    if not sender or not sender:is_alive() then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
        return
    end

    local pos1 = obj:get_world_pos()
    local pos2 = sender:get_world_pos()
    if not pos1 or not pos2 then return end
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > BREAK_DIST then
        -- 超过10米：散功目标3秒，断线
        impactenginer:send_impact_to_unit(obj, SANGONG_IMPACT_ID, sender, 0, false, 0)
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
        return
    end

    -- 武道975：每秒吸取目标20点怒气
    local params975 = get_talent_975_params(sender)
    if params975 then
        if obj:get_obj_type() == "human" then
            obj:rage_increment(-RAGE_DRAIN_PER_SEC, sender)
            skynet.error(string.format("[545][975] 吸取怒气: sender=%s target=%s drain=%d",
                tostring(sender:get_name()), tostring(obj:get_name()), RAGE_DRAIN_PER_SEC))
        end
        if sender:get_obj_type() == "human" then
            sender:rage_increment(RAGE_DRAIN_PER_SEC, sender)
        end
    end
end

-- 武道975：目标死亡时，施法者额外恢复怒气
function std_impact_545:on_die(imp, obj)
    local caster_obj_id = imp:get_caster_obj_id()
    local scene = obj:get_scene()
    if not scene then return end
    local sender = scene:get_obj_by_id(caster_obj_id)
    if not sender then return end

    local params975 = get_talent_975_params(sender)
    if not params975 then return end

    local extra_rage = params975[1] or 0
    if extra_rage > 0 and sender:get_obj_type() == "human" then
        sender:rage_increment(extra_rage, sender)
        skynet.error(string.format("[545][975] 目标死亡额外怒气: sender=%s extra_rage=%d",
            tostring(sender:get_name()), extra_rage))
    end
end

return std_impact_545
