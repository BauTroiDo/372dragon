local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_daorao = class("oerhai_daorao", script_base)
oerhai_daorao.script_id = 024001
oerhai_daorao.g_eventList = {
    808099, 808100, 808101, 808094, 1010043, 1000112, 1000113, 1000114, 1010110, 1050001,
    1018801, 1018731, 1018741, 1018751, 1018761, 1018771, 1018781, 1018791, 1018811
}
function oerhai_daorao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Người trẻ tuổi, ở đây chớ nên chạy loạn!#r Dã Nhân và Người Sói đều không phải là kẻ dễ trêu chọc, nhìn tình cảnh hiện tại của thôn chúng ta, ngươi sẽ biết những kẻ xâm lược kia hung hãn đến nhường nào.#r Con đường lớn phía trước gọi là Trà Mã Đạo, rất nhiều Thương nhân từ đây Vận chuyển trà lá đến những quốc gia xa xôi, trước kia thỉnh thoảng lại có đoàn ngựa đi qua, tiếng chuông ngựa có thể truyền đi rất xa...")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oerhai_daorao:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oerhai_daorao:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oerhai_daorao:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oerhai_daorao:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oerhai_daorao:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oerhai_daorao:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oerhai_daorao:OnDie(selfId, killerId) end

return oerhai_daorao
