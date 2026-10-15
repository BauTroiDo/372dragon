local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_2 = class("obj_2", script_base)
obj_2.script_id = 331002
obj_2.g_Impact1 = 3003
obj_2.g_Impact2 = -1
obj_2.g_SpecailObj = 2
function obj_2:OnDefaultEvent(selfId, bagIndex) end
function obj_2:IsSkillLikeScript(selfId) return 1 end
function obj_2:CancelImpacts(selfId) return 0 end
function obj_2:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_2:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_2:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_2:OnActivateEachTick(selfId) return 1 end

return obj_2
