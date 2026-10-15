local class = require "class"
local define = require "define"
local script_base = require "script_base"
local clean_all_pkvalue = class("clean_all_pkvalue", script_base)
clean_all_pkvalue.script_id = 800112
function clean_all_pkvalue:CheckCost(selfId, targetId, nValue)
    local gb_value = self:LuaFnGetHumanGoodBadValue(selfId)
    if not gb_value or gb_value < nValue * 2000 then
        self:NotifyFail(selfId, "#Yêu cầu#W tiêu trừ sát khí của ngài" .. nValue * 2000 .. "Điểm thiện ác, hiện tại điểm thiện ác của ngài không đủ.",
            targetId)
        return 0
    end
    local money = self:GetMoney(selfId)
    if not money or money < nValue * 50000 then
        self:NotifyFail(selfId, "Tiêu trừ sát khí của ngài yêu cầu tiền bạc #{_MONEY" .. nValue * 50000 .. "}, tiền bạc của ngài không đủ.",
            targetId)
        return 0
    end
    return 1
end

function clean_all_pkvalue:PayForClean(selfId, nValue)
    local gb_value = self:LuaFnGetHumanGoodBadValue(selfId)
    self:LuaFnSetHumanGoodBadValue(selfId, gb_value - (nValue * 2000))
    self:CostMoney(selfId, nValue * 50000)
end

function clean_all_pkvalue:OnDefaultEvent(selfId, targetId)
    local pk_value = self:LuaFnGetHumanPKValue(selfId)
    if pk_value then
    else
        return 0
    end
    if pk_value < 1 then
        self:NotifyFail(selfId, "Ngươi không hề có sát khí", targetId)
        return 0
    end
    if self:CheckCost(selfId, targetId, pk_value) ~= 1 then
        return 0
    end
    self:PayForClean(selfId, pk_value)
    self:SetPKValue(selfId, 0)
    --self:LuaFnAuditGoodbadDecPKValue(selfId, 0)
    self:NotifyFail(selfId, "Ngươi đã thành công tiêu trừ toàn bộ sát khí.", targetId)
end

function clean_all_pkvalue:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Xóa toàn bộ sát khí", 6,1)
end

function clean_all_pkvalue:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function clean_all_pkvalue:NotifyFail(selfId, Tip, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return clean_all_pkvalue
