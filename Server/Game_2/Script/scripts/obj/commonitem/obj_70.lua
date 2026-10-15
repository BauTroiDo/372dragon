local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_70 = class("obj_70", script_base)
obj_70.script_id = 331070
obj_70.g_Impact1 = 3003
obj_70.g_Impact2 = -1
obj_70.g_SpecailObj = 93

function obj_70:OnDefaultEvent(selfId, bagIndex) end

function obj_70:IsSkillLikeScript(selfId) return 1 end

function obj_70:CancelImpacts(selfId) return 0 end

function obj_70:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_70:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_70:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_70:OnActivateEachTick(selfId) return 1 end

return obj_70
