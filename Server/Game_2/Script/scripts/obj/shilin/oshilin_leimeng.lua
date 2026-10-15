local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_leimeng = class("oshilin_leimeng", script_base)
function oshilin_leimeng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Lôi Mông~~")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshilin_leimeng
