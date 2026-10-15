local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
function common_item:OnDefaultEvent(selfId, bagIndex)

end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bagspace = self:LuaFnGetPropertyBagSpace(selfId)
    if bagspace < 1 then
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    local item_count = self:LuaFnGetAvailableItemCount(selfId, 38002745)
    if item_count < 1 then
        self:notify_tips(selfId, "Hộp thú hồn Cùng Kỳ không tồn tại")
        return 0
    end
    local bagspace = self:LuaFnGetPropertyBagSpace(selfId)
    if bagspace < 1 then
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        return 0
    end
    local r = self:LuaFnDelAvailableItem(selfId, 38002745, 1)
    if not r then
        self:notify_tips(selfId, "Hộp thú hồn Cùng Kỳ không tồn tại")
        return 0
    end
    local BagPos = self:TryRecieveItem(selfId, 70600015)
    -- self:SetPetSoulLevel(selfId, BagPos, 4)
	local human = self:get_scene():get_obj_by_id(selfId)
	local prop_bag_container = human:get_prop_bag_container()
	local item = prop_bag_container:get_item(BagPos)
	item:get_pet_equip_data():set_pet_soul_level(4)
	self:LuaFnRefreshItemInfo(selfId, BagPos)
    return 1
end

function common_item:SetPetSoulLevel(selfId, BagPos, level)
	if 0 == 0 then return end
	--不开放这里，可以call任意兽魂任意阶级
	local human = self:get_scene():get_obj_by_id(selfId)
	local prop_bag_container = human:get_prop_bag_container()
	local item = prop_bag_container:get_item(BagPos)
	item:get_pet_equip_data():set_pet_soul_level(level)
	self:LuaFnRefreshItemInfo(selfId, BagPos)
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
