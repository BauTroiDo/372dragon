local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local dead = class("dead", base)

function dead:get_estate()
    return define.ENUM_STATE.ESTATE_DEAD
end

function dead:can_stall()
    return define.OPERATE_RESULT.OR_BUSY
end

function dead:can_jump()
    return define.OPERATE_RESULT.OR_BUSY
end

function dead:can_use_skill()
    return define.OPERATE_RESULT.OR_BUSY
end

function dead:can_use_ability()
    return define.OPERATE_RESULT.OR_BUSY
end

function dead:can_use_item()
    return define.OPERATE_RESULT.OR_BUSY
end

function dead:state_logic(ai, delta_time)
    self:ai_logic_dead(ai, delta_time)
end

return dead