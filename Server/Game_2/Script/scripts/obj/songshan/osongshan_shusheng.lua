local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_shusheng = class("osongshan_shusheng", script_base)
function osongshan_shusheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Thiên Tiên muội muội~~")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osongshan_shusheng
