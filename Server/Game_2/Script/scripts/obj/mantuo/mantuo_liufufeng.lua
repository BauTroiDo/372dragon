local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_liufufeng = class("mantuo_liufufeng", script_base)
mantuo_liufufeng.script_id = 015053
function mantuo_liufufeng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_86}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_liufufeng
