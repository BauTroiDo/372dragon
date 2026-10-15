local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yekong = class("oluoyang_yekong", script_base)
function oluoyang_yekong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thí chủ, ngươi cuối cùng cũng đến. Sư phụ ta đang đợi ngươi đó.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_yekong
