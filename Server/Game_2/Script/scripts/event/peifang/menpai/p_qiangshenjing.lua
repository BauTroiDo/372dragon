local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_qiangshenjing = class("p_qiangshenjing", script_base)
p_qiangshenjing.script_id = 700263
p_qiangshenjing.g_AbilityNeedLevel = 4
p_qiangshenjing.g_RecipeId = 263
p_qiangshenjing.g_SpecialEffectID = 18
function p_qiangshenjing:OnDefaultEvent(selfId,bagIndex)

end

function p_qiangshenjing:IsSkillLikeScript(selfId)
return 1
end

function p_qiangshenjing:CancelImpacts(selfId)
return 0
end

function p_qiangshenjing:OnConditionCheck(selfId)
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

function p_qiangshenjing:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_qiangshenjing:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_qiangshenjing:OnActivateEachTick(selfId)
return 1
end

return p_qiangshenjing