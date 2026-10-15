local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhudanchen = class("osuzhou_zhudanchen", script_base)
function osuzhou_zhudanchen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0007}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zhudanchen
