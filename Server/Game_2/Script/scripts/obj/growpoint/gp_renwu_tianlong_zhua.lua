local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_tianlong_zhua = class("gp_renwu_tianlong_zhua", script_base)
gp_renwu_tianlong_zhua.g_MainItemId = 40003003
function gp_renwu_tianlong_zhua:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_tianlong_zhua:OnOpen(selfId, targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_renwu_tianlong_zhua:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_tianlong_zhua:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_tianlong_zhua:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_tianlong_zhua
