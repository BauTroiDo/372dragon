local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_yuanshantie = class("p_yuanshantie", script_base)
p_yuanshantie.script_id = 700313
p_yuanshantie.g_AbilityNeedLevel = 1
p_yuanshantie.g_RecipeId = 313
p_yuanshantie.g_SpecialEffectID = 18
function p_yuanshantie:OnDefaultEvent(selfId,bagIndex)

end

function p_yuanshantie:IsSkillLikeScript(selfId)
return 1
end

function p_yuanshantie:CancelImpacts(selfId)
return 0
end

function p_yuanshantie:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_QIMENDUNJIA)
if not self:LuaFnVerifyUsedItem(selfId) then
return 0
end
if AbilityLevel < self.g_AbilityNeedLevel then
self:BeginEvent(self.script_id)
strText = "Kỹ năng Cấp độ không đủ"
self:AddText(strText)
self:EndEvent()
self:DispatchMissionTips(selfId)
return 0
end
if self:LuaFnIsPrescrLearned(selfId,self.g_RecipeId) then
self:BeginEvent(self.script_id)
strText = "Phương thuốc này đã học được rồi"
self:AddText(strText)
self:EndEvent()
self:DispatchMissionTips(selfId)
return 0
end
return 1
end

function p_yuanshantie:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_yuanshantie:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_yuanshantie:OnActivateEachTick(selfId)
return 1
end

return p_yuanshantie