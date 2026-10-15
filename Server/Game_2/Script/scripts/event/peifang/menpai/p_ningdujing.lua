local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_ningdujing = class("p_ningdujing", script_base)
p_ningdujing.script_id = 700390
p_ningdujing.g_AbilityNeedLevel = 6
p_ningdujing.g_RecipeId = 390
p_ningdujing.g_SpecialEffectID = 18
function p_ningdujing:OnDefaultEvent(selfId,bagIndex)

end

function p_ningdujing:IsSkillLikeScript(selfId)
return 1
end

function p_ningdujing:CancelImpacts(selfId)
return 0
end

function p_ningdujing:OnConditionCheck(selfId)
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

function p_ningdujing:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_ningdujing:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_ningdujing:OnActivateEachTick(selfId)
return 1
end

return p_ningdujing