local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_bidufu = class("p_bidufu", script_base)
p_bidufu.script_id = 700325
p_bidufu.g_AbilityNeedLevel = 1
p_bidufu.g_RecipeId = 325
p_bidufu.g_SpecialEffectID = 18
function p_bidufu:OnDefaultEvent(selfId,bagIndex)

end

function p_bidufu:IsSkillLikeScript(selfId)
return 1
end

function p_bidufu:CancelImpacts(selfId)
return 0
end

function p_bidufu:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_ZHIFU)
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

function p_bidufu:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_bidufu:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_bidufu:OnActivateEachTick(selfId)
return 1
end

return p_bidufu