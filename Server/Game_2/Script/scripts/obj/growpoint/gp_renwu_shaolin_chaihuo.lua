local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_shaolin_chaihuo = class("gp_renwu_shaolin_chaihuo", script_base)
gp_renwu_shaolin_chaihuo.g_MainItemId = 40002125
gp_renwu_shaolin_chaihuo.g_MissionId = 1060
function gp_renwu_shaolin_chaihuo:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_shaolin_chaihuo:OnOpen(selfId, targetId)
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

function gp_renwu_shaolin_chaihuo:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_shaolin_chaihuo:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_shaolin_chaihuo:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_shaolin_chaihuo
