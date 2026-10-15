local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_38 = class("Delivery_38", script_base)
Delivery_38.script_id = 200095
Delivery_38.g_Position_X = 113.5541
Delivery_38.g_Position_Z = 63.7330
Delivery_38.g_SceneID = 0
Delivery_38.g_AccomplishNPC_Name = "赫连铁树"
Delivery_38.g_MissionId = 38
Delivery_38.g_PreMissionId = 37
Delivery_38.g_Name = "赫连铁树"
Delivery_38.g_MissionKind = 49
Delivery_38.g_MissionLevel = 70
Delivery_38.g_IfMissionElite = 0
Delivery_38.g_MissionName = "Vạn Quốc Xúc Cúc Cẩm Tiêu Tái"
Delivery_38.g_MissionInfo = "#{Mis_juqing_0038}"
Delivery_38.g_MissionTarget = "#{Mis_juqing_Tar_0038}"
Delivery_38.g_MissionComplete = "  #{TM_20080313_05}"
Delivery_38.g_MoneyBonus = 10800
Delivery_38.g_exp = 21600
Delivery_38.g_Custom = { { ["id"] = "已找到赫连铁树", ["num"] = 1 }}
Delivery_38.g_IsMissionOkFail = 0
function Delivery_38:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
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
function Delivery_38:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_38:CheckAccept(selfId)
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
function Delivery_38:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, " #{TM_20080313_02}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#{TM_20080313_06}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_38:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_38:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_38:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_38:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#{TM_20080313_07}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200096), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_38:OnKillObject(selfId, objdataId)
end
function Delivery_38:OnEnterZone(selfId, zoneId)
end
function Delivery_38:OnItemChanged(selfId, itemdataId)
end
return Delivery_38