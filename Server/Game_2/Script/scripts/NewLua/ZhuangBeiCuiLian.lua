--神器升星与重洗系统
local class = require "class"
local script_base = require "script_base"
local ZhuangBeiCuiLian = class("ZhuangBeiCuiLian", script_base)
ZhuangBeiCuiLian.script_id = 892102

-- 可升星装备白名单（O(1)查找）
ZhuangBeiCuiLian.UpgradeWhiteList = {
	[10300100] = 1, [10300101] = 1, [10300102] = 1,
	[10301100] = 1, [10301101] = 1, [10301102] = 1,
	[10301200] = 1, [10301201] = 1, [10301202] = 1,
	[10302100] = 1, [10302101] = 1, [10302102] = 1,
	[10302200] = 1, [10302201] = 1, [10302202] = 1,
	[10303100] = 1, [10303101] = 1, [10303102] = 1,
	[10303200] = 1, [10303201] = 1, [10303202] = 1,
	[10304100] = 1, [10304101] = 1, [10304102] = 1,
	[10305100] = 1, [10305101] = 1, [10305102] = 1,
	[10305200] = 1, [10305201] = 1, [10305202] = 1,
	[10306100] = 1, [10306101] = 1, [10306102] = 1,
	[10307000] = 1, [10307001] = 1, [10307002] = 1,
	[10310100] = 1, [10310101] = 1, [10310102] = 1,
	[10311100] = 1, [10311101] = 1, [10311102] = 1,
	[10311200] = 1, [10311201] = 1, [10311202] = 1,
	[10312100] = 1, [10312101] = 1, [10312102] = 1,
	[10312200] = 1, [10312201] = 1, [10312202] = 1,
	[10313100] = 1, [10313101] = 1, [10313102] = 1,
	[10313200] = 1, [10313201] = 1, [10313202] = 1,
	[10314100] = 1, [10314101] = 1, [10314102] = 1,
	[10315100] = 1, [10315101] = 1, [10315102] = 1,
	[10315200] = 1, [10315201] = 1, [10315202] = 1,
	[10316100] = 1, [10316101] = 1, [10316102] = 1,
	[10317000] = 1, [10317001] = 1, [10317002] = 1,
	[10320100] = 1, [10320101] = 1, [10320102] = 1,
	[10321100] = 1, [10321101] = 1, [10321102] = 1,
	[10321200] = 1, [10321201] = 1, [10321202] = 1,
	[10322100] = 1, [10322101] = 1, [10322102] = 1,
	[10322200] = 1, [10322201] = 1, [10322202] = 1,
	[10323100] = 1, [10323101] = 1, [10323102] = 1,
	[10323200] = 1, [10323201] = 1, [10323202] = 1,
	[10324100] = 1, [10324101] = 1, [10324102] = 1,
	[10325100] = 1, [10325101] = 1, [10325102] = 1,
	[10325200] = 1, [10325201] = 1, [10325202] = 1,
	[10326100] = 1, [10326101] = 1, [10326102] = 1,
	[10327000] = 1, [10327001] = 1, [10327002] = 1,
	[10330100] = 1, [10330101] = 1, [10330102] = 1,
	[10331100] = 1, [10331101] = 1, [10331102] = 1,
	[10331200] = 1, [10331201] = 1, [10331202] = 1,
	[10332100] = 1, [10332101] = 1, [10332102] = 1,
	[10332200] = 1, [10332201] = 1, [10332202] = 1,
	[10333100] = 1, [10333101] = 1, [10333102] = 1,
	[10333200] = 1, [10333201] = 1, [10333202] = 1,
	[10334100] = 1, [10334101] = 1, [10334102] = 1,
	[10335100] = 1, [10335101] = 1, [10335102] = 1,
	[10335200] = 1, [10335201] = 1, [10335202] = 1,
	[10336100] = 1, [10336101] = 1, [10336102] = 1,
	[10337000] = 1, [10337001] = 1, [10337002] = 1,
}

-- 可重洗装备白名单（包含升星白名单 + 额外ID）
ZhuangBeiCuiLian.RerollWhiteList = {
	[10300100] = 1, [10300101] = 1, [10300102] = 1,
	[10301100] = 1, [10301101] = 1, [10301102] = 1,
	[10301200] = 1, [10301201] = 1, [10301202] = 1,
	[10302100] = 1, [10302101] = 1, [10302102] = 1,
	[10302200] = 1, [10302201] = 1, [10302202] = 1,
	[10303100] = 1, [10303101] = 1, [10303102] = 1,
	[10303200] = 1, [10303201] = 1, [10303202] = 1,
	[10304100] = 1, [10304101] = 1, [10304102] = 1,
	[10305100] = 1, [10305101] = 1, [10305102] = 1,
	[10305200] = 1, [10305201] = 1, [10305202] = 1,
	[10306100] = 1, [10306101] = 1, [10306102] = 1,
	[10307000] = 1, [10307001] = 1, [10307002] = 1,
	[10310100] = 1, [10310101] = 1, [10310102] = 1,
	[10311100] = 1, [10311101] = 1, [10311102] = 1,
	[10311200] = 1, [10311201] = 1, [10311202] = 1,
	[10312100] = 1, [10312101] = 1, [10312102] = 1,
	[10312200] = 1, [10312201] = 1, [10312202] = 1,
	[10313100] = 1, [10313101] = 1, [10313102] = 1,
	[10313200] = 1, [10313201] = 1, [10313202] = 1,
	[10314100] = 1, [10314101] = 1, [10314102] = 1,
	[10315100] = 1, [10315101] = 1, [10315102] = 1,
	[10315200] = 1, [10315201] = 1, [10315202] = 1,
	[10316100] = 1, [10316101] = 1, [10316102] = 1,
	[10317000] = 1, [10317001] = 1, [10317002] = 1,
	[10320100] = 1, [10320101] = 1, [10320102] = 1,
	[10321100] = 1, [10321101] = 1, [10321102] = 1,
	[10321200] = 1, [10321201] = 1, [10321202] = 1,
	[10322100] = 1, [10322101] = 1, [10322102] = 1,
	[10322200] = 1, [10322201] = 1, [10322202] = 1,
	[10323100] = 1, [10323101] = 1, [10323102] = 1,
	[10323200] = 1, [10323201] = 1, [10323202] = 1,
	[10324100] = 1, [10324101] = 1, [10324102] = 1,
	[10325100] = 1, [10325101] = 1, [10325102] = 1,
	[10325200] = 1, [10325201] = 1, [10325202] = 1,
	[10326100] = 1, [10326101] = 1, [10326102] = 1,
	[10327000] = 1, [10327001] = 1, [10327002] = 1,
	[10330100] = 1, [10330101] = 1, [10330102] = 1,
	[10331100] = 1, [10331101] = 1, [10331102] = 1,
	[10331200] = 1, [10331201] = 1, [10331202] = 1,
	[10332100] = 1, [10332101] = 1, [10332102] = 1,
	[10332200] = 1, [10332201] = 1, [10332202] = 1,
	[10333100] = 1, [10333101] = 1, [10333102] = 1,
	[10333200] = 1, [10333201] = 1, [10333202] = 1,
	[10334100] = 1, [10334101] = 1, [10334102] = 1,
	[10335100] = 1, [10335101] = 1, [10335102] = 1,
	[10335200] = 1, [10335201] = 1, [10335202] = 1,
	[10336100] = 1, [10336101] = 1, [10336102] = 1,
	[10337000] = 1, [10337001] = 1, [10337002] = 1,
	-- 重洗额外ID
	[10340100] = 1, [10340101] = 1, [10340102] = 1,
	[10341100] = 1, [10341101] = 1, [10341102] = 1,
	[10341200] = 1, [10341201] = 1, [10341202] = 1,
	[10342100] = 1, [10342101] = 1, [10342102] = 1,
	[10343100] = 1, [10343101] = 1, [10343102] = 1,
	[10343200] = 1, [10343201] = 1, [10343202] = 1,
	[10344100] = 1, [10344101] = 1, [10344102] = 1,
	[10345100] = 1, [10345101] = 1, [10345102] = 1,
	[10345200] = 1, [10345201] = 1, [10345202] = 1,
	[10346100] = 1, [10346101] = 1, [10346102] = 1,
	[10347100] = 1, [10347101] = 1, [10347102] = 1,
}

--**********************************
-- 事件交互入口
--**********************************
function ZhuangBeiCuiLian:OnDefaultEvent(selfId, targetId)
end

--**********************************
-- 事件列表选中一项
--**********************************
function ZhuangBeiCuiLian:OnEventRequest(selfId, targetId, eventId)
end

--**********************************
-- 神器升星与重洗主函数
-- tepp: 333=升星, 444=重洗
-- equipitm: 装备位置
--**********************************
function ZhuangBeiCuiLian:WuhunMagicUp(selfId, tepp, equipitm, equipitmo)
	if equipitm == -1 or equipitmo == -1 then
		return
	end
	if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "Túi không đủ chỗ, từ chối thao tác")
		return
	end

	-- 神器升星
	if tepp == 333 then
		local whz = self:LuaFnGetItemTableIndexByIndex(selfId, equipitm)
		if not self:LuaFnIsItemAvailable(selfId, equipitm) then
			self:notify_tips(selfId, "Error")
			return
		end
		local quality = self:GetBagItemQuality(selfId, equipitm)

		if not self.UpgradeWhiteList[whz] then
			self:notify_tips(selfId, "Chỉ thần khí 102 mới thăng sao ở chỗ ta được")
			return
		end

		if quality == 9 then
			self:notify_tips(selfId, "Trang bị này đã tối đa 8 sao")
			return
		end

		local idx = whz + 10000

		local num = 0
		if quality == 5 then
			num = 200
		elseif quality == 6 then
			num = 500
		elseif quality == 7 then
			num = 800
		elseif quality == 8 then
			num = 1200
		end

		if self:LuaFnGetAvailableItemCount(selfId, 30505909) < num then
			self:notify_tips(selfId, "Cần [Huyền Binh Thạch]"..num.."cái")
			return
		end

		if not self:LuaFnDelAvailableItem(selfId, 30505909, num) then
			self:notify_tips(selfId, "[Huyền Binh Thạch] trừ thất bại, xin kiểm có khóa không")
			return
		end

		local HumanMoney = self:GetMoney(selfId)
		local HumanMoneyJZ = self:GetMoneyJZ(selfId)
		if HumanMoney + HumanMoneyJZ < 1 then
			self:notify_tips(selfId, "Tiền không đủ 1 kim")
			return
		end

		-- 检查是否可无损替换
		local ret = self:LuaFnCheckRefreshEquipID_Attr(selfId, equipitm, idx)
		if ret == 0 then
			-- 绑定装备
			if not self:GetBagItemIsBind(selfId, equipitm) then
				self:LuaFnItemBind(selfId, equipitm)
			end
			-- 执行无损替换（保留强化/宝石/雕纹）
			ret = self:LuaFnRefreshEquipID_Attr(selfId, equipitm, idx)
			if ret == 0 then
				-- 设置品质
				if quality < 9 then
					self:ReSetEequipQuality(selfId, equipitm, quality + 1)
				end
				self:notify_tips(selfId, "Thăng sao thành công, xem ô đạo cụ")
				self:GiveItemTip(selfId, idx, 1, 18)
				-- 广播
				local str = string.format("#PChúc mừng người chơi".."#{_INFOUSR%s} tại Lạc Dương (95,177) thăng sao thành công thần khí #{_INFOMSG%s}", self:GetName(selfId), self:GetBagItemTransfer(selfId, equipitm))
				self:BroadMsgByChatPipe(selfId, str, 4)
				self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
			else
				self:notify_tips(selfId, "Thăng cấp thất bại")
			end
		elseif ret == 1 then
			self:notify_tips(selfId, "Đối tượng bất thường.")
		elseif ret == 2 then
			self:notify_tips(selfId, "Xin đặt trang bị gốc vào.")
		elseif ret == 3 then
			self:notify_tips(selfId, "Trang bị gốc không tồn tại.")
		elseif ret == 4 then
			self:notify_tips(selfId, "Trang bị đích không tồn tại.")
		elseif ret == 5 then
			self:notify_tips(selfId, "Trang bị gốc và đích khác loại.")
		else
			self:notify_tips(selfId, "Lỗi không xác định.")
		end
	end

	-- 神器重洗
	if tepp == 444 then
		local whz = self:LuaFnGetItemTableIndexByIndex(selfId, equipitm)
		if not self:LuaFnIsItemAvailable(selfId, equipitm) then
			self:notify_tips(selfId, "Error")
			return
		end
		local quality = self:GetBagItemQuality(selfId, equipitm)

		if not self.RerollWhiteList[whz] then
			self:notify_tips(selfId, "Chỉ thần khí 102 mới tẩy lại ở chỗ ta được")
			return
		end

		local idx = whz

		local num = 5
		if self:LuaFnGetAvailableItemCount(selfId, 30505908) < num then
			self:notify_tips(selfId, "Cần [Thần Binh Phù cấp 3]"..num.."cái")
			return
		end

		if not self:LuaFnDelAvailableItem(selfId, 30505908, num) then
			self:notify_tips(selfId, "[Thần Binh Phù cấp 3] trừ thất bại, xin kiểm có khóa không")
			return
		end

		local HumanMoney = self:GetMoney(selfId)
		local HumanMoneyJZ = self:GetMoneyJZ(selfId)
		if HumanMoney + HumanMoneyJZ < 1 then
			self:notify_tips(selfId, "Tiền không đủ 1 kim")
			return
		end

		-- 检查是否可无损替换
		local ret = self:LuaFnCheckRefreshEquipID_Attr(selfId, equipitm, idx)
		if ret == 0 then
			-- 绑定装备
			if not self:GetBagItemIsBind(selfId, equipitm) then
				self:LuaFnItemBind(selfId, equipitm)
			end
			-- 执行无损替换（保留强化/宝石/雕纹）
			ret = self:LuaFnRefreshEquipID_Attr(selfId, equipitm, idx)
			if ret == 0 then
				-- 恢复品质（重洗不改变星级）
				self:ReSetEequipQuality(selfId, equipitm, quality)
				self:notify_tips(selfId, "Tẩy lại thành công, xem ô đạo cụ")
				self:GiveItemTip(selfId, idx, 1, 18)
				-- 广播
				local str = string.format("#PChúc mừng người chơi".."#{_INFOUSR%s} tại Lạc Dương (266,163) tẩy lại thành công thần khí #{_INFOMSG%s}", self:GetName(selfId), self:GetBagItemTransfer(selfId, equipitm))
				self:BroadMsgByChatPipe(selfId, str, 4)
				self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
			else
				self:notify_tips(selfId, "Tẩy luyện thất bại")
			end
		elseif ret == 1 then
			self:notify_tips(selfId, "Đối tượng bất thường.")
		elseif ret == 2 then
			self:notify_tips(selfId, "Xin đặt trang bị gốc vào.")
		elseif ret == 3 then
			self:notify_tips(selfId, "Trang bị gốc không tồn tại.")
		elseif ret == 4 then
			self:notify_tips(selfId, "Trang bị đích không tồn tại.")
		elseif ret == 5 then
			self:notify_tips(selfId, "Trang bị gốc và đích khác loại.")
		else
			self:notify_tips(selfId, "Lỗi không xác định.")
		end
	end
end

return ZhuangBeiCuiLian
