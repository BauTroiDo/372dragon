local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4934 = class("item_4934", script_base)
item_4934.script_id = 334934
item_4934.g_Impact1 = 4934
item_4934.g_Impact2 = -1
function item_4934:OnDefaultEvent(selfId, bagIndex)
end

function item_4934:IsSkillLikeScript(selfId)
    return 1
end

function item_4934:CancelImpacts(selfId)
    return 0
end

function item_4934:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4934:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4934:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:CallScriptFunction(330000, "YianhuaDuihuanBaoshi", selfId)
    end
    return 1
end

function item_4934:OnActivateEachTick(selfId)
    return 1
end

return item_4934
