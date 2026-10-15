local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_huajianying = class("osuzhou_huajianying", script_base)
osuzhou_huajianying.script_id = 001029
osuzhou_huajianying.g_EventList = {050101, 500610,1018710,1018711}

function osuzhou_huajianying:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Bổn tiêu cục nhờ có các huynh đệ hắc bạch lưỡng đạo nể mặt, Tống tiêu chưa từng xảy ra sơ suất, đến tiêu cục chúng ta bảo tiêu, ngươi cứ việc yên tâm là được.")
    for i, findId in pairs(self.g_EventList) do
        self:CallScriptFunction(findId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Liên Hoàn Phó Bảntửu quán", 11, 105)
    self:AddNumText("Lâu LanLiên Hoàn Phó Bảntửu quán", 11, 106)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_huajianying:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_huajianying:OnEventRequest(selfId, targetId, arg, index)
    if index == 105 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_077}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 106 then
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

function osuzhou_huajianying:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId, missionScriptId)
            end
            return
        end
    end
end

function osuzhou_huajianying:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_huajianying:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_huajianying:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_huajianying:OnDie(selfId, killerId)
end

return osuzhou_huajianying
