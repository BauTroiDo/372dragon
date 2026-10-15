--云涵儿

--脚本号
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yunhaner = class("oluoyang_yunhaner", script_base)
oluoyang_yunhaner.g_shoptableindex = 102
local g_change_needitem = {itemindex = 30501318, itennum = 200}
local g_eventList = {400918, 400963}
local hecheng = {
	[36] = 30503034,
	[37] = 30503035,
	[38] = 30503036,

	[39] = 30503043,
	[40] = 30503044,
	[41] = 30503045,

	[42] = 30503052,
	[43] = 30503053,
	[44] = 30503054,

	[45] = 30503061,
	[46] = 30503062,
	[47] = 30503063,
}
--兑换目标物品
local g_change_targetitem = {item_1_index = 30402022, item_2_index = 30402021, item_3_index = 30402024, item_4_index = 30402023}
function oluoyang_yunhaner:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
	    self:AddText("Tiểu thư nhà ta thu thập các loại Trân thú, nhân thủ không đủ, nếu ngươi có thể giúp đỡ sẽ nhận được thù lao.")
		for _, eventId in ipairs(g_eventList) do
			print("luoyang_yunhaner:OnDefaultEvent eventId =", eventId)
			self:CallScriptFunction(eventId, "OnEnumerate", self, selfId)
		end
	    self:AddNumText("#{BBSX_081107_1}",6,11)
	    self:AddNumText("Mua Kỹ năng Trân Thú thư",7,2)
	    self:AddNumText("Tra cứu Tỉ lệ trưởng thành Trân thú",6,3)
	    self:AddNumText("#{XXWD_8916_07}",11,5)
	    self:AddNumText("Linh Thú Đan hợp thành",6,6)
	    self:AddNumText("Giới thiệu hợp thành Linh Thú Đan",11,7)
	    self:AddNumText("Làm thế nào để Trân thú nhanh chóng Thăng cấp",11,8)
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

function oluoyang_yunhaner:OnEventRequest(selfId, targetId, arg, index)
	if arg == self.script_id then
		if index == 2 then
			self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
		elseif index == 3 then
			self:BeginEvent(self.script_id)
				self:AddText("  Tra cứu tỷ lệ trưởng thành của Trân thú, mỗi lần tra cứu Yêu cầu thu #{_MONEY100} phí.")
				self:AddNumText("Xác nhận", -1, 4)
				self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif index == 4 then
			self:BeginUICommand()
				self:UICommand_AddInt(targetId)
				self:UICommand_AddInt(6)				--珍兽查询分支
			self:EndUICommand()
			self:DispatchUICommand(selfId, 3)	--调用珍兽界面
		elseif index == 5 then
			self:BeginEvent(self.script_id)
				self:AddText("#{XXWD_8916_08}")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif index == 6 then
			self:BeginEvent(self.script_id)
			self:AddText("#{WPDJ_140912_58}")
			self:AddNumText("#{WPDJ_140912_59}",6,31)
			self:AddNumText("#{WPDJ_140912_63}",6,32)
			self:AddNumText("#{WPDJ_140912_67}",6,33)
			self:AddNumText("#{WPDJ_140912_71}",6,34)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		elseif index == 31 then
			self:BeginEvent(self.script_id)
			self:AddNumText("#{WPDJ_140912_60}",6,36)
			self:AddNumText("#{WPDJ_140912_61}",6,37)
			self:AddNumText("#{WPDJ_140912_62}",6,38)
			self:AddNumText("#{FBSJ_081209_12}",8,6)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		elseif index == 32 then
			self:BeginEvent(self.script_id)
			self:AddNumText("#{WPDJ_140912_64}",6,39)
			self:AddNumText("#{WPDJ_140912_65}",6,40)
			self:AddNumText("#{WPDJ_140912_66}",6,41)
			self:AddNumText("#{FBSJ_081209_12}",8,6)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		elseif index == 33 then
			self:BeginEvent(self.script_id)
			self:AddNumText("#{WPDJ_140912_68}",6,42)
			self:AddNumText("#{WPDJ_140912_69}",6,43)
			self:AddNumText("#{WPDJ_140912_70}",6,44)
			self:AddNumText("#{FBSJ_081209_12}",8,6)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		elseif index == 34 then
			self:BeginEvent(self.script_id)
			self:AddNumText("#{WPDJ_140912_72}",6,45)
			self:AddNumText("#{WPDJ_140912_73}",6,46)
			self:AddNumText("#{WPDJ_140912_74}",6,47)
			self:AddNumText("#{FBSJ_081209_12}",8,6)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		elseif index == 7 then
			self:BeginEvent(self.script_id)
				self:AddText("#{JNHC_81015_12}" )
			self:EndEvent()
			self:DispatchEventList(selfId, targetId )
		elseif index == 8 then
			self:BeginEvent(self.script_id)
				self:AddText("#{ZSKSSJ_081126_5}" )
			self:EndEvent()
			self:DispatchEventList(selfId, targetId )
		elseif index == 11 then
			self:BeginEvent(self.script_id)
				self:AddText("#{BBSX_081107_2}")
				self:AddNumText("#{BBSX_081107_4}",6,21)
				self:AddNumText("#{BBSX_081107_5}",6,22)
				self:AddNumText("#{BBSX_081107_6}",6,23)
				self:AddNumText("#{BBSX_081107_7}",6,24)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		elseif index == 21 then
			self:ChangeItem(selfId, targetId, 21)
		elseif index == 22 then
			self:ChangeItem(selfId, targetId, 22)
		elseif index == 23 then
			self:ChangeItem(selfId, targetId, 23)
		elseif index == 24 then
			self:ChangeItem(selfId, targetId, 24)
		elseif hecheng[index] then
			local id = hecheng[index]
			local result_id, cost_money = self:GetPetMedicineHCCompound(id)
			if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < cost_money then
				self:notify_tips(selfId, "Kim tiền không đủ")
				return
			end
			local item_count = self:LuaFnGetAvailableItemCount(selfId, id)
			if item_count < 5 then
				self:notify_tips(selfId, "Không đủ nguyên liệu hợp thành")
				return
			end
			if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
				self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
				return
			end
			self:LuaFnCostMoneyWithPriority(selfId, cost_money)
			self:LuaFnDelAvailableItem(selfId, id, 5)
			self:TryRecieveItem(selfId, result_id)
			self:notify_tips(selfId, "Hợp thành thành công")
		end
	else
		self:CallScriptFunction(arg, "OnEventRequest", self, selfId)
	end
end

function oluoyang_yunhaner:ChangeItem(selfId, targetId, key)
	local nTargetitem
	if key == 21 then
		nTargetitem = g_change_targetitem.item_1_index
	elseif key == 22 then
		nTargetitem = g_change_targetitem.item_2_index
	elseif key == 23 then
		nTargetitem = g_change_targetitem.item_3_index
	elseif key == 24 then
		nTargetitem = g_change_targetitem.item_4_index
	else
		return
	end
	local nAvailableCount = self:LuaFnGetAvailableItemCount(selfId,  g_change_needitem.itemindex)
	if nAvailableCount < g_change_needitem.itennum then
		local strName = string.format("#H#{_ITEM%d}#W", nTargetitem)
		self:MsgBox(selfId, targetId, "#{BBSX_081107_8}"..strName )
		return
	end
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId )
	if( FreeSpace < 1 ) then
		self:MsgBox(selfId, targetId, "#{BBSX_081107_9}")
	    return
	end
	if self:LuaFnDelAvailableItem(selfId, g_change_needitem.itemindex, g_change_needitem.itennum) then
        local BagPos = self:TryRecieveItem(selfId, nTargetitem, false)
            if BagPos ~= define.INVAILD_ID then
			    local szItemTransfer = self:GetBagItemTransfer(selfId, 0)
				self:ShowRandomSystemNotice(selfId, szItemTransfer )
				local strNotice = string.format("Đổi thành công, ngươi nhận được #H#{_ITEM%d}#W", nTargetitem)
                self:MsgBox(selfId, targetId, strNotice)
			else
                self:MsgBox(selfId, targetId, "#{BBSX_081107_9}")
				return
            end
	else
        self:MsgBox(selfId, targetId, "Trừ vật phẩm thất bại!")
		return
	end
end

function oluoyang_yunhaner:ShowRandomSystemNotice(selfId, strItemInfo )
	local PlayerName = self:GetName(selfId)
	local str = gbk.fromutf8(string.format("#{_INFOUSR%s}#Ptrải nghìn cay vạn đắng, gom đủ 200 mảnh#Y#{_ITEM30501318}#P, và đổi thành công tại#GLạc Dương (182,155)#Ychỗ Vân Hàm Nhi#Pmột quyển #{_INFOMSG%%s}#P.", PlayerName))
    str = string.format(str, strItemInfo)
	self:BroadMsgByChatPipe(selfId, str, 4 )
end


return oluoyang_yunhaner