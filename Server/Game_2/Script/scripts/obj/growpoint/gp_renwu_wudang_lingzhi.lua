local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_wudang_lingzhi = class("gp_renwu_wudang_lingzhi", script_base)
gp_renwu_wudang_lingzhi.g_MainItemId = 40003021
gp_renwu_wudang_lingzhi.g_MissionId = 1075
function gp_renwu_wudang_lingzhi:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_wudang_lingzhi:OnOpen(selfId, targetId)
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

function gp_renwu_wudang_lingzhi:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_wudang_lingzhi:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_wudang_lingzhi:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_wudang_lingzhi
