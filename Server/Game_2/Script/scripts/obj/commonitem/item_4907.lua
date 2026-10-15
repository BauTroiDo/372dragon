local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4907 = class("item_4907", script_base)
item_4907.g_petCommonId = define.PETCOMMON
item_4907.script_id = 334907
function item_4907:IsSkillLikeScript(selfId)
    return 1
end

function item_4907:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    local petDataID = self:LuaFnGetPetDataIDByGUID(selfId, petGUID_H, petGUID_L)
    if not petDataID or petDataID < 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Không thể hoàn đồng đối với Trân thú chỉ định.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local petTakeLevel = self:GetPetTakeLevel(petDataID)
    if not petTakeLevel or petTakeLevel < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Không thể nhận dạng Cấp độ mang theo của Trân thú.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if petTakeLevel > 85 then
        self:BeginEvent(self.script_id)
        self:AddText("#{95ZSH_081121_01}")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if self:LuaFnPetCanReturnToChild(selfId, petGUID_H, petGUID_L, 0, -1) == 0 then
        return 0
    end
    return 1
end

function item_4907:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4907:OnActivateOnce(selfId)
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    local ret = self:LuaFnPetReturnToChild(selfId, petGUID_H, petGUID_L, 0, -1)
    if (ret) then
        self:BeginEvent(self.script_id)
        self:AddText("Trân thú Hoàn Đồng thành công!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    return 1
end

function item_4907:OnActivateEachTick(selfId)
    return 1
end

function item_4907:CancelImpacts(selfId)
    return 0
end

return item_4907
