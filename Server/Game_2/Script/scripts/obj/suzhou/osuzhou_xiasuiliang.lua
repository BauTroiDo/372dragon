local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_xiasuiliang = class("osuzhou_xiasuiliang", script_base)
osuzhou_xiasuiliang.script_id = 001071
osuzhou_xiasuiliang.g_eventList = {125020}

function osuzhou_xiasuiliang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  #G$N#W anh hùng! Đến Tế Đàn Tung Sơn thể hiện thực lực của ngươi đi!#r #GTrước khi vào Tế Đàn, ngươi phải gia nhập một đội, tất cả mọi người trong đội đó đều thuộc cùng một phe với ngươi, ngoài họ ra, tất cả những người Khác trên Tế Đàn đều là đối thủ của ngươi.#W #r Thế nào, muốn thử xem không?"
    )
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_xiasuiliang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_xiasuiliang:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function osuzhou_xiasuiliang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_xiasuiliang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_xiasuiliang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_xiasuiliang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_xiasuiliang:OnDie(selfId, killerId)
end

return osuzhou_xiasuiliang
