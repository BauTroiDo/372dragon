local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otaihu_huyanqing = class("otaihu_huyanqing", script_base)
otaihu_huyanqing.script_id = 004001
otaihu_huyanqing.g_EventList = {232002}

function otaihu_huyanqing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local nam = self:LuaFnGetName(selfId)
    self:AddText("  " .. nam .. " , đến đây đi.#r")
    for i, findId in pairs(self.g_EventList) do
        self:CallScriptFunction(self.g_EventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otaihu_huyanqing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function otaihu_huyanqing:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_EventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function otaihu_huyanqing:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function otaihu_huyanqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function otaihu_huyanqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function otaihu_huyanqing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function otaihu_huyanqing:OnDie(selfId, killerId)
end

return otaihu_huyanqing
