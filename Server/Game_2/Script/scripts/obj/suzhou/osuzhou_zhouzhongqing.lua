local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhouzhongqing = class("osuzhou_zhouzhongqing", script_base)
osuzhou_zhouzhongqing.script_id = 892895
osuzhou_zhouzhongqing.g_eventList = { 892891, 892893 }

function osuzhou_zhouzhongqing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{HSLJ_190919_09}")
    self:AddNumText("#{HSLJ_190919_10}", 19, 1000)
    self:AddNumText("#{HSLJ_190919_11}", 6, 1200)
    self:AddNumText("#{HSLJ_190919_270}", 11, 1300)
    self:AddNumText("Đại chiến tuyết nguyên", 19, 2000)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_zhouzhongqing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_zhouzhongqing:OnEventRequest(selfId, targetId, arg, index)
    if index == 1200 then
        if self:GetLevel(selfId) < 60 then
            self:BeginEvent(self.script_id)
            self:AddText("#{HSLJ_190919_55}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        else
            return
        end
    end
    if index == 1300 then
        self:BeginEvent(self.script_id)
        self:AddNumText("#{HSLJ_190919_275}", 11, 1301)
        self:AddNumText("#{HSLJ_190919_276}", 11, 1302)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 1301 then
        self:BeginEvent(self.script_id)
        self:AddText("#{HSLJ_190919_277}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 1302 then
        self:BeginEvent(self.script_id)
        self:AddText("#{HSLJ_190919_278}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 2000 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1289, 50, 50)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
            return
        end
    end
end

function osuzhou_zhouzhongqing:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_zhouzhongqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_zhouzhongqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_zhouzhongqing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_zhouzhongqing:OnDie(selfId, killerId)
end

return osuzhou_zhouzhongqing
