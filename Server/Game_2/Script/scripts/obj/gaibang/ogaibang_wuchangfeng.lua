local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_wuchangfeng = class("ogaibang_wuchangfeng", script_base)
ogaibang_wuchangfeng.script_id = 010006
ogaibang_wuchangfeng.g_eventList = {713514, 713573, 701606}

function ogaibang_wuchangfeng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Kỹ năng của ta chỉ dạy đệ tử bổn phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Nấu Rượu tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_wuchangfeng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ogaibang_wuchangfeng:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_025}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function ogaibang_wuchangfeng:OnMissionAccept(selfId, targetId, missionScriptId)
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

function ogaibang_wuchangfeng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ogaibang_wuchangfeng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ogaibang_wuchangfeng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ogaibang_wuchangfeng:OnDie(selfId, killerId)
end

return ogaibang_wuchangfeng
