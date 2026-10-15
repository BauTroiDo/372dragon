local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oDynamicNPC_ThiefSoldier = class("oDynamicNPC_ThiefSoldier", script_base)
oDynamicNPC_ThiefSoldier.script_id = 050012
oDynamicNPC_ThiefSoldier.g_EventList = {050013}

oDynamicNPC_ThiefSoldier.g_minLevel = 20
function oDynamicNPC_ThiefSoldier:UpdateEventList(selfId, targetId)
	-- self:notify_tips(selfId, "到这里？？")
	-- if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
    for i, eventId in pairs(self.g_EventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
	
    -- self:CallScriptFunction(self.g_EventList[1], "OnEnumerate", self, selfId, targetId)
end

function oDynamicNPC_ThiefSoldier:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oDynamicNPC_ThiefSoldier:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_EventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oDynamicNPC_ThiefSoldier:OnMissionAccept(selfId, targetId,
                                                  missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function oDynamicNPC_ThiefSoldier:OnMissionRefuse(selfId, targetId,
                                                  missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oDynamicNPC_ThiefSoldier:OnMissionContinue(selfId, targetId,
                                                    missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oDynamicNPC_ThiefSoldier:OnMissionSubmit(selfId, targetId,
                                                  missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oDynamicNPC_ThiefSoldier:OnDie(selfId, killerId) end

return oDynamicNPC_ThiefSoldier
