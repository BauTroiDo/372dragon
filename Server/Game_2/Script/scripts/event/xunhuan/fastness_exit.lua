local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fastness_exit = class("fastness_exit", script_base)
fastness_exit.script_id = 050105
fastness_exit.g_ControlScript = 050100
fastness_exit.g_Back_X = 60
fastness_exit.g_Back_Z = 161
function fastness_exit:OnEnterArea(selfId)
local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
self:CallScriptFunction((400900),"TransferFunc",selfId,oldsceneId,self.g_Back_X,self.g_Back_Z)
end

function fastness_exit:OnTimer(selfId)
return
end

function fastness_exit:OnLeaveArea(selfId)
return
end

return fastness_exit