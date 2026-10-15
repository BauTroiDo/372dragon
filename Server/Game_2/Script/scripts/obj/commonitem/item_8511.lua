local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8511 = class("item_8511", script_base)
item_8511.script_id = 338511
function item_8511:OnDefaultEvent(selfId, bagIndex)
end

function item_8511:IsSkillLikeScript(selfId)
    return 1
end

function item_8511:CancelImpacts(selfId)
    return 0
end

function item_8511:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local ret = self:CallScriptFunction(050221, "IsMonster", selfId, 1)
    return ret
end

function item_8511:OnDeplete(selfId)
    return 1
end

function item_8511:OnActivateOnce(selfId)
    local ret = self:CallScriptFunction(050221, "GenerateMonster", selfId, 1)
    if ret == 1 then
        self:LuaFnDepletingUsedItem(selfId)
    end
    return 1
end

function item_8511:OnActivateEachTick(selfId)
    return 1
end

return item_8511
