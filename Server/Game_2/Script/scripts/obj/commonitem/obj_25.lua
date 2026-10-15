local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_25 = class("obj_25", script_base)
obj_25.script_id = 331025
obj_25.g_Impact1 = 3003
obj_25.g_Impact2 = -1
obj_25.g_SpecailObj = 25
function obj_25:OnDefaultEvent(selfId, bagIndex) end

function obj_25:IsSkillLikeScript(selfId)
	return 1; 
end

function obj_25:CancelImpacts(selfId) return 0 end

function obj_25:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_25:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_25:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
        local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
        self:CallScriptFunction(50019, "OnItemUsed", selfId, itemTblIndex)
    end
    return 1
end

function obj_25:OnActivateEachTick(selfId) return 1 end

return obj_25
