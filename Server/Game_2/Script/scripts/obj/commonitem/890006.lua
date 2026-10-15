local class = require "class"
local define = require "define"
local script_base = require "script_base"
local commonitem = class("commonitem", script_base)
commonitem.script_id = 890006
local tbl = { [30103061] = 1, [30103062] = 1}
function commonitem:OnDefaultEvent(selfId, bagIndex)
end

function commonitem:IsSkillLikeScript(selfId)
    return 1
end

function commonitem:CancelImpacts(selfId)
    return 0
end

function commonitem:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function commonitem:OnDeplete(selfId)
    return 1
end

function commonitem:OnActivateOnce(selfId)
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local ItemIndex = self:GetBagItemIndex(selfId, bag_index)
    local id = tbl[ItemIndex]
    local day = self:GetTime2Day2()
    self:ActiveRmbChatInfo(selfId, id, day)
    self:EraseItem(selfId, bag_index)
    return 1
end

function commonitem:OnActivateEachTick(selfId)
    return 1
end

return commonitem
