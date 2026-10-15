local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yuelao = class("oluoyang_yuelao", script_base)
oluoyang_yuelao.script_id = 000093
oluoyang_yuelao.g_name = "月老"
oluoyang_yuelao.StartTime = 9040
oluoyang_yuelao.EndTime = 9047
oluoyang_yuelao.g_RelationEventList = {
    806003, 806016, 806005, 806004, 806017, 888901, 808010
}

function oluoyang_yuelao:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_yuelao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0025}")
    self:AddNumText("Kết hôn tửu quán", 11, 10)
    self:AddNumText("Về Tâm Hữu Linh Tê", 11, 11)
    local curDayTime = self:GetDayTime()
    if (curDayTime >= self.StartTime and curDayTime < self.EndTime) then
        self:AddNumText("Về hoạt động Thần Tình Yêu Chi Vẫn", 11, 12)
    end
    for i, eventId in pairs(self.g_RelationEventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_yuelao:OnEventRequest(selfId, targetId, arg, index)
    if self.script_id == arg and index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_066}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self.script_id == arg and index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_102}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self.script_id == arg and index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{QRJ_81009_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_RelationEventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
            return
        end
    end
end

function oluoyang_yuelao:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function oluoyang_yuelao:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

return oluoyang_yuelao
