local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangyuyan = class("mantuo_wangyuyan", script_base)
mantuo_wangyuyan.script_id = 015050
function mantuo_wangyuyan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_111}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_wangyuyan
