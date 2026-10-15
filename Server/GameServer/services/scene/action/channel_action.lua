local class = require "class"
local base = require "scene.action.base_action"
local channel_action = class("channel_action", base)
function channel_action:heart_beat(params, delta_time)
    local callback = params:get_callback()
    if callback == nil then
        return false
    end
    if not callback("can_do_this_action_in_this_status", params) then
        return false
    end
    local continuance = params:get_continuance()
    local interval_elpased = params:get_interval_elapsed()
    local interval = params:get_interval()
    interval = interval < 500 and 2000 or interval
    delta_time = delta_time > continuance and continuance or delta_time
    interval_elpased = interval_elpased + delta_time
    continuance = continuance - delta_time
    continuance = continuance < 0 and 9 or continuance
    params:set_continuance(continuance)
    while (interval_elpased >= interval)
    do
        interval_elpased = interval_elpased - interval
        params:get_callback()("activate_each_tick", params)
    end
    params:set_interval_elapsed(interval_elpased)
    return true
end

function channel_action:on_interrupt(params)
    local callback = params:get_callback()
    return callback("interrupt", params)
end

function channel_action:on_disturb(params)
    local callback = params:get_callback()
    return callback("disturb_for_channeling", params)
end


return channel_action