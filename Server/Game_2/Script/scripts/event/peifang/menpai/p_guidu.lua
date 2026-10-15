local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_guidu = class("p_guidu", script_base)
p_guidu.script_id = 700359
p_guidu.g_AbilityNeedLevel = 8
p_guidu.g_RecipeId = 359
p_guidu.g_SpecialEffectID = 18
function p_guidu:OnDefaultEvent(selfId,bagIndex)

end

function p_guidu:IsSkillLikeScript(selfId)
return 1
end

function p_guidu:CancelImpacts(selfId)
return 0
end

function p_guidu:OnConditionCheck(selfId)
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

function p_guidu:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_guidu:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_guidu:OnActivateEachTick(selfId)
return 1
end

return p_guidu