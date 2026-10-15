local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyannan_zhouwuwei = class("oyannan_zhouwuwei", script_base)
oyannan_zhouwuwei.script_id = 018005
oyannan_zhouwuwei.g_eventList = {808103, 808104, 808105, 808094}
function oyannan_zhouwuwei:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Việc phòng thủ #YNhạn Môn Quan#W hiện nay chủ yếu chia làm ba phần: #YChủng Thế Hành#W đại soái phụ trách đối phó với bọn đạo phỉ #YTần Gia Trại#W ở phía nam #YNhạn Môn Quan#W; #YKhúc Đoan#W phó soái phụ trách đối phó với #YLính Liêu#W ở phía bắc #YNhạn Môn Quan#W; #YMã Thừa Thiến#W giám quân phụ trách giám sát công việc của hai vị nguyên soái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oyannan_zhouwuwei:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oyannan_zhouwuwei:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oyannan_zhouwuwei:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId, missionScriptId)
            end
            return
        end
    end
end

function oyannan_zhouwuwei:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oyannan_zhouwuwei:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oyannan_zhouwuwei:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oyannan_zhouwuwei:OnDie(selfId, killerId) end

return oyannan_zhouwuwei
