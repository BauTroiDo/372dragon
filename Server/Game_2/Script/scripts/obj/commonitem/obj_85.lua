local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_85 = class("obj_85", script_base)
obj_85.script_id = 331085
obj_85.g_Impact1 = 3003
obj_85.g_Impact2 = -1
obj_85.g_SpecailObj = 158

function obj_85:OnDefaultEvent(selfId, bagIndex) end

function obj_85:IsSkillLikeScript(selfId) return 1 end

function obj_85:CancelImpacts(selfId) return 0 end

function obj_85:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_85:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_85:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_85:OnActivateEachTick(selfId) return 1 end

return obj_85
