local define = require "define"
local abilityenginer = require "abilityenginer":getinstance()
local class = require "class"
local base = class("base")

function base:get_state_name()
    return self.classname
end

function base:get_estate()
    return define.ENUM_STATE.ESTATE_INVALID
end

function base:can_stall()
    return define.OPERATE_RESULT.OR_OK
end

function base:can_stop()
    return define.OPERATE_RESULT.OR_OK
end

function base:stop(ai)
    local result = self:can_stop(ai)
    if result ~= define.OPERATE_RESULT.OR_OK then
        return result
    end
    ai:get_character():do_stop()
    return define.OPERATE_RESULT.OR_OK
end

function base:can_jump()
    return define.OPERATE_RESULT.OR_OK
end

function base:can_move()
    return define.OPERATE_RESULT.OR_OK
end

function base:can_use_skill()
    return define.OPERATE_RESULT.OR_OK
end

function base:can_use_ability(ai)
    if ai:get_character():get_obj_type() ~= "human" then
        return define.OPERATE_RESULT.OR_ERROR
    else
        local human = ai:get_character()
        local ability_opera = human:get_ability_opera()
        local ability = abilityenginer:get_ability(ability_opera.ability_id)
        if ability then
            return ability:can_use_ability(human)
        else
            return define.OPERATE_RESULT.OR_ERROR
        end
    end
end

function base:can_use_item()
    return define.OPERATE_RESULT.OR_OK
end

function base:logic(ai, delta_time)
    self:state_logic(ai, delta_time)
end

function base:use_ability(ai)
    local res = self:can_use_ability(ai)
    if res ~= define.OPERATE_RESULT.OR_OK then
        return res
    end
    return ai:get_character():do_use_ability()
end

function base:use_item(ai, ...)
    local res = self:can_use_item(ai)
    if res ~= define.OPERATE_RESULT.OR_OK then
        return res
    end
    return define.OPERATE_RESULT.OR_OK
end
local skynet = require "skynet"
function base:use_skill(ai, skill_id, id_tar, x, y, dir, guid_tar, script_arg_1, script_arg_2, script_arg_3)
    -- print("state.base use_skill id =", skill_id)
    local result = self:can_use_skill(ai, skill_id)
    if result ~= define.OPERATE_RESULT.OR_OK then
        return result
    end
    local character = ai:get_character()
	-- skynet.logi("use_skill name:",character:get_name())
    if character:get_obj_type() == "human" then
        return define.OPERATE_RESULT.OR_OK
    end
    local can = character:can_use_skill_now()
    if character and can then
        local pos = { x = x, y = y }
        return character:do_use_skill(skill_id, id_tar, pos, dir, guid_tar, script_arg_1, script_arg_2, script_arg_3)
    end
    return define.OPERATE_RESULT.OR_OK
end

function base:obj_use_item(ai, ...)
    local character = ai:get_character()
    if character then
        return character:do_use_item(...)
    end
    return define.OPERATE_RESULT.OR_OK
end

function base:obj_active_monster(ai, ...)
    local character = ai:get_character()
    if character then
        return character:do_activite_monster(...)
    end
    return define.OPERATE_RESULT.OR_OK
end

function base:obj_use_skill(ai, ...)
    local character = ai:get_character()
    if character then
        return character:do_use_skill(...)
    end
    return define.OPERATE_RESULT.OR_OK
end

function base:move(ai, handle, pos_tar)
    local character = ai:get_character()
    character:do_move(handle, pos_tar)
    return define.OPERATE_RESULT.OR_OK
end

function base:jump(ai)
    local result = self:can_jump(ai)
    if result ~= define.OPERATE_RESULT.OR_OK then
        return result
    end
    local character = ai:get_character()
    if character then
        return character:do_jump()
    end
    return define.OPERATE_RESULT.OR_OK
end

function base:stall(ai)
    return self:can_stall(ai)
end

function base:ai_logic_dead(ai, delta_time)
    ai:ai_logic_dead(delta_time)
end

function base:ai_logic_terror(ai, delta_time)
    ai:ai_logic_terror(delta_time)
end

function base:ai_logic_idle(ai, delta_time)
    ai:ai_logic_idle(delta_time)
end

function base:ai_logic_combat(ai, delta_time)
    ai:ai_logic_combat(delta_time)
end

function base:ai_logic_flee(ai, delta_time)
    ai:ai_logic_flee(delta_time)
end

function base:ai_logic_patrol(ai, delta_time)
    ai:ai_logic_patrol(delta_time)
end

function base:ai_logic_go_home(ai, delta_time)
    ai:ai_logic_go_home(delta_time)
end

function base:ai_logic_service(ai, delta_time)
    ai:ai_logic_service(delta_time)
end

function base:ai_logic_approach(ai, delta_time)
    ai:ai_logic_approach(delta_time)
end

function base:ai_logic_sit(ai, delta_time)
    ai:ai_logic_sit(delta_time)
end

function base:ai_logic_team_follow(ai, delta_time)
    ai:ai_logic_team_follow(delta_time)
end

function base:on_be_skill(ai, sender, skill_id, behaviortype)
    ai:event_on_be_skill(sender, skill_id, behaviortype)
end

function base:on_die(ai, killer)
    ai:event_on_die(killer)
end

return base