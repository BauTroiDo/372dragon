local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_renfeiyan = class("otianlong_renfeiyan", script_base)
function otianlong_renfeiyan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta cùng các lão hoàng gia đến Thiên Long Tự đã hai năm rồi, nhưng ta vẫn luôn nhớ rõ người thanh niên đã gặp ở Lạc Dương thành hai năm trước.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_renfeiyan
