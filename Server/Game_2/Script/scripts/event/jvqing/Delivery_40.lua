local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_40 = class("Delivery_40", script_base)
Delivery_40.script_id = 200097
Delivery_40.g_MissionId = 40
Delivery_40.g_PreMissionId = 39
Delivery_40.g_Position_X = 112
Delivery_40.g_Position_Z = 64
Delivery_40.g_SceneID = 0
Delivery_40.g_AccomplishNPC_Name = "努儿海"
Delivery_40.g_Name = "天山童姥"
Delivery_40.g_MissionKind = 49
Delivery_40.g_MissionLevel = 70
Delivery_40.g_IfMissionElite = 0
Delivery_40.g_MissionName = "Tuy nguy thật an"
Delivery_40.g_MissionInfo = "#{Mis_juqing_0040}"
Delivery_40.g_MissionTarget = "#{Mis_juqing_Tar_0040}"
Delivery_40.g_MissionComplete = "  $N, Mai Kiếm nha đầu này không đơn giản a. Chiêu đại bổn kỳ của ta, có thể lừa được Lý Thu Thủy, lại không lừa được nó. Xem ra ta chọn nó làm chưởng môn đời kế, không nhìn lầm người."
Delivery_40.g_MoneyBonus = 21600
Delivery_40.g_exp = 43200
Delivery_40.g_Custom = { { ["id"] = "已找到天山童姥", ["num"] = 1 }}
Delivery_40.g_IsMissionOkFail = 0
function Delivery_40:OnDefaultEvent(selfId, targetId)
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
function Delivery_40:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_40:CheckAccept(selfId)
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
function Delivery_40:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Tuy Nguy Thật An", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_40:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_40:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_40:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_40:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Tuy Nguy Thật An", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200051), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_40:OnKillObject(selfId, objdataId)
end
function Delivery_40:OnEnterZone(selfId, zoneId)
end
function Delivery_40:OnItemChanged(selfId, itemdataId)
end
return Delivery_40