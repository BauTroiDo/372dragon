local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local stall = class("stall", base)

function stall:get_estate()
    return define.ENUM_STATE.ESTATE_STALL
end

function stall:can_jump()
    return define.OPERATE_RESULT.OR_BUSY
end

function stall:can_move()
    return define.OPERATE_RESULT.OR_BUSY
end

function stall:can_use_skill()
    return define.OPERATE_RESULT.OR_BUSY
end

function stall:can_use_ability()
    return define.OPERATE_RESULT.OR_BUSY
end

function stall:can_use_item()
    return define.OPERATE_RESULT.OR_BUSY
end

function stall:state_logic(ai, delta_time)
    --self:ai_logic_stall(ai, delta_time)
end


return stall