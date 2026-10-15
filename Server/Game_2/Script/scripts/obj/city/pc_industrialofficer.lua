local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pc_industrialofficer = class("pc_industrialofficer", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
pc_industrialofficer.script_id = 805008
pc_industrialofficer.g_BuildingID16 = 5
pc_industrialofficer.g_eventList = {600002}
pc_industrialofficer.g_eventSetList = {600002}

function pc_industrialofficer:UpdateEventList(selfId, targetId)
    local i = 1
    local eventId = 0
    local Humanguildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    self:BeginEvent(self.script_id)
    if Humanguildid == cityguildid then
        self:AddText( "    Việc công xưởng của bang ta, đều có thể tìm lão Mã này, hễ có thể giúp đỡ, ta xin dốc lòng.")
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Nhiệm vụ công trình tửu quán", 11, 7)
        self:AddNumText("修理装备", 6, 9)
        self:AddNumText("Đại diện hợp thành Bảo thạch", 6, 10)
        self:AddNumText("Cửa hàng công thức", 7, 6)
        self:AddNumText("Tửu quán Đoán Đài", 11, 8)
        self:AddNumText("Về kỹ năng quan hoài.", 11, 11)
        self:AddNumText("Lĩnh Kỹ năng Quan Tâm", 6, 12)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID16, 888)
    else
        local PlayerGender = self:GetSex(selfId)
        local rank
        if PlayerGender == 0 then
            rank = "Hiệp Nữ"
        elseif PlayerGender == 1 then
            rank = "Đại Hiệp"
        else
            rank = "Xin hỏi"
        end
        self:AddText("    Lão Mã ta vốn là kẻ thô kệch," .. rank .. "có gì chỉ giáo?")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_industrialofficer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_industrialofficer:IsValidEvent(selfId, eventId)
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

function pc_industrialofficer:CheckFavorOfGuild(selfId)
    local Humanguildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    if (Humanguildid ~= cityguildid) then return 1 end
    local GuidPoint = self:CityGetAttr(selfId, 6)
    local CurDay = self:GetDayTime()
    local OldDay = self:GetMissionData(selfId, ScriptGlobal.MD_FAVOROFGUILD_LASTTIME)
    if (CurDay <= OldDay) then return 3 end
    if (GuidPoint < 1) then return 2 end
    local citySceneId = self:CityGetSelfCityID(selfId)
    local Status = self:CityGetMaintainStatus(selfId, citySceneId)
    if (Status == 1) then return 4 end
    return 0
end

function pc_industrialofficer:SetFavorOfGuild(selfId)
    local FavorCode = self:CheckFavorOfGuild(selfId)
    if (0 ~= FavorCode) then return end
    local Level = self:GetLevel(selfId)
    local Name = self:GetName(selfId)
    local Point = 0
    local BuffLevel = 0
    if (Level >= 10 and Level < 20) then
        Point = 10
        BuffLevel = 7800
    elseif (Level >= 20 and Level < 30) then
        Point = 15
        BuffLevel = 7801
    elseif (Level >= 30 and Level < 40) then
        Point = 20
        BuffLevel = 7802
    elseif (Level >= 40 and Level < 50) then
        Point = 25
        BuffLevel = 7803
    elseif (Level >= 50 and Level < 60) then
        Point = 30
        BuffLevel = 7804
    elseif (Level >= 60 and Level < 70) then
        Point = 35
        BuffLevel = 7805
    elseif (Level >= 70 and Level < 80) then
        Point = 40
        BuffLevel = 7806
    elseif (Level >= 80 and Level < 90) then
        Point = 45
        BuffLevel = 7807
    elseif (Level >= 90 and Level < 100) then
        Point = 50
        BuffLevel = 7808
    elseif (Level >= 100 and Level < 110) then
        Point = 55
        BuffLevel = 30000
    elseif (Level >= 110 and Level < 120) then
        Point = 60
        BuffLevel = 30001
    elseif (Level >= 120 and Level < 130) then
        Point = 65
        BuffLevel = 30002
    elseif (Level >= 130 and Level < 140) then
        Point = 70
        BuffLevel = 30003
    elseif (Level >= 140 and Level < 150) then
        Point = 75
        BuffLevel = 30004
    elseif (Level >= 150 and Level <= 200) then
        Point = 80
        BuffLevel = 30005
    else
        Point = 0
        BuffLevel = 0
    end
    if (Point > 0) then
        local CurDay = self:GetDayTime()
        local GuidPoint = self:CityGetAttr(selfId, 6)
        if self:CityChangeAttr(selfId, 6, -1) ~= 1 then return end
        self:SetMissionData(selfId, ScriptGlobal.MD_FAVOROFGUILD_LASTTIME, CurDay)
        local sMessage = string.format("@*;SrvMsg;GLD:#Y#{_INFOUSR%s}#cffff00 tại Quan viên công nghiệp #c00ff00Mã Ứng Hùng#cffff00 đã lĩnh thành công kỹ năng bang phái quan tâm của hôm nay, #c00ff00Cường lực#cffff00 và #c00ff00Nội lực#cffff00 mỗi loại tăng #c00ff00%d#cffff00 điểm.", Name, Point)
        sMessage = gbk.fromutf8(sMessage)
        self:BroadMsgByChatPipe(selfId, sMessage, 6)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, BuffLevel, 0)
    end
end

function pc_industrialofficer:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    elseif arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent", selfId, targetId, arg, self.script_id,self.g_BuildingID16)
        return
    end
    if index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID16)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Industry_Mission_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 8 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_DuanTai}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 9 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_085}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 12 then
        local FavorCode = self:CheckFavorOfGuild(selfId)
        if (0 == FavorCode) then
            self:SetFavorOfGuild(selfId)
        elseif (1 == FavorCode) then
            self:BeginEvent(self.script_id)
            self:AddText("#{FAVOROFGUILD_NOTMEMBER}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif (2 == FavorCode) then
            self:BeginEvent(self.script_id)
            self:AddText("#{FAVOROFGUILD_POINTNOTENOUGH}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif (3 == FavorCode) then
            self:BeginEvent(self.script_id)
            self:AddText("#{FAVOROFGUILD_TIMENOTENOUGH}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif (4 == FavorCode) then
            self:BeginEvent(self.script_id)
            self:AddText("#{FAVOROFGUILD_CITYSTATENOTENOUGH}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end

    elseif index == 888 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate", self, selfId, targetId, self.g_BuildingID16)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function pc_industrialofficer:OnMissionAccept(selfId, targetId, missionScriptId)
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

function pc_industrialofficer:OnMissionRefuse(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function pc_industrialofficer:OnMissionContinue(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
        return
    end
end

function pc_industrialofficer:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
        return
    end
end

function pc_industrialofficer:OnDie(selfId, killerId) end

function pc_industrialofficer:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return require('cys_social_npc').install(pc_industrialofficer)
