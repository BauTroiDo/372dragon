local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxueyuan_doudou = class("oxueyuan_doudou", script_base)

function oxueyuan_doudou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ngươi đến tìm ta sao? Bố Lạt và Viên Bình nói ta không phải là chim cánh cụt...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxueyuan_doudou
