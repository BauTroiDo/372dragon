local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local terror = class("terror", base)

function terror:get_estate()
    return define.ENUM_STATE.ESTATE_TERROR
end

function terror:can_jump()
    return define.OPERATE_RESULT.OR_OK
end

function terror:can_move()
    return define.OPERATE_RESULT.OR_BUSY
end

function terror:can_use_skill(ai, skill_id)
    if skill_id == 299 or skill_id == 509 then
        return define.OPERATE_RESULT.OR_OK
    end
    return define.OPERATE_RESULT.OR_BUSY
end

function terror:can_use_ability()
    return define.OPERATE_RESULT.OR_BUSY
end

function terror:can_use_item()
    return define.OPERATE_RESULT.OR_BUSY
end

function terror:state_logic(ai, delta_time)
    self:ai_logic_terror(ai, delta_time)
end


return terror