local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_wangyan = class("oxingxiu_wangyan", script_base)
oxingxiu_wangyan.g_eventList = {
    229007,
    227000,
    227001,
    227002,
    227003,
    227004,
    227005,
    227006,
    227007,
    227008,
    227009,
    227010,
    227011,
    227012,
    227020,
    227900,
    050061,

    1018799,
    1018800,
    1018801,
}

function oxingxiu_wangyan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Vương Ngạn, ta phát bố nhiệm vụ sư môn Tinh Túc phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_wangyan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oxingxiu_wangyan:OnEventRequest(selfId, targetId, arg, index)
    if arg == 229011 then
        self:CallScriptFunction(
            229011,
            "OnDefaultEvent",
            selfId,
            targetId,
            define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU,
            index
        )
        return
    elseif arg == 050025 then
        self:CallScriptFunction(050025, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU)
        return
    elseif arg == 050061 then
        self:CallScriptFunction(050061, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oxingxiu_wangyan:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function oxingxiu_wangyan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oxingxiu_wangyan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oxingxiu_wangyan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oxingxiu_wangyan:OnDie(selfId, killerId)
end

function oxingxiu_wangyan:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
    for i, findId in pairs(self.g_eventList) do
        if scriptId == findId then
            self:CallScriptFunction(
                scriptId,
                "OnMissionCheck",
                selfId,
                npcid,
                scriptId,
                index1,
                index2,
                index3,
                indexpet
            )
            return
        end
    end
end

return oxingxiu_wangyan
