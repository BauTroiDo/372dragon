local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shimen_0902 = class("shimen_0902", script_base)
shimen_0902.script_id = 228907
shimen_0902.g_MissionId = 2127
shimen_0902.g_Name = "岳老三"
shimen_0902.g_MissionKind = 61
shimen_0902.g_MissionLevel = 10
shimen_0902.g_IfMissionElite = 0
shimen_0902.g_MissionName = "Vì sư môn mà chiến"
shimen_0902.g_MissionInfo = "#{event_erengu_0001}"
shimen_0902.g_MissionTarget = "    Tìm Nhạc Lão Tam ở Ác Nhân Cốc#{_INFOAIM183,182,703,Nhạc Lão Tam}."
shimen_0902.g_MissionComplete = "  Ngươi là đồng môn mới đến đúng không, ngươi đến thật là tốt, nơi ta có rất nhiều việc yêu cầu ngươi hỗ trợ đây."
shimen_0902.g_MoneyBonus = 800
function shimen_0902:OnDefaultEvent(selfId, targetId,arg,index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            self:OnContinue(selfId, targetId)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) ~= self.g_Name then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionInfo)
            self:AddText("#{M_MUBIAO}")
            self:AddText(self.g_MissionTarget)
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
        end
    end
end

function shimen_0902:OnEnumerate(caller, selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) ~= self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
        end
    end
end

function shimen_0902:CheckAccept(selfId)
    local MenPai = self:GetMenPai(selfId)
    if MenPai ~= 16 then
        return 0
    else
        return 1
    end
end

function shimen_0902:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Vì sư môn mà chiến", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
end

function shimen_0902:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end

function shimen_0902:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function shimen_0902:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(888888, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end

function shimen_0902:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 800)
        local ret = self:DelMission(selfId, self.g_MissionId)
        if ret then
            self:MissionCom(selfId, self.g_MissionId)
            self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Vì sư môn mà chiến", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
    end
end

function shimen_0902:OnKillObject(selfId, objdataId)
end

function shimen_0902:OnEnterZone(selfId, zoneId)
end

function shimen_0902:OnItemChanged(selfId, itemdataId)
end

return shimen_0902
