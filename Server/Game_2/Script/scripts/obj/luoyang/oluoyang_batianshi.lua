local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_batianshi = class("oluoyang_batianshi", script_base)
oluoyang_batianshi.g_eventList = {893259}
function oluoyang_batianshi:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  Thật khéo!" .. PlayerName .. PlayerSex ..
                     ", vậy mà lại gặp mặt ở đây. Đại Lý mỗi lần tham gia giải đấu Cúc Cầu, đều chỉ là bồi Thái Tử đọc sách mà thôi.")
    for i, findId in pairs(self.g_eventList) do
        self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function oluoyang_batianshi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_batianshi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg,index)
            return
        end
    end
end

function oluoyang_batianshi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_batianshi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_batianshi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oluoyang_batianshi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_batianshi:OnDie(selfId, killerId)
end

return oluoyang_batianshi
