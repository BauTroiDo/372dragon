local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_qinglongshi = class("gp_qinglongshi", script_base)
gp_qinglongshi.g_MainItemId = 30900051
function gp_qinglongshi:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    local rand = math.random(1, 100)
    if rand >= 70 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    end
end

function gp_qinglongshi:OnOpen(selfId, targetId)
    if self:CallScriptFunction(402047, "HaveTankBuff", selfId) ~= 0 then
        return define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW
    else
        return define.OPERATE_RESULT.OR_OK
    end
end

function gp_qinglongshi:OnRecycle(selfId, targetId)
    return 1
end

function gp_qinglongshi:OnProcOver(selfId, targetId)
    return 0
end

function gp_qinglongshi:OnTickCreateFinish(growPointType, tickCount)
end

return gp_qinglongshi
