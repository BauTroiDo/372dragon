local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_ouyangxiu = class("osuzhou_ouyangxiu", script_base)
function osuzhou_ouyangxiu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0001}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_ouyangxiu
