local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pc_commercialofficer = class("pc_commercialofficer", script_base)
pc_commercialofficer.script_id = 805017
pc_commercialofficer.g_BuildingID12 = 9
pc_commercialofficer.g_eventList = {600017}
pc_commercialofficer.g_eventSetList = {600017}

function pc_commercialofficer:UpdateEventList(selfId, targetId)
    local i = 1
    local eventId = 0
    local PlayerName = self:GetName(selfId)
    local Humanguildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    self:BeginEvent(self.script_id)
    if Humanguildid == cityguildid then
        self:AddText( "    Ta vốn lấy Đào Chu Công làm sư tôn, đạo làm ăn, huynh đệ chúng ta có thể cùng nhau nghiên cứu.")
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Nhiệm vụ thị tập tửu quán", 11, 1)
        self:AddNumText("Quản lý Thương nghiệp quyển", 6, 3)
        self:AddNumText("Tập phường tửu quán", 11, 2)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID12, 888)
    else
        self:AddText("    Nếu không phải người trong bang ta, ắt lòng dạ khác, thương trường như chiến trường, ta vẫn nên ít lời thì hơn.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_commercialofficer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_commercialofficer:IsValidEvent(selfId, eventId)
    local i = 1
    local findId = 0
    local bValid = 0
    for i, findId in pairs(self.g_eventList) do
        if eventId == findId then
            bValid = 1
            break
        end
    end
    if bValid == 0 then
        for i, findId in pairs(self.g_eventSetList) do
            if self:CallScriptFunction(findId, "IsInEventList", selfId, eventId) == 1 then
                bValid = 1
                break
            end
        end
    end
    return bValid
end

function pc_commercialofficer:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    elseif arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent", selfId, targetId, arg, self.script_id, self.g_BuildingID12)
        return
    end
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Market_Mission_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_JiFang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 888 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate",self, selfId, targetId, self.g_BuildingID12)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function pc_commercialofficer:OnMissionAccept(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
        if ret > 0 then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
        elseif ret == -1 then
            self:NotifyFailTips(selfId, "Ngươi hiện tại không thể lĩnh nhiệm vụ này")
        elseif ret == -2 then
            self:NotifyFailTips(selfId, "Không thể nhận thêm nhiệm vụ.")
        end
        return
    end
end

function pc_commercialofficer:OnMissionRefuse(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function pc_commercialofficer:OnMissionContinue(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
        return
    end
end

function pc_commercialofficer:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
        return
    end
end

function pc_commercialofficer:OnDie(selfId, killerId) end

function pc_commercialofficer:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return pc_commercialofficer
