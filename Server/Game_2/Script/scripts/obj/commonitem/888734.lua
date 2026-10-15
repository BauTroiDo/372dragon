local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local chartitleinfo = {
    [38002411] = 1072
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
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	if chartitleinfo[nItemId] == nil then
		self:notify_tips(selfId,"Đạo cụ chưa mở.")
		return 0
	end
	if self:LuaFnHaveAgname(selfId,chartitleinfo[nItemId]) then
		self:notify_tips(selfId,"Ngươi đã sở hữu danh hiệu này.")
		return 0
	end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	self:LuaFnAddNewAgname(selfId,chartitleinfo[nItemId])
	self:notify_tips(selfId,"Dùng thành công, đã nhận danh hiệu này.")
    self:LuaFnDecItemLayCount(selfId, bag_index, 1)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
