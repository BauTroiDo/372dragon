local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_sushi = class("osuzhou_sushi", script_base)
function osuzhou_sushi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0002}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_sushi
