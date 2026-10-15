local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_zhikeseng = class("oshaolin_zhikeseng", script_base)
oshaolin_zhikeseng.script_id = 009034
oshaolin_zhikeseng.g_eventList = {500061}

function oshaolin_zhikeseng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:AddText("A Di Đà Phật, bần tăng đã chờ đợi lâu rồi. Xin cho phép bần tăng chỉ đường cho thí chủ.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_zhikeseng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshaolin_zhikeseng:OnEventRequest(selfId, targetId, arg, index)
    print("oshaolin_zhikeseng:OnEventRequest =", selfId, targetId, arg, index)
    self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
    return
end

function oshaolin_zhikeseng:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshaolin_zhikeseng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshaolin_zhikeseng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshaolin_zhikeseng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oshaolin_zhikeseng:OnDie(selfId, killerId)
end

return oshaolin_zhikeseng
