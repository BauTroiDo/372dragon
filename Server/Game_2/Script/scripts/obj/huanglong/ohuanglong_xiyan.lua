local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohuanglong_xiyan = class("ohuanglong_xiyan", script_base)

function ohuanglong_xiyan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta sống ở Hoàng Long Trấn chỉ vài ngày, nhưng mấy ngày này ta lại cảm thấy vô so an nhàn ấm áp. so với cuộc sống địa ngục trước đây của ta, thật sự tốt hơn không biết bao nhiêu lần.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ohuanglong_xiyan
