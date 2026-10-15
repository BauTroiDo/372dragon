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
    self:BeginAddItem()
    self:AddItem(10124962,1)
	self:AddItem(20307213,1)
	self:AddItem(30008201,1)
    local ret = self:EndAddItem(selfId)
	if not ret then
		return 0
	end
    return self:LuaFnVerifyUsedItem(selfId)
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    self:BeginAddItem()
    self:AddItem(10124962,1, true)
	self:AddItem(20307213,1, true)
	self:AddItem(30008201,1, true)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Chúc mừng bạn mở hộp Thiên Cương Tuyết thành công.")
		self:notify_tips(selfId,string.format("Nhận vật phẩm %s.",self:GetItemName(10124962)))
		self:notify_tips(selfId,string.format("Nhận vật phẩm %s.",self:GetItemName(20307213)))
		self:notify_tips(selfId,string.format("Nhận vật phẩm %s.",self:GetItemName(30008201)))
        local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
        self:LuaFnDecItemLayCount(selfId, bag_index, 1)
    end
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
