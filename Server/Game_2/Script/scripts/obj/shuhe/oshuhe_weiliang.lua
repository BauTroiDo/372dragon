local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_weiliang = class("oshuhe_weiliang", script_base)
oshuhe_weiliang.script_id = 001189
oshuhe_weiliang.g_eventList = {713509, 713568, 713608}

oshuhe_weiliang.g_shoptableindex = 73
oshuhe_weiliang.g_MsgInfo = {"#{SHGZ_0612_11}", "#{SHGZ_0620_31}", "#{SHGZ_0620_32}", "#{SHGZ_0620_33}"}

function oshuhe_weiliang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Mua công cụ", 6, 29)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_weiliang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_weiliang:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 29 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
        return 0
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,  arg, index)
            return
        end
    end
end

function oshuhe_weiliang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshuhe_weiliang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_weiliang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_weiliang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_weiliang
