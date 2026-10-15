local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_30505076 = class("item_30505076", script_base)
item_30505076.script_id = 332001
item_30505076.g_Impact1 = 3004
item_30505076.g_Impact2 = -1
function item_30505076:OnDefaultEvent(selfId, bagIndex)
end

function item_30505076:IsSkillLikeScript(selfId)
    return 1
end

function item_30505076:CancelImpacts(selfId)
    return 0
end

function item_30505076:OnConditionCheck(selfId)
    local nLevel = self:GetLevel(selfId)
    if nLevel < 30 then
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_30505076:OnDeplete(selfId)
    local szTransfer
    local szPlayerName = self:LuaFnGetName(selfId)
    local nItemBagIndex = self:GetBagPosByItemSn(selfId, 30505076)
    if nItemBagIndex >= 0 then
        szTransfer = self:GetBagItemTransfer(selfId, nItemBagIndex)
    end
    local message =
        string.format("#{_INFOUSR%s} dùng một viên Thiên Hạ Đệ Nhất Kỳ Dược #{_INFOMSG%s}, không khỏi cảm thấy toàn thân thư thái, cảm giác công lực bản thân tiến bộ vượt bậc.", szPlayerName, szTransfer)
    self:AddGlobalCountNews(message)
    local ExpBonus = 500000
    self:AddExp(selfId, ExpBonus)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_30505076:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
    end
    return 1
end

function item_30505076:OnActivateEachTick(selfId)
    return 1
end

function item_30505076:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_30505076
