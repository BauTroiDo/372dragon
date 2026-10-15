local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local Awards = {
    [38002985] = {10158014, 10158015, 10158016, 10158017, 10158018, 10158019, 10158020},
    [38002986] = {10158021, 10158022, 10158023, 10158024, 10158025, 10158026, 10158027},
}

function common_item:OnDefaultEvent(selfId, bagIndex)

end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
    return self:LuaFnVerifyUsedItem(selfId)
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local BagItemIndex = self:GetBagItemIndex(selfId, bag_index)
    self:BeginUICommand()
    self:UICommand_AddInt(bag_index)
    self:UICommand_AddInt(BagItemIndex)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89027601)
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

function common_item:PickUpItem(selfId, ItemId, BagIndex, Index)
    local BagItemIndex = self:GetBagItemIndex(selfId, BagIndex)
    local Item = Awards[BagItemIndex][Index]
    self:BeginAddItem()
    self:AddItem(Item, 1, true)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:LuaFnDecItemLayCount(selfId, BagIndex, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 1000)
        local str = self:ContactArgs("#{SQYD_230802_78", 1, self:GetItemName(Item))
        self:notify_tips(selfId, str .. "}")
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89027602)
    else
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
    end
end

return common_item
