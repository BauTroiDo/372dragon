local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_hanyongan = class("odali_hanyongan", script_base)
odali_hanyongan.g_shoptableindex_1 = 8
function odali_hanyongan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tiệm cầm đồ của ta là tiệm cầm đồ lớn nhất Đại Lý thành.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_hanyongan:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex_1)
    end
end

return odali_hanyongan
