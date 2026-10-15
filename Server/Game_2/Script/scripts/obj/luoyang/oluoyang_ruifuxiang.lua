local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_ruifuxiang = class("oluoyang_ruifuxiang", script_base)
oluoyang_ruifuxiang.script_id = 000099
oluoyang_ruifuxiang.g_shoptableindex = 16
oluoyang_ruifuxiang.g_eventList = {1018718,1018719}
function oluoyang_ruifuxiang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Người người tấp nập, đều vì lợi mà đến, người người ồn ào, đều vì lợi mà đi.")
    self:AddNumText("Mua bán tạp hóa", 7, 1)
    for i,eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_ruifuxiang:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end
function oluoyang_ruifuxiang:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept",selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,targetId, missionScriptId)
            end
            return
        end
    end
end

function oluoyang_ruifuxiang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:OnDefaultEvent(selfId, targetId)
            return
        end
    end
end

function oluoyang_ruifuxiang:OnMissionContinue(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,targetId)
            return
        end
    end
end

function oluoyang_ruifuxiang:OnMissionSubmit(selfId, targetId, missionScriptId,selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_ruifuxiang:OnDie(selfId, killerId) end

return oluoyang_ruifuxiang
