local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_jiangmingxuan = class("oshuhe_jiangmingxuan", script_base)
oshuhe_jiangmingxuan.script_id = 001190
oshuhe_jiangmingxuan.g_eventList = {713503, 713562, 713602}

oshuhe_jiangmingxuan.g_MsgInfo = {"#{SHGZ_0612_12}", "#{SHGZ_0620_34}", "#{SHGZ_0620_35}", "#{SHGZ_0620_36}"}

function oshuhe_jiangmingxuan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_jiangmingxuan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_jiangmingxuan:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,  arg, index)
            return
        end
    end
end

function oshuhe_jiangmingxuan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshuhe_jiangmingxuan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_jiangmingxuan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_jiangmingxuan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_jiangmingxuan
