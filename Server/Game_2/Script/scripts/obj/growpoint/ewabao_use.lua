local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local ewabao_use = class("ewabao_use", script_base)
function ewabao_use:OnUse(selfId, targetId)
    local StoreMapX = self:GetStoreMapX(selfId, targetId)
    local StoreMapZ = self:GetStoreMapZ(selfId, targetId)
    local StoreMapSceneID = self:GetStoreMapSceneID(selfId, targetId)
    local sceneid = self:get_scene():get_id()
    if StoreMapSceneID ~= sceneid then
        return define.USEITEM_SKILL_FAIL
    end
    local HumanX = self:GetHumanWorldX(selfId)
    HumanX = StoreMapX - HumanX
    if math.abs(HumanX) > 2.0 then
        return define.USEITEM_SKILL_FAIL
    end
    local HumanZ = self:GetHumanWorldZ(selfId)
    HumanZ = StoreMapZ - HumanZ
    if math.abs(HumanZ) > 2.0 then
        return define.USEITEM_SKILL_FAIL
    end
    local StoreMapIndex = self:FindStorePointOnScene(0, StoreMapX, StoreMapZ)
    if StoreMapIndex == -1 then
        return define.USEITEM_CANNT_USE
    end
    local StoreMapType = self:GetStorePointType(StoreMapIndex)
    self:DelStorePointOnScene(StoreMapType, StoreMapIndex)
    self:TryRecieveItem(selfId, 10222001)
    return define.USEITEM_SUCCESS
end

return ewabao_use
