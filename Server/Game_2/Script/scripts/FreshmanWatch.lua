local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local FreshmanWatch = class("FreshmanWatch", script_base)
FreshmanWatch.script_id = 889103
FreshmanWatch.open_lv = 4		--开放次数
FreshmanWatch.g_TimeAndEquipData = {1,3,5,5,5,5,5,5,5,5}
FreshmanWatch.g_TimeItem = 
{
    [1] = {{["itemId"] = 10141192, ["num"] = 1},{["itemId"] = 10141036, ["num"] = 1}},
    [2] = {{["itemId"] = 38000958, ["num"] = 1},{["itemId"] = 10141026, ["num"] = 1},{["itemId"] = 30008027, ["num"] = 1}},
    [3] = {{["itemId"] = 10126621, ["num"] = 1},{["itemId"] = 30310171, ["num"] = 1}}, -- 招财猫是JB个啥啊
    [4] = {{["itemId"] = 30900059, ["num"] = 1},{["itemId"] = 30607000, ["num"] = 1}},
	
    [5] = {{["itemId"] = 10423061, ["num"] = 1},{["itemId"] = 38008005, ["num"] = 1}},
    [6] = {{["itemId"] = 30309008, ["num"] = 1},{["itemId"] = 38008005, ["num"] = 1}},
    [7] = {{["itemId"] = 30607000, ["num"] = 1},{["itemId"] = 38008005, ["num"] = 1}},
    [8] = {{["itemId"] = 10141034, ["num"] = 1},{["itemId"] = 38008005, ["num"] = 1}},
    [9] = {{["itemId"] = 10141024, ["num"] = 1},{["itemId"] = 38008005, ["num"] = 1}},
    [10] = {{["itemId"] = 30008002, ["num"] = 1},{["itemId"] = 31000006, ["num"] = 1},{["itemId"] = 38008005, ["num"] = 1}}
}
function FreshmanWatch:TakeGift(selfId, nState)
    if nState == nil or nState < 0 or nState > self.open_lv then
        return
    end
    local sceneId = self:GetSceneID()
    if sceneId == 77 then
        return
    end
    local nGiftLevel = self:GetMissionDataEx(selfId,114)
    if nGiftLevel ~= (nState - 1) or self.g_TimeItem[nState] == nil then
        self:OpenFreshManTime(selfId)
        return
    end
    self:BeginAddItem()
    for _, nData in pairs(self.g_TimeItem[nState]) do
        self:AddItem(nData["itemId"], nData["num"],true)
    end
    if not self:EndAddItem(selfId,true) then
        return
    end
    -- local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
    -- if nBagsPos < 3 then
        -- self:NotifyTip(selfId,"背包空间不足。")
        -- return
    -- end
    local nNowSelfTime = self:GetMissionDataEx(selfId,115)
    local nLastTime = self:LuaFnGetCurrentTime() - nNowSelfTime
    if nLastTime < 1 or nLastTime < self.g_TimeAndEquipData[nGiftLevel + 1] * 60 then
        self:NotifyTip(selfId, "Chưa tới giờ, xin thử lại sau")
        return
    end
    self:SetMissionDataEx(selfId, 114, nGiftLevel + 1)
    self:SetMissionDataEx(selfId, 115, self:LuaFnGetCurrentTime())
    for _, nData in pairs(self.g_TimeItem[nState]) do
        self:TryRecieveItemWithCount(selfId, nData["itemId"], nData["num"],true)
        self:NotifyTip(selfId, string.format("Ngươi đã nhận quà:#{_ITEM%s}, xem túi",nData["itemId"]))
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    self:OpenFreshManTime(selfId)
end

function FreshmanWatch:OpenFreshManTime(selfId)
    local g_State = self:GetMissionDataEx(selfId, 114)
    self:BeginUICommand()
    if g_State >= self.open_lv then
        self:UICommand_AddInt(0)
        self:UICommand_AddInt(0)
    else
        self:UICommand_AddInt(g_State + 1)
        self:UICommand_AddInt(self.g_TimeAndEquipData[g_State + 1])
    end
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 889103)
end

function FreshmanWatch:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return FreshmanWatch
