local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_xiaomozhou = class("p_xiaomozhou", script_base)
p_xiaomozhou.script_id = 700239
p_xiaomozhou.g_AbilityNeedLevel = 2
p_xiaomozhou.g_RecipeId = 239
p_xiaomozhou.g_SpecialEffectID = 18
function p_xiaomozhou:OnDefaultEvent(selfId,bagIndex)

end

function p_xiaomozhou:IsSkillLikeScript(selfId)
return 1
end

function p_xiaomozhou:CancelImpacts(selfId)
return 0
end

function p_xiaomozhou:OnConditionCheck(selfId)
AbilityLevel = self:QueryHumanAbilityLevel(selfId,define.ABILITY_ZHIDU)
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

function p_xiaomozhou:OnDeplete(selfId)
if self:LuaFnDepletingUsedItem(selfId) then
return 1
end
return 0
end

function p_xiaomozhou:OnActivateOnce(selfId)
self:CallScriptFunction(713501,"ReadRecipe",selfId,self.g_RecipeId)
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_SpecialEffectID,0)
return 1
end

function p_xiaomozhou:OnActivateEachTick(selfId)
return 1
end

return p_xiaomozhou