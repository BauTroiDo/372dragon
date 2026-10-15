local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_yandu = class("p_yandu", script_base)
p_yandu.script_id = 700385
p_yandu.g_AbilityNeedLevel = 6
p_yandu.g_RecipeId = 385
p_yandu.g_SpecialEffectID = 18
function p_yandu:OnDefaultEvent(selfId,bagIndex)

end

function p_yandu:IsSkillLikeScript(selfId)
return 1
end

function p_yandu:CancelImpacts(selfId)
return 0
end

function p_yandu:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_ZHIDU)
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

function p_yandu:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_yandu:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_yandu:OnActivateEachTick(selfId)
return 1
end

return p_yandu