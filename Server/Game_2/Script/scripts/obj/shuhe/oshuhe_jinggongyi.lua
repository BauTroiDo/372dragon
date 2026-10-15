local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_jinggongyi = class("oshuhe_jinggongyi", script_base)
oshuhe_jinggongyi.script_id = 001200
oshuhe_jinggongyi.g_eventList = {713507, 713566, 713606}

oshuhe_jinggongyi.g_shoptableindex = 69
oshuhe_jinggongyi.g_MsgInfo = {"#{SHGZ_0612_17}", "#{SHGZ_0620_49}", "#{SHGZ_0620_50}", "#{SHGZ_0620_51}"}

function oshuhe_jinggongyi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Mua Đả Tạo Đồ", 7, 32)
    self:AddNumText("#{INTERFACE_XML_1196}", 7, 33)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_jinggongyi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_jinggongyi:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 32 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif arg == 33 then
        self:DispatchShopItem(selfId, targetId, 204)
        return 0
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,  arg, index)
            return
        end
    end
end

function oshuhe_jinggongyi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshuhe_jinggongyi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_jinggongyi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_jinggongyi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_jinggongyi
