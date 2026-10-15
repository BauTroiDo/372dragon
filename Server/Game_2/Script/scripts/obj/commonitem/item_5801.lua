local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5801 = class("item_5801", script_base)
item_5801.script_id = 335801
item_5801.g_Impact1 = 5907
item_5801.g_Impact2 = -1
function item_5801:OnDefaultEvent(selfId, bagIndex)
end

function item_5801:IsSkillLikeScript(selfId)
    return 1
end

function item_5801:CancelImpacts(selfId)
    return 0
end

function item_5801:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5801:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5801:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local sMessage = "@*;SrvMsg;ALL:TQLQ_20071218_05;"
        self:BroadMsgByChatPipe(selfId, sMessage, 8)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        local BagIndex = self:TryRecieveItem(selfId, 30008034)
        if BagIndex ~= -1 then
            self:LuaFnItemBind(selfId, BagIndex)
        end
    end
    return 1
end

function item_5801:OnActivateEachTick(selfId)
    return 1
end

return item_5801
