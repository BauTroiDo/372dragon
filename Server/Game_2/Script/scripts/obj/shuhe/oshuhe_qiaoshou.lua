local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_qiaoshou = class("oshuhe_qiaoshou", script_base)
oshuhe_qiaoshou.script_id = 001199
oshuhe_qiaoshou.g_eventList = {713506, 713565, 713605}

oshuhe_qiaoshou.g_shoptableindex = 62
oshuhe_qiaoshou.g_MsgInfo = {"#{SHGZ_0612_16}", "#{SHGZ_0620_46}", "#{SHGZ_0620_47}", "#{SHGZ_0620_48}"}

function oshuhe_qiaoshou:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Mua Đả Tạo Đồ", 7, 31)
    self:AddNumText("#{INTERFACE_XML_1195}", 7, 32)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_qiaoshou:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_qiaoshou:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 31 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif arg == 32 then
        self:DispatchShopItem(selfId, targetId, 203)
        return 0
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,  arg, index)
            return
        end
    end
end

function oshuhe_qiaoshou:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshuhe_qiaoshou:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_qiaoshou:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_qiaoshou:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_qiaoshou
