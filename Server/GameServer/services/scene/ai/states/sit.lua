local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local sit = class("sit", base)

function sit:get_estate()
    return define.ENUM_STATE.ESTATE_SIT
end

function sit:can_jump()
    return define.OPERATE_RESULT.OR_BUSY
end

function sit:can_move()
    return define.OPERATE_RESULT.OR_BUSY
end

function sit:can_use_skill()
    return define.OPERATE_RESULT.OR_BUSY
end

function sit:can_use_ability()
    return define.OPERATE_RESULT.OR_BUSY
end

function sit:state_logic(ai, delta_time)
    self:ai_logic_sit(ai, delta_time)
end


return sit