local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local BagItemIndex = {
    [38002799] = { 20600009, 20600015, 20600021, 20600027, 20600033, 20600039 },
    [38002800] = { 20600010, 20600016, 20600022, 20600028, 20600034, 20600040 },
    [38002801] = { 20600011, 20600017, 20600023, 20600029, 20600035, 20600041 },
    [38002802] = { 20600012, 20600018, 20600024, 20600030, 20600036, 20600042 },
    [38002803] = { 20600013, 20600019, 20600025, 20600031, 20600037, 20600043 },
    [38002804] = { 20600014, 20600020, 20600026, 20600032, 20600038, 20600044 },
    [38002806] = { 38002799, 38002800, 38002801, 38002802, 38002803, 38002804},
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
    local ItemIndex = self:GetBagItemIndex(selfId, bag_index)
    local materials = BagItemIndex[ItemIndex]
    self:BeginUICommand()
    self:UICommand_AddInt(bag_index)
    for _, itemid in ipairs(materials) do
        self:UICommand_AddInt(itemid)
        self:UICommand_AddInt(1)
    end
    self:UICommand_AddInt(self.script_id)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89006401)
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

function common_item:ClientActivateOnce(selfId, BagIndex, Index)
    local ItemIndex = self:GetBagItemIndex(selfId, BagIndex)
    local materials = BagItemIndex[ItemIndex]
    local Item = materials[Index]
    self:BeginAddItem()
    self:AddItem(Item, 1)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:LuaFnDecItemLayCount(selfId, BagIndex, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 1000)
        local str = self:ContactArgs("#{SDHDRW_220808_24", 1, self:GetItemName(Item))
        self:notify_tips(selfId, str .. "}")
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89006402)
    else
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
    end
end

return common_item
