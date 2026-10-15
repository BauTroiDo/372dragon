local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local approach = class("approach", base)

function approach:get_estate()
    return define.ENUM_STATE.ESTATE_APPROACH
end

function approach:state_logic(ai, delta_time)
    self:ai_logic_approach(ai, delta_time)
end

return approach