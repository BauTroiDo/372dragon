local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_58 = class("obj_58", script_base)
obj_58.script_id = 331058
obj_58.g_Impact1 = 3003
obj_58.g_Impact2 = -1
obj_58.g_SpecailObj = 64

function obj_58:OnDefaultEvent(selfId, bagIndex) end

function obj_58:IsSkillLikeScript(selfId) return 1 end

function obj_58:CancelImpacts(selfId) return 0 end

function obj_58:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_58:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_58:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_58:OnActivateEachTick(selfId) return 1 end

return obj_58
