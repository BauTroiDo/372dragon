local class = require "class"
local base = require "scene.action.base_action"
local charge_action = class("charge_action", base)

function charge_action:heart_beat(params, delta_time)
    local callback = params:get_callback()
    if callback == nil then
        return false
    end
    if not callback("can_do_this_action_in_this_status", params) then
        return false
    end
    local continuance = params:get_continuance()
    -- print("continuance =", continuance, ";delta_time =", delta_time)
    -- continuance = continuance - (delta_time * 1.1)
    continuance = continuance - delta_time
    if continuance < 0 then
        continuance = 0
    end
    params:set_continuance(continuance)
    if continuance == 0 then
        params:get_callback()("activate_once", params)
    end
    return true
end

function charge_action:on_interrupt(params)
    local callback = params:get_callback()
    return callback("interrupt", params)
end

function charge_action:on_disturb(params)
    local callback = params:get_callback()
    return callback("disturb_for_charging", params)
end



return charge_action