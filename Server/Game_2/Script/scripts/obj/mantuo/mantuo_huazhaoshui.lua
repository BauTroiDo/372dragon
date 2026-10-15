local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_huazhaoshui = class("mantuo_huazhaoshui", script_base)
mantuo_huazhaoshui.script_id = 015061
function mantuo_huazhaoshui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_85}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_huazhaoshui
