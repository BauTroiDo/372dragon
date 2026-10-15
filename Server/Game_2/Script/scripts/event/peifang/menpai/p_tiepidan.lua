local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_tiepidan = class("p_tiepidan", script_base)
p_tiepidan.script_id = 700311
p_tiepidan.g_AbilityNeedLevel = 4
p_tiepidan.g_RecipeId = 311
p_tiepidan.g_SpecialEffectID = 18
function p_tiepidan:OnDefaultEvent(selfId,bagIndex)

end

function p_tiepidan:IsSkillLikeScript(selfId)
return 1
end

function p_tiepidan:CancelImpacts(selfId)
return 0
end

function p_tiepidan:OnConditionCheck(selfId)
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

function p_tiepidan:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_tiepidan:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_tiepidan:OnActivateEachTick(selfId)
return 1
end

return p_tiepidan