--===================================
-- 一掷豪礼千金情
--===================================
local gbk = require "wire_charset"
local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local TopChongZhi = class("TopChongZhi", script_base)
TopChongZhi.script_id = 180001

TopChongZhi.Openlv = 8

TopChongZhi.TopChongZhi_GetGiftsCondition =
{
	[1] = { Point = 18 },
	[2] = { Point = 48 },
	[3] = { Point = 88 },
	[4] = { Point = 128 },
	[5] = { Point = 168 },
	[6] = { Point = 208 },
	[7] = { Point = 248 },
	[8] = { Point = 288 },
}

TopChongZhi.TopChongZhi_Gifts = {
	[1] ={
		{GiftItemID = 20501004, num = 20,},{GiftItemID = 20502004, num = 20,},{GiftItemID = 30008117, num = 1,},{GiftItemID = 38008209, num = 1,}
	,},
	[2] ={
		{GiftItemID = 20501004, num = 50,},{GiftItemID = 20502004, num = 50,},{GiftItemID = 20310166, num = 150,},{GiftItemID = 30900132, num = 2,}
	,},
	[3] ={
		{GiftItemID = 20501004, num = 100,},{GiftItemID = 20502004, num = 100,},{GiftItemID = 20310166, num = 500,},{GiftItemID = 30900132, num = 5,}
	,},
	[4] ={
		{GiftItemID = 20501004, num = 150,},{GiftItemID = 20502004, num = 150,},{GiftItemID = 20310166, num = 500,},{GiftItemID = 30900132, num = 6,}
	,},
	[5] ={
		{GiftItemID = 30008029, num = 20,},{GiftItemID = 30008117, num = 2,},{GiftItemID = 20310166, num = 1000,},{GiftItemID = 30900132, num = 6,}
	,},
	[6] ={
		{GiftItemID = 30008029, num = 30,},{GiftItemID = 30008117, num = 3,},{GiftItemID = 20310166, num = 1000,},{GiftItemID = 30900132, num = 10,}
	,},
	[7] ={
		{GiftItemID = 30008105, num = 1,},{GiftItemID = 20310166, num = 1000,},{GiftItemID = 20310166, num = 1000,},{GiftItemID = 30900132, num = 15,}
	,},
	[8] ={
		{GiftItemID = 38002426, num = 1,},{GiftItemID = 20310166, num = 1000,},{GiftItemID = 20310166, num = 1000,},{GiftItemID = 30900132, num = 20,}
	,},
}

function TopChongZhi:OpenTopChongZhi(selfId,targetId,index)
	local nPoint = self:GetMissionData(selfId, ScriptGlobal.MD_CHANGE_POINTCOUNT)
	local need_tal = self.TopChongZhi_GetGiftsCondition
	local mdid = ScriptGlobal.MD_HUIKUI_1
	local nCurPrize = self:GetMissionData(selfId, mdid)
	local tPirzeFlag = self:MathCilCompute_1_InEx(nCurPrize)
	local allClaimed = true
	for i = 1,self.Openlv do
		if tPirzeFlag[i] ~= 2 then
			allClaimed = false
			break
		end
	end
	-- if allClaimed then
	-- 	self:NotifyTips(selfId,"回馈已全部领取。")
	-- 	return
	-- end
	self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(nPoint)
		self:UICommand_AddInt(0)
		self:UICommand_AddInt(1)
		self:UICommand_AddInt(self.Openlv)
		for i = 1,8 do
			if tPirzeFlag[i] == 2 then
				self:UICommand_AddInt(2)
			elseif nPoint >= need_tal[i].Point then
				self:UICommand_AddInt(1)
			else
				self:UICommand_AddInt(0)
			end
		end
	self:EndUICommand()
	self:DispatchUICommand(selfId,18100001)
end

function TopChongZhi:YBCost_GetPrize(selfId,TargetID,nSelectIdx,flag)
	local need_tbl = self.TopChongZhi_GetGiftsCondition
	local award = self.TopChongZhi_Gifts
	local mdid = ScriptGlobal.MD_HUIKUI_1
	local TopChongZhiTxt = {"một","hai","ba","bốn","năm","sáu","bảy","tám"}
	if not nSelectIdx or nSelectIdx < 1 or nSelectIdx > self.Openlv then
		return
	end
	if not need_tbl[nSelectIdx] or not award[nSelectIdx] then
		self:NotifyTips(selfId,"Yêu cầu hoặc thưởng bất thường.")
		return
	end
	if self:GetLevel(selfId) < 15 then
		self:NotifyTips(selfId,"#{CZHL_200916_22}")
		return
	end
	local nCurPrize = self:GetMissionData(selfId,mdid)
	local tPirzeFlag = self:MathCilCompute_1_InEx(nCurPrize)
	if tPirzeFlag[nSelectIdx] == 2 then
		self:NotifyTips(selfId,string.format("Bạn đã nhận hào tình lễ %s trùng, không nhận lại được.",TopChongZhiTxt[nSelectIdx]))
		return
	end
	local nPoint = self:GetMissionData(selfId, ScriptGlobal.MD_CHANGE_POINTCOUNT)
	if nPoint >= need_tbl[nSelectIdx].Point then
		self:BeginAddItem()
		for i,item in pairs(award[nSelectIdx]) do
			-- if item.GiftItemID == 30900016 then
			-- 	self:AddItem(item.GiftItemID,item.num,true)
			-- else
			-- 	self:AddItem(item.GiftItemID,item.num,false)
			-- end
			self:AddItem(item.GiftItemID,item.num,false)
		end
		if not self:EndAddItem(selfId) then
			return
		end
		tPirzeFlag[nSelectIdx]  = 2;
		nCurPrize = self:MathCilCompute_1_OutEx(tPirzeFlag)
		self:SetMissionData(selfId,mdid,nCurPrize);
		if self:GetMissionData(selfId,mdid) == nCurPrize then
			self:AddItemListToHuman(selfId)
			self:NotifyTips(selfId,string.format("Nhận hào tình lễ %s trùng thành công!",TopChongZhiTxt[nSelectIdx]))
			self:ShowObjBuffEffect(selfId,selfId,-1,18)
			local strGlobalNews = gbk.fromutf8("#PThiếu hiệp #{_INFOUSR%s} tận hiển phong phạm hào hiệp, tại#Ytiệm tiền Tôn Tiến Bảo#G(65,40)#Pở#GLạc Dương#Ptham gia#YNhất Trịch Thiên Kim Hào Tình Lễ#P, nhận#Ghào tình lễ %s trùng")
			self:AddGlobalCountNews(string.format(strGlobalNews, gbk.fromutf8(self:GetName(selfId)),gbk.fromutf8(TopChongZhiTxt[nSelectIdx])), true)
		else
			self:BeginAddItem()
			self:NotifyTips(selfId,"Nhận thất bại")
		end
		self:OpenTopChongZhi(selfId,TargetID,101)
	else
		self:NotifyTips(selfId, string.format("Chưa đạt điều kiện nhận hào tình lễ %s trùng.",TopChongZhiTxt[nSelectIdx]))
		return
	end
end

function TopChongZhi:NotifyTips(selfId,msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return TopChongZhi
