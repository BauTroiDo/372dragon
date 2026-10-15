local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_shenxingjing = class("p_shenxingjing", script_base)
p_shenxingjing.script_id = 700291
p_shenxingjing.g_AbilityNeedLevel = 7
p_shenxingjing.g_RecipeId = 291
p_shenxingjing.g_SpecialEffectID = 18
function p_shenxingjing:OnDefaultEvent(selfId,bagIndex)

end

function p_shenxingjing:IsSkillLikeScript(selfId)
return 1
end

function p_shenxingjing:CancelImpacts(selfId)
return 0
end

function p_shenxingjing:OnConditionCheck(selfId)
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

function p_shenxingjing:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_shenxingjing:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_shenxingjing:OnActivateEachTick(selfId)
return 1
end

return p_shenxingjing