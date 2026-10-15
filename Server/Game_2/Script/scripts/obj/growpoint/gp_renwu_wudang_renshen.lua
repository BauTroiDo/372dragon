local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_wudang_renshen = class("gp_renwu_wudang_renshen", script_base)
gp_renwu_wudang_renshen.g_MainItemId = 40003023
gp_renwu_wudang_renshen.g_MissionId = 1075
function gp_renwu_wudang_renshen:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_wudang_renshen:OnOpen(selfId, targetId)
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

function gp_renwu_wudang_renshen:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_wudang_renshen:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_wudang_renshen:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_wudang_renshen
