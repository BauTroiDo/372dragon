local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_xiaozhanhuo = class("p_xiaozhanhuo", script_base)
p_xiaozhanhuo.script_id = 700247
p_xiaozhanhuo.g_AbilityNeedLevel = 1
p_xiaozhanhuo.g_RecipeId = 247
p_xiaozhanhuo.g_SpecialEffectID = 18
function p_xiaozhanhuo:OnDefaultEvent(selfId,bagIndex)

end

function p_xiaozhanhuo:IsSkillLikeScript(selfId)
return 1
end

function p_xiaozhanhuo:CancelImpacts(selfId)
return 0
end

function p_xiaozhanhuo:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_SHENGHUOSHU)
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

function p_xiaozhanhuo:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_xiaozhanhuo:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_xiaozhanhuo:OnActivateEachTick(selfId)
return 1
end

return p_xiaozhanhuo