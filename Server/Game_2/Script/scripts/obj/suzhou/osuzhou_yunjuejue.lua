local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local osuzhou_yunjuejue = class("osuzhou_yunjuejue", script_base)
osuzhou_yunjuejue.script_id = 999903

function osuzhou_yunjuejue:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSPVP_211231_24}")
    self:AddNumText("#{ZSPVP_211231_25}", 6, 1)
    self:AddNumText("#{ZSPVP_211231_26}", 6, 2)
    self:AddNumText("#{ZSPVP_211231_81}", 6, 3)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunjuejue:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_yunjuejue:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(value)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89307801)
        return
    end
    if index == 2 then
        local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(value)
        self:UICommand_AddInt(5)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89307802)
        return
    end
    if index == 3 then
        local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
        self:BeginEvent(self.script_id)
        local str = self:ContactArgs("#{ZSPVP_211231_83", value)
        self:AddText(str .. "}")
        self:AddNumText("#{ZSPVP_211231_84}", 6, 4)
        self:AddNumText("#{ZSPVP_211231_85}", 6, 5)
        self:AddNumText("#{ZSPVP_211231_86}", 6, 6)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 4 then
        local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
        if value < 10 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSPVP_211231_87}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginAddItem()
            self:AddItem(38002532, 5, true)
            local r = self:EndAddItem(selfId)
            if r then
                self:AddItemListToHuman(selfId)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
                self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT, value - 10)
                self:notify_tips(selfId, "Lĩnh thưởng thành công.")
                self:OnEventRequest(selfId, targetId, self.script_id, 3)
            else
                self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
            end
        end
        return
    end
    if index == 5 then
        local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
        if value < 4 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSPVP_211231_87}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginAddItem()
            self:AddItem(38002533, 5, true)
            local r = self:EndAddItem(selfId)
            if r then
                self:AddItemListToHuman(selfId)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
                self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT, value - 4)
                self:notify_tips(selfId, "Lĩnh thưởng thành công.")
                self:OnEventRequest(selfId, targetId, self.script_id, 3)
            else
                self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
            end
        end
        return
    end
    if index == 6 then
        local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
        if value < 2 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSPVP_211231_87}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginAddItem()
            self:AddItem(38002534, 5, true)
            local r = self:EndAddItem(selfId)
            if r then
                self:AddItemListToHuman(selfId)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
                self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT, value - 2)
                self:notify_tips(selfId, "Lĩnh thưởng thành công.")
                self:OnEventRequest(selfId, targetId, self.script_id, 3)
            else
                self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
            end
        end
        return
    end
end

local PetSoulExchangeCount = {
    [38002515] = 8, [38002516] = 8, [38002517] = 8, [38002518] = 8, [38002519] = 8,
    [38002520] = 3, [38002521] = 3, [38002522] = 3, [38002523] = 3, [38002524] = 3,
    [38002525] = 1, [38002526] = 1, [38002527] = 1, [38002528] = 1, [38002529] = 1,
}
function osuzhou_yunjuejue:OnPetSoulExchange(selfId, targetId, BagPos_1, BagPos_2, BagPos_3, BagPos_4, BagPos_5, BagPos_6, BagPos_7, BagPos_8)
    local BagPoss = { BagPos_1, BagPos_2, BagPos_3, BagPos_4, BagPos_5, BagPos_6, BagPos_7, BagPos_8 }
    local count = 0
    for _, BagPos in ipairs(BagPoss) do
        local lay_count = self:GetBagItemLayCount(selfId, BagPos)
        local item_index = self:GetBagItemIndex(selfId, BagPos)
        local add_count = PetSoulExchangeCount[item_index]
        if add_count then
            count = count + add_count * lay_count
            self:LuaFnEraseItem(selfId, BagPos)
        end
    end
    local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT, value + count)
    self:OnEventRequest(selfId, targetId, self.script_id, 1)
end

local PetSoulPrizeDrawItems = {
    38002515, 38002516, 38002517, 38002518, 38002519,
    38002520, 38002521, 38002522, 38002523, 38002524
}
function osuzhou_yunjuejue:OnPetSoulPrizeDraw(selfId)
    local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
    if value < 8 then
        self:notify_tips(selfId, "Không đủ điểm Hồn Trần")
        return
    else
        local num = math.random(#PetSoulPrizeDrawItems)
        local itemid = PetSoulPrizeDrawItems[num]
        self:BeginAddItem()
        self:AddItem(itemid, 1, true)
        local r = self:EndAddItem(selfId)
        if r then
            self:AddItemListToHuman(selfId)
            self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT, value - 8)
            self:BeginUICommand()
            self:UICommand_AddInt(-2)
            self:UICommand_AddInt(value)
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(num)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89307802)
        else
            self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        end
    end
end

return osuzhou_yunjuejue
