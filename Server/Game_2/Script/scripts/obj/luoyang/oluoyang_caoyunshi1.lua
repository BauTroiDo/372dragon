local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_caoyunshi1 = class("oluoyang_caoyunshi1", script_base)
oluoyang_caoyunshi1.script_id = 311006
oluoyang_caoyunshi1.g_eventList = {311010}

oluoyang_caoyunshi1.g_MissionId = 1000
oluoyang_caoyunshi1.g_GodFireEventList = {1018720,1018721}

oluoyang_caoyunshi1.g_ActivityTime = {
    {["tstart"] = 1230, ["tend"] = 1330}, {["tstart"] = 1930, ["tend"] = 2030},
    {["tstart"] = 2130, ["tend"] = 2230}
}

oluoyang_caoyunshi1.g_Mission_IsComplete = 0
oluoyang_caoyunshi1.g_LuoYang_RecordIdx = 1
oluoyang_caoyunshi1.g_SuZhou_RecordIdx = 2
oluoyang_caoyunshi1.g_DaLi_RecordIdx = 3
oluoyang_caoyunshi1.g_KongMing_Lighten = 4
oluoyang_caoyunshi1.g_RoundIndex = 7
oluoyang_caoyunshi1.g_KongMing_CntMax = 24
function oluoyang_caoyunshi1:UpdateEventList(selfId, targetId)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
end

function oluoyang_caoyunshi1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    if self:OnIsFillPlayCard(selfId, targetId) == 1 then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_LuoYang_RecordIdx, 1)
        self:NotifyTip(selfId, "#{GodFire_Info_002}")
        if self:GetMissionParam(selfId, misIndex, self.g_LuoYang_RecordIdx) == 1 and
            self:GetMissionParam(selfId, misIndex, self.g_SuZhou_RecordIdx) == 1 and
            self:GetMissionParam(selfId, misIndex, self.g_DaLi_RecordIdx) == 1 then
            if self:GetMissionParam(selfId, misIndex, self.g_KongMing_Lighten) >=
                self.g_KongMing_CntMax then
                self:AddText("#{GodFire_Info_028}")
                self:SetMissionByIndex(selfId, misIndex,
                                       self.g_Mission_IsComplete, 1)
            else
                self:AddText("#{GodFire_Info_037}")
            end
        else
            self:AddText("#{GodFire_Info_010}")
        end
    else
        self:AddText("#{function_caoyun_0}")
        self:AddNumText("Tìm hiểu Tào Vận", 11, 1)
        self:AddNumText("Bắt đầu Tào Vận", 7, 2)
        for i, eventId in pairs(self.g_GodFireEventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_caoyunshi1:OnEventRequest(selfId, targetId, arg, index)
    local NumText = index
    if NumText == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_051}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif NumText == 2 then
        self:UpdateEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnHandle_QuestUI", selfId,
                                    targetId, NumText)
            return
        end
    end
    for i, findId in pairs(self.g_GodFireEventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end

function oluoyang_caoyunshi1:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_GodFireEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId,
                                    targetId, missionScriptId)
            return
        end
    end
end

function oluoyang_caoyunshi1:OnMissionRefuse(selfId, targetId, missionScriptId)
    return
end

function oluoyang_caoyunshi1:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_GodFireEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_caoyunshi1:OnMissionSubmit(selfId, targetId, missionScriptId,
                                             selectRadioId)
    for i, findId in pairs(self.g_GodFireEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_caoyunshi1:OnDie(selfId, killerId) end

function oluoyang_caoyunshi1:OnIsFillPlayCard(selfId, targetId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return 0 end
    local nDayTime = self:GetMissionData(selfId, define.MD_ENUM.MD_GODOFFIRE_DAYTIME)
    local nDay = self:LuaFnGetDayOfThisMonth()
    if nDayTime ~= nDay then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local nRoundIdx = self:GetMissionParam(selfId, misIndex, self.g_RoundIndex)
    local nHour = self:GetHour()
    local nMinute = self:GetMinute()
    local curHourTime = nHour * 100 + nMinute
    if curHourTime < self.g_ActivityTime[nRoundIdx]["tstart"] or curHourTime >
        self.g_ActivityTime[nRoundIdx]["tend"] then return 0 end
    if self:GetMissionParam(selfId, misIndex, self.g_LuoYang_RecordIdx) == 1 then
        return 0
    end
    return 0
end

function oluoyang_caoyunshi1:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return oluoyang_caoyunshi1
