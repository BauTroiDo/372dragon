local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_zhuanggujing = class("p_zhuanggujing", script_base)
p_zhuanggujing.script_id = 700262
p_zhuanggujing.g_AbilityNeedLevel = 1
p_zhuanggujing.g_RecipeId = 262
p_zhuanggujing.g_SpecialEffectID = 18
function p_zhuanggujing:OnDefaultEvent(selfId,bagIndex)

end

function p_zhuanggujing:IsSkillLikeScript(selfId)
return 1
end

function p_zhuanggujing:CancelImpacts(selfId)
return 0
end

function p_zhuanggujing:OnConditionCheck(selfId)
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

function p_zhuanggujing:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_zhuanggujing:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_zhuanggujing:OnActivateEachTick(selfId)
return 1
end

return p_zhuanggujing