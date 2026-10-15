local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuyi_wangchen = class("owuyi_wangchen", script_base)
owuyi_wangchen.script_id = 032112
owuyi_wangchen.g_eventList = {212123}
function owuyi_wangchen:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nhân sinh không quá trăm năm đều sẽ đi đến hồi kết, bất luận là đế vương tướng tướng hay thứ dân bá tánh. Vậy ở trên đời, rốt cuộc là vì cái gì? A Di Đà Phật, thí chủ, vấn đề này có phải cũng đang làm ngươi bận lòng chăng?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owuyi_wangchen:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owuyi_wangchen:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function owuyi_wangchen:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owuyi_wangchen:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owuyi_wangchen:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owuyi_wangchen:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owuyi_wangchen:OnDie(selfId, killerId) end

return owuyi_wangchen
