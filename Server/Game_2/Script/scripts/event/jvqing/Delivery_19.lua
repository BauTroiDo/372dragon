local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_19 = class("Delivery_19", script_base)
Delivery_19.script_id = 200089
Delivery_19.g_MissionId = 19
Delivery_19.g_PreMissionId = 18
Delivery_19.g_Position_X = 38
Delivery_19.g_Position_Z = 99
Delivery_19.g_SceneID = 9
Delivery_19.g_AccomplishNPC_Name = "玄慈"
Delivery_19.g_Name = "玄慈"
Delivery_19.g_MissionKind = 47
Delivery_19.g_MissionLevel = 40
Delivery_19.g_IfMissionElite = 0
Delivery_19.g_MissionName = "Thiên hạ võ công xuất Thiếu Lâm"
Delivery_19.g_MissionInfo = "#{Mis_juqing_0019}"
Delivery_19.g_MissionTarget = "#{Mis_juqing_Tar_0019}"
Delivery_19.g_MissionComplete = "  A di đà Phật, thí chủ đến Thiếu Lâm của mục đích, lão nạp đã đoán được. Đáng tiếc lão nạp thân ở ngoài hồng trần, không hỏi chuyện hồng trần nữa rồi, A di đà Phật..."
Delivery_19.g_MoneyBonus = 5400
Delivery_19.g_exp = 5400
Delivery_19.g_Custom = {{ ["id"] = "已找到玄慈", ["num"] = 1 }}
Delivery_19.g_IsMissionOkFail = 0
function Delivery_19:OnDefaultEvent(selfId, targetId)
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
function Delivery_19:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_19:CheckAccept(selfId)
    if (self:IsMissionHaveDone(selfId, self.g_MissionId)) then
        return 0
    end
    if self:GetLevel(selfId) < self.g_MissionLevel then
        return 0
    end
    if (not self:IsMissionHaveDone(selfId, self.g_PreMissionId)) then
        return 0
    end
    return 1
end
function Delivery_19:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Thiên Hạ Võ Công Xuất Thiếu Lâm", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_19:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_19:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_19:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_19:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Thiên Hạ Võ Công Xuất Thiếu Lâm", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200090), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_19:OnKillObject(selfId, objdataId)
end
function Delivery_19:OnEnterZone(selfId, zoneId)
end
function Delivery_19:OnItemChanged(selfId, itemdataId)
end
return Delivery_19