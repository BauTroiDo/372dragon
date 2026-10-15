local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
function common_item:OnDefaultEvent(selfId, bagIndex)
end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    return 0
end

function common_item:OnActivateOnce(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 810209111)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
