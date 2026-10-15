local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_zhangzhongxing = class("owudang_zhangzhongxing", script_base)
owudang_zhangzhongxing.script_id = 012014
owudang_zhangzhongxing.g_eventList = {
    229002,
    223000,
    223001,
    223002,
    223003,
    223004,
    223005,
    223006,
    223007,
    223008,
    223009,
    223010,
    223011,
    223012,
    223020,
    223900,
    050061,

    1018759,
    1018760,
    1018761
}

function owudang_zhangzhongxing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Trương Trung Hành, ta phát bố nhiệm vụ sư môn phái Võ Đang.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owudang_zhangzhongxing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owudang_zhangzhongxing:OnEventRequest(selfId, targetId, arg, index)
    if index == 229011 then
        self:CallScriptFunction(
            229011,
            "OnDefaultEvent",
            selfId,
            targetId,
            define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG,
            index
        )
        return
    elseif index == 050025 then
        self:CallScriptFunction(050025, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG)
        return
    elseif index == 050061 then
        self:CallScriptFunction(050061, "OnDefaultEvent", selfId, targetId, define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function owudang_zhangzhongxing:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owudang_zhangzhongxing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owudang_zhangzhongxing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owudang_zhangzhongxing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owudang_zhangzhongxing:OnDie(selfId, killerId)
end

function owudang_zhangzhongxing:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
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

return owudang_zhangzhongxing
