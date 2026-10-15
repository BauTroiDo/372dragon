local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0220 = class("edali_0220", script_base)
edali_0220.script_id = 210220
edali_0220.g_Position_X = 265.4445
edali_0220.g_Position_Z = 128.5832
edali_0220.g_SceneID = 2
edali_0220.g_AccomplishNPC_Name = "云飘飘"
edali_0220.g_MissionId = 700
edali_0220.g_Name = "云飘飘"
edali_0220.g_MissionKind = 13
edali_0220.g_MissionLevel = 7
edali_0220.g_IfMissionElite = 0
edali_0220.g_MissionName = "Làm sao bắt Trân thú đây?"
edali_0220.g_MissionInfo = "#{event_dali_0027}"
edali_0220.g_MissionTarget = "    Đến #GĐại Lý Thành Đại Lộ Phía Đông#W của #YTrùng Điểu Phường#W tìm phường chủ #RVân Phiêu Phiêu#W #{_INFOAIM265,129,2,Vân Phiêu Phiêu}.#b#G(Hãy dùng chuột trái chọn vào tọa độ có gạch dưới để giúp ngươi tìm được NPC này)#l"
edali_0220.g_MissionComplete = "#{event_dali_0028}"
edali_0220.g_MoneyBonus = 90000
edali_0220.g_SignPost = { ["x"] = 263, ["z"] = 129, ["tip"] = "云飘飘" }

function edali_0220:OnDefaultEvent(selfId, targetId)
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
            self:AddText("#{M_MUBIAO}")
            self:AddText(self.g_MissionTarget)
            self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
        end
    end
end

function edali_0220:OnEnumerate(caller, selfId, targetId, arg, index)
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

function edali_0220:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 7 then
        return 1
    else
        return 0
    end
end

function edali_0220:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Làm sao bắt Trân thú đây?", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, self.g_SignPost["x"], self.g_SignPost["z"],self.g_SignPost["tip"])
end

function edali_0220:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0220:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0220:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end

function edali_0220:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 500)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Làm sao bắt Trân thú đây?", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(210221, "OnDefaultEvent", selfId, targetId)
    end
end

function edali_0220:OnKillObject(selfId, objdataId)

end

function edali_0220:OnEnterZone(selfId, zoneId)

end

function edali_0220:OnItemChanged(selfId, itemdataId)

end

return edali_0220
