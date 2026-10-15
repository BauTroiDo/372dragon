--机缘商店
--普通
local class = require "class"
local script_base = require "script_base"
local jiyuanshop = class("jiyuanshop", script_base)
local shop_items =
{
    [38002675] = {4000,20},
    [38003160] = {5000,5},
    [38003161] = {10000,5},
	[38003163] = {15000,10},
	[38003565] = {300000,1},
	[38003583] = {300000,1},
	[38003584] = {300000,1},
	[38003567] = {300000,1},
}
function jiyuanshop:buyitem(selfId, ...)
    print("jiyuanshop:buyitem ... =", ...)
    local targetId, shop_item = ...
	local buyitem = shop_items[shop_item]
	if not buyitem then
		return
	elseif self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:notify_tips(selfId, "#{YXJJ_091118_09}")
        return
	end
    local price = buyitem[1]
    local nCount = buyitem[2]
    local yuanbao = self:GetYuanBao(selfId)
    if yuanbao < price then
        self:notify_tips(selfId, "#{YBBT_81021_07}")
        return
    end
    local buy_count = self:LuaFnGetJiYuanShopCountByID(selfId, shop_item)
    if buy_count >= nCount then
        self:notify_tips(selfId, "#{SDHDRW_220808_06}")
        return
    end
	if self:OnJiYuanShopBuy(selfId, shop_item, targetId) then
		self:LuaFnCostYuanBao(selfId, price)
		self:TryRecieveItem(selfId, shop_item)
		self:BuyItemTip(selfId,shop_item,1,18)
		self:OnJiYuanShopBuy(selfId, shop_item, targetId)
	end
end
return jiyuanshop