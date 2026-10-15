local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_zijin = class("mantuo_zijin", script_base)
mantuo_zijin.script_id = 015044
function mantuo_zijin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_19}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_zijin
