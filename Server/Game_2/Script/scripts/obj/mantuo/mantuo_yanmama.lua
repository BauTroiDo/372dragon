local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_yanmama = class("mantuo_yanmama", script_base)
mantuo_yanmama.script_id = 015057
function mantuo_yanmama:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_55}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_yanmama
