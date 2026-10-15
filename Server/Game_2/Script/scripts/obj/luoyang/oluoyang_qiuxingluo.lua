local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_qiuxingluo = class("oluoyang_qiuxingluo", script_base)
oluoyang_qiuxingluo.script_id = 000122
oluoyang_qiuxingluo.g_eventList = {250551}

function oluoyang_qiuxingluo:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText(
        "Giải đấu Cúc Cầu sắp bắt đầu rồi, ta bận chết mất, nếu ngươi rảnh thì có thể giúp ta nhắn một lời được không?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Nhiệm vụ Lạc Dương gửi thư tửu quán", 11, 10)
    self:AddNumText("Về Giải Đấu Cúc Cầu", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_qiuxingluo:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_qiuxingluo:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_075}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#BVề Đại Tái Xúc Cúc")
        self:AddText("#{CUJU_INFO}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_qiuxingluo:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_qiuxingluo:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_qiuxingluo:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_qiuxingluo:OnMissionSubmit(selfId, targetId, missionScriptId,
                                             selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_qiuxingluo:OnDie(selfId, killerId) end

return oluoyang_qiuxingluo
