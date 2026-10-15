local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
common_item.UsedCount_IDX = 1
common_item.MonsterDataID = 50950
function common_item:OnDefaultEvent(selfId, bagIndex)
end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
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
    return 0
end

function common_item:OnActivateOnce(selfId)
    local targetId = self:LuaFnGetTargetObjID(selfId)
    local name = self:GetName(targetId)
    if name ~= "上生台" then
        self:notify_tips(selfId, "Linh Lung Thược·Nhị Giai chỉ mở được Thượng Sinh Đài")
        return 0
    end
    local count = self:MonsterAI_GetIntParamByIndex(targetId, self.UsedCount_IDX)
    count = count + 1
    if count == 18 then
        local x, z = self:GetWorldPos(targetId)
        self:LuaFnCreateMonster(self.MonsterDataID, x, z, 4, define.INVAILD_ID, define.INVAILD_ID)
        self:LuaFnDeleteMonster(targetId)
    else
        local title = string.format("Linh Lung Thược·Nhị Giai %d/%d", count, 18)
        self:SetCharacterTitle(targetId, title)
        self:MonsterAI_SetIntParamByIndex(targetId, self.UsedCount_IDX, count)
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
