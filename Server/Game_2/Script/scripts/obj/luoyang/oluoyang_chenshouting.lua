local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_chenshouting = class("oluoyang_chenshouting", script_base)
function oluoyang_chenshouting:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hiện tại Thương hội đang thiếu hàng, ngươi hãy đợi vài ngày rồi quay lại nhé.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_chenshouting
