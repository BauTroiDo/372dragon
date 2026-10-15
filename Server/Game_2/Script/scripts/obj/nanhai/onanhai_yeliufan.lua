local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_yeliufan = class("onanhai_yeliufan", script_base)
onanhai_yeliufan.script_id = 34001
onanhai_yeliufan.g_eventList = {212114}
function onanhai_yeliufan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Rốt cuộc là ai làm! Ta nhất định sẽ tra ra hung thủ, ta muốn dùng đầu của hắn tế bái sư phụ, sư nương và tất cả người của Nam Hải Kiếm Phái!#r Đáng thương nhất là Cửu sư muội, nàng nhất định rất đau lòng... Trong lòng nàng, chỉ có, đại sư huynh a...")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function onanhai_yeliufan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function onanhai_yeliufan:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function onanhai_yeliufan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function onanhai_yeliufan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function onanhai_yeliufan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function onanhai_yeliufan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function onanhai_yeliufan:OnDie(selfId, killerId) end

return onanhai_yeliufan
