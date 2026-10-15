local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_27 = class("obj_27", script_base)
obj_27.script_id = 300075
obj_27.g_Impact1 = 3003
obj_27.g_Impact2 = -1
obj_27.g_SpecailObj = 78

function obj_27:OnDefaultEvent(selfId, bagIndex) end

function obj_27:IsSkillLikeScript(selfId) return 1 end

function obj_27:CancelImpacts(selfId) return 0 end

function obj_27:OnConditionCheck(selfId)
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_27:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function obj_27:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_27:OnActivateEachTick(selfId) return 1 end

return obj_27
