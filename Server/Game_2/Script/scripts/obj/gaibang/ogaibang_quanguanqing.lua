local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_quanguanqing = class("ogaibang_quanguanqing", script_base)
function ogaibang_quanguanqing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Đại thù của Mã phó bang chủ nhất định phải báo, ai phản đối kẻ đó chính là đồng bọn giết hại Mã phó bang chủ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogaibang_quanguanqing
