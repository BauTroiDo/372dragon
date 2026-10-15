local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5803 = class("item_5803", script_base)
item_5803.script_id = 335803
item_5803.g_Impact1 = 5907
item_5803.g_Impact2 = -1
function item_5803:OnDefaultEvent(selfId, bagIndex)
end

function item_5803:IsSkillLikeScript(selfId)
    return 1
end

function item_5803:CancelImpacts(selfId)
    return 0
end

function item_5803:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5803:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5803:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local sMessage = "@*;SrvMsg;ALL:TQLQ_20071218_05;"
        self:BroadMsgByChatPipe(selfId, sMessage, 8)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        local BagIndex = self:TryRecieveItem(selfId, 10141087)
        if BagIndex ~= -1 then
            self:LuaFnItemBind(selfId, BagIndex)
        end
    end
    return 1
end

function item_5803:OnActivateEachTick(selfId)
    return 1
end

return item_5803
