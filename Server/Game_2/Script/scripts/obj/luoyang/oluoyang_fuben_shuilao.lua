local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_fuben_shuilao = class("oluoyang_fuben_shuilao", script_base)
oluoyang_fuben_shuilao.script_id = 000090
oluoyang_fuben_shuilao.g_eventList = {231000}

function oluoyang_fuben_shuilao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  " .. PlayerName .. " Tới đây nào.")
    for i, findId in pairs(oluoyang_fuben_shuilao.g_eventList) do
        self:CallScriptFunction(oluoyang_fuben_shuilao.g_eventList[i],
                                "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_fuben_shuilao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Ngươi mau đến Chùa Bạch Mã đi, Đại sư Trí Thanh nhất định nóng lòng muốn gặp ngươi đó! Ta mấy ngày nay công vụ bận rộn, đợi ta bình định phản loạn ở Thủy Lao xong, nhất định đến Chùa Bạch Mã giúp Đại sư Trí Thanh cứu tế dân chúng.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_fuben_shuilao:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(oluoyang_fuben_shuilao.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_fuben_shuilao:OnMissionAccept(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(oluoyang_fuben_shuilao.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function oluoyang_fuben_shuilao:OnMissionRefuse(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(oluoyang_fuben_shuilao.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_fuben_shuilao:OnMissionContinue(selfId, targetId,
                                                  missionScriptId)
    for i, findId in pairs(oluoyang_fuben_shuilao.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_fuben_shuilao:OnMissionSubmit(selfId, targetId,
                                                missionScriptId, selectRadioId)
    for i, findId in pairs(oluoyang_fuben_shuilao.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_fuben_shuilao:OnDie(selfId, killerId) end

return oluoyang_fuben_shuilao
