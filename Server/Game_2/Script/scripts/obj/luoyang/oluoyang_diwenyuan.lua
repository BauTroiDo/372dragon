local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_diwenyuan = class("oluoyang_diwenyuan", script_base)
oluoyang_diwenyuan.script_id = 000083
oluoyang_diwenyuan.g_missionName = "Thay đổi trận doanh"
oluoyang_diwenyuan.g_eventList = {250503}

function oluoyang_diwenyuan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText(
        "  Trên tỷ võ trường, sinh tử do mệnh, đã ký vào sinh tử trạng này, thì không được hối hận, ngươi có thể suy nghĩ kỹ rồi!")
    if self:GetCurCamp(selfId) == 1 then
        self:AddNumText("Trở về trận doanh ban đầu", 6, 0)
    else
        self:AddNumText("Thiết lập trận doanh PK", 6, 1)
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_diwenyuan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_diwenyuan:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:SetCurCamp(selfId, 0)
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đã trở về trận doanh ban đầu.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    elseif index == 1 then
        self:SetCurCamp(selfId, 1)
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đã thiết lập trận doanh PK.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_diwenyuan:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oluoyang_diwenyuan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_diwenyuan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_diwenyuan:OnMissionSubmit(selfId, targetId, missionScriptId,
                                            selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_diwenyuan:OnDie(selfId, killerId) end

return oluoyang_diwenyuan
