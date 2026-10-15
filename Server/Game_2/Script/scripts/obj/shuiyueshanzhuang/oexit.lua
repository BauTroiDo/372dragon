local class = require "class"
local script_base = require "script_base"

local oexit = class("oexit", script_base)
oexit.script_id = 892340
oexit.g_FuBenScriptId = 892328

function oexit:OnDefaultEvent(selfId, targetId)
    if self:LuaFnGetSceneType() ~= 1 or self:LuaFnGetCopySceneData_Param(11) ~= 1 then
        return
    end

    self:BeginEvent(self.script_id)
    self:AddText("Thủy Nguyệt Sơn Trang đã bình định, thiếu hiệp rời phụ bản từ đây được.")
    self:AddNumText("#GRời Thủy Nguyệt Sơn Trang", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oexit:OnEventRequest(selfId, targetId, arg, index)
    if index ~= 1 or self:LuaFnGetCopySceneData_Param(11) ~= 1 then
        return
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "Exit", selfId)
end

return oexit
