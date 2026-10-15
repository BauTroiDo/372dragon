local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local idle = class("idle", base)

function idle:get_estate()
    return define.ENUM_STATE.ESTATE_IDLE
end

function idle:state_logic(ai, delta_time)
    self:ai_logic_idle(ai, delta_time)
end

return idle