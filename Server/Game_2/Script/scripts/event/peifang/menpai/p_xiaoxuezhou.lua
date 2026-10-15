local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_xiaoxuezhou = class("p_xiaoxuezhou", script_base)
p_xiaoxuezhou.script_id = 700234
p_xiaoxuezhou.g_AbilityNeedLevel = 1
p_xiaoxuezhou.g_RecipeId = 234
p_xiaoxuezhou.g_SpecialEffectID = 18
function p_xiaoxuezhou:OnDefaultEvent(selfId,bagIndex)

end

function p_xiaoxuezhou:IsSkillLikeScript(selfId)
return 1
end

function p_xiaoxuezhou:CancelImpacts(selfId)
return 0
end

function p_xiaoxuezhou:OnConditionCheck(selfId)
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

function p_xiaoxuezhou:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_xiaoxuezhou:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_xiaoxuezhou:OnActivateEachTick(selfId)
return 1
end

return p_xiaoxuezhou