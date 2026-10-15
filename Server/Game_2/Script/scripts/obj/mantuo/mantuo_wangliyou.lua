local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangliyou = class("mantuo_wangliyou", script_base)
mantuo_wangliyou.script_id = 015058
function mantuo_wangliyou:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_58}")
    self:AddNumText("#{MPSD_220622_59}", 8, 1)
    self:AddNumText("#{MPSD_220622_60}", 8, 2)
    self:AddNumText("#{MPSD_220622_61}", 8, 3)
    self:AddNumText("#{MPSD_220622_62}", 8, 4)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wangliyou:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function mantuo_wangliyou:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_63}")
    elseif index == 2 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_64}")
    elseif index == 3 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_65}")
    elseif index == 4 then
        self:MsgBox(selfId, targetId, "#{MPSD_220622_66}")
    end
end

function mantuo_wangliyou:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wangliyou:Tips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return mantuo_wangliyou
