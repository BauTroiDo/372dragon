local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local changeheadstyle = class("changeheadstyle", script_base)

function changeheadstyle:UnlockAndChangeExteriorHeadId(selfId, ...)
    print("hangeheadstyle:UnlockAndChangeExteriorHeadId", ...)
    local styleId, check = ...
    -- 头像未选中或选中无效
	if styleId <= 0 then
		self:notify_tips (selfId, "#{INTERHEAD_XML_004}" )
		return
	end
	if self:HaveThisHeadImage(selfId, styleId) then
		self:ChangePlayerHeadImage(selfId, styleId)
		self:notify_tips(selfId, "Đã có ảnh đại diện này, đã đổi cho bạn" )
		return
	end
	-- 得到调整头像所需物品的id及其数量
    local ItemCount = 1
	local ItemId = 30008039
	-- 返回值非法
	if ItemId < 0 or ItemCount < 0 then
		return
	end
	local nItemNum = self:LuaFnGetAvailableItemCount(selfId, ItemId )
	--消耗物品是否够用或锁定
	if ItemCount > nItemNum then
		self:UnlockAndChangeExteriorHeadId_YuanbaoPay(selfId, ItemId, check)
		return
	end
	-- 物品检测通过，再检查玩家金钱
	local moneyJZ = self:GetMoneyJZ (selfId);
	local money = self:GetMoney (selfId);
	-- 物品和金钱检测都通过
	if (moneyJZ + money >= 50000)	then
		-- 设置玩家新头像（会在这个过程中消耗物品和金钱）
        local ret = self:ChangePlayerHeadImage(selfId, styleId)
        if not ret then
            self:notify_tips(selfId, "Đã có ảnh đại diện này" )
            return
        end
        self:LuaFnDelAvailableItem(selfId,ItemId,1) --材料扣除
        self:LuaFnCostMoneyWithPriority(selfId, 50000) --扣钱
        self:notify_tips(selfId, "#{INTERHEAD_XML_010}" )
	-- 金钱不足
	else
		self:notify_tips(selfId, "#{INTERHEAD_XML_006}" )
		return
	end

	-- 发布公告
	local message
	local name = self:GetName(selfId)
	name = gbk.fromutf8(name)
	if math.random(2) == 1 then
		message = string.format("#W#{_INFOUSR%s}#{INTERHEAD_XML_007}", name);
	else
		message = string.format("#W#{INTERHEAD_XML_011}#{_INFOUSR%s}#{INTERHEAD_XML_012}", name);
	end
	self:BroadMsgByChatPipe(selfId, message, 4);
end

function changeheadstyle:UnlockAndChangeExteriorHeadId_YuanbaoPay(selfId, ItemIndex, check)
	local hint = "#{XFYH_20120221_27"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
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

return changeheadstyle