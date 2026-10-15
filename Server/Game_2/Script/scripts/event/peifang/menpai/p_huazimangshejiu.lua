local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_huazimangshejiu = class("p_huazimangshejiu", script_base)
p_huazimangshejiu.script_id = 700252
p_huazimangshejiu.g_AbilityNeedLevel = 7
p_huazimangshejiu.g_RecipeId = 252
p_huazimangshejiu.g_SpecialEffectID = 18
function p_huazimangshejiu:OnDefaultEvent(selfId,bagIndex)

end

function p_huazimangshejiu:IsSkillLikeScript(selfId)
return 1
end

function p_huazimangshejiu:CancelImpacts(selfId)
return 0
end

function p_huazimangshejiu:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_NIANGJIU)
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

function p_huazimangshejiu:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_huazimangshejiu:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_huazimangshejiu:OnActivateEachTick(selfId)
return 1
end

return p_huazimangshejiu