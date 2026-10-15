local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocangshan_shashang = class("ocangshan_shashang", script_base)
ocangshan_shashang.script_id = 025002
ocangshan_shashang.g_eventList = {}
function ocangshan_shashang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  Nơi đây là đình Quan Nguyệt của Thương Sơn, phía trước chính là Nhĩ Hải, mỗi khi đêm trăng, gió Nhĩ Hải ngừng thổi nước lặng im, ánh trăng sáng trong hòa vào mặt hồ, tựa như vạn điểm tinh quang, dậy lên muôn mẫu sóng bạc.#r   Vách núi đối diện là vọng tuyết nham, từ trên vách núi đó có thể nhìn thấy những ngọn Thương Sơn phủ đầy Bạch Tuyết, lớp bạc quấn thân, dưới ánh mặt trời chiếu rọi, trắng tinh lấp lánh.#r   Thế nhưng cảnh sắc tuyệt đẹp như vậy giờ đây đã không còn ai dám tới thưởng ngoạn nữa...")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ocangshan_shashang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ocangshan_shashang:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function ocangshan_shashang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function ocangshan_shashang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ocangshan_shashang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ocangshan_shashang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ocangshan_shashang:OnDie(selfId, killerId) end

return ocangshan_shashang
