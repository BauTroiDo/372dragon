local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxueyuan_yuanping = class("oxueyuan_yuanping", script_base)
function oxueyuan_yuanping:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ngươi đã thấy người khổng lồ bị phong trong khối băng bao giờ chưa? Thật muốn biết hắn tới từ đâu...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxueyuan_yuanping
