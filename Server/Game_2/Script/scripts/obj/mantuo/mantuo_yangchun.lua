local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_yangchun = class("mantuo_yangchun", script_base)
mantuo_yangchun.script_id = 015038
function mantuo_yangchun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_52}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_yangchun
