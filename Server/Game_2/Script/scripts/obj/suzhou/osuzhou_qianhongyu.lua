local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_qianhongyu = class("osuzhou_qianhongyu", script_base)
osuzhou_qianhongyu.script_id = 001065
osuzhou_qianhongyu.g_EventList = {050100, 050102, 050106, 500609, 500611,1018709,1018710,1018711,1018712}

function osuzhou_qianhongyu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText( "    Không sai, Hiệu úy Tô Châu Tiền Hoành Vũ chính là ta! Tìm ta có việc gì?")
    for i, findId in pairs(self.g_EventList) do
        self:CallScriptFunction(findId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Liên Hoàn Phó Bảntửu quán", 11, 10)
    self:AddNumText("Lâu LanLiên Hoàn Phó Bảntửu quán", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_qianhongyu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_qianhongyu:OnEventRequest(selfId, targetId, arg, index)
    print("osuzhou_qianhongyu:OnEventRequest", selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_078}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XSHBZ_80917_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_EventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function osuzhou_qianhongyu:OnMissionAccept(selfId, targetId, missionScriptId)
    print("osuzhou_qianhongyu:OnMissionAccept", selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept",
                                                selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,
                                        targetId, missionScriptId)
            end
            return
        end
    end
end

function osuzhou_qianhongyu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_qianhongyu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_qianhongyu:OnMissionSubmit(selfId, targetId, missionScriptId,selectRadioId)
    print("osuzhou_qianhongyu:OnMissionSubmit =", selfId, targetId, missionScriptId,selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_qianhongyu:OnDie(selfId, killerId) end

return osuzhou_qianhongyu
