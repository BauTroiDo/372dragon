local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_gaoshengxiang = class("odali_gaoshengxiang", script_base)
odali_gaoshengxiang.g_shoptableindex = 6
odali_gaoshengxiang.script_id = 002057
odali_gaoshengxiang.g_eventList = {210273,210274}

function odali_gaoshengxiang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tiệm có nhiều hàng bán, mời chọn mua." )
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua bán tạp hóa", 7, 1)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function odali_gaoshengxiang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_gaoshengxiang:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    if index == 1 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

function odali_gaoshengxiang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_gaoshengxiang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_gaoshengxiang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_gaoshengxiang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_gaoshengxiang:OnDie(selfId, killerId)
end

return odali_gaoshengxiang
