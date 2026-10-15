local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_gaibang_baishe = class("gp_renwu_gaibang_baishe", script_base)
gp_renwu_gaibang_baishe.g_MainItemId = 40003009
gp_renwu_gaibang_baishe.g_MissionId = 1065
function gp_renwu_gaibang_baishe:OnCreate(growPointType,x,y)
self:ItemBoxEnterScene(x,y,growPointType,define.QUALITY_MUST_BE_CHANGE,1,self.g_MainItemId)
end

function gp_renwu_gaibang_baishe:OnOpen(selfId,targetId)
local ret = self:CallScriptFunction(ScriptGlobal.SHIMEN_MISSION_SCRIPT_ID,"IsCaiJiMission",selfId,self.g_MissionId,self.g_MainItemId)
if ret > 0 then
return define.OPERATE_RESULT.OR_OK
else
return define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW
end
end

function gp_renwu_gaibang_baishe:OnRecycle(selfId,targetId)
return 1
end

function gp_renwu_gaibang_baishe:OnProcOver(selfId,targetId)
return 0
end

function gp_renwu_gaibang_baishe:OnTickCreateFinish(growPointType,tickCount)

end

return gp_renwu_gaibang_baishe