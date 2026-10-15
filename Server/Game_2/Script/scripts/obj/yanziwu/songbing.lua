local class = require "class"
local define = require "define"
local script_base = require "script_base"
local songbing = class("songbing", script_base)
songbing.script_id = 402262
songbing.g_eventList = {}

function songbing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local nRand = math.random(4)
    local str
    if nRand == 1 then
        str = "  Nghe nói lần này phản tặc đã mời Tứ Đại Ác Nhân đến ám sát Hô Diên Báo tướng quân!"
    elseif nRand == 2 then
        str = "  Hô Diên Báo tướng quân đang gặp nguy hiểm, xin các vị mau chóng đến kỳ hạm để bảo vệ ngài!"
    elseif nRand == 3 then
        str = "  Hô Diên Báo tướng quân là hổ tướng khó có được của Đại Tống ta, đặc biệt giỏi thủy chiến, có ông ấy, thủy quân Đại Tống tất thắng!"
    else
        str = "  Nếu ta cũng biết khinh công, nhất định sẽ đạp lá sen bay đến kỳ hạm để bảo vệ Hô Diên Báo tướng quân!"
    end
    self:AddText(str)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function songbing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function songbing:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function songbing:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function songbing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function songbing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function songbing:OnMissionSubmit(selfId, targetId, missionScriptId,  selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function songbing:OnDie(selfId, killerId) end

return songbing
