local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
function common_item:OnDefaultEvent(selfId, bagIndex)
end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89119501)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

function common_item:ConfirmOpenTeQuan(selfId)
    local ItemIndex = 38000206
    if self:LuaFnGetAvailableItemCount(selfId, ItemIndex) < 1 then
        self:notify_tips(selfId, "#{TQJF_221108_42}")
        return 0
    end
    self:LuaFnDelAvailableItem(selfId, ItemIndex, 1)
    self:notify_tips(selfId, "#{TQJF_221108_22}")
    self:BeginUICommand()
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89106202)
    self:SetMissionFlag(selfId, ScriptGlobal.MF_SWEEP_ALL_MONTH_CARD, 1)
    local time = self:TransferNowTime()
    self:SetMissionData(selfId, ScriptGlobal.MD_SweepAll_SeckillTequanData, time)
end

return common_item
