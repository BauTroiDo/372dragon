local pet_gameplay = require "cy_pet_gameplay"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_6096 = class("item_6096", script_base)
item_6096.g_petCommonId = define.PETCOMMON
item_6096.script_id = 336096
function item_6096:GetPetBookId(selfId)
    local ItemIndexInBag = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local PetBookId = self:LuaFnGetItemTableIndexByIndex(selfId, ItemIndexInBag)
    return PetBookId
end

function item_6096:IsSkillLikeScript(selfId)
    return 1
end

function item_6096:OnConditionCheck(selfId)
    return pet_gameplay.study(self, selfId, false) and 1 or 0
end

function item_6096:OnDeplete(selfId)
    return 1
end

function item_6096:OnActivateOnce(selfId)
    if not pet_gameplay.study(self, selfId, true) then return 0 end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return 1
end

function item_6096:OnActivateEachTick(selfId)
    return 1
end

function item_6096:CancelImpacts(selfId)
    return 0
end

return item_6096
