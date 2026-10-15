local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_emei_heihou = class("gp_renwu_emei_heihou", script_base)
gp_renwu_emei_heihou.g_MainItemId = 40003032
gp_renwu_emei_heihou.g_MissionId = 1090
function gp_renwu_emei_heihou:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_emei_heihou:OnOpen(selfId, targetId)
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

function gp_renwu_emei_heihou:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_emei_heihou:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_emei_heihou:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_emei_heihou
