--云姗姗

local class = require "class"
local script_base = require "script_base"
local osuzhou_yunshanshan = class("osuzhou_yunshanshan", script_base)
local g_EquipList = {
	[3] = {70500045,70501045,70502045,70503045,70504045},
	[4] = {70500050,70501050,70502050,70503050,70504050},
	[5] = {70500055,70501055,70502055,70503055,70504055},
	[6] = {70500060,70501060,70502060,70503060,70504060},
	[7] = {70500065,70501065,70502065,70503065,70504065},
	[8] = {70500070,70501070,70502070,70503070,70504070},
	[9] = {70500075,70501075,70502075,70503075,70504075},
	[10] = {70500080,70501080,70502080,70503080,70504080},
	[11] = {70500085,70501085,70502085,70503085,70504085},
	-------------------------------------------------------
	[13] = {70500090,70501090,70502090,70503090,70504090},
	[14] = {70500095,70501095,70502095,70503095,70504095},
	[15] = {70500100,70501100,70502100,70503100,70504100},
	[16] = {70500105,70501105,70502105,70503105,70504105},
	[17] = {70500110,70501110,70502110,70503110,70504110},
	[18] = {70500115,70501115,70502115,70503115,70504115},
	[19] = {70500120,70501120,70502120,70503120,70504120},
	[20] = {70500125,70501125,70502125,70503125,70504125},
	[21] = {70500130,70501130,70502130,70503130,70504130},
}
local g_StoneNumList = {}
for i = 1, 21 do
	local count = 30
	if i >= 13 then
		count = 100
	end
	local list = g_EquipList[i]
	if list then
		for _, item_index in ipairs(list) do
			g_StoneNumList[item_index] = count
		end
	end
end
function osuzhou_yunshanshan:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{ZSZB_090421_09}")
    self:AddNumText("Trân thú Sáo Trang Tinh Cấp Thăng",6,1)
    self:AddNumText("Phân giải bộ Trân thú",6,2)
    self:AddNumText("Đổi Trân thúBộ Trang bị",6,3)
    -- self:AddNumText("珍兽套装星级提升介绍",11,4)
    -- self:AddNumText("珍兽套装拆解介绍",11,5)
    self:AddNumText("Giới thiệu bộ trân thú",11,5)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunshanshan:OnEventRequest(selfId, targetId, arg, index)
    if index == 0  then
		-- 关闭窗口
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1000)
		return
	end

	if index == 1 then
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(1)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 19831204)
	end

	if index == 2 then
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(30)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 19831205)
	end

	if index == 3 then
		self:BeginEvent(self.script_id)
        self:AddText("#{ZSZBDH_090806_1}")
        self:AddNumText("#{ZSZBDH_XML_1}", 6, 1000 )
        self:AddNumText("#{ZSZBDH_XML_2}", 6, 1001 )
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if index == 4 then
		self:BeginEvent(self.script_id)
        self:AddText("#{ZSZBSJ_090706_14}")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if index == 5 then
		self:BeginEvent(self.script_id)
        self:AddText("#{ZSZBSJ_090706_16}")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if index == 1000 then
		self:BeginEvent(self.script_id)
        self:AddText("#{ZSZBDH_090806_2}")
			for i = 3,11 do
				self:AddNumText("#{ZSZBDH_XML_"..i.."}", 6,2000 + i )
			end
		self:AddNumText("Trở về", 0, 0 )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
		return
	end
	if index == 1001 then
		self:BeginEvent(self.script_id)
        self:AddText("#{ZSZBDH_090806_3}")
			for i = 13,21 do
				self:AddNumText("#{ZSZBDH_XML_"..i.."}", 6, 2000 + i )
			end
		self:AddNumText("Trở về", 0, 0 )
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
		return
	end

	if index > 2000 and index < 2100 then
		self:BeginEvent(self.script_id)
			local nIndex = index % 100
			local szStr = "#{ZSZBDH_XML_"..nIndex.."}#{ZSZBDH_090806_4}".."#G30".."#W#{ZSZBDH_090806_5}"
			self:AddText(szStr)
			for i = 1,5 do
				self:AddRadioItemBonus(g_EquipList[nIndex][i], 4 )
			end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId, self.script_id, 0)
	end
end

function osuzhou_yunshanshan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
	--处理提交后的显示情况
	--为了安全，这里要仔细，不能出错
	local nItemIndex = -1
	for i = 3,21 do
		if g_EquipList[i] ~= nil then
			for j = 1,5 do
				if g_EquipList[i][j] == selectRadioId then
					nItemIndex = selectRadioId
					break
				end
			end
		end
	end	
	if nItemIndex == -1  then
		return
	end

	local Num = g_StoneNumList[nItemIndex]
	local costtab = {}
	local itemcount
	local allnum = 0
	for i,j in ipairs({20301007, 20301009}) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, j)
		if itemcount > 0 then
			allnum = allnum + itemcount
			table.insert(costtab,j)
		end
	end
	-- local nHavtItem = self:LuaFnGetAvailableItemsCount(selfId, 20301007, 20301009)
	-- 检查是不是有足够的石头可以扣除
	if allnum < Num then
		self:notify_tips(selfId, "#{ZSZBDH_090806_7}")
		return
	end
	-- 检查背包空间
	self:BeginAddItem()
		self:AddItem(selectRadioId, 1)
	local bBagOk = self:EndAddItem(selfId)	
	if not bBagOk then
		self:notfiy_tips(selfId, "#{ZSZBDH_090806_8}")
		return
	end

	-- 删除相关的石头
	local bDelOk = self:LuaFnMtl_CostMaterial(selfId, Num, costtab)
	if not bDelOk then
		self:notify_tips(selfId, "#{ZSZBDH_090806_7}")
		return
	else
		--给玩家东西，完成
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId, "#{ZSZBDH_090806_9}")
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0) --特效
		return
	end
end

return osuzhou_yunshanshan