local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangxinglang = class("mantuo_wangxinglang", script_base)
mantuo_wangxinglang.script_id = 015060
function mantuo_wangxinglang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_84}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_wangxinglang
