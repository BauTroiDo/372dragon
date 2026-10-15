local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_susu = class("mantuo_susu", script_base)
mantuo_susu.script_id = 015045
function mantuo_susu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_88}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_susu
