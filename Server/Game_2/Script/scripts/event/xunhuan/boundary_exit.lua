local class = require "class"
local define = require "define"
local script_base = require "script_base"
local boundary_exit = class("boundary_exit", script_base)
boundary_exit.script_id = 050103
boundary_exit.g_ControlScript = 050100
boundary_exit.g_Back_X = 60
boundary_exit.g_Back_Z = 161
function boundary_exit:OnEnterArea(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:CallScriptFunction((400900), "TransferFunc", selfId, oldsceneId,
                            self.g_Back_X, self.g_Back_Z)
end

function boundary_exit:OnTimer(selfId) return end

function boundary_exit:OnLeaveArea(selfId) return end

return boundary_exit
