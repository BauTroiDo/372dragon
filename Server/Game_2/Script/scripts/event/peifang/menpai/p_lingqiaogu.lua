local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_lingqiaogu = class("p_lingqiaogu", script_base)
p_lingqiaogu.script_id = 700277
p_lingqiaogu.g_AbilityNeedLevel = 1
p_lingqiaogu.g_RecipeId = 277
p_lingqiaogu.g_SpecialEffectID = 18
function p_lingqiaogu:OnDefaultEvent(selfId,bagIndex)

end

function p_lingqiaogu:IsSkillLikeScript(selfId)
return 1
end

function p_lingqiaogu:CancelImpacts(selfId)
return 0
end

function p_lingqiaogu:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_ZHIGU)
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

function p_lingqiaogu:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_lingqiaogu:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_lingqiaogu:OnActivateEachTick(selfId)
return 1
end

return p_lingqiaogu