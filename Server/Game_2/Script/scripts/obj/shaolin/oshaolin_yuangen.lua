local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_yuangen = class("oshaolin_yuangen", script_base)
function oshaolin_yuangen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Duyên Căn")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshaolin_yuangen
