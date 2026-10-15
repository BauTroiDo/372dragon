local base = require "scene.ai.states.base"
local class = require "class"
local define = require "define"
local team_follow = class("team_follow", base)

function team_follow:get_estate()
    return define.ENUM_STATE.ESTATE_TEAMFOLLOW
end

function team_follow:can_stall()
    return false
end

function team_follow:can_stop()
    return false
end

function team_follow:can_jump()
    return define.OPERATE_RESULT.OR_OK
end

function team_follow:can_move()
    return define.OPERATE_RESULT.OR_BUSY
end

function team_follow:can_use_skill()
    return define.OPERATE_RESULT.OR_BUSY
end

function team_follow:can_use_ability()
    return define.OPERATE_RESULT.OR_BUSY
end

function team_follow:can_use_item()
    return define.OPERATE_RESULT.OR_BUSY
end

function team_follow:state_logic(ai, delta_time)
    self:ai_logic_team_follow(ai, delta_time)
end


return team_follow