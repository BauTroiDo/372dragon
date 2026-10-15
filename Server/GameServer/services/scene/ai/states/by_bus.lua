local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local by_bus = class("by_bus", base)

function by_bus:get_estate()
    return define.ENUM_STATE.ESTATE_BY_BUS
end

function by_bus:can_stall()
    return false
end

function by_bus:can_stop()
    return false
end

function by_bus:can_jump()
    return define.OPERATE_RESULT.OR_OK
end

function by_bus:can_move()
    return define.OPERATE_RESULT.OR_BUSY
end

function by_bus:can_use_skill()
    return define.OPERATE_RESULT.OR_BUSY
end

function by_bus:can_use_ability()
    return define.OPERATE_RESULT.OR_BUSY
end

function by_bus:can_use_item()
    return define.OPERATE_RESULT.OR_BUSY
end

function by_bus:state_logic()
end


return by_bus