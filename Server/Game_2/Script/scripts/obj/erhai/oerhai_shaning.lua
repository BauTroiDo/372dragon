local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_shaning = class("oerhai_shaning", script_base)
oerhai_shaning.script_id = 024004
oerhai_shaning.g_eventList = { 1030111, 1010111 }
function oerhai_shaning:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là cô nhi, chưa từng gặp A Ba và A Ma, là thúc thúc nuôi ta lớn từ nhỏ, thúc thúc đối với ta như con ruột, ta nhất định phải tìm được người.#r Ta từng thấy một bức họa của một vị cô cô trong phòng ngủ của thúc thúc, vị cô cô kia rất đẹp, mỗi lần thúc thúc say rượu đều nhìn chằm chằm vào bức họa đó, nhìn mãi.#r Có lẽ thúc thúc đã đi tìm vị cô cô đó rồi chăng?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oerhai_shaning:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oerhai_shaning:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oerhai_shaning:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oerhai_shaning:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oerhai_shaning:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oerhai_shaning:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oerhai_shaning:OnDie(selfId, killerId) end

return oerhai_shaning
