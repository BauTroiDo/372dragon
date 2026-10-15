local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_shenqing = class("odali_shenqing", script_base)
odali_shenqing.script_id = 002069
odali_shenqing.g_eventList = {210265}

function odali_shenqing:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex .. ", phải đối đãi tốt với #YTrân thú#W của mình đó. Về #Thao tác#W có gì không hiểu, ta có thể giúp ngươi giải đáp.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Trân Thú bị giảm điểm sinh mệnh thì phải làm sao?", 11, 0)
    self:AddNumText("Trân thú bị giảm độ vui vẻ thì phải làm sao?", 11, 1)
    self:AddNumText("Làm thế nào để tăng Trân Thú Cấp độ", 11, 2)
    self:AddNumText("Làm thế nào để bắt Trân Thú", 11, 3)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_shenqing:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    if index == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#{OBJ_dali_0041}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{OBJ_dali_0042}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{OBJ_dali_0043}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#{OBJ_dali_0044}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function odali_shenqing:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId, missionScriptId)
            end
            return
        end
    end
end

function odali_shenqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:OnDefaultEvent(selfId, targetId)
            return
        end
    end
end

function odali_shenqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_shenqing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_shenqing:OnDie(selfId, killerId)
end

return odali_shenqing
