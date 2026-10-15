local class = require "class"
local define = require "define"
local script_base = require "script_base"
local XinShouNew = class("XinShouNew", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
XinShouNew.script_id = 892679
XinShouNew.g_XinShouNew_7DayPrize = {
    [1] = 
    {
        [1] = { ["ItemID"] = 10141246, ["num"] = 1 },
        [2] = { ["ItemID"] = 30900045, ["num"] = 1 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 1 },
    },
    [2] = 
    { 
        [1] = { ["ItemID"] = 38000080, ["num"] = 1 },
        [2] = { ["ItemID"] = 30502000, ["num"] = 20 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 1 },
    },
    [3] = 
    {
        [1] = { ["ItemID"] = 10124229, ["num"] = 1 },
        [2] = { ["ItemID"] = 30008048, ["num"] = 1 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 2 },
    },
    [4] = 
    { 
        [1] = { ["ItemID"] = 50513004, ["num"] = 1 },
        [2] = { ["ItemID"] = 30503133, ["num"] = 5 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 3 },
    },
    [5] = 
    { 
        [1] = { ["ItemID"] = 30900045, ["num"] = 2 },
        [2] = { ["ItemID"] = 30700241, ["num"] = 5 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 5 },
    },
    [6] = 
    { 
        [1] = { ["ItemID"] = 20310168, ["num"] = 100 },
        [2] = { ["ItemID"] = 20502003, ["num"] = 5 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 5 },
    },
    [7] = { 
        [1] = { ["ItemID"] = 50613004, ["num"] = 1 },
        [2] = { ["ItemID"] = 20501003, ["num"] = 5 },
        [3] = { ["ItemID"] = 38008005, ["num"] = 10 },
    }
}
local XinShouNewBagSpeace = 
{
    [1] = {["Property"] = 3,["Material"] = 0},
    [2] = {["Property"] = 3,["Material"] = 0},
    [3] = {["Property"] = 3,["Material"] = 0},
    [4] = {["Property"] = 2,["Material"] = 1},
    [5] = {["Property"] = 3,["Material"] = 0},
    [6] = {["Property"] = 1,["Material"] = 2},
    [7] = {["Property"] = 1,["Material"] = 2},
}
function XinShouNew:CheckGetFullPrize(selfId)
    local nLingQu = self:GetMissionData(selfId, 521)
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
    self:DispatchUICommand(selfId, 89267901)
end

function XinShouNew:Get7DayPrize(selfId, Index)
    local nLingQu = self:GetMissionData(selfId, 521)
    local nTab = {}
    for i = 1, 7 do
        nTab[i] = (math.floor(nLingQu / 10 ^ (i - 1)) % 10)
    end
    if nTab[Index] == 1 then
        self:NotifySystemMsg(selfId, "#{QRDL_200915_24}")
        return
    end

    local nTime = self:GetMissionData(selfId, 520)
    if Index > (nTime % 100) then
        self:NotifySystemMsg(selfId, "Xin lỗi, đăng nhập tích lũy của bạn chưa đủ" .. self:tostring(Index) .. "ngày, không nhận thưởng được.")
        return
    end
    self:BeginAddItem()
        self:AddItem(self.g_XinShouNew_7DayPrize[Index][1]["ItemID"], self.g_XinShouNew_7DayPrize[Index][1]["num"],true)
        self:AddItem(self.g_XinShouNew_7DayPrize[Index][2]["ItemID"], self.g_XinShouNew_7DayPrize[Index][2]["num"],true)
        self:AddItem(self.g_XinShouNew_7DayPrize[Index][3]["ItemID"], self.g_XinShouNew_7DayPrize[Index][3]["num"],true)
    if not self:EndAddItem(selfId) then
        self:NotifySystemMsg(selfId,"Túi hành trang không đủ chỗ")
        return
    end
    local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
    local nBagMaterial = self:LuaFnGetMaterialBagSpace(selfId)
    if nBagsPos < XinShouNewBagSpeace[Index]["Property"] or nBagMaterial < XinShouNewBagSpeace[Index]["Material"] then
        self:NotifySystemMsg(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    self:AddItemListToHuman(selfId)
    nTab[Index]      = 1
    local nFinalData = 0
    for i = 1, 7 do
        nFinalData = nFinalData + nTab[i] * 10 ^ (i - 1)
    end
    self:SetMissionData(selfId, 521, nFinalData)
    self:NotifySystemMsg(selfId,string.format("Bạn nhận thành công %s cái %s.",self.g_XinShouNew_7DayPrize[Index][1]["num"],self:GetItemName(self.g_XinShouNew_7DayPrize[Index][1]["ItemID"])))
    self:NotifySystemMsg(selfId,string.format("Bạn nhận thành công %s cái %s.",self.g_XinShouNew_7DayPrize[Index][2]["num"],self:GetItemName(self.g_XinShouNew_7DayPrize[Index][2]["ItemID"])))
    self:NotifySystemMsg(selfId,string.format("Bạn nhận thành công %s cái %s.",self.g_XinShouNew_7DayPrize[Index][3]["num"],self:GetItemName(self.g_XinShouNew_7DayPrize[Index][3]["ItemID"])))
    self:OnOpenXinShouNewWindow(selfId)
end

function XinShouNew:OnOpenXinShouNewWindow(selfId)
	local NowTime = self:GetMissionData(selfId,522)
	local NewTime = self:GetDayTime()
    local nTime = self:GetMissionData(selfId, 520)
    local nLingQu = self:GetMissionData(selfId, 521)
	local Feek800Day = self:GetMissionDataEx(selfId,137)
	if NowTime ~= tonumber(NewTime) then
		if nTime < 7 then
			self:SetMissionData(selfId,520,nTime + 1) --记录登陆天数
		end
		if Feek800Day < 7 then
			self:SetMissionDataEx(selfId,137,Feek800Day + 1) --记录登陆天数
		end
		self:SetMissionData(selfId,522,tonumber(NewTime))
	end
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(nTime)
    self:UICommand_AddInt(nLingQu)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89267902)
end

function XinShouNew:NotifySystemMsg(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return XinShouNew
