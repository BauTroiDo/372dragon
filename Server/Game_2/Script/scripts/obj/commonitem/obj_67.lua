local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_67 = class("obj_67", script_base)
obj_67.script_id = 331067
obj_67.g_Impact1 = 3003
obj_67.g_Impact2 = -1
obj_67.g_SpecailObj = 75

function obj_67:OnDefaultEvent(selfId, bagIndex) end

function obj_67:IsSkillLikeScript(selfId) return 1 end

function obj_67:CancelImpacts(selfId) return 0 end

function obj_67:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_67:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_67:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_67:OnActivateEachTick(selfId) return 1 end

return obj_67
