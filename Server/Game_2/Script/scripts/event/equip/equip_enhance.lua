--装备强化
--脚本号
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local equip_enhance = class("equip_enhance", script_base)

local g_QianghualuId = 30900045
local g_QianghualuTime = 11

function equip_enhance:FinishEnhance(selfId, itemidx1, itemidx2 )
    -- CYS-FORGE 23/09 legacy rolls/paid shortcuts cannot bypass Space.
    do self:notify_tips(selfId,"Hãy dùng khung Nhịp rèn để cường hoá bằng Space."); return end
	local locked = self:LuaFnIsItemLocked(selfId, itemidx1 )
	if locked then
        self:notify_tips(selfId, "Trang bị này không dùng được.")
		return
	end
	local ret = self:LuaFnIsItemAvailable(selfId, itemidx2 )
	if not ret then
        self:notify_tips(selfId, "Không thể dùng Tinh Hoa Cường Hóa hoặc Lộ Cường Hóa này.")
		return
	end
	local equip_level = self:GetBagItemLevel(selfId, itemidx1 )
	local item_index = self:LuaFnGetItemTableIndexByIndex(selfId, itemidx2 )
	local cur_strong = self:LuaFnGetEquipEnhanceLevel(selfId, itemidx1)
	if cur_strong >= 9 then
		-- 强化等级>=9，需要至尊强化精华或至尊强化露
		if item_index ~= 38008160 and item_index ~= 38008161 then
			local str = string.format( "Trang bị này Cường Hóa Yêu cầu %s hoặc %s.", self:GetItemName(38008160), self:GetItemName(38008161))
			self:notify_tips(selfId, str)
			return
		end
	elseif equip_level < 40 then
		if item_index ~= 30900005 then
			--低级强化精华
			local str = string.format( "Trang bị này Cường Hóa Yêu cầu %s.", self:GetItemName(30900005))
            self:notify_tips(selfId, str)
			return
		end
	else
		if item_index ~= 30900006 and item_index ~= g_QianghualuId then
			--高级强化精华
            local str = string.format( "Trang bị này Cường Hóa Yêu cầu %s.", self:GetItemName(30900006))
            self:notify_tips(selfId, str)
			return
		end
	end
	--检查是否能够强化
	local ret, arg0 = self:LuaFnEquipEnhanceCheck(selfId, itemidx1, itemidx2 )
	local text="Trang bị Cường Hóa thành công!"
	-- zchw
	local equip_index = self:LuaFnGetItemTableIndexByIndex(selfId, itemidx1)
	if (equip_index == 104230241) or (equip_index == 104220161) then --重楼玉，重楼戒
		if item_index == 30900006 then --高级强化精华
			local bindStatus = self:LuaFnGetItemBindStatus(selfId, itemidx2)
			if bindStatus then --绑定
				text = "Trang bị này không thể dùng Thiên Cương Cường Hóa Tinh Hoa đã khóa để cường hóa!";
                self:notify_tips(selfId, text)
				return
			end
		end
	end
	if not self:LuaFnIsIdentd(selfId,itemidx1) then
		self:notify_tips(selfId,"Trang bị chưa giám định không cường hóa được.")
		return
	end
	if ret == 0 then
		local bindStatus = self:LuaFnGetItemBindStatus(selfId, itemidx2)
		--强化消耗检查成功
		self:DoFinishEnhance(selfId, itemidx1, itemidx2)
		if bindStatus then
			self:LuaFnItemBind(selfId, itemidx1)
		end
		return
	end
	if ret == -1 then
		text="Lỗi không xác định."
	end
	if ret == -2 then
		text="Trang bị không thể dùng."
	end
	if ret == -3 then
		--text="强化精华不可用。"
		text="Cường Hóa Tinh Hoa hoặc Cường Hóa Lộ không thể dùng."
	end
	if ret == -4 then
		text="Cấp độ cường hóa của Trang bị này đã đạt tối đa."
	end

	if ret == -5 then
		text="Cường hóa Trang bị này Yêu cầu #{_EXCHG%d}, tiền mặt của ngài không đủ." --zchw
		text=string.format( text, arg0 )
	end
	if ret == -7 then
		text="Trang bị này không thể được cường hóa."
	end

	if ret == -6 then
		self:DoFinishEnhance(selfId, itemidx1, itemidx2)
		return
	end
    self:notify_tips(selfId, text)
end

function equip_enhance:DoFinishEnhance(selfId, itemidx1, itemidx2)
    -- CYS-FORGE 23/09 legacy rolls/paid shortcuts cannot bypass Space.
    do self:notify_tips(selfId,"Hãy dùng khung Nhịp rèn để cường hoá bằng Space."); return end
	local text="Trang bị Cường Hóa thành công!"
	--强化
    local item_index = self:LuaFnGetItemTableIndexByIndex(selfId, itemidx2 )
	local old_level = self:LuaFnGetEquipEnhanceLevel(selfId, itemidx1)
	local ret,arg0 = self:LuaFnEquipEnhance(selfId, itemidx1, itemidx2, g_QianghualuTime )
	if ret == 0 then
		local new_level = self:LuaFnGetEquipEnhanceLevel(selfId, itemidx1)
		if new_level > old_level then
			if g_QianghualuId == item_index then
				local r, t = self:LuaFnEraseItemTimes(selfId, itemidx2, g_QianghualuTime )
				local szMsg = string.format( "Thiên Cương Cường Hóa Lộ còn lại %d/%d lần sử dụng", tonumber(t), tonumber(g_QianghualuTime) );
				self:notify_tips(selfId, szMsg)
			end
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
			-- 成功后绑定装备
			if self:LuaFnGetItemBindStatus(selfId,itemidx2) then
				self:LuaFnItemBind(selfId,itemidx1)
			end
			self:notify_tips(selfId, text)
			return
		else
			-- 引擎返回0但等级未提升，视为失败
			text = "Thật đáng tiếc Trang bị của ngài cường hóa thất bại rồi, đừng nản lòng!!!"
			if g_QianghualuId == item_index then
				local r, t = self:LuaFnEraseItemTimes(selfId, itemidx2, g_QianghualuTime )
				local szMsg = string.format( "Thiên Cương Cường Hóa Lộ còn lại %d/%d lần sử dụng", tonumber(t), tonumber(g_QianghualuTime) );
				self:notify_tips(selfId, szMsg)
			end
			self:notify_tips(selfId, text)
			return
		end
	end
	if ret == -1 then
		text="Lỗi không xác định."
	end
	if ret == -2 then
		text="Trang bị không thể dùng."
	end
	if ret == -3 then
		text="Cường Hóa Tinh Hoa không thể dùng."
	end
	if ret == -4 then
		text="Cấp độ cường hóa của Trang bị này đã đạt tối đa."
	end

	if ret == -5 then
		text="Cường hóa Trang bị này Yêu cầu #{_EXCHG%d}, tiền mặt của ngài không đủ." --zchw
		text=string.format( text, arg0 )
	end

	if ret == -6 then
		text="Thật đáng tiếc Trang bị của ngài cường hóa thất bại rồi, đừng nản lòng!!!"
		if g_QianghualuId == item_index then
			local r, t = self:LuaFnEraseItemTimes(selfId, itemidx2, g_QianghualuTime )
			local szMsg = string.format( "Thiên Cương Cường Hóa Lộ còn lại %d/%d lần sử dụng", tonumber(t), tonumber(g_QianghualuTime) );
            self:notify_tips(selfId, szMsg)
		end
	end
	self:notify_tips(selfId, text)
end

function equip_enhance:DoQuickQiangHuaByYB(selfId, ItemPos, check)
    -- CYS-FORGE 23/09 legacy rolls/paid shortcuts cannot bypass Space.
    do self:notify_tips(selfId,"Hãy dùng khung Nhịp rèn để cường hoá bằng Space."); return end
	local cost = 85626
	if check == 0 then
		self:BeginUICommand()
		self:UICommand_AddInt(ItemPos)
		local BagItem = self:GetBagItem(selfId, ItemPos)
		local level = self:LuaFnGetEquipEnhanceLevel(selfId, ItemPos)
		local str = self:ContactArgs("#{QHTS_200710_04", BagItem:get_base_config().name, level, cost)
		self:UICommand_AddStr(str .. "}")
		self:EndUICommand()
		self:DispatchUICommand(selfId, 80926201)
	else
		if self:GetYuanBao(selfId) < cost then
			self:notify_tips(selfId, "Không đủ nguyên bảo!")
			return
		end
		self:LuaFnCostYuanBao(selfId, cost)
		self:LuaFnSetEquipEnhanceLevel(selfId, ItemPos, 9)
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
		self:notify_tips(selfId, "Cường hóa nhanh thành công")
	end
end

function equip_enhance:FinishMoveEnhance(selfId,Item1,Item2)
	if Item2 == Item1 then
	    return
	end
	local ret = self:LuaFnIsItemLocked(selfId, Item1 )
	if ret then
		self:notify_tips(selfId, "#{ZBQH_130521_13}" )
		return
	end
	ret = self:LuaFnIsItemAvailable(selfId, Item2 )
	if not ret then
		self:notify_tips(selfId, "#{ZBQH_130521_20}" )
		return
	end
	local gem_index1 = self:LuaFnGetItemTableIndexByIndex(selfId, Item1 )
	local gem_index2 = self:LuaFnGetItemTableIndexByIndex(selfId, Item2 )
	local equipType1 = self:GetItemEquipPoint(gem_index1 )
	local equipType2 = self:GetItemEquipPoint(gem_index2 )
	local curlevel1  = self:LuaFnGetEquipEnhanceLevel(selfId,Item1)
	local curlevel2  = self:LuaFnGetEquipEnhanceLevel(selfId,Item2)
	local Equip_Level1 = self:GetBagItemLevel(selfId, Item1 )
	local Equip_Level2 = self:GetBagItemLevel(selfId, Item2 )
	local leftItemName = self:GetItemName(gem_index1)
	local systemstringid =""
	if equipType1 == -1 or equipType2 == -1 then
		return
	end
	if equipType1 == define.HUMAN_EQUIP.HEQUIP_ANQI then
		Equip_Level1 = self:GetBagDarkLevel(selfId, Item1)
	end
	if equipType2 == define.HUMAN_EQUIP.HEQUIP_ANQI then
		Equip_Level2 = self:GetBagDarkLevel(selfId, Item2)
	end
	if equipType1 ~= equipType2 then
		if Equip_Level1 < 40 then
			systemstringid = string.format("#H Chỉ có thể chuyển Cấp độ cường hóa của %s#H lên %s#H có Trang bị Cấp độ dưới cấp 40.",leftItemName, g_EquipName[Equip_Level1].name)
		end
		if Equip_Level1 >= 40 then
			systemstringid =  string.format("#H Chỉ có thể chuyển Cấp độ cường hóa của %s#H lên %s#H có Trang bị Cấp độ đạt cấp 40 trở lên.",leftItemName, g_EquipName[Equip_Level1].name)
		end
		self:notify_tips(selfId, systemstringid)
		return
	end
	if Equip_Level1 < 40 and Equip_Level2 >= 40 then
		systemstringid = string.format("#H Chỉ có thể chuyển Cấp độ cường hóa của %s#H lên %s#H có Trang bị Cấp độ dưới cấp 40.",leftItemName, g_EquipName[Equip_Level1].name)
		self:notify_tips(selfId, systemstringid)
		return
	end
    if Equip_Level1 >= 40 and Equip_Level2 < 40 then
		systemstringid = string.format("#H Chỉ có thể chuyển Cấp độ cường hóa của %s#H lên %s#H có Trang bị Cấp độ đạt cấp 40 trở lên.",leftItemName, g_EquipName[Equip_Level1].name)
		self:notify_tips(selfId, systemstringid)
		return
	end
	if curlevel1 <= curlevel2 then
		systemstringid = string.format("#H Cấp độ cường hóa của Trang bị này đã đạt hoặc vượt quá Cấp độ cường hóa của Trang bị gốc: %s#H cấp, không thể tiếp nhận chuyển di.",curlevel1)
		self:notify_tips(selfId, systemstringid)
		return
	end
	local NeedMoney = curlevel1*5
	if NeedMoney > 100 then
		NeedMoney = 100
	end
	local nMoneyJZ = self:GetMoneyJZ(selfId)
	local nMoneyJB = self:GetMoney(selfId)
	local nMoneySelf = nMoneyJZ + nMoneyJB
	if nMoneySelf < NeedMoney*10000 then
		self:notify_tips(selfId, "Chuyển cường hóa cần#{_EXCHG%d}, tiền của bạn không đủ",NeedMoney*10000)
		return
	end
	--原装备数据清空
	self:LuaFnSetEquipEnhanceLevel(selfId,Item1,0)
	self:LuaFnCostMoneyWithPriority(selfId, NeedMoney*10000 );
	--目标装备数据存储
	self:LuaFnSetEquipEnhanceLevel(selfId,Item2,curlevel1)
	if self:LuaFnGetItemBindStatus(selfId,Item1) then
		--防止重复调用保留性能。
		--if not self:LuaFnGetItemBindStatus(selfId,Item2) then
			self:LuaFnItemBind(selfId,Item2) --成功后绑定装备
		--end
	end
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
	self:notify_tips(selfId, "Chúc mừng bạn, chuyển cường hóa thành công!!")
	local szTranItm2 = self:GetBagItemTransfer(selfId, Item2 )
	local name = self:LuaFnGetName(selfId )
	local szMsg	= string.format( "#W#{_INFOUSR%s}#G đã tiêu hao #{_EXCHG%d} thành công đem #Y" .. leftItemName .. "#Gcường hóa chuyển sang#{_INFOMSG%%s}", name, NeedMoney*10000)
	szMsg = gbk.fromutf8(szMsg)
	szMsg = string.format(szMsg, szTranItm2)
	self:AddGlobalCountNews(szMsg, true)
end

function equip_enhance:GetBagDarkLevel(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local anqi = obj:get_prop_bag_container():get_item(BagPos)
    assert(anqi, BagPos)
	local level = self:GetBagItemLevel(selfId, BagPos)
	local xiulian_level = anqi:get_equip_data():get_aq_xiulian()
    return (xiulian_level > level) and xiulian_level or level
end


-- CYS-FORGE 23/09 new functions on the existing, permitted script 809262.
function equip_enhance:CysForgeQuote(selfId,slot,seq)
    local h=self.scene:get_obj_by_id(selfId)
    if h and h:get_obj_type()=="human" then require("cys_forge").quote(self,h,slot,seq) end
end
function equip_enhance:CysForgeBegin(selfId,slot,material,seq)
    local h=self.scene:get_obj_by_id(selfId)
    if h and h:get_obj_type()=="human" then require("cys_forge").begin(self,h,slot,material,seq) end
end
function equip_enhance:CysForgeStrike(selfId,nonce,elapsed)
    local h=self.scene:get_obj_by_id(selfId)
    if h and h:get_obj_type()=="human" then require("cys_forge").strike(self,h,nonce,elapsed) end
end
function equip_enhance:CysForgeCancel(selfId,seq)
    local h=self.scene:get_obj_by_id(selfId)
    if h and h:get_obj_type()=="human" then require("cys_forge").cancel(self,h,seq) end
end

return equip_enhance