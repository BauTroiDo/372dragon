local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_xiaochai = class("odali_xiaochai", script_base)
odali_xiaochai.script_id = 002055
odali_xiaochai.g_shoptableindex = 3
function odali_xiaochai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Tiệm ta có vô số hàng hóa, kính mời quý khách chọn mua!")
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_xiaochai:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return odali_xiaochai
