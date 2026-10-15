local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4925 = class("item_4925", script_base)
item_4925.script_id = 334925
function item_4925:OnDefaultEvent(selfId, bagIndex)
end

function item_4925:IsSkillLikeScript(selfId)
    return 1
end

function item_4925:CancelImpacts(selfId)
    return 0
end

function item_4925:OnConditionCheck(selfId)
    local bCanCreate = self:LuaFnGetSceneAttr_CanCreateRascalKiller()
    if bCanCreate then
        self:BeginEvent(self.script_id)
        self:AddText("Không thể sử dụng tại khung cảnh này")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local level = self:GetLevel(selfId)
    if not level or level < 21 then
        self:BeginEvent(self.script_id)
        self:AddText("Cấp độ không đủ cấp 21 không thể sử dụng")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4925:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4925:OnActivateOnce(selfId)
    local nMonsterDataID = self:LuaFnGetSceneAttr_RandomMonsterDataID()
    if nMonsterDataID and nMonsterDataID ~= -1 then
        local posX, posZ = self:LuaFnGetWorldPos(selfId)
        local nObjID = self:LuaFnCreateMonster(nMonsterDataID, posX, posZ, 1, 0, 300026)
        if nObjID and nObjID ~= -1 then
            self:SetCharacterDieTime(nObjID, 600000)
            self:SetCharacterTitle(nObjID, "Kẻ Kết Liễu Treo Máy")
            self:LuaFnSetMonsterExp(nObjID, 0)
            self:LuaFnDisableMonsterDropBox(nObjID)
        end
    end
    return 1
end

function item_4925:OnActivateEachTick(selfId)
    return 1
end

return item_4925
