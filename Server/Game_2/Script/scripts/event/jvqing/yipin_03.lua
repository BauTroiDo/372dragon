local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yipin_03 = class("yipin_03", script_base)
yipin_03.script_id = 200052
yipin_03.g_MissionId = 42
yipin_03.g_PreMissionId = 41
yipin_03.g_Position_X = 113
yipin_03.g_Position_Z = 64
yipin_03.g_SceneID = 0
yipin_03.g_AccomplishNPC_Name = "赫连铁树"
yipin_03.g_Name = "赫连铁树"
yipin_03.g_IfMissionElite = 1
yipin_03.g_MissionLevel = 70
yipin_03.g_MissionKind = 49
yipin_03.g_MissionName = "Khuyên Bội Không Quy Nguyệt Dạ Hồn"
yipin_03.g_MissionInfo = "#{Mis_juqing_0042}"
yipin_03.g_MissionTarget = "#{Mis_juqing_Tar_0042}"
yipin_03.g_MissionComplete = "  Ôi, Hoàng thái phi lại băng hà trên đường... Hoàng thượng nhất định sẽ vô cùng đau buồn!"
yipin_03.g_MoneyBonus = 10800
yipin_03.g_exp = 21600
yipin_03.g_Custom = { { ["id"] = "已找到赫连铁树", ["num"] = 1 }}
function yipin_03:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionComplete)
            self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
        end
    elseif self:CheckAccept(selfId, targetId) > 0 then
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
function yipin_03:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
        end
    elseif self:CheckAccept(selfId, targetId) > 0 then
        if self:GetName(targetId) == "虚竹" then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
        end
    end
end
function yipin_03:CheckAccept(selfId, targetId)
    if not self:IsMissionHaveDone(selfId, self.g_PreMissionId) then
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < 70 then
        return 0
    end
    return 1
end
function yipin_03:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId, targetId) ~= 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Khuyên Bội Không Quy Nguyệt Dạ Hồn", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end
function yipin_03:OnTimer(selfId)
end
function yipin_03:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function yipin_03:OnContinue(selfId, targetId)
end
function yipin_03:CheckSubmit(selfId, selectRadioId)
end
function yipin_03:OnSubmit(selfId, targetId, selectRadioId)
    self:AddMoney(selfId, self.g_MoneyBonus)
    self:LuaFnAddExp(selfId, self.g_exp)
    self:DelMission(selfId, self.g_MissionId)
    self:MissionCom(selfId, self.g_MissionId)
    self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Khuyên Bội Không Quy Nguyệt Dạ Hồn", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction((200053), "OnDefaultEvent", selfId, targetId)
end
function yipin_03:OnKillObject(selfId, objdataId, objId)
end
function yipin_03:OnEnterZone(selfId, zoneId)
end
function yipin_03:OnItemChanged(selfId, itemdataId)
end
return yipin_03