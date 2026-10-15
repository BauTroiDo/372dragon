-- costumes-all 17/09/2026: NPC "Tiem Thoi Trang" (script 990011) — sinh boi Tools/server/costume_data.py.
-- Moi muc menu (type 7) mo mot shop 431.. chua thoi trang CY, ban bang nguyen bao (ShopTable cot 7 = 5).
-- Khong sua tay: chay lai `costume_data.py plan && apply` se ghi de file nay.
local class = require "class"
local script_base = require "script_base"
local costume_shop = class("costume_shop", script_base)
costume_shop.script_id = 990011
costume_shop.SHOPS = {
    { id = 431, count = 83, text = "Tập 1/7: Phật Y Như Lai" },
    { id = 432, count = 83, text = "Tập 2/7: Tiên Lữ Tình Duyên" },
    { id = 433, count = 83, text = "Tập 3/7: Lí Hí Lan Phương" },
    { id = 434, count = 83, text = "Tập 4/7: Cẩm Tú Du Tiên" },
    { id = 435, count = 83, text = "Tập 5/7: Hàn Cung Tiêu Mộng" },
    { id = 436, count = 83, text = "Tập 6/7: Phượng Trì Ngâm" },
    { id = 437, count = 80, text = "Tập 7/7: Thủy Long Ngâm" },
}

function costume_shop:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Tiệm Thời Trang Vân Y: 578 bộ thời trang, bán bằng Nguyên Bảo. Mời chọn tập.")
    for i, s in ipairs(self.SHOPS) do
        self:AddNumText(s.text, 7, i)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function costume_shop:OnEventRequest(selfId, targetId, arg, index)
    local s = self.SHOPS[index]
    if s then
        self:DispatchShopItem(selfId, targetId, s.id)
    else
        self:OnDefaultEvent(selfId, targetId)
    end
end

return costume_shop
