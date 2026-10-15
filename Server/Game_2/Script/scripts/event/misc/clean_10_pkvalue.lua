local class = require "class"
local define = require "define"
local script_base = require "script_base"
local clean_10_pkvalue = class("clean_10_pkvalue", script_base)
clean_10_pkvalue.script_id = 800111
clean_10_pkvalue.g_ModScript = 800112
function clean_10_pkvalue:OnDefaultEvent(selfId, targetId)
    local pk_value = self:LuaFnGetHumanPKValue(selfId)
    if pk_value then
    else
        return 0
    end
    if pk_value < 10 then
        self:NotifyFail(selfId, "Sát Khí của ngươi không đủ 10 điểm", targetId)
        return 0
    end
    if self:CallScriptFunction(self.g_ModScript, "CheckCost", selfId, targetId, 10) ~= 1 then
        return 0
    end
    self:CallScriptFunction(self.g_ModScript, "PayForClean", selfId, 10)
    self:SetPKValue(selfId, pk_value - 10)
    --self:LuaFnAuditGoodbadDecPKValue(selfId, 10)
    self:NotifyFail(selfId, "Ngươi đã thành công tiêu trừ 10 điểm sát khí.", targetId)
    return 1
end

function clean_10_pkvalue:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Tiêu trừ 10 điểm sát khí", 6, 2)
end

function clean_10_pkvalue:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function clean_10_pkvalue:NotifyFail(selfId, Tip, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return clean_10_pkvalue
