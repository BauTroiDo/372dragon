local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_lingzhen = class("oxihu_lingzhen", script_base)
oxihu_lingzhen.script_id = 050203
oxihu_lingzhen.g_eventList = {050018, 050019}
oxihu_lingzhen.g_StartDayTime = 8257
oxihu_lingzhen.g_EndDayTime = 8282
function oxihu_lingzhen:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Cảnh đêm Tây Hồ thực là đẹp! Nếu vào thời khắc đẹp nhất, bắn lên vài bó pháo hoa lễ hội xinh đẹp thì càng tốt hơn.")
    if self:IsHaveMission(selfId, 131) then
        self:CallScriptFunction(050018, "OnEnumerate", self, selfId, targetId)
    elseif self:IsHaveMission(selfId, 132) then
        self:CallScriptFunction(050019, "OnEnumerate", self, selfId, targetId)
    else
        local randIndex = math.random(1, 2)
        if randIndex == 1 then
            self:CallScriptFunction(050018, "OnEnumerate", self, selfId, targetId)
        else
            self:CallScriptFunction(050019, "OnEnumerate", self, selfId, targetId)
        end
    end
    local check = self:IsMidAutumnPeriod(selfId)
    if check and check == 1 then
        self:AddNumText("Về thưởng nguyệt ngắm pháo hoa", 11, 1)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxihu_lingzhen:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oxihu_lingzhen:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    local num = index
    if num == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{FANGYIANHUA_ABOUT}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function oxihu_lingzhen:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oxihu_lingzhen:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oxihu_lingzhen:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oxihu_lingzhen:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oxihu_lingzhen:OnDie(selfId, killerId) end
function oxihu_lingzhen:IsMidAutumnPeriod(selfId)
    local curDay = self:GetDayTime()
    if not curDay then return 0 end
    if curDay < self.g_StartDayTime or curDay > self.g_EndDayTime then
        return 0
    end
    return 1
end

return oxihu_lingzhen
