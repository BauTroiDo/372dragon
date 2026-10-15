local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuyi_ziwei = class("owuyi_ziwei", script_base)
owuyi_ziwei.script_id = 032004
owuyi_ziwei.g_eventList = {}
function owuyi_ziwei:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hoan nghênh ngươi đến doanh địa tuần tra của người Sơn Việt, ngươi Có thể sử dụng tại nơi này đi lại ngắm nghía, nhưng ngàn vạn lần đừng làm hại đến những hoa hoa cỏ cỏ kia, chúng là những người bạn tốt của người Sơn Việt chúng ta đó.#r  Đằng kia là Thủy Tiên tỷ tỷ, tỷ ấy là người thông minh nhất của doanh địa chúng ta đó.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owuyi_ziwei:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owuyi_ziwei:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function owuyi_ziwei:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owuyi_ziwei:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owuyi_ziwei:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owuyi_ziwei:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owuyi_ziwei:OnDie(selfId, killerId) end

return owuyi_ziwei
