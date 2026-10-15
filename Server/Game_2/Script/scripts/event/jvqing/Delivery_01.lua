local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_01 = class("Delivery_01", script_base)
Delivery_01.script_id = 200080
Delivery_01.g_Position_X = 62.9422
Delivery_01.g_Position_Z = 35.9417
Delivery_01.g_SceneID = 2
Delivery_01.g_AccomplishNPC_Name = "段正淳"
Delivery_01.g_MissionId = 1
Delivery_01.g_PreMissionId = 3
Delivery_01.g_Name = "段正淳"
Delivery_01.g_MissionKind = 51
Delivery_01.g_MissionLevel = 20
Delivery_01.g_IfMissionElite = 0
Delivery_01.g_MissionName = "Ai gia tử đệ ai gia viện"
Delivery_01.g_MissionInfo = "#{Mis_juqing_0001}"
Delivery_01.g_MissionTarget = "#{Mis_juqing_Tar_0001}"
Delivery_01.g_MissionComplete = "  $N, ngươi cuối cùng cũng đến, ta đợi ngươi đã lâu."
Delivery_01.g_MoneyBonus = 10
Delivery_01.g_exp = 2800
Delivery_01.g_Custom = {{ ["id"] = "已找到段正淳", ["num"] = 1 }}
Delivery_01.g_IsMissionOkFail = 0
function Delivery_01:OnDefaultEvent(selfId, targetId)
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
function Delivery_01:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_01:CheckAccept(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < self.g_MissionLevel then
        return 0
    end
    return 1
end
function Delivery_01:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Ai Gia Tử Đệ Ai Gia Viện", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_01:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_01:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_01:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_01:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Ai Gia Tử Đệ Ai Gia Viện", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200081), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_01:OnKillObject(selfId, objdataId)
end
function Delivery_01:OnEnterZone(selfId, zoneId)
end
function Delivery_01:OnItemChanged(selfId, itemdataId)
end
return Delivery_01