local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otaihu_dicheng = class("otaihu_dicheng", script_base)
function otaihu_dicheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Sao lại có nhiều quan binh đến vậy, ta không dám ra ngoài cướp bóc nữa rồi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otaihu_dicheng
