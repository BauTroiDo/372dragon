local class = require "class"
local define = require "define"
local skynet = require "skynet"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

local std_talent_741 = class("std_talent_741", base)

-- 横行复始：横扫乾坤(365)持续时间内，每累计造成N次伤害后，自动释放一次必中千里横行(342)
-- 不影响技能原有冷却，不消耗连击段

local QIANLI_SKILL_ID = 342
local TRIGGER_SKILL_ID = 365

local FLAG_ACTIVE   = "tal741_force_342"
local FLAG_OLD_SP   = "tal741_force_342_old_sp"
local FLAG_FAKE_SP  = "tal741_force_342_fake_sp"

local function is_force_cast(sender)
    return sender:get_game_flag_key(FLAG_ACTIVE) == 1
end

local function clear_force_cast(sender)
    sender:set_game_flag_key(FLAG_ACTIVE, 0)
    sender:set_game_flag_key(FLAG_OLD_SP, 0)
    sender:set_game_flag_key(FLAG_FAKE_SP, 0)
end

function std_talent_741:is_specific_skill(skill_id)
    return skill_id == TRIGGER_SKILL_ID
end

function std_talent_741:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_741:delay_cast_qianli(sender)
    skynet.fork(function()
        local scene = sender:get_scene()
        if not scene or not sender:is_alive() then
            return
        end

        -- 等待当前动作结束（不等封禁状态，active_skill_now 绕过状态门禁）
        local actionenginer = scene:get_action_enginer()
        while sender:is_alive() and not actionenginer:can_do_next_action(sender) do
            skynet.sleep(1)
        end
        if not sender:is_alive() then
            return
        end

        local template = skillenginer:get_skill_template(QIANLI_SKILL_ID)
        if not template then
            skynet.error("[TALENT_741] get_skill_template(", QIANLI_SKILL_ID, ") failed")
            return
        end

        local old_sp = sender:get_strike_point()
        local fake_sp = 0

        sender:set_game_flag_key(FLAG_ACTIVE, 1)
        sender:set_game_flag_key(FLAG_OLD_SP, old_sp)

        -- 至少要有 1 段连击点，保证 342 能通过段数条件检查
        if old_sp < define.STRIKE_POINT_SEGMENT_SIZE then
            sender:set_strike_point(define.STRIKE_POINT_SEGMENT_SIZE)
            sender:set_game_flag_key(FLAG_FAKE_SP, 1)
            fake_sp = 1
        end

        -- 计算消耗的连击段数（用于 skill_80.lua 判断一段/二段/三段）
        local use_sp = math.floor(old_sp / define.STRIKE_POINT_SEGMENT_SIZE) * define.STRIKE_POINT_SEGMENT_SIZE
        if use_sp < define.STRIKE_POINT_SEGMENT_SIZE then
            use_sp = define.STRIKE_POINT_SEGMENT_SIZE
        end

        -- 填充 params，走 active_skill_now 绕过 process_skill_request 的状态门禁
        local params = sender:get_targeting_and_depleting_params()
        local pos = sender:get_world_pos()
        local level = sender:get_skill_level(QIANLI_SKILL_ID) or 1

        params:set_activated_script(define.INVAILD_ID)
        params:set_activated_skill(QIANLI_SKILL_ID)
        params:set_skill_level(level)
        params:set_target_obj(define.INVAILD_ID)
        params:set_target_position({ x = pos.x, y = pos.y })
        params:set_target_dir(sender:get_dir())
        params:set_ignore_condition_check_flag(true)
        params:set_ignore_cool_down_write_flag(true)
        params:set_deplete_strike_point(use_sp)

        local sk = scene:get_skill_enginer()
        local ret = sk:active_skill_now(sender)

        skynet.error("[TALENT_741] active_skill_now ret=", ret)

        if ret == false then
            -- 技能未能启动（active_skill_now 瞬发技能成功返回nil，只有false才是真失败），恢复现场
            params:set_ignore_condition_check_flag(false)
            params:set_ignore_cool_down_write_flag(false)
            if fake_sp == 1 then
                sender:set_strike_point(old_sp)
                sender:send_refresh_attrib()
            end
            clear_force_cast(sender)
        end
        -- 成功路径：on_use_skill_success_fully 里恢复冷却/连击/flag
    end)
end

function std_talent_741:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if not self:is_specific_skill(skill_id) then
        return
    end

    local key = "_talent_741_hit_count"
    local count = (sender[key] or 0) + 1
    local threshold = self:get_refix_value(talent, level)

    skynet.error("[TALENT_741] skill=", skill_id, " count=", count, " threshold=", threshold)

    if threshold > 0 and count >= threshold then
        sender[key] = 0
        self:delay_cast_qianli(sender)
    else
        sender[key] = count
    end
end

function std_talent_741:refix_skill_info(talent, level, skill_info, sender)
    if skill_info:get_skill_id() ~= QIANLI_SKILL_ID then
        return
    end
    if not is_force_cast(sender) then
        return
    end
    -- 脚本触发的 342 设成必中
    skill_info:set_accuracy(999)
end

function std_talent_741:on_use_skill_success_fully(talent, level, skill_info, sender)
    if skill_info:get_skill_id() ~= QIANLI_SKILL_ID then
        return
    end
    if not is_force_cast(sender) then
        return
    end

    skynet.error("[TALENT_741] on_use_skill_success_fully: restoring state")

    -- 恢复连击点（如果之前临时注入过）
    if sender:get_game_flag_key(FLAG_FAKE_SP) == 1 then
        local old_sp = sender:get_game_flag_key(FLAG_OLD_SP) or 0
        sender:set_strike_point(old_sp)
        sender:send_refresh_attrib()
    end

    -- 关闭绕过标志
    local params = sender:get_targeting_and_depleting_params()
    params:set_ignore_condition_check_flag(false)
    params:set_ignore_cool_down_write_flag(false)
    clear_force_cast(sender)
end

return std_talent_741
