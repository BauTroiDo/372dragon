local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_wuciren = class("oluoyang_wuciren", script_base)
oluoyang_wuciren.script_id = 000149
oluoyang_wuciren.g_eventList = {500600,1018701}

function oluoyang_wuciren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Tại gia nhờ phụ mẫu, xuất môn nhờ bạn hữu. Hành tẩu giang hồ tu vi Cá nhân tự nhiên quan trọng, nhưng có vài bằng hữu quan hệ thân mật là điều tất yếu. Hoặc là bạn tốt chí hướng tương đồng, hoặc là huynh đệ kết nghĩa kim lan, hoặc là người quen đồng môn đồng phái. Giang hồ bao la, ngươi luôn có thể tìm được vài tri kỷ có thể cùng nhau du ngoạn, cùng nhau tiến thoái. Đao kiếm tề minh, cùng nhau xông pha ân cừu giang hồ, há chẳng phải là chuyện vui lớn nhất đời người!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_wuciren:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end

function oluoyang_wuciren:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
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

function oluoyang_wuciren:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:OnDefaultEvent(selfId, targetId)
            return
        end
    end
end

function oluoyang_wuciren:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_wuciren:OnMissionSubmit(selfId, targetId, missionScriptId,
                                          selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_wuciren:OnDie(selfId, killerId) end

return oluoyang_wuciren
