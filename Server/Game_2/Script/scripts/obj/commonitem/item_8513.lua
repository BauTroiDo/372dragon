local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8513 = class("item_8513", script_base)
item_8513.script_id = 338513
function item_8513:OnDefaultEvent(selfId, bagIndex)
end

function item_8513:IsSkillLikeScript(selfId)
    return 1
end

function item_8513:CancelImpacts(selfId)
    return 0
end

function item_8513:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local ret = self:CallScriptFunction(050221, "IsMonster", selfId, 3)
    return ret
end

function item_8513:OnDeplete(selfId)
    return 1
end

function item_8513:OnActivateOnce(selfId)
    local ret = self:CallScriptFunction(050221, "GenerateMonster", selfId, 3)
    if ret == 1 then
        self:LuaFnDepletingUsedItem(selfId)
    end
    return 1
end

function item_8513:OnActivateEachTick(selfId)
    return 1
end

return item_8513
