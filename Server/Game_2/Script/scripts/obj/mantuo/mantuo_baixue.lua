local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_baixue = class("mantuo_baixue", script_base)
mantuo_baixue.script_id = 015039
function mantuo_baixue:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_53}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_baixue
