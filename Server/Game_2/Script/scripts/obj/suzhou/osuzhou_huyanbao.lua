local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_huyanbao = class("osuzhou_huyanbao", script_base)
osuzhou_huyanbao.script_id = 001061
osuzhou_huyanbao.g_EventList = {232000, 232001, 500618,1018719,1018720}

osuzhou_huyanbao.g_dlg = "  Đại sự không hay rồi, đám tù nhân trong thủy lao của chúng ta nổi loạn, phần lớn binh lính đều xuất hồ huấn luyện rồi, dẫn đến nhân thủ ở thủy trại không đủ, ta đây phải đến phủ Tô Châu cầu cứu thôi, sao? Ngươi bằng lòng giúp chúng ta một tay đến thủy trại bình định loạn phạm nhân không?"
function osuzhou_huyanbao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_dlg)
    for i, findId in pairs(self.g_EventList) do
        if findId == 232000 or findId == 500618 or findId == 1018719 or findId == 1018720 then
            self:CallScriptFunction(findId, "OnEnumerate", self, selfId, targetId)
        end
    end
    self:AddNumText("Nhiệm vụ thủy laotửu quán", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_huyanbao:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_huyanbao:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_074}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_EventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end

function osuzhou_huyanbao:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_huyanbao:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_huyanbao:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_huyanbao:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_huyanbao:OnDie(selfId, killerId)
end

return osuzhou_huyanbao
