local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojingji_Npc_2 = class("ojingji_Npc_2", script_base)
ojingji_Npc_2.script_id = 125012
ojingji_Npc_2.g_eventList = {}
ojingji_Npc_2.g_Position = {
    {["x"] = 143, ["z"] = 151, ["name"] = "范钟离"},
    {["x"] = 28, ["z"] = 152, ["name"] = "石世崇"},
    {["x"] = 149, ["z"] = 80, ["name"] = "邓定通"},
    {["x"] = 36, ["z"] = 49, ["name"] = "梁万冀"}
}
function ojingji_Npc_2:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ngươi muốn thiết lập điểm hồi sinh của ngươi ở chỗ ta sao?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Hãy đặt điểm phục sinh của ta tại đây.", 9, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ojingji_Npc_2:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ojingji_Npc_2:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        local nIndex = 0
        for i = 1, 4 do
            if self:GetName(targetId) == self.g_Position[i]["name"] then
                nIndex = i
            end
        end
        self:SetPlayerDefaultReliveInfoEx(selfId, 1, 1, 0, self.g_Position[nIndex]["x"], self.g_Position[nIndex]["z"], 125020)
        self:BeginEvent(self.script_id)
        self:AddText("Điểm phục sinh của ngươi đã được đặt ở chỗ ta rồi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 152, 100)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function ojingji_Npc_2:OnMissionAccept(selfId, targetId, missionScriptId)
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

function ojingji_Npc_2:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ojingji_Npc_2:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ojingji_Npc_2:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ojingji_Npc_2:OnDie(selfId, killerId) end

return ojingji_Npc_2
