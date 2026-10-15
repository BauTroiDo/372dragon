local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local combat = class("combat", base)

function combat:get_estate()
    return define.ENUM_STATE.ESTATE_COMBAT
end

function combat:state_logic(ai, delta_time)
    self:ai_logic_combat(ai, delta_time)
end

return combat