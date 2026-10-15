local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local cp_abilitylogic = class("cp_abilitylogic", script_base)
cp_abilitylogic.script_id = 701601
cp_abilitylogic.g_EquipGemTable = {}
cp_abilitylogic.g_EquipGemCost = {}
cp_abilitylogic.g_EnergyCostTbl = {}
cp_abilitylogic.g_EnergyCostTbl[define.ABILITY_CAIKUANG] = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
cp_abilitylogic.g_EnergyCostTbl[define.ABILITY_CAIYAO] = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
cp_abilitylogic.g_EnergyCostTbl[define.ABILITY_ZHONGZHI] = {10, 10, 10, 20, 20, 20, 30, 30, 30, 30, 30, 30}

function cp_abilitylogic:CalcQuality(RecipeLevel, AbilityLevel, AbilityMaxLevel, ItemIndex)
    if self:IsEquipItem(ItemIndex) then
        local lEquipPoint = self:GetItemEquipPoint(ItemIndex)
        local lEquipLevel = self:GeEquipReqLevel(ItemIndex)
        if (lEquipPoint == -1) then
            return math.random(0, 49)
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_WEAPON then
            return (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_CAP then
            return 20 + (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_ARMOR then
            return 10 + (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_CUFF then
            return 40 + (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_BOOT then
            return 30 + (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_SASH then
            return 20 + (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_RING then
            return 30 + (lEquipLevel / 10) - 1
        elseif lEquipPoint == define.HUMAN_EQUIP.HEQUIP_NECKLACE then
            return 40 + (lEquipLevel / 10) - 1
        end
    end
    return math.random(0, 49)
end

function cp_abilitylogic:GainExperience(selfId, AbilityID, RecipeLevel)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, AbilityID)
    local MinLevelDisparity = 0
    local MaxLevelDisparity = 1
    local ExpGain = 0
    if AbilityLevel < 1 or AbilityLevel > 12 then
        return
    end
    local ExpLimit
    local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel = self:LuaFnGetAbilityLevelUpConfig(AbilityID, AbilityLevel)
    if ret then
        ExpLimit = currentLevelAbilityExpTop
    end
    local ExpNow = self:GetAbilityExp(selfId, AbilityID)
    if ExpLimit <= ExpNow then
        return
    end
    local LevelDisparity = AbilityLevel - RecipeLevel
    if LevelDisparity < 0 then
        LevelDisparity = 0
    end
    if LevelDisparity <= MinLevelDisparity then
        ExpGain = 100
    elseif LevelDisparity <= MaxLevelDisparity then
        ExpGain = 100 / (LevelDisparity - MinLevelDisparity + 1)
    end
    local Exp = ExpGain + ExpNow
    if Exp > ExpLimit then
        Exp = ExpLimit
    end
    self:SetAbilityExp(selfId, AbilityID, Exp)
end

function cp_abilitylogic:CheckAbilityLevel(selfId, AbilityID)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, AbilityID)
    local ExpPoint = self:GetAbilityExp(selfId, AbilityID)
    local Flag = 0
    if AbilityLevel <= 10 then
        if AbilityLevel * 10 < ExpPoint then
            Flag = 1
        end
    elseif AbilityLevel <= 20 then
        if (10 * 10 + (AbilityLevel - 10) * 20) < ExpPoint then
            Flag = 1
        end
    end
    if Flag > 0 then
        self:SetHumanAbilityLevel(selfId, AbilityID, AbilityLevel + 1)
        self:AddText(selfId, 0, "#Kỹ năng sống##Thăng cấp# rồi!")
    end
end

function cp_abilitylogic:TooManyGems(selfId, EquipPos)
    local GemCount = self:GetGemEmbededCount(selfId, EquipPos)
    if GemCount < 3 then
        return 0
    end
    return 1
end

function cp_abilitylogic:EmbedProc(selfId, EquipBagIndex, GemIndex, MatIndex1, MatIndex2)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_XIANGQIAN)
    local ExpPoint = self:GetAbilityExp(selfId, define.ABILITY_XIANGQIAN)
    local GemQual = self:GetItemQuality(GemIndex)
    local GemType = self:GetItemIndex(GemIndex)
    local odds = 25
    if MatIndex1 == 30900009 then
        odds = 50
    end
    if MatIndex1 == 30900010 then
        odds = 75
    end
    local rand = math.random(100)
    local EnergyCost = GemQual * 2 + 1
    local MyNewEnergy = self:GetHumanEnergy(selfId) - EnergyCost
    if MyNewEnergy < 0 then
        return 4
    end
    local GemCount = self:GetGemEmbededCount(selfId, EquipBagIndex)
    local need_money = self.g_EquipGemCost[GemQual]
    if GemCount == 1 then
        need_money = need_money * 2
    elseif GemCount == 2 then
        need_money = need_money * 3
    end
    local ret = self:LuaFnCostMoney(selfId, need_money)
    if ret ~= 1 then
        return 4
    end
    self:SetHumanEnergy(selfId, MyNewEnergy)
    if odds > rand then
        return 0
    else
        if MatIndex2 == 30900011 then
            if GemQual <= 1 then
                return 1
            else
                return 5
            end
        else
            if GemQual <= 2 then
                return 1
            else
                return 6
            end
        end
    end
end

function cp_abilitylogic:IsGemConflict(Gem1SerialNumber, Gem2SerialNumber)
    return (self:LuaFnGetItemType(Gem1SerialNumber) == self:LuaFnGetItemType(Gem2SerialNumber))
end

function cp_abilitylogic:IsGemFitEquip(selfId, GemSerialNum, EquipBagIndex)
    local EquipType = self:LuaFnGetBagEquipType(selfId, EquipBagIndex)
    local GemType = self:LuaFnGetItemType(GemSerialNum)
    local GemQual = self:GetItemQuality(GemSerialNum)
    local GemCount = self:GetGemEmbededCount(selfId, EquipBagIndex)
    if GemQual <= 0 or GemQual > 9 then
        return 0
    end
    local need_money = self.g_EquipGemCost[GemQual]
    if GemCount == 1 then
        need_money = need_money * 2
    elseif GemCount == 2 then
        need_money = need_money * 3
    end
    local money = self:GetMoney(selfId)
    if money < need_money then
        return 0
    end
    for i = 1, GemCount do
        local GemEmbededType = self:GetGemEmbededType(selfId, EquipBagIndex, i)
        if GemEmbededType == GemType then
            return 0
        end
    end
    if EquipType == -1 then
        return 0
    end
    for i, gem in pairs(self.g_EquipGemTable[EquipType]) do
        if gem == GemType then
            return 1
        end
    end
    return 0
end

function cp_abilitylogic:CalcEnergyCostCaiJi(selfId, AbilityID, BaseLevel)
    if not self.g_EnergyCostTbl[AbilityID] then
        return
    end
    local energyCost = self.g_EnergyCostTbl[AbilityID][BaseLevel]
    if not energyCost then
        energyCost = 0
    end
    return energyCost
end

function cp_abilitylogic:EnergyCostCaiJi(selfId, AbilityID, BaseLevel)
    local energyCost = self:CalcEnergyCostCaiJi(selfId, AbilityID, BaseLevel)
    if energyCost > 0 then
        local curEnergy = self:GetHumanEnergy(selfId)
        curEnergy = curEnergy - energyCost
        if curEnergy < 0 then
            curEnergy = 0
        end
        self:SetHumanEnergy(selfId, curEnergy)
    end
end

function cp_abilitylogic:EnergyCostZhongZhi(selfId, AbilityID, BaseLevel)
    self:EnergyCostCaiJi(selfId, AbilityID, BaseLevel)
end

function cp_abilitylogic:VigorCostZhiYao(selfId, AbilityID, RecipeLevel)
    local cost = 0
    if RecipeLevel < 8 then
        cost = 5 + 5 * RecipeLevel
    else
        cost = 40
    end
    return cost
end

function cp_abilitylogic:VigorCostPengRen(selfId, AbilityID, RecipeLevel)
    local cost = 0
    if RecipeLevel < 8 then
        cost = 5 + 5 * RecipeLevel
    else
        cost = 40
    end
    return cost
end

function cp_abilitylogic:VigorCostDazao(selfId, AbilityID, RecipeLevel)
    local cost = 0
    cost = 5 + 15 * RecipeLevel
    return cost
end

return cp_abilitylogic
