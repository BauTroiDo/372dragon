local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8510 = class("item_8510", script_base)
item_8510.script_id = 338510
function item_8510:OnDefaultEvent(selfId, bagIndex)
end

function item_8510:IsSkillLikeScript(selfId)
    return 1
end

function item_8510:CancelImpacts(selfId)
    return 0
end

function item_8510:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local ret = self:CallScriptFunction(050221, "IsMonster", selfId, 4)
    return ret
end

function item_8510:OnDeplete(selfId)
    return 1
end

function item_8510:OnActivateOnce(selfId)
    local ret = self:CallScriptFunction(050221, "GenerateMonster", selfId, 4)
    if ret == 1 then
        self:LuaFnDepletingUsedItem(selfId)
    end
    return 1
end

function item_8510:OnActivateEachTick(selfId)
    return 1
end

return item_8510
