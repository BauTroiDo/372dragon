local class = require "class"
local gbk = require "wire_charset"
local script_base = require "script_base"
local changehairstyle = class("changehairstyle", script_base)

function changehairstyle:UnlockAndChangeExteriorHairId(selfId, ...)
    print("hangeheadstyle:UnlockAndChangeExteriorHairId", ...)
    local styleId, check = ...
	if self:HaveThisHairStyle(selfId, styleId) then
		self:ChangePlayerHairModel(selfId, styleId)
		self:notify_tips(selfId, "Đã có kiểu tóc này, đã đổi cho bạn" )
		return
	end
	-- 得到调整头像所需物品的id及其数量
	local ItemId, ItemCount = self:GetChangeHairItemIdAndItemCount(styleId)
	-- 返回值非法
	if ItemId < 0 or ItemCount < 0 then
		return
	end
	--local nItemNum = self:LuaFnGetAvailableItemCount(selfId, ItemId )
	--消耗物品是否够用或锁定
	--if ItemCount > nItemNum then
	--	self:UnlockAndChangeExteriorHairId_YuanbaoPay(selfId, ItemId, check)
	--	return
	--end

	-- 物品检测通过，再检查玩家金钱
	local moneyJZ = self:GetMoneyJZ (selfId)
	local money = self:GetMoney (selfId)

	-- 物品和金钱检测都通过
	if (moneyJZ + money >= 50000)	then
		-- 设置玩家新发型
        local ret = self:ChangePlayerHairModel(selfId, styleId)
        if not ret then
            self:notify_tips(selfId, "Đã có kiểu tóc này" )
            return
        end
        --self:LuaFnDelAvailableItem(selfId,ItemId,1) --材料扣除
        self:LuaFnCostMoneyWithPriority(selfId, 50000) --扣钱
        self:notify_tips(selfId, "Đổi kiểu tóc thành công." )
	-- 金钱不足
	else
		self:notify_tips(selfId, "Trên người ngươi mang theo không đủ tiền." )
		return
	end

	-- 发布公告
	-- 发送广播
	local message
	local randMessage = math.random(3)
    local name = self:GetName(selfId)
	name = gbk.fromutf8(name)
	if randMessage == 1 then
		message = string.format("#{FaXing_00}#{_INFOUSR%s}#{FaXing_01}", name);
	elseif randMessage == 2 then
		message = string.format("#{FaXing_02}#{_INFOUSR%s}#{FaXing_03}", name);
	else
		message = string.format("#{FaXing_04}#{_INFOUSR%s}#{FaXing_05}", name);
	end
	self:BroadMsgByChatPipe(selfId, message, 4)
end

function changehairstyle:UnlockAndChangeExteriorHairId_YuanbaoPay(selfId, ItemIndex, check)

	local hint = "#{XFYH_20120221_04"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		self:notify_tips(selfId, "Bạn không có bản vẽ kiểu tóc này, hoặc nó đang khóa." )
		return
	end
	self:BeginUICommand()
	self:UICommand_AddInt(4)
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(merchadise.price)
	self:UICommand_AddInt(index - 1)
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(self.script_id)
	self:UICommand_AddInt(check)
	self:UICommand_AddInt(-1)
	self:UICommand_AddInt(1)
	local str = self:ContactArgs(hint, merchadise.id, merchadise.price, "#{XFYH_20120221_10}", "#{XFYH_20120221_12}", merchadise.pnum or 1) .. "}"
	self:UICommand_AddStr(str)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 20120222)
end

return changehairstyle