local class = require "class"
local define = require "define"
local script_base = require "script_base"
local FeelFeedBack800 = class("FeelFeedBack800", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
FeelFeedBack800.script_id = 792012
local g_FeelFeedBack800_PrizeList = {
    [1] = 
    {
        [1] = { ["ItemID"] = 38002780, ["num"] = 1 },
        [2] = { ["ItemID"] = 30008002, ["num"] = 1 },
        [3] = { ["ItemID"] = 30501361, ["num"] = 5 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 20 },
    },
    [2] = 
    { 
        [1] = { ["ItemID"] = 30900045, ["num"] = 1 },
        [2] = { ["ItemID"] = 20310174, ["num"] = 5 },
        [3] = { ["ItemID"] = 30502002, ["num"] = 20 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 30 },
    },
    [3] = 
    {
        [1] = { ["ItemID"] = 38002779, ["num"] = 1 },
        [2] = { ["ItemID"] = 20310174, ["num"] = 10 },
        [3] = { ["ItemID"] = 30008115, ["num"] = 1 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 50 },
    },
    [4] = 
    { 
        [1] = { ["ItemID"] = 38002519, ["num"] = 10 },
        [2] = { ["ItemID"] = 20310174, ["num"] = 10 },
        [3] = { ["ItemID"] = 30503133, ["num"] = 5 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 50 },
    },
    [5] = 
    { 
        [1] = { ["ItemID"] = 20310168, ["num"] = 100 },
        [2] = { ["ItemID"] = 20310174, ["num"] = 20 },
        [3] = { ["ItemID"] = 38002530, ["num"] = 20 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 50 },
    },
    [6] = 
    { 
        [1] = { ["ItemID"] = 20502003, ["num"] = 10 },
        [2] = { ["ItemID"] = 20310174, ["num"] = 20 },
        [3] = { ["ItemID"] = 38002524, ["num"] = 10 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 50 },
    },
    [7] = { 
        [1] = { ["ItemID"] = 50613004, ["num"] = 1 },
        [2] = { ["ItemID"] = 20310174, ["num"] = 20 },
        [3] = { ["ItemID"] = 20501003, ["num"] = 10 },
        [4] = { ["ItemID"] = 38008005, ["num"] = 100 },
    }
}
local FeelFeedBack800BagSpeace = 
{
    [1] = {["Property"] = 2,["Material"] = 2},
    [2] = {["Property"] = 2,["Material"] = 2},
    [3] = {["Property"] = 2,["Material"] = 2},
    [4] = {["Property"] = 2,["Material"] = 2},
    [5] = {["Property"] = 2,["Material"] = 2},
    [6] = {["Property"] = 2,["Material"] = 2},
    [7] = {["Property"] = 2,["Material"] = 2},
}
function FeelFeedBack800:CheckGetFullPrize(selfId)
    local nLingQu = self:GetMissionDataEx(selfId, 136)
    local IsShowButton = 1
    local IsShowTips = 1
    local nGetNum = 0
    local nTab = {}
    for i = 1, 7 do
        nTab[i] = (math.floor(nLingQu / 10 ^ (i - 1)) % 10)
        if nTab[i] ~= 0 then
            nGetNum = nGetNum + 1
        end
    end
    if nGetNum >= 7 then
        IsShowButton = 0
        IsShowTips = 0
    end
    
    self:BeginUICommand()
    self:UICommand_AddInt(IsShowButton)
    self:UICommand_AddInt(IsShowTips)
    self:EndUICommand()
    --self:DispatchUICommand(selfId,79201201)
	self:DispatchUICommand(selfId,79115006)
end

function FeelFeedBack800:XiaRiZhanLing(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId,79115006)
end

function FeelFeedBack800:GetPrize(selfId, Index)
	if self:GetLevel(selfId) < 15 then
		self:notify_tips(selfId,"#{QRDL_20211229_21}")
		return
	end
    local nLingQu = self:GetMissionDataEx(selfId, 136)
    local nTab = {}
    for i = 1, 7 do
        nTab[i] = (math.floor(nLingQu / 10 ^ (i - 1)) % 10)
    end
    if nTab[Index] == 1 then
        self:NotifySystemMsg(selfId, "#{QRDL_200915_24}")
        return
    end

    local nTime = self:GetMissionDataEx(selfId, 137)
    if Index > (nTime % 100) then
        self:NotifySystemMsg(selfId, "Xin lỗi, thưởng này thuộc Mãn Tửu Tái Ca Hạ Thử Tịch thứ"..tostring(Index).."ngày nữa mới mở, không nhận thưởng được.")
        return
    end
	local item_list =  g_FeelFeedBack800_PrizeList[Index]
    self:BeginAddItem()
	for _, item in ipairs(item_list) do
		self:AddItem(item.ItemID, item.num,true)
	end
    if not self:EndAddItem(selfId) then
        self:NotifySystemMsg(selfId,"Túi hành trang không đủ chỗ")
        return
    end
    local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
    local nBagMaterial = self:LuaFnGetMaterialBagSpace(selfId)
    if nBagsPos < FeelFeedBack800BagSpeace[Index]["Property"] or nBagMaterial < FeelFeedBack800BagSpeace[Index]["Material"] then
        self:NotifySystemMsg(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    nTab[Index]      = 1
    local nFinalData = 0
    for i = 1, 7 do
        nFinalData = nFinalData + nTab[i] * 10 ^ (i - 1)
    end
    self:SetMissionDataEx(selfId, 136, nFinalData)
    self:AddItemListToHuman(selfId)
	for _, item in ipairs(item_list) do
		self:NotifySystemMsg(selfId,string.format("Bạn nhận thành công %s cái %s.",item.num,self:GetItemName(item.ItemID)))
	end
    self:OnOpenMainWindow(selfId)
end

function FeelFeedBack800:OnOpenMainWindow(selfId)
    local nTime = self:GetMissionDataEx(selfId,137)
    local nLingQu = self:GetMissionDataEx(selfId,136)
	local NowTime = self:GetMissionData(selfId,522)
	local NewTime = self:GetDayTime()
    local nSevenDay = self:GetMissionData(selfId, 520)
	if NowTime ~= tonumber(NewTime) then
		if nSevenDay < 7 then
			self:SetMissionData(selfId,520,nSevenDay + 1) --记录登陆天数
		end
		if nTime < 7 then
			self:SetMissionDataEx(selfId,137,nTime + 1) --记录登陆天数
		end
		self:SetMissionData(selfId,522,tonumber(NewTime))
	end
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(nTime)
    self:UICommand_AddInt(nLingQu)
	self:UICommand_AddInt(20231020)
	self:UICommand_AddInt(1)
	self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 79201202)
end

function FeelFeedBack800:NotifySystemMsg(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return FeelFeedBack800
