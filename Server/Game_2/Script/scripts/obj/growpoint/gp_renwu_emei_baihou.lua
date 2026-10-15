local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_emei_baihou = class("gp_renwu_emei_baihou", script_base)
gp_renwu_emei_baihou.g_MainItemId = 40003033
gp_renwu_emei_baihou.g_MissionId = 1090
function gp_renwu_emei_baihou:OnCreate(growPointType, x, y)
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
end

function gp_renwu_emei_baihou:OnOpen(selfId, targetId)
    local ret =
        self:CallScriptFunction(ScriptGlobal.SHIMEN_MISSION_SCRIPT_ID, "IsCaiJiMission", selfId, self.g_MissionId, self.g_MainItemId)
    if ret > 0 then
        return define.OPERATE_RESULT.OR_OK
    else
        return define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW
    end
end

function gp_renwu_emei_baihou:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_emei_baihou:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_emei_baihou:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_emei_baihou
