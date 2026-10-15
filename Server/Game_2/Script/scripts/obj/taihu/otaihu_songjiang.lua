local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otaihu_songjiang = class("otaihu_songjiang", script_base)
function otaihu_songjiang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Một Minh Giáo nhỏ bé đối với Hô Diên tướng quân mà nói, chỉ là chuyện nhỏ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otaihu_songjiang
