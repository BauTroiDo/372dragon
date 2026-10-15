local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_tianlong_manyue = class("gp_renwu_tianlong_manyue", script_base)
gp_renwu_tianlong_manyue.g_MainItemId = 40003000
gp_renwu_tianlong_manyue.g_MissionId = 1080
function gp_renwu_tianlong_manyue:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_tianlong_manyue:OnOpen(selfId, targetId)
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

function gp_renwu_tianlong_manyue:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_tianlong_manyue:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_tianlong_manyue:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_tianlong_manyue
