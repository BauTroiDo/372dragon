local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_weihanjin = class("osuzhou_weihanjin", script_base)
function osuzhou_weihanjin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tô học sĩ, tiếng đàn không ở trên đàn, không ở trên ngón tay, mà ở trong tâm.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_weihanjin
