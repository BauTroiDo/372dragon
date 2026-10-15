local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_fengboe = class("osuzhou_fengboe", script_base)
function osuzhou_fengboe:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Muốn đánh nhau không? Ở đằng kia có lôi đài, chúng ta đến so thử một chút, sao? Không dám à?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_fengboe
