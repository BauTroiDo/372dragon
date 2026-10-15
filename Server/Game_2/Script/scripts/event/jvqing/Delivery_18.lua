local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Delivery_18 = class("Delivery_18", script_base)
Delivery_18.script_id = 200088
Delivery_18.g_MissionId = 18
Delivery_18.g_PreMissionId = 17
Delivery_18.g_Name = "徐惊雷"
Delivery_18.g_MissionKind = 47
Delivery_18.g_MissionLevel = 40
Delivery_18.g_Position_X = 210.2844
Delivery_18.g_Position_Z = 201.6758
Delivery_18.g_SceneID = 0
Delivery_18.g_AccomplishNPC_Name = "徐惊雷"
Delivery_18.g_IfMissionElite = 0
Delivery_18.g_MissionName = "Cộng Đồng Tiến Thoái"
Delivery_18.g_MissionInfo = "#{Mis_juqing_0018}"
Delivery_18.g_MissionTarget = "#{Mis_juqing_Tar_0018}"
Delivery_18.g_MissionComplete = "  Thật không ngờ Trấn Nam Vương lại coi thường đại nghĩa dân tộc, thật khiến người ta đau lòng!"
Delivery_18.g_MoneyBonus = 5400
Delivery_18.g_exp = 5400
Delivery_18.g_Custom = { { ["id"] = "已找到徐惊雷", ["num"] = 1 }}
Delivery_18.g_IsMissionOkFail = 0
function Delivery_18:OnDefaultEvent(selfId, targetId)
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
function Delivery_18:OnEnumerate(caller, selfId, targetId, arg, index)
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
function Delivery_18:CheckAccept(selfId)
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
function Delivery_18:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId) < 1 then
        return 0
    end
    self:BeginAddItem()
    self:AddItem(40001006, 1)
    local ret = self:EndAddItem(selfId)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YTúi nhiệm vụ của ngươi đã đầy.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    else
        local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
        if ret <= 0 then
            self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            return
        end
        self:AddItemListToHuman(selfId)
        self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Cùng Chung Tiến Thoái", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
    end
end
function Delivery_18:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:DelItem(selfId, 40001006, 1)
end
function Delivery_18:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function Delivery_18:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end
function Delivery_18:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:DelItem(selfId, 40001006, 1)
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Cùng Chung Tiến Thoái", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200089), "OnDefaultEvent", selfId, targetId)
    end
end
function Delivery_18:OnKillObject(selfId, objdataId)
end
function Delivery_18:OnEnterZone(selfId, zoneId)
end
function Delivery_18:OnItemChanged(selfId, itemdataId)
end
return Delivery_18