local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_24 = class("Delivery_24", script_base)
Delivery_24.script_id = 200091
Delivery_24.g_Position_X = 230.2647
Delivery_24.g_Position_Z = 215.0359
Delivery_24.g_SceneID = 0
Delivery_24.g_AccomplishNPC_Name = "康敏"
Delivery_24.g_MissionId = 24
Delivery_24.g_PreMissionId = 23
Delivery_24.g_Name = "康敏"
Delivery_24.g_MissionKind = 52
Delivery_24.g_MissionLevel = 50
Delivery_24.g_IfMissionElite = 0
Delivery_24.g_MissionName = "Bảo Vệ Mã Phu Nhân"
Delivery_24.g_MissionInfo = "#{Mis_juqing_0024}"
Delivery_24.g_MissionTarget = "#{Mis_juqing_Tar_0024}"
Delivery_24.g_MissionComplete = "  Đại hiệp đường xa đến đây, không bằng vào nhà uống chén trà, nghỉ ngơi chân một lát."
Delivery_24.g_MoneyBonus = 7200
Delivery_24.g_exp = 9360
Delivery_24.g_Custom = { { ["id"] = "已找到康敏", ["num"] = 1 }
}
Delivery_24.g_IsMissionOkFail = 0
function Delivery_24:OnDefaultEvent(selfId, targetId)
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
function Delivery_24:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_24:CheckAccept(selfId)
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
function Delivery_24:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Bảo vệ Mã phu nhân", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_24:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_24:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_24:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_24:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Bảo vệ Mã phu nhân", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200092), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_24:OnKillObject(selfId, objdataId)
end
function Delivery_24:OnEnterZone(selfId, zoneId)
end
function Delivery_24:OnItemChanged(selfId, itemdataId)
end
return Delivery_24