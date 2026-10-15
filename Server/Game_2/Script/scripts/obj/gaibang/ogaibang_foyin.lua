local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_foyin = class("ogaibang_foyin", script_base)
ogaibang_foyin.script_id = 010002
ogaibang_foyin.g_eventList = {221901}

function ogaibang_foyin:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  Hầm rượu của Cái Bang này, thật có nhiều rượu ngon." .. PlayerName .. ", ngươi không muốn nếm thử sao?#r Ta làm hòa thượng mấy ngày, thật không thú vị, giờ làm khất cái, mới thấy thỏa lòng.")
    for i, findId in pairs(self.g_eventList) do
        self:CallScriptFunction(self.g_eventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_foyin:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ogaibang_foyin:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function ogaibang_foyin:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            return
        end
    end
end

function ogaibang_foyin:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ogaibang_foyin:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ogaibang_foyin:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ogaibang_foyin:OnDie(selfId, killerId)
end

return ogaibang_foyin
