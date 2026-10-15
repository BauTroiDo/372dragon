local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_tianlong_yan = class("gp_renwu_tianlong_yan", script_base)
gp_renwu_tianlong_yan.g_MainItemId = 40003001
gp_renwu_tianlong_yan.g_MissionId = 1080
function gp_renwu_tianlong_yan:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_tianlong_yan:OnOpen(selfId, targetId)
    local ret =
        self:CallScriptFunction(
        ScriptGlobal.SHIMEN_MISSION_SCRIPT_ID,
        "IsCaiJiMission",
        selfId,
        self.g_MissionId,
        self.g_MainItemId
    )
    if ret > 0 then
        return define.OPERATE_RESULT.OR_OK
    else
        return define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW
    end
end

function gp_renwu_tianlong_yan:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_tianlong_yan:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_tianlong_yan:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_tianlong_yan
