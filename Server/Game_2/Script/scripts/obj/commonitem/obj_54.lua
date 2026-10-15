local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_54 = class("obj_54", script_base)
obj_54.script_id = 331054
obj_54.g_Impact1 = 3003
obj_54.g_Impact2 = -1
obj_54.g_SpecailObj = 60

function obj_54:OnDefaultEvent(selfId, bagIndex) end

function obj_54:IsSkillLikeScript(selfId) return 1 end

function obj_54:CancelImpacts(selfId) return 0 end

function obj_54:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_54:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_54:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_54:OnActivateEachTick(selfId) return 1 end

return obj_54
