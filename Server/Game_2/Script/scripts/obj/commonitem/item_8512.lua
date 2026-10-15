local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8512 = class("item_8512", script_base)
item_8512.script_id = 338512
function item_8512:OnDefaultEvent(selfId, bagIndex)
end

function item_8512:IsSkillLikeScript(selfId)
    return 1
end

function item_8512:CancelImpacts(selfId)
    return 0
end

function item_8512:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local ret = self:CallScriptFunction(050221, "IsMonster", selfId, 5)
    return ret
end

function item_8512:OnDeplete(selfId)
    return 1
end

function item_8512:OnActivateOnce(selfId)
    local ret = self:CallScriptFunction(050221, "GenerateMonster", selfId, 5)
    if ret == 1 then
        self:LuaFnDepletingUsedItem(selfId)
    end
    return 1
end

function item_8512:OnActivateEachTick(selfId)
    return 1
end

return item_8512
