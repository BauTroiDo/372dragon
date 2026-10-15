local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_39 = class("Delivery_39", script_base)
Delivery_39.script_id = 200096
Delivery_39.g_MissionId = 39
Delivery_39.g_PreMissionId = 38
Delivery_39.g_Position_X = 133
Delivery_39.g_Position_Z = 64
Delivery_39.g_SceneID = 0
Delivery_39.g_AccomplishNPC_Name = "赫连铁树"
Delivery_39.g_Name = "梅剑"
Delivery_39.g_MissionKind = 49
Delivery_39.g_MissionLevel = 70
Delivery_39.g_IfMissionElite = 0
Delivery_39.g_MissionName = "Nhất kiếm thượng Thiên Sơn"
Delivery_39.g_MissionInfo = "#{Mis_juqing_0039}"
Delivery_39.g_MissionTarget = "#{Mis_juqing_Tar_0039}"
Delivery_39.g_MissionComplete = "  Lý Thu Thủy, mấy ngày trước lão tôn chủ vẫn luôn nhắc đến cái tên này. Nhưng nàng ta rốt cuộc là ai, chúng ta cũng không rõ lắm."
Delivery_39.g_MoneyBonus = 10800
Delivery_39.g_exp = 19800
Delivery_39.g_Custom = { { ["id"] = "已找到梅剑", ["num"] = 1 }}
Delivery_39.g_IsMissionOkFail = 0
function Delivery_39:OnDefaultEvent(selfId, targetId)
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
function Delivery_39:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_39:CheckAccept(selfId)
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
function Delivery_39:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Nhất Kiếm Thượng Thiên Sơn", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function Delivery_39:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function Delivery_39:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_39:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_39:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Nhất Kiếm Thượng Thiên Sơn", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200097), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_39:OnKillObject(selfId, objdataId)
end
function Delivery_39:OnEnterZone(selfId, zoneId)
end
function Delivery_39:OnItemChanged(selfId, itemdataId)
end
return Delivery_39