local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangyijian = class("mantuo_wangyijian", script_base)
mantuo_wangyijian.script_id = 015047
function mantuo_wangyijian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_91}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_wangyijian
