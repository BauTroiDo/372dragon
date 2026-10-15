--===================================
-- 材料合成界面
--===================================
local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local CaiLiaoCompoundNew = class("CaiLiaoCompoundNew", script_base)

-- 合成数值
CaiLiaoCompoundNew.CompoundInfo = 
{
	-- level1为碎片，level4为3级材料，这样
	[1] = { newlevel = 2, needlevel = 1, needcount = 5, needmoney = 500, },
	[2] = { newlevel = 3, needlevel = 2, needcount = 5, needmoney = 1000, },
	[3] = { newlevel = 4, needlevel = 3, needcount = 5, needmoney = 1500, },
	[4] = { newlevel = 5, needlevel = 4, needcount = 5, needmoney = 5000, },
}
-- 道具
CaiLiaoCompoundNew.CompoundItemInfo = 
{
	[1]=
	{
		{nItemID = 20502000, strShowName = "#{CLHC_170904_74}"},	--秘银碎片
		{nItemID = 20502001, strShowName = "#{CLHC_170904_77}"},	--1级秘银
		{nItemID = 20502002, strShowName = "#{CLHC_170904_78}"},	--2级秘银
		{nItemID = 20502003, strShowName = "#{CLHC_170904_79}"},	--3级秘银
		{nItemID = 20502004, strShowName = "#{CLHC_170904_80}"},	--4级秘银
	},
	
	[2]=
	{
		{nItemID = 20501000, strShowName = "#{CLHC_170904_75}"},	--棉布碎片
		{nItemID = 20501001, strShowName = "#{CLHC_170904_81}"},	--1级棉布
		{nItemID = 20501002, strShowName = "#{CLHC_170904_82}"},	--2级棉布
		{nItemID = 20501003, strShowName = "#{CLHC_170904_83}"},	--3级棉布
		{nItemID = 20501004, strShowName = "#{CLHC_170904_84}"},	--4级棉布
	},
	
	[3]=
	{
		{nItemID = 20500000, strShowName = "#{CLHC_170904_76}"},	--精铁碎片
		{nItemID = 20500001, strShowName = "#{CLHC_170904_85}"},	--1级精铁
		{nItemID = 20500002, strShowName = "#{CLHC_170904_86}"},	--2级精铁
		{nItemID = 20500003, strShowName = "#{CLHC_170904_87}"},	--3级精铁
		{nItemID = 20500004, strShowName = "#{CLHC_170904_88}"},	--4级精铁
	},
}
function CaiLiaoCompoundNew:CaiLiaoCompound_New(selfId,TargetID,g_CurNum_PerTime,nIndex,nSubIndex,Sub)
	--print("CaiLiaoCompoundNew:CaiLiaoCompound_New =",TargetID)
	if nIndex < 1 or nIndex > 3 then
		self:NotifyTips(selfId,"CompoundNew_Error_nIndex!!!")
		return
	end
	if nSubIndex < 1 or nSubIndex > 4 then
		self:NotifyTips(selfId,"CompoundNew_Error_nSubIndex!!!")
		return
	end
	local tSubData = self.CompoundInfo[nSubIndex]
	local tItem = self.CompoundItemInfo[nIndex]
	if tSubData == nil then
		self:NotifyTips(selfId,"tSubData_nil!!!" )
		return
	end
	if tItem == nil then
	    self:NotifyTips(selfId,"tItem_nil!!!" )
		return
	end
	local needCount = tSubData.needcount
	if needCount == nil or needCount <= 0 then
		self:NotifyTips(selfId,"needCount_nil!!!" )
		return
	end
	local needMoney = tSubData.needmoney
	if needMoney == nil or needMoney <= 0 then
		self:NotifyTips(selfId,"needmoney_nil!!!" )
		return
	end
	local needLevel = tSubData.needlevel
	if needLevel == nil or needLevel <= 0 then
		self:NotifyTips(selfId,"needlevel_nil!!!" )
		return
	end
	local needItemId = tItem[needLevel].nItemID
	if needItemId == nil or needItemId <= 0 then
		self:NotifyTips(selfId,"needItemId_nil!!!" )
		return
	end
	local newLevel = tSubData.newlevel
	if newLevel == nil or newLevel <= 0 then
		self:NotifyTips(selfId,"newLevel_nil!!!" )
		return
	end
	local newItemId = tItem[newLevel].nItemID
	if newItemId == nil or newItemId <= 0 then
		self:NotifyTips(selfId,"newItemId_nil!!!" )
		return
	end
	local nHaveCount = self:LuaFnGetAvailableItemCount(selfId,needItemId)
	if nHaveCount < needCount then
		self:NotifyTips(selfId,string.format("Xin lỗi, %s trên người không đủ %d cái, không tiếp tục được",tItem[needLevel].strShowName,needCount))
		return
	end
	local NewCompoundNum = math.floor(nHaveCount/5)
	if g_CurNum_PerTime > NewCompoundNum then
		self:NotifyTips(selfId,string.format("Xin lỗi, %s trên người không đủ hợp thành %d cái, %s.",tItem[needLevel].strShowName,g_CurNum_PerTime,self:GetItemName(newItemId)))
		return
	end
	local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
	if nMoneySelf < needMoney * g_CurNum_PerTime then
		self:NotifyTips(selfId,"Kim tiền không đủ.")
		return
	end
    self:BeginAddItem()
    self:AddItem(newItemId,g_CurNum_PerTime)
    if not self:EndAddItem(selfId) then
		self:NotifyTips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
	local IsBind = false
	if self:GetBagPosByItemSnAvailableBind(selfId,needItemId,true) > -1 then
		IsBind = true
	end
	local del = self:LuaFnDelAvailableItem(selfId,needItemId,needCount * g_CurNum_PerTime)
	if not del then
		self:NotifyTips(selfId,"Trừ đạo cụ thất bại.")
        return
    end
	del = self:LuaFnCostMoneyWithPriority(selfId,needMoney * g_CurNum_PerTime)
	if not del then
		self:NotifyTips(selfId,"Trừ tiền thất bại.")
        return
    end
	local strTransfer = nil
	local name = self:GetName(selfId)
	for i = 1,g_CurNum_PerTime do
		local bagepos = self:TryRecieveItem(selfId,newItemId,IsBind)
		if i == 1 then
			strTransfer = self:GetBagItemTransfer(selfId,bagepos)	
		end
	end
	self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
	self:NotifyTips(selfId,string.format("Hợp thành thành công %d cái %s.",g_CurNum_PerTime,self:GetItemName(newItemId)))
	if newLevel > 3 then
		local fmt = gbk.fromutf8(
									"#{_INFOUSR%s}#Hsau một phen nỗ lực, cuối cùng hợp thành %d cái #{_INFOMSG%s}.")
		local strText = string.format(fmt,gbk.fromutf8(name),g_CurNum_PerTime,strTransfer)
		self:BroadMsgByChatPipe(selfId,strText,4)
	end
	self:BeginUICommand()
		self:UICommand_AddInt(2)
		self:UICommand_AddInt(TargetID)
	self:EndUICommand()
	self:DispatchUICommand(selfId,920170825)
end

function CaiLiaoCompoundNew:NotifyTips(selfId,msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return CaiLiaoCompoundNew
