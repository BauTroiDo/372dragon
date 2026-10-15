local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
common_item.script_id = 300112
function common_item:OnDefaultEvent(selfId, bagIndex)
end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
	local targetX,targetZ = 139,169
	local PlayerX = self:GetHumanWorldX(selfId)
	local PlayerZ = self:GetHumanWorldZ(selfId)
	local Distance = math.floor(math.sqrt((targetX-PlayerX)*(targetX-PlayerX)+(targetZ-PlayerZ)*(targetZ-PlayerZ)))
	if Distance > 5 then
		self:notify_tips(selfId,"Cách chỗ bắn pháo hoa hỷ khánh còn"..Distance.."gạo")
		return 0
	end
	if self:IsHaveMission(selfId,1417) then
		if self:HaveItemInBag(selfId,30505273) then
			self:DelItem(selfId,30505273)
			self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,113,0)
			self:notify_tips(selfId, "Thi phóng Hỉ Khánh Pháo Hoa thành công, mau trở về tìm Triệu Thiên Sư đi.")
			local misIndex = self:GetMissionIndexByID(selfId,1417)
			self:SetMissionByIndex(selfId,misIndex,0,1)
			self:SetMissionByIndex(selfId,misIndex,1,1)
		end
	end
    return 0
end

function common_item:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 1
end

function common_item:OnActivateOnce(selfId)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
