local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_xingxuandan = class("p_xingxuandan", script_base)
p_xingxuandan.script_id = 700349
p_xingxuandan.g_AbilityNeedLevel = 5
p_xingxuandan.g_RecipeId = 349
p_xingxuandan.g_SpecialEffectID = 18
function p_xingxuandan:OnDefaultEvent(selfId,bagIndex)

end

function p_xingxuandan:IsSkillLikeScript(selfId)
return 1
end

function p_xingxuandan:CancelImpacts(selfId)
return 0
end

function p_xingxuandan:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_LIANDAN)
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

function p_xingxuandan:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_xingxuandan:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_xingxuandan:OnActivateEachTick(selfId)
return 1
end

return p_xingxuandan