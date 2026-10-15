local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_caikuang_xuantiekuang = class("gp_caikuang_xuantiekuang", script_base)
gp_caikuang_xuantiekuang.g_MainItemId = 20103006
gp_caikuang_xuantiekuang.g_SubItemId = 50112001
gp_caikuang_xuantiekuang.g_Byproduct = {20103018, 20103030, 20103042, 20103054}

gp_caikuang_xuantiekuang.g_AbilityId = 7
gp_caikuang_xuantiekuang.g_AbilityLevel = 6
function gp_caikuang_xuantiekuang:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    local ItemCount = math.random(1, 100)
    if ItemCount >= 61 and ItemCount <= 90 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    elseif ItemCount >= 91 and ItemCount <= 100 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 2, self.g_MainItemId, self.g_MainItemId)
    end
    if ItemCount == 1 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_SubItemId)
    end
    if ItemCount >= 51 and ItemCount <= 70 then
        local ByproductId = math.random(1, 4)
        if ItemCount >= 51 and ItemCount <= 62 then
            self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_Byproduct[ByproductId])
        elseif ItemCount >= 63 and ItemCount <= 68 then
            self:AddItemToBox(
                targetId,
                define.QUALITY_MUST_BE_CHANGE,
                2,
                self.g_Byproduct[ByproductId],
                self.g_Byproduct[ByproductId]
            )
        elseif ItemCount >= 69 and ItemCount <= 70 then
            self:AddItemToBox(
                targetId,
                define.QUALITY_MUST_BE_CHANGE,
                3,
                self.g_Byproduct[ByproductId],
                self.g_Byproduct[ByproductId],
                self.g_Byproduct[ByproductId]
            )
        end
    end
end

function gp_caikuang_xuantiekuang:OnOpen(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, ABilityID)
    local res = self:OpenCheck(selfId, ABilityID, AbilityLevel)
    return res
end

function gp_caikuang_xuantiekuang:OnRecycle(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "GainExperience", selfId, ABilityID, self.g_AbilityLevel)
    return 1
end

function gp_caikuang_xuantiekuang:OnProcOver(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "EnergyCostCaiJi", selfId, ABilityID, self.g_AbilityLevel)
    return 0
end

function gp_caikuang_xuantiekuang:OpenCheck(selfId, AbilityId, AbilityLevel)
    if AbilityLevel < self.g_AbilityLevel then
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
    if self:GetHumanEnergy(selfId) < (math.floor(self.g_AbilityLevel * 1.5 + 2) * 2) then
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_ENERGY
    end
    return define.OPERATE_RESULT.OR_OK
end

return gp_caikuang_xuantiekuang
