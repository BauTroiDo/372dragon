local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oseektreasure_jinjiumiao = class("oseektreasure_jinjiumiao", script_base)
oseektreasure_jinjiumiao.script_id = 044700
oseektreasure_jinjiumiao.g_name = "金久妙"
oseektreasure_jinjiumiao.g_eventId_yes = 1
oseektreasure_jinjiumiao.g_eventId_no = 0
function oseektreasure_jinjiumiao:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oseektreasure_jinjiumiao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLXB_8815_07}")
    self:AddText("Thật sự muốn ra ngoài sao?")
    self:AddNumText("Xác nhận", 9, self.g_eventId_yes)
    self:AddNumText("Hủy bỏ", 8, self.g_eventId_no)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oseektreasure_jinjiumiao:OnEventRequest(selfId, targetId, arg, index)
    if index == self.g_eventId_yes then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 186, 162, 77)
    elseif index == self.g_eventId_no then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

return oseektreasure_jinjiumiao
