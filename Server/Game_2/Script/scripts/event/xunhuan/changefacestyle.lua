local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local changefacestyle = class("changefacestyle", script_base)

function changefacestyle:UnlockAndChangeExteriorFaceId(selfId, ...)
    print("hangeheadstyle:UnlockAndChangeExteriorFaceId", ...)
    local styleId, check = ...
	if self:HaveThisFaceStyle(selfId, styleId) then
		self:ChangePlayerFaceModel(selfId, styleId)
		self:notify_tips(selfId, "Đã có khuôn mặt này, đã đổi cho bạn" )
		return
	end

	-- 得到调整头像所需物品的id及其数量
	local ItemId, ItemCount = self:GetChangeFaceItemIdAndItemCount(styleId)
	-- 返回值非法
	if ItemId < 0 or ItemCount < 0 then
		return
	end
	local nItemNum = self:LuaFnGetAvailableItemCount(selfId, ItemId )
	--消耗物品是否够用或锁定
	--if ItemCount > nItemNum then
	--	self:UnlockAndChangeExteriorFaceId_YuanbaoPay(selfId, ItemId, check)
	--	return
	--end

    --local ItemPos = self:LuaFnGetItemPosByItemDataID(selfId, ItemId, 0)
	--local szItemTransfer = self:GetBagItemTransfer(selfId, ItemPos)

	-- 物品检测通过，再检查玩家金钱
	local moneyJZ = self:GetMoneyJZ (selfId)
	local money = self:GetMoney (selfId)

	-- 物品和金钱检测都通过
	if (moneyJZ + money >= 50000)	then
		-- 设置玩家新脸型
        local ret = self:ChangePlayerFaceModel(selfId, styleId)
        if not ret then
            self:notify_tips(selfId, "Đã có khuôn mặt này" )
            return
        end
        --self:LuaFnDelAvailableItem(selfId,ItemId,1) --材料扣除
        self:LuaFnCostMoneyWithPriority(selfId, 50000) --扣钱
        self:notify_tips(selfId, "Đổi khuôn mặt thành công." )
	-- 金钱不足
	else
		self:notify_tips(selfId, "Kim tiền không đủ" )
		return
	end

	-- 发布公告
	-- 发送广播
	local message
	local randMessage = math.random(3)
	local nsex = self:GetSex(selfId)
	local str1,str2
	if nsex == 0  then
		str1 = "nàng"
		str2 = "Mỹ"
	else
		str1 = "hắn"
		str2 = "Soái"
	end
    local name = self:GetName(selfId)
	if randMessage == 1 then
        local fmt = "#HNgười cần mặt tử, cây cần vỏ,#W#{_INFOUSR%s}#Hthấu hiểu đạo lý này, hôm nay dùng#W#{_INFOMSG%s}#Hmà chỉnh dung này còn kinh khủng hơn, đơn giản là khiến Phan An tức chết, khiến Điêu Thèm hờn ghen!"
		--message = string.format(gbk.fromutf8(fmt), gbk.fromutf8(name), szItemTransfer)
	elseif randMessage == 2 then
        local fmt = gbk.fromutf8("#HGương Ma nói trên thế gian này" .. str2 .. "của người đã ra đời! Đó chính là #W#{_INFOUSR%s}#H vừa khiến nhạn trên trời rơi xuống, mau đi xem" .. str1 .. "nhé, cái#W#{_INFOMSG%s}#Hnày dùng xong quả nhiên hiệu quả nổi bật!")
		--message = string.format(fmt,  gbk.fromutf8(name), szItemTransfer)
	else
        local fmt = gbk.fromutf8("#HỦa? Sao cá dưới suối lật hết bụng? Lẽ nào trúng độc chết? Không phải, hóa ra#W#{_INFOUSR%s}#Hvừa đi ngang, đàn cá thẹn quá ngất đi. Trời ạ!" .. str1 .. "Dùng#W#{_INFOMSG%s}#Hxong lại có dung nhan tuyệt thế thế này!")
		--message = string.format(fmt, gbk.fromutf8(name), szItemTransfer)
	end
	--self:BroadMsgByChatPipe(selfId, message, 4)
end

function changefacestyle:UnlockAndChangeExteriorFaceId_YuanbaoPay(selfId, ItemIndex, check)
	local hint = "#{XFYH_20120221_29"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		self:notify_tips(selfId, "Bạn không có Định Nhan Châu này, hoặc nó đang khóa." )
		return
	end
	self:BeginUICommand()
	self:UICommand_AddInt(3)
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

return changefacestyle