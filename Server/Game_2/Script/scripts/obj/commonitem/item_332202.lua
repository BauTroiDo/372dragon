local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_332202 = class("item_332202", script_base)
item_332202.script_id = 332202
item_332202.g_DarkBox = 30008010
function item_332202:OnDefaultEvent(selfId, bagIndex)
end

function item_332202:IsSkillLikeScript(selfId)
    return 1
end

function item_332202:CancelImpacts(selfId)
    return 0
end

function item_332202:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_332202:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_332202:OnActivateOnce(selfId)
    self:ShowNotice(selfId, "Hãy đến Nguyên bảo cửa hàng mua Ám Kim Khóa rồi mới có thể mở được bảo rương.")
    return 1
end

function item_332202:OnActivateEachTick(selfId)
    return 1
end

function item_332202:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_332202
