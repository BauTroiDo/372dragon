local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ozhenlong_qisheng = class("ozhenlong_qisheng", script_base)
ozhenlong_qisheng.script_id = 044000
ozhenlong_qisheng.g_name = "齐圣"
ozhenlong_qisheng.g_eventId_yes = 0
ozhenlong_qisheng.g_eventId_no = 1
function ozhenlong_qisheng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ozhenlong_qisheng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta có thể truyền tống ngài ra ngoài, có muốn truyền tống không?")
    self:AddNumText("Xác nhận", 9, self.g_eventId_yes)
    self:AddNumText("Hủy bỏ", 8, self.g_eventId_no)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ozhenlong_qisheng:OnEventRequest(selfId, targetId, arg, index)
    local selectEventId = index
    if selectEventId then
        if selectEventId == self.g_eventId_yes then
            self:CallScriptFunction(401001, "PlayerExit", selfId)
        else
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
    end
end

function ozhenlong_qisheng:OnMissionAccept(selfId, targetId, missionScriptId) end

function ozhenlong_qisheng:OnMissionRefuse(selfId, targetId, missionScriptId) end

return ozhenlong_qisheng
