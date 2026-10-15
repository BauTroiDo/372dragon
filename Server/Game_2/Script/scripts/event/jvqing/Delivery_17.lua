local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_17 = class("Delivery_17", script_base)
Delivery_17.script_id = 200087
Delivery_17.g_MissionId = 17
Delivery_17.g_PreMissionId = 16
Delivery_17.g_Position_X = 63
Delivery_17.g_Position_Z = 36
Delivery_17.g_SceneID = 2
Delivery_17.g_AccomplishNPC_Name = "段正淳"
Delivery_17.g_Name = "段正淳"
Delivery_17.g_MissionKind = 47
Delivery_17.g_MissionLevel = 40
Delivery_17.g_IfMissionElite = 0
Delivery_17.g_MissionName = "Quần Long Vô Thủ"
Delivery_17.g_MissionInfo = "#{Mis_juqing_0017}"
Delivery_17.g_MissionTarget = "#{Mis_juqing_Tar_0017}"
Delivery_17.g_MissionComplete = "  Ha ha, Thiếu hiệp đã lâu không gặp, gần đây có khỏe không? Đến Đại Lý ta có việc gì sao?"
Delivery_17.g_MoneyBonus = 5400
Delivery_17.g_exp = 5400
Delivery_17.g_Custom = { { ["id"] = "已找到段正淳", ["num"] = 1 }}
Delivery_17.g_IsMissionOkFail = 0
function Delivery_17:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId)then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            self:OnContinue(selfId, targetId)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) ~= self.g_Name then
            local PlayerName = self:GetName(selfId)
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
function Delivery_17:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_17:CheckAccept(selfId)
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
function Delivery_17:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Quần Long Vô Thủ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_17:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_17:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_17:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_17:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Quần Long Vô Thủ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200088), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_17:OnKillObject(selfId, objdataId)
end
function Delivery_17:OnEnterZone(selfId, zoneId)
end
function Delivery_17:OnItemChanged(selfId, itemdataId)
end
return Delivery_17