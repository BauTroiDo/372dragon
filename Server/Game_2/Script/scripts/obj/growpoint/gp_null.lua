local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_null = class("gp_null", script_base)
function gp_null:OnRecycle(selfId, targetId)
    return 1
end

function gp_null:OnCreate(growPointType, x, y)
end

function gp_null:OnOpen(selfId, targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_null:OnProcOver(selfId, targetId)
end

return gp_null
