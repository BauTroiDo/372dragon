local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otaihu_kouxun = class("otaihu_kouxun", script_base)
function otaihu_kouxun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hành quân đánh giặc tuy rằng chiến thuật chiến lược các phương diện đều rất quan trọng, nhưng ta cho rằng, lòng người càng quan trọng hơn, được lòng người ắt được thiên hạ!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otaihu_kouxun
