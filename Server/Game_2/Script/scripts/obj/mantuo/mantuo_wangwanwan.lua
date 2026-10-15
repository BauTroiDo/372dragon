local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangwanwan = class("mantuo_wangwanwan", script_base)
mantuo_wangwanwan.script_id = 015048
function mantuo_wangwanwan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_118}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_wangwanwan
