local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_xuanci = class("oshaolin_xuanci", script_base)
oshaolin_xuanci.g_eventList = {229009, 200089, 200090, 212140, 229012, 808092}

function oshaolin_xuanci:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta thấy việc sư đệ Huyền Bi viên tịch, không hề liên quan đến Đoàn gia Đại Lý.")
    for i, findId in pairs(self.g_eventList) do
        self:CallScriptFunction(self.g_eventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_xuanci:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshaolin_xuanci:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(
                index,
                "OnDefaultEvent",
                selfId,
                targetId,
                define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN
            )
            return
        end
    end
end

function oshaolin_xuanci:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function oshaolin_xuanci:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshaolin_xuanci:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshaolin_xuanci:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oshaolin_xuanci:OnDie(selfId, killerId)
end

return oshaolin_xuanci
