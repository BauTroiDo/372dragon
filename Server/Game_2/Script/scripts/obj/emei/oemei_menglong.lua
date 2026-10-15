local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_menglong = class("oemei_menglong", script_base)
oemei_menglong.script_id = 015009
oemei_menglong.g_eventList = {
    229003,
    226000,
    226001,
    226002,
    226003,
    226004,
    226005,
    226006,
    226007,
    226008,
    226009,
    226010,
    226011,
    226012,
    226020,
    226900,
    050061,

    1018789,
    1018790,
    1018791
}

function oemei_menglong:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Mạnh Long, ta phát bố nhiệm vụ sư môn của Nga My phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oemei_menglong:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oemei_menglong:OnEventRequest(selfId, targetId, arg, index)
    if index == 229011 then
        self:CallScriptFunction(
            229011,
            "OnDefaultEvent",
            selfId,
            targetId,
            define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI,
            index
        )
        return
    elseif index == 050025 then
        self:CallScriptFunction(050025, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI)
        return
    elseif index == 050061 then
        self:CallScriptFunction(050061, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oemei_menglong:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oemei_menglong:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oemei_menglong:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oemei_menglong:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oemei_menglong:OnDie(selfId, killerId)
end

function oemei_menglong:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
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

return oemei_menglong
