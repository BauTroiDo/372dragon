local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_taoling = class("mantuo_taoling", script_base)
mantuo_taoling.script_id = 015054
function mantuo_taoling:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_87}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_taoling
