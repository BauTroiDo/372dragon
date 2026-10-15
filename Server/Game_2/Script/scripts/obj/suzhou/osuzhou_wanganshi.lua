local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_wanganshi = class("osuzhou_wanganshi", script_base)
osuzhou_wanganshi.script_id = 001000
osuzhou_wanganshi.g_eventList = {} --{212130, 212133}

function osuzhou_wanganshi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    if self:GetName(targetId) ~= "沈夜雨" then
        self:AddText("  Trời biến chẳng đáng sợ, tổ tông chẳng đáng noi theo, lời lẽ tầm thường chẳng đáng lo lắng.")
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        if (self:IsMissionHaveDone(selfId, 255)) then
            self:AddNumText("Lĩnh danh hiệu", 6, 999)
        end
    else
        self:AddText("#{SYSZ_20210203_02}")
            self:AddNumText("Đưa ta ra ngoài", 6, 88)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_wanganshi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_wanganshi:OnEventRequest(selfId, targetId, arg, index)
	if index == 88 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 221, 209)
	end
    if index == 999 then
        self:LuaFnAwardTitle(selfId, 11, 304)
        self:SetCurTitle(selfId, 11, 304)
        self:LuaFnAddNewAgname(selfId, 11, 304)
        self:LuaFnDispatchAllTitle(selfId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function osuzhou_wanganshi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_wanganshi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_wanganshi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_wanganshi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_wanganshi:OnDie(selfId, killerId)
end

return osuzhou_wanganshi
