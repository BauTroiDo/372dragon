--元宝商店
--普通
local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local yuanbaoshop = class("yuanbaoshop", script_base)
-- CYS-NBSHOP: matches the CY YuanbaoShop.lua menu and CY item tables.
local shoplist = {}
shoplist[1] = {188, 189, 197} -- new / popular / bargain
shoplist[2] = {150, 307, 308, 178, 198, 193} -- gems 3 / 4 / 5 / 6 / essence / tools
shoplist[3] = {194, 135, 152, 195} -- pets / normal / advanced / medicine
shoplist[4] = {136, 137, 248, 144} -- medicine / crafting / rare / identify
shoplist[5] = {120, 247, 181, 145, 182, 134, 208, 345} -- costume / fashion / transform / hair / face / ride / advanced ride / manor
shoplist[6] = {190, 191, 254, 192, 133} -- traditional / personal / festival / scene fireworks / flowers
shoplist[7] = {146, 253, 277, 278} -- skill secrets / advanced secrets / offensive / defensive
shoplist[8] = {156, 159, 160, 161, 162, 163} -- weapon / cap+armour / glove+boot / cuff+shoulder / belt+neck / ring+amulet
shoplist[9] = {150, 178, 198, 193, 137, 194, 136} -- CY search shortcuts
shoplist[10] = {134, 208, 120, 247, 181, 145, 182} -- CY search shortcuts
shoplist[11] = {150, 178, 193, 137, 248} -- CY search shortcuts
shoplist[12] = {194, 135, 152, 195} -- CY search shortcuts
shoplist[13] = {134, 208, 248, 144} -- CY search shortcuts
shoplist[14] = {190, 191, 254, 192, 133} -- CY search shortcuts
shoplist[15] = {146, 253, 277, 278, 135, 152} -- CY search shortcuts
shoplist[101] = {209} -- new bind goods
shoplist[102] = {215} -- gem processing
shoplist[103] = {216} -- pet medicine
shoplist[104] = {217, 218, 219, 302, 323, 304} -- medicine / rare / armour engraving / weapon engraving / new engraving / processing
function yuanbaoshop:OpenYuanbaoShop(selfid, targetid, shopA, shopB)
    -- Unknown menu coordinates must not index a nil subtable or reopen an unrelated GL shop.
    local category = shoplist[tonumber(shopA)]
    local shop_id = category and category[tonumber(shopB)]
    if not shop_id then
        self:notify_tips(selfid, "Danh muc cua hang nay chua duoc ho tro.")
        return
    end
    if targetid == -1 then
        if self:GetLevel(selfid) < 15 then
            self:notify_tips(selfid,"Chức năng này chỉ dùng được khi cấp bạn >= 15.")
            return
        end
        self:DispatchYuanbaoShopItem(selfid, shop_id)
    else
        self:DispatchNpcYuanbaoShopItem(selfid, targetid, shop_id)
    end
end

-- CY YuanbaoShop_Show requests this metadata separately after opening the shelf.
-- Use the same live dispatcher as odali_shenmishangren:OnEventRequest(index=3).
function yuanbaoshop:OpenJiYuanShop(selfid, targetid)
    if targetid == -1 and self:GetLevel(selfid) < 15 then
        self:notify_tips(selfid, "Chức năng này chỉ dùng được khi cấp bạn >= 15.")
        return
    end
    self:DispatchJiYuanShopInfo(selfid, targetid)
end

function yuanbaoshop:yuanbao_pay(selfId, ItemIndex, check, uiindex, hint)
    if check == 1 then
        local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
        if index == nil then
            return
        end
        local item_name = self:GetItemName(merchadise.id)
        self:BeginUICommand()
        self:UICommand_AddInt(check)
        self:UICommand_AddInt(10)
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(merchadise.price)
        self:UICommand_AddInt(index - 1)
        self:UICommand_AddInt(0)
        self:UICommand_AddInt(-1)
        local str = self:ContactArgs(hint, 1, merchadise.price, 1, item_name) .. "}"
        self:UICommand_AddStr(str)
        self:EndUICommand()
        self:DispatchUICommand(selfId, uiindex)
    else
        local index, merchadise = self:BuyMerchadiseByItemIndex(selfId, ItemIndex)
        if index == nil then
            return
        end
        self:BeginUICommand()
        self:UICommand_AddInt(check)
        self:UICommand_AddInt(10)
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(merchadise.price)
        self:UICommand_AddInt(index - 1)
        self:UICommand_AddInt(0)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, uiindex)
    end
end

return yuanbaoshop