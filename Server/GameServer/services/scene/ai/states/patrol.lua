local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local patrol = class("patrol", base)

function patrol:get_estate()
    return define.ENUM_STATE.ESTATE_PATROL
end

function patrol:state_logic(ai, delta_time)
    self:ai_logic_patrol(ai, delta_time)
end

return patrol