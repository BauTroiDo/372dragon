--装备刻铭
--脚本号
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local equip_bind = class("equip_bind", script_base)

function equip_bind:FinishBind(selfId, itemIndex1, itemIndex2 )
	local text = ""
	local ret = self:LuaFnIsItemLocked(selfId, itemIndex1 )
	if ret then
        self:notify_tips(selfId, "Trang bị này không dùng được.")
		return
	end

	-- 褚少微，2008.6.11。重楼戒10422016，重楼玉10423024无法铭刻。
	local itemTableIndex = self:LuaFnGetItemTableIndexByIndex(selfId, itemIndex1 )
	if itemTableIndex == 10422016 or itemTableIndex == 10423024 then
        self:notify_tips(selfId, "Trang bị này không thể khắc minh.")
		return
	end
	ret = self:LuaFnIsItemAvailable(selfId, itemIndex2 )
	if not ret then
        self:notify_tips(selfId, "Khóa Định Phù không dùng được.")
		return
	end
	local equip_level = self:GetBagItemLevel(selfId, itemIndex1 )
	local gem_index = self:LuaFnGetItemTableIndexByIndex(selfId, itemIndex2 )
	if equip_level < 50 then
		if gem_index ~= 30900013 then
			--低级锁定符
            self:notify_tips(selfId, "Trang bị khắc minh Yêu cầu Khắc Minh Phù Sơ Cấp.")
			return
		end
	else
		if gem_index ~= 30900014 then
			--高级锁定符
            self:notify_tips(selfId, "Trang bị khắc minh Yêu cầu Khắc Minh Phù Cao Cấp.")
			return
		end
	end
	local EquipPoint = self:LuaFnGetBagEquipType(selfId, itemIndex1 )
	local need_money
	local HumanMoney = self:GetMoney(selfId ) + self:GetMoneyJZ(selfId);
	if EquipPoint == define.HUMAN_EQUIP.HEQUIP_WEAPON or EquipPoint == define.HUMAN_EQUIP.HEQUIP_ARMOR then
		need_money = 500 + equip_level * 200
	else
		need_money = 250 + equip_level * 100
	end
	if HumanMoney < need_money then
		text="Khắc minh Trang bị này Yêu cầu #{_EXCHG%d}, tiền bạc trên người ngài không đủ."
		text=string.format( text, need_money )
        self:notify_tips(selfId, text)
		return
	end
	--检查是否能够锁定
	ret = self:LuaFnLockCheck(selfId, itemIndex1, need_money )
	if ret == 0 then --成功了
		text="Trang bị khắc minh thành công."
		self:LuaFnEquipLock(selfId, itemIndex1 )
		self:LuaFnEraseItem(selfId, itemIndex2 )
		self:LuaFnCostMoneyWithPriority(selfId, need_money )
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
		local szTranItm	= self:GetBagItemTransfer( selfId, itemIndex1 )
		if szTranItm ~= nil then
			local szMsg		= string.format( "#W#{_INFOUSR%s}#{AQ_9}#W#{_INFOMSG%s}#{AQ_10}",
									self:LuaFnGetName(selfId ), szTranItm )
			--公告精简，需求等级30以下的装备，不发铭刻公告
			--if (equip_level >= 30) then
				--AddGlobalCountNews(szMsg )
			--end
		end
	end

	if ret == -1 then
		text="Lỗi không xác định."
	end
	if ret == -2 then
		text="Trang bị không thể dùng."
	end
	if ret == -3 then
		text="Trang bị đã được khắc minh."
	end
    self:notify_tips(selfId, text)
end

function equip_bind:FinishUnBind(selfId, itemIndex1, itemIndex2 )
	local text = ""
	local ret = self:LuaFnIsItemEquipLock(selfId, itemIndex1 )
	if not ret  then
        self:notify_tips(selfId, "Trang bị của ngài chưa khắc minh, không Yêu cầu tiến hành trừ minh.")
		return
	end
	ret = self:LuaFnIsItemAvailable(selfId, itemIndex2 )
	if not ret then
        self:notify_tips(selfId, "Trừ Minh Phù không thể dùng.")
		return
	end

	local need_money = 10000
	local HumanMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId);
	if HumanMoney < need_money then
		text="Trừ minh trang bị này Yêu cầu #{_EXCHG%d}, tiền trên người ngài không đủ."
		text=string.format( text, need_money )
        self:notify_tips(selfId, text)
		return
	end
	--检查是否能够除铭
	ret = self:LuaFnUnLockCheck(selfId, itemIndex1, need_money )

	if ret == 0 then --成功了
		self:LuaFnEquipUnLock(selfId, itemIndex1 )
		self:LuaFnEraseItem( selfId, itemIndex2 )
		self:LuaFnCostMoneyWithPriority( selfId, need_money )
		self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, 49, 0)
		local szTranItm	= self:GetBagItemTransfer(selfId, itemIndex1 )
		if szTranItm ~= nil then
			text = string.format( "#{_INFOMSG%s} đã hoàn thành trừ minh.",
									szTranItm )
			--AddGlobalCountNews( sceneId, szMsg )
		end
	end
	if ret == -1 then
		text="Lỗi không xác định."
	end
	if ret == -2 then
		text="Trang bị không thể dùng."
	end
	if ret == -3 then
		text="Trang bị của ngài chưa khắc minh, không Yêu cầu tiến hành trừ minh."
	end
	self:notify_tips(selfId, text)
end

return equip_bind