local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zenggong = class("osuzhou_zenggong", script_base)
function osuzhou_zenggong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0003}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zenggong
