local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_qinguan = class("oxiaoyao_qinguan", script_base)
oxiaoyao_qinguan.g_eventList = {
    229005,
    225000,
    225001,
    225002,
    225003,
    225004,
    225005,
    225006,
    225007,
    225008,
    225009,
    225010,
    225011,
    225012,
    225020,
    225900,
    050061,

    1018779,
    1018780,
    1018781
}

function oxiaoyao_qinguan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Tần Quan, ta phát nhiệm vụ sư môn phái Tiêu Dao.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiaoyao_qinguan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oxiaoyao_qinguan:OnEventRequest(selfId, targetId, arg, index)
    if arg == 229011 then
        self:CallScriptFunction(
            229011,
            "OnDefaultEvent",
            selfId,
            targetId,
            define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO,
            index
        )
        return
    elseif arg == 050025 then
        self:CallScriptFunction(050025, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO)
        return
    elseif arg == 050061 then
        self:CallScriptFunction(050061, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oxiaoyao_qinguan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oxiaoyao_qinguan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oxiaoyao_qinguan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oxiaoyao_qinguan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oxiaoyao_qinguan:OnDie(selfId, killerId)
end

function oxiaoyao_qinguan:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
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

return oxiaoyao_qinguan
