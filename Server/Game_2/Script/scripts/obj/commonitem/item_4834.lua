local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4834 = class("item_4834", script_base)
item_4834.g_petCommonId = define.PETCOMMON
item_4834.script_id = 334834
function item_4834:IsSkillLikeScript(selfId)
    return 1
end

function item_4834:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    if self:LuaFnGetPetLevelByGUID(selfId, petGUID_H, petGUID_L) >= 70 then
        self:BeginEvent(self.script_id)
        self:AddText("Trân Thú của ngài vượt quá cấp 70, xin dùng Cao cấp Hoàn Đồng Đan để hoàn đồng.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
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

function item_4834:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4834:OnActivateOnce(selfId)
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    local ret = self:LuaFnPetReturnToChild(selfId, petGUID_H, petGUID_L, 0, -1)
    if ret then
        self:BeginEvent(self.script_id)
        self:AddText("Trân thú Hoàn Đồng thành công!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    return 1
end

function item_4834:OnActivateEachTick(selfId)
    return 1
end

function item_4834:CancelImpacts(selfId)
    return 0
end

return item_4834
