local class = require "class"
local define = require "define"
local script_base = require "script_base"
local forest_exit = class("forest_exit", script_base)
forest_exit.script_id = 050104
forest_exit.g_ControlScript = 050101
forest_exit.g_Back_X = 250
forest_exit.g_Back_Z = 107
function forest_exit:OnEnterArea(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:CallScriptFunction((400900), "TransferFunc", selfId, oldsceneId,
                            self.g_Back_X, self.g_Back_Z)
end

function forest_exit:OnTimer(selfId) return end

function forest_exit:OnLeaveArea(selfId) return end

return forest_exit
