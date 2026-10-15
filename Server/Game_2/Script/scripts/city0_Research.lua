local class = require "class"
local define = require "define"
local script_base = require "script_base"
local city0_Research = class("city0_Research", script_base)
city0_Research.script_id = 805026
city0_Research.g_MissionId = 443
city0_Research.g_MissionIdPre = 441
city0_Research.g_Name = "帮会大总管"
city0_Research.g_ItemId = 30101001
city0_Research.g_ItemNeedNum = 1
city0_Research.g_MissionKind = 13
city0_Research.g_MissionLevel = 1
city0_Research.g_IfMissionElite = 0
city0_Research.g_IsMissionOkFail = 0
city0_Research.g_DemandItem = {{["id"] = 30101001, ["num"] = 1}}
city0_Research.g_MissionName = "Thăng cấp nghiên cứu"
city0_Research.g_MissionInfo_1 = "  #R"
city0_Research.g_MissionInfo_2 = "#{city0_levelup_0001}"
city0_Research.g_MissionTarget = "Cho Đại tổng quản bang hội 5 kim tệ"
city0_Research.g_MissionContinue = "Ngươi đã có 5 kim tệ chưa?"
city0_Research.g_MissionComplete =
    "  Ừm, làm không tệ. Xem ra ngươi rất có tiền a."
city0_Research.g_MoneyBonus = 0
city0_Research.g_SignPost = {
    ["x"] = 109,
    ["z"] = 167,
    ["tip"] = "帮会大总管"
}
city0_Research.g_ItemBonus = {{["id"] = 30304001, ["num"] = 1}}

function city0_Research:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionContinue)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        local PlayerName = self:GetName(selfId)
        local PlayerSex = self:GetSex(selfId)
        if PlayerSex == 0 then
            PlayerSex = "Cô nương"
        else
            PlayerSex = "Thiếu hiệp"
        end
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo_1 .. PlayerName .. PlayerSex .. self.g_MissionInfo_2)
        self:AddText("#{M_MUBIAO}")
        self:AddText(self.g_MissionTarget)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id,  self.g_MissionId)
    end
end

function city0_Research:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    end
end

function city0_Research:CheckAccept(selfId)
    if type(self.CityIncProgress) ~= "function" then return 0 end
    if self:GetLevel(selfId) >= 1 then
        return 1
    else
        return 0
    end
end

function city0_Research:OnAccept(selfId)
    if type(self.CityIncProgress) ~= "function" then return 0 end
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Thăng cấp nghiên cứu", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
end

function city0_Research:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end

function city0_Research:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id,  self.g_MissionId)
end

function city0_Research:CheckSubmit(selfId)
    if type(self.CityIncProgress) ~= "function" then return 0 end
    local SelfMoney = self:GetMoney(selfId)
    if (SelfMoney < 50000) then return 0 end
    return 1
end

function city0_Research:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        local ret = self:DelMission(selfId, self.g_MissionId)
        if ret then
            self:CostMoney(selfId, 50000)
            self:CityIncProgress(selfId, 1)
            self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Thăng cấp nghiên cứu", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
    end
end

function city0_Research:OnKillObject(selfId, objdataId) end

function city0_Research:OnEnterZone(selfId, zoneId) end

function city0_Research:OnItemChanged(selfId, itemdataId) end

return city0_Research
