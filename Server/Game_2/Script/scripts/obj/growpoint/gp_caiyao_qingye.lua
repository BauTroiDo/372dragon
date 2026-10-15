local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_caiyao_qingye = class("gp_caiyao_qingye", script_base)
gp_caiyao_qingye.g_MainItemId = 20101002
gp_caiyao_qingye.g_SubItemId = 20304005
gp_caiyao_qingye.g_AbilityId = 8
gp_caiyao_qingye.g_AbilityLevel = 1
function gp_caiyao_qingye:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    local ItemCount = math.random(1, 100)
    if ItemCount >= 61 and ItemCount <= 90 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    elseif ItemCount >= 91 and ItemCount <= 100 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 2, self.g_MainItemId, self.g_MainItemId)
    end
    if ItemCount >= 1 and ItemCount <= 12 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_SubItemId)
    elseif ItemCount >= 13 and ItemCount <= 18 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 2, self.g_SubItemId, self.g_SubItemId)
    elseif ItemCount >= 19 and ItemCount <= 20 then
        self:AddItemToBox(
            targetId,
            define.QUALITY_MUST_BE_CHANGE,
            3,
            self.g_SubItemId,
            self.g_SubItemId,
            self.g_SubItemId
        )
    end
end

function gp_caiyao_qingye:OnOpen(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, ABilityID)
    local res = self:OpenCheck(selfId, ABilityID, AbilityLevel)
    return res
end

function gp_caiyao_qingye:OnRecycle(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "GainExperience", selfId, ABilityID, self.g_AbilityLevel)
    return 1
end

function gp_caiyao_qingye:OnProcOver(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "EnergyCostCaiJi", selfId, ABilityID, self.g_AbilityLevel)
    return 0
end

function gp_caiyao_qingye:OpenCheck(selfId, AbilityId, AbilityLevel)
    if AbilityLevel < self.g_AbilityLevel then
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
    if self:GetHumanEnergy(selfId) < (math.floor(self.g_AbilityLevel * 1.5 + 2) * 2) then
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_ENERGY
    end
    return define.OPERATE_RESULT.OR_OK
end

return gp_caiyao_qingye
