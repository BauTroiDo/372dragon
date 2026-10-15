local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ochangbai_liaoguocuiliangguan = class("ochangbai_liaoguocuiliangguan", script_base)
ochangbai_liaoguocuiliangguan.script_id = 022002
ochangbai_liaoguocuiliangguan.g_eventList = {}
function ochangbai_liaoguocuiliangguan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  Đại Liêu quốc vĩnh viễn bất khả chiến thắng!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ochangbai_liaoguocuiliangguan:OnDefaultEvent(selfId, targetId)
    self:x022010_UpdateEventList(selfId, targetId)
end

function ochangbai_liaoguocuiliangguan:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function ochangbai_liaoguocuiliangguan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function ochangbai_liaoguocuiliangguan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ochangbai_liaoguocuiliangguan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ochangbai_liaoguocuiliangguan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,targetId, selectRadioId)
            return
        end
    end
end

function ochangbai_liaoguocuiliangguan:OnDie(selfId, killerId) end

return ochangbai_liaoguocuiliangguan
