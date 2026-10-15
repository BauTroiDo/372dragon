local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_332300 = class("item_332300", script_base)
item_332300.script_id = 332300
function item_332300:OnDefaultEvent(selfId, bagIndex)
end

function item_332300:IsSkillLikeScript(selfId)
    return 1
end

function item_332300:CancelImpacts(selfId)
    return 0
end

function item_332300:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_332300:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_332300:OnActivateOnce(selfId)
    local YuanBaoPerAct = 240
    self:YuanBao(selfId, -1, 1, YuanBaoPerAct)
    self:ShowNotice(selfId, "Ngươi đã tăng thành công của" .. (YuanBaoPerAct) .. "điểm Nguyên bảo.")
    return 1
end

function item_332300:OnActivateEachTick(selfId)
    return 1
end

function item_332300:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_332300
