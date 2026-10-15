local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_wudang_shouwu = class("gp_renwu_wudang_shouwu", script_base)
gp_renwu_wudang_shouwu.g_MainItemId = 40003022
gp_renwu_wudang_shouwu.g_MissionId = 1075
function gp_renwu_wudang_shouwu:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_wudang_shouwu:OnOpen(selfId, targetId)
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

function gp_renwu_wudang_shouwu:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_wudang_shouwu:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_wudang_shouwu:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_wudang_shouwu
