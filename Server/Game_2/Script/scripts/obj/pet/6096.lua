local pet_gameplay = require "cy_pet_gameplay"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_petCommonId = define.PETCOMMON
function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    return pet_gameplay.study(self, selfId, false) and 1 or 0
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:GetPetBookId(selfId)
	local ItemIndexInBag, PetBookId
	ItemIndexInBag = self:LuaFnGetBagIndexOfUsedItem(selfId)	--获取宠物技能书在背包中Index
	PetBookId = self:LuaFnGetItemTableIndexByIndex(selfId, ItemIndexInBag) --获取宠物技能书ID
	return PetBookId
end

function common_item:OnActivateOnce(selfId)
    if not pet_gameplay.study(self, selfId, true) then return 0 end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return 1
end


return common_item