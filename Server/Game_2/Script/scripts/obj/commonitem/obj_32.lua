local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_32 = class("obj_32", script_base)
obj_32.script_id = 331032
obj_32.g_Impact1 = 3003
obj_32.g_Impact2 = -1
obj_32.g_SpecailObj = 32

function obj_32:OnDefaultEvent(selfId, bagIndex) end

function obj_32:IsSkillLikeScript(selfId) return 1 end

function obj_32:CancelImpacts(selfId) return 0 end

function obj_32:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_32:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_32:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
        local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
        self:CallScriptFunction(50018, "OnItemUsed", selfId, itemTblIndex)
    end
    return 1
end

function obj_32:OnActivateEachTick(selfId) return 1 end

return obj_32
