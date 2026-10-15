local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8514 = class("item_8514", script_base)
item_8514.script_id = 338514
function item_8514:OnDefaultEvent(selfId, bagIndex)
end

function item_8514:IsSkillLikeScript(selfId)
    return 1
end

function item_8514:CancelImpacts(selfId)
    return 0
end

function item_8514:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local ret = self:CallScriptFunction(050221, "IsMonster", selfId, 2)
    return ret
end

function item_8514:OnDeplete(selfId)
    return 1
end

function item_8514:OnActivateOnce(selfId)
    local ret = self:CallScriptFunction(050221, "GenerateMonster", selfId, 2)
    if ret == 1 then
        self:LuaFnDepletingUsedItem(selfId)
    end
    return 1
end

function item_8514:OnActivateEachTick(selfId)
    return 1
end

return item_8514
