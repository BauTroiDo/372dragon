local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_benfan = class("otianlong_benfan", script_base)
otianlong_benfan.g_eventList = {
    229004,
    224000,
    224001,
    224002,
    224003,
    224004,
    224005,
    224006,
    224007,
    224008,
    224009,
    224010,
    224011,
    224012,
    224020,
    224900,
    050061,

    1018769,
    1018770,
    1018771
}

function otianlong_benfan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Bần phàm, ta phát bố nhiệm vụ sư môn Thiên Long Tự.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianlong_benfan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function otianlong_benfan:OnEventRequest(selfId, targetId, arg, index)
    if arg == 229011 then
        self:CallScriptFunction(
            229011,
            "OnDefaultEvent",
            selfId,
            targetId,
            define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI,
            index
        )
        return
    elseif arg == 050025 then
        self:CallScriptFunction(050025, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI)
        return
    elseif arg == 050061 then
        self:CallScriptFunction(050061, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function otianlong_benfan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function otianlong_benfan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function otianlong_benfan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function otianlong_benfan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function otianlong_benfan:OnDie(selfId, killerId)
end

function otianlong_benfan:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
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

return otianlong_benfan
