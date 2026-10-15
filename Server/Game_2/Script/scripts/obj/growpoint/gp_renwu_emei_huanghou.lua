local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_emei_huanghou = class("gp_renwu_emei_huanghou", script_base)
gp_renwu_emei_huanghou.g_MainItemId = 40003031
gp_renwu_emei_huanghou.g_MissionId = 1090
function gp_renwu_emei_huanghou:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_emei_huanghou:OnOpen(selfId, targetId)
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

function gp_renwu_emei_huanghou:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_emei_huanghou:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_emei_huanghou:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_emei_huanghou
