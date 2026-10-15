local class = require "class"
local script_base = require "script_base"

local pc_expandofficer = class("pc_expandofficer", script_base)
pc_expandofficer.script_id = 805013
pc_expandofficer.g_BuildingID7 = 15
pc_expandofficer.g_eventList = {600046, 600023}
pc_expandofficer.g_eventList2 = {600047, 600048, 600049}
pc_expandofficer.g_eventSetList = {600023}

function pc_expandofficer:UpdateEventList(selfId, targetId)
    local humanGuildId = self:GetHumanGuildID(selfId)
    local cityGuildId = self:GetCityGuildID(selfId)

    self:BeginEvent(self.script_id)
    if humanGuildId == cityGuildId then
        self:AddText("    Vị thế và danh tiếng bang ta trên giang hồ đều do ta phụ trách, có kiến nghị gì hay cứ nói.")
        for _, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Về nhiệm vụ Khuếch trương.", 11, 1)
        self:AddNumText("tửu quán thao trường", 11, 2)
        self:AddNumText("Mua công thức Công Trình Học", 7, 3)
        self:AddNumText("Xây dựng cờ lớn bang hội", 6, 4)
        self:AddNumText("Tu luyện phòng ngự", 6, 5)
        self:AddNumText("Xây dựng tiễn tháp Cao cấp", 6, 6)
    else
        self:AddText("    Nơi này là thao trường trọng địa, không phải đệ tử bản bang thì đừng nên dòm ngó thì hơn.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_expandofficer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_expandofficer:IsValidEvent(selfId, eventId)
    for _, findId in pairs(self.g_eventList) do
        if eventId == findId then
            return 1
        end
    end

    for _, findId in pairs(self.g_eventSetList) do
        if self:CallScriptFunction(findId, "IsInEventList", selfId, eventId) == 1 then
            return 1
        end
    end

    return 0
end

function pc_expandofficer:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    end

    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Expand_Mission_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_JiaoChang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 3 or index == 4 or index == 5 or index == 6 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function pc_expandofficer:OnMissionAccept(selfId, targetId, missionScriptId)
    for _, eventId in pairs(self.g_eventList2) do
        if missionScriptId == eventId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            return
        end
    end

    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
        if ret > 0 then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
        elseif ret == -1 then
            self:NotifyFailTips(selfId, "Ngươi hiện tại không thể lĩnh nhiệm vụ này")
        elseif ret == -2 then
            self:NotifyFailTips(selfId, "Không thể nhận thêm nhiệm vụ.")
        end
    end
end

function pc_expandofficer:OnMissionRefuse(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
    end
end

function pc_expandofficer:OnMissionContinue(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
    end
end

function pc_expandofficer:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for _, eventId in pairs(self.g_eventList2) do
        if missionScriptId == eventId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end

    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
    end
end

function pc_expandofficer:OnDie(selfId, killerId) end

function pc_expandofficer:NotifyFailTips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return pc_expandofficer
