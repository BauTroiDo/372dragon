local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
function common_item:IsSkillLikeScript()
    return 0
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    return 1
end

function common_item:OnDefaultEvent(selfId, BagPos)
    local visual = self:LuaFnGetEquipVisual(selfId, BagPos)
    local index = self:LuaFnGetExteriorRideIDByVisual(visual)
	if not index then
		return 1
	end
    local add = self:GetEquipCanAddRxpirationTime(selfId, BagPos)
	if add == -1 then
		if self:CheckHaveExteriorRide(selfId,index) then
			self:notify_tips(selfId, "Tọa kỵ vĩnh viễn này bạn đã có, không kích hoạt lại được.")
			return 1
		end
	end
    local ret = self:LuaFnAddRideRxpirationTime(selfId, index, add)
    if not ret then
        return 1
    end
    self:EraseItem(selfId, BagPos )
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    self:ChangePlayerRide(selfId, index)
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return common_item