local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_33 = class("Delivery_33", script_base)
Delivery_33.script_id = 200094
Delivery_33.g_Position_X = 125.5508
Delivery_33.g_Position_Z = 144.8913
Delivery_33.g_SceneID = 14
Delivery_33.g_AccomplishNPC_Name = "苏星河"
Delivery_33.g_MissionId = 33
Delivery_33.g_PreMissionId = 32
Delivery_33.g_Name = "苏星河"
Delivery_33.g_MissionKind = 53
Delivery_33.g_MissionLevel = 60
Delivery_33.g_IfMissionElite = 0
Delivery_33.g_MissionName = "Trân Lung Kỳ Hội"
Delivery_33.g_MissionInfo = "#{Mis_juqing_0033}"
Delivery_33.g_MissionTarget = "#{Mis_juqing_Tar_0033}"
Delivery_33.g_MissionComplete = "  Nghe danh đại hiệp $N đã lâu, hôm nay gặp mặt quả nhiên là phong thái hơn người, lớp sóng sau xô lớp sóng trước!"
Delivery_33.g_MoneyBonus = 18000
Delivery_33.g_exp = 37500
Delivery_33.g_Custom = { { ["id"] = "已找到苏星河", ["num"] = 1 }}
Delivery_33.g_IsMissionOkFail = 0
function Delivery_33:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            self:OnContinue(selfId, targetId)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) ~= self.g_Name then

            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionInfo)
            self:AddText("#{M_MUBIAO}#r")
            self:AddText(self.g_MissionTarget)
            self:AddText("#{M_SHOUHUO}#r")
            self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
        end
    end
end
function Delivery_33:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) ~= self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
        end
    end
end
function Delivery_33:CheckAccept(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < self.g_MissionLevel then
        return 0
    end
    if not self:IsMissionHaveDone(selfId, self.g_PreMissionId) then
        return 0
    end
    return 1
end
function Delivery_33:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Trân Lung Kỳ Hội", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_33:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_33:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_33:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_33:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Trân Lung Kỳ Hội", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200041), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_33:OnKillObject(selfId, objdataId)
end
function Delivery_33:OnEnterZone(selfId, zoneId)
end
function Delivery_33:OnItemChanged(selfId, itemdataId)
end
return Delivery_33