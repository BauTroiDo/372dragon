local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_xinshoulong = class("odali_xinshoulong", script_base)
odali_xinshoulong.script_id = 002031
odali_xinshoulong.g_startTime = 09097
odali_xinshoulong.g_EndTime = 09150
odali_xinshoulong.g_eventList = {210278,210263,210259,210267}

function odali_xinshoulong:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Muội muội"
    else
        PlayerSex = "Huynh đệ"
    end
    self:BeginEvent(self.script_id)
    local curDayTime = self:GetDayTime()
    if curDayTime >= self.g_startTime and curDayTime <= self.g_EndTime then
        self:AddText("#{XFMTL_20090319_05}")
    else
        self:AddText("#{OBJ_dali_0013}" .. PlayerName .. PlayerSex .. "Há bằng thử tài một phen?")
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_xinshoulong:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_xinshoulong:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function odali_xinshoulong:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_xinshoulong:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_xinshoulong:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_xinshoulong:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_xinshoulong:OnDie(selfId, killerId)
end

return odali_xinshoulong
