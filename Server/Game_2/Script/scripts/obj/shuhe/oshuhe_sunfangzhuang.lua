local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_sunfangzhuang = class("oshuhe_sunfangzhuang", script_base)
oshuhe_sunfangzhuang.script_id = 001198
oshuhe_sunfangzhuang.g_eventList = {713510, 713569, 713609}

oshuhe_sunfangzhuang.g_shoptableindex = 73
oshuhe_sunfangzhuang.g_MsgInfo = {"#{SHGZ_0612_15}", "#{SHGZ_0620_43}", "#{SHGZ_0620_44}", "#{SHGZ_0620_45}"}

function oshuhe_sunfangzhuang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Mua công cụ", 7, 30)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_sunfangzhuang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_sunfangzhuang:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 30 then
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

function oshuhe_sunfangzhuang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshuhe_sunfangzhuang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_sunfangzhuang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_sunfangzhuang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_sunfangzhuang
