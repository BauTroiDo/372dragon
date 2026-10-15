local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangningyue = class("mantuo_wangningyue", script_base)
mantuo_wangningyue.script_id = 015049
function mantuo_wangningyue:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_117}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_wangningyue
