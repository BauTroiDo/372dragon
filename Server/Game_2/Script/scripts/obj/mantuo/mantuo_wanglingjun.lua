local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wanglingjun = class("mantuo_wanglingjun", script_base)
mantuo_wanglingjun.script_id = 015059
function mantuo_wanglingjun:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_67}")
    self:AddNumText("#{MPSD_220622_68}", 8, 1)
    self:AddNumText("#{MPSD_220622_69}", 8, 2)
    self:AddNumText("#{MPSD_220622_70}", 8, 3)
    self:AddNumText("#{MPSD_220622_71}", 8, 4)
    self:AddNumText("#{MPSD_220622_72}", 8, 5)
    self:AddNumText("#{MPSD_220622_73}", 8, 6)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wanglingjun:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function mantuo_wanglingjun:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_74}")
    elseif index == 2 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_75}")
    elseif index == 3 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_76}")
    elseif index == 4 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_77}")
    elseif index == 5 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_78}")
    elseif index == 6 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_79}")
    end
end

function mantuo_wanglingjun:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wanglingjun:Tips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return mantuo_wanglingjun
