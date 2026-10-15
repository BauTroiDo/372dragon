local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_30505907 = class("item_30505907", script_base)
item_30505907.script_id = 332003
function item_30505907:OnDefaultEvent(selfId, bagIndex)
end

function item_30505907:IsSkillLikeScript(selfId)
    return 1
end

function item_30505907:CancelImpacts(selfId)
    return 0
end

function item_30505907:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local PlayerLevel = self:GetLevel(selfId)
    if PlayerLevel < 75 then
        return 0
    end
    if self:TryCreatePet(selfId, 1) <= 0 then
        self:BeginEvent(self.script_id)
        local strText = "Xin lỗi, ô sủng vật của bạn không có đủ không gian, vui lòng sắp xếp lại khoảng trống sau đó hãy sử dụng."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    return 1
end

function item_30505907:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_30505907:OnActivateOnce(selfId)
    local bCreate = self:TryCreatePet(selfId, 1)
    local PetID_LongBaby = 22209
    if bCreate > 0 then
        self:LuaFnCreatePetToHuman(selfId, PetID_LongBaby, 1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    end
    return 1
end

function item_30505907:OnActivateEachTick(selfId)
    return 1
end

return item_30505907
