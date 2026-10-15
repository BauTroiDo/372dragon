local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_xinshouba = class("odali_xinshouba", script_base)
odali_xinshouba.script_id = 002032
odali_xinshouba.g_DuanWuJieDay = {["start"] = 20090528, ["stop1"] = 20090604, ["level"] = 30}

odali_xinshouba.g_eventList = {210210, 210211, 210212, 210246, 808130, 808124, 889062, 889061}

function odali_xinshouba:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Muội muội"
    else
        PlayerSex = "Huynh đệ"
    end
    self:AddText("  " .. PlayerName .. PlayerSex .. "#{OBJ_dali_0014}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:Help_Duanwujie(selfId, targetId)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_xinshouba:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_xinshouba:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    self:SubHelp_Duanwujie(selfId, targetId)
end

function odali_xinshouba:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_xinshouba:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_xinshouba:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_xinshouba:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_xinshouba:OnDie(selfId, killerId)
end

function odali_xinshouba:Help_Duanwujie(selfId, targetId)
    local curDayTime = self:GetTime2Day()
    if curDayTime >= self.g_DuanWuJieDay["start"] and curDayTime <= self.g_DuanWuJieDay["stop1"] then
        self:AddNumText("#{DWJ_090511_02}", 11, 5500)
    end
end

function odali_xinshouba:SubHelp_Duanwujie(selfId, targetId, arg, index)
    local numText = index
    if numText == 5500 then
        self:BeginEvent(self.script_id)
        self:AddText("#{DWJ_090511_03}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return odali_xinshouba
