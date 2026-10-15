local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_pudujing = class("p_pudujing", script_base)
p_pudujing.script_id = 700336
p_pudujing.g_AbilityNeedLevel = 5
p_pudujing.g_RecipeId = 336
p_pudujing.g_SpecialEffectID = 18
function p_pudujing:OnDefaultEvent(selfId,bagIndex)

end

function p_pudujing:IsSkillLikeScript(selfId)
return 1
end

function p_pudujing:CancelImpacts(selfId)
return 0
end

function p_pudujing:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_XUANBINGSHU)
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

function p_pudujing:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_pudujing:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_pudujing:OnActivateEachTick(selfId)
return 1
end

return p_pudujing