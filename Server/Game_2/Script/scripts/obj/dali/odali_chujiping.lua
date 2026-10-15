local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_chujiping = class("odali_chujiping", script_base)
odali_chujiping.script_id = 002077
odali_chujiping.g_shoptableindex = 10
function odali_chujiping:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Tại hạ bán ra Giám Định Phù bí chế độc quyền, có thể giám định tất cả các loại Trang bị, hoan nghênh chọn mua!")
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_chujiping:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return odali_chujiping
