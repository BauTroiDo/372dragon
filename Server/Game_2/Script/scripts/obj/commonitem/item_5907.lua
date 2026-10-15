local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5907 = class("item_5907", script_base)
item_5907.script_id = 335907
item_5907.g_Impact1 = 5907
item_5907.g_Impact2 = -1
function item_5907:OnDefaultEvent(selfId, bagIndex)
end

function item_5907:IsSkillLikeScript(selfId)
    return 1
end

function item_5907:CancelImpacts(selfId)
    return 0
end

function item_5907:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5907:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5907:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local sMessage = "@*;SrvMsg;ALL:TQLQ_20071218_05;"
        self:BroadMsgByChatPipe(selfId, sMessage, 8)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_5907:OnActivateEachTick(selfId)
    return 1
end

return item_5907
