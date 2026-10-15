local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local go_home = class("go_home", base)

function go_home:get_estate()
    return define.ENUM_STATE.ESTATE_GOHOME
end

function go_home:state_logic(ai, delta_time)
    self:ai_logic_go_home(ai, delta_time)
end

return go_home