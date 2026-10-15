local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_biaoshi = class("oluoyang_biaoshi", script_base)
oluoyang_biaoshi.script_id = 000073
oluoyang_biaoshi.g_eventList = {889051}

function oluoyang_biaoshi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_biaoshi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{HJMAYH_230228_19}")
	--没有脚本，不走
    -- for i, eventId in pairs(self.g_eventList) do
        -- self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    -- end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_biaoshi:OnEventRequest(selfId, targetId, arg, index)
	--没有脚本，不走
    -- for i, findId in pairs(self.g_eventList) do
        -- if arg == findId then
            -- self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            -- return
        -- end
    -- end
end

function oluoyang_biaoshi:OnMissionAccept(selfId, targetId, missionScriptId) end

function oluoyang_biaoshi:OnMissionRefuse(selfId, targetId, missionScriptId) end

function oluoyang_biaoshi:OnMissionContinue(selfId, targetId, missionScriptId) end

function oluoyang_biaoshi:OnMissionSubmit(selfId, targetId, missionScriptId,
                                          selectRadioId) end

return oluoyang_biaoshi
