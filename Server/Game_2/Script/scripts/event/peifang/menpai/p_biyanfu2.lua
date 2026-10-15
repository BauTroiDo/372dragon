local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_biyanfu2 = class("p_biyanfu2", script_base)
p_biyanfu2.script_id = 700324
p_biyanfu2.g_AbilityNeedLevel = 7
p_biyanfu2.g_RecipeId = 324
p_biyanfu2.g_SpecialEffectID = 18
function p_biyanfu2:OnDefaultEvent(selfId,bagIndex)

end

function p_biyanfu2:IsSkillLikeScript(selfId)
return 1
end

function p_biyanfu2:CancelImpacts(selfId)
return 0
end

function p_biyanfu2:OnConditionCheck(selfId)
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

function p_biyanfu2:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_biyanfu2:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_biyanfu2:OnActivateEachTick(selfId)
return 1
end

return p_biyanfu2