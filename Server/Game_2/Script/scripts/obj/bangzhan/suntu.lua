local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suntu = class("suntu", script_base)
suntu.script_id = 402295
suntu.g_eventList = {701603}

suntu.g_healScriptId = 000064
function suntu:UpdateEventList(selfId, targetId)
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_23}")
        self:AddNumText("治疗", 6, 0)
        self:EndEvent()
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_20}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function suntu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function suntu:OnEventRequest(selfId, targetId, arg, index)
    local gld = self:CallScriptFunction(self.g_healScriptId, "CalcMoney_hpmp", selfId, targetId) * 0.1
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 0 then
        return
    end
    local key = index
    if key == 1000 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if key == 1001 then
        gld = self:CallScriptFunction(self.g_healScriptId, "CalcMoney_hpmp", selfId, targetId) * 0.1
        local money = self:GetMoney(selfId)
        local JiaoZi = self:GetMoneyJZ(selfId)
        gld = math.floor(gld)
        if money + JiaoZi < gld then
            self:BeginEvent(self.script_id)
            self:AddText("#{BHXZ_081103_85}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:LuaFnCostMoneyWithPriority(selfId, gld)
            self:CallScriptFunction(self.g_healScriptId, "Restore_hpmp", selfId, targetId)
        end
        return
    end
    if key == 0 then
        if
            self:GetHp(selfId) == self:GetMaxHp(selfId) and self:GetRage(selfId) == self:GetMaxRage(selfId) and
                self:GetMp(selfId) == self:GetMaxMp(selfId)
         then
            self:BeginEvent(self.script_id)
            self:AddText("#{BHXZ_081103_86}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            self:LuaFnDispelAllHostileImpacts(selfId)
            return
        end
        if gld <= 0 then
            self:CallScriptFunction(self.g_healScriptId, "Restore_hpmp", selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("#{BHXZ_081103_87}#{_EXCHG" .. gld .. "}#{BHXZ_081103_88}")
            self:AddNumText("là", -1, 1001)
            self:AddNumText("không", -1, 1000)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    else
        for i, findId in pairs(self.g_eventList) do
            if arg == findId then
                self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
                return
            end
        end
    end
end

function suntu:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function suntu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function suntu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function suntu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function suntu:OnDie(selfId, killerId)
end

return suntu
