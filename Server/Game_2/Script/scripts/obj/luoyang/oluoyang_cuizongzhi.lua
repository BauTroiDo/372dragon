local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_cuizongzhi = class("oluoyang_cuizongzhi", script_base)
oluoyang_cuizongzhi.g_shoptableindex = 8
oluoyang_cuizongzhi.script_id = 000055
function oluoyang_cuizongzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Mọi người luôn nói dáng vẻ của ta sau khi say tựa như ngọc thụ lâm phong, không biết có phải thật không.")
    self:AddNumText("Mua thịt", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_cuizongzhi:OnEventRequest(selfId, targetId, arg, index)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_cuizongzhi
