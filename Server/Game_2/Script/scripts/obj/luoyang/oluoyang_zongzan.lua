local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zongzan = class("oluoyang_zongzan", script_base)
function oluoyang_zongzan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Đại Tống đã giành được chức vô địch trong Đại Tái Cúc Cầu lần trước, lần này đến lượt Thổ Phồn ta đoạt quán quân.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zongzan
