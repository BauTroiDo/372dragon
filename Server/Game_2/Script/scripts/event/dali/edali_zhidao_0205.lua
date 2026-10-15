local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0205 = class("edali_zhidao_0205", script_base)
edali_zhidao_0205.script_id = 210205
edali_zhidao_0205.g_Position_X = 147.4986
edali_zhidao_0205.g_Position_Z = 146.2925
edali_zhidao_0205.g_SceneID = 2
edali_zhidao_0205.g_AccomplishNPC_Name = "钱龙"
edali_zhidao_0205.g_MissionId = 445
edali_zhidao_0205.g_Name = "钱龙"
edali_zhidao_0205.g_MissionKind = 13
edali_zhidao_0205.g_MissionLevel = 2
edali_zhidao_0205.g_IfMissionElite = 0
edali_zhidao_0205.g_MissionName = "Làm quen bằng hữu mới"
edali_zhidao_0205.g_MissionInfo = "#{event_dali_0008}"
edali_zhidao_0205.g_MissionTarget =
    "Tại #GĐại Lý Thành Ngũ Hoa Đàn#W tìm Tứ đại thiện nhân của #RTiền Long#W #{_INFOAIM145,139,2,Tiền Long}.#b#G(Xin dùng chuột trái điểm vào tọa độ có gạch dưới, giúp ngài tìm được NPC này)#l"
edali_zhidao_0205.g_MissionComplete = "#{event_dali_0009}"
edali_zhidao_0205.g_MoneyBonus = 350000
edali_zhidao_0205.g_SignPost = {["x"] = 145, ["z"] = 138, ["tip"] = "钱龙"}

edali_zhidao_0205.g_Custom = {{["id"] = "已找到钱龙", ["num"] = 1}}

edali_zhidao_0205.g_IsMissionOkFail = 1
function edali_zhidao_0205:OnDefaultEvent(selfId, targetId)
    if (self:IsMissionHaveDone(selfId, self.g_MissionId)) then
        return
    elseif (self:IsHaveMission(selfId, self.g_MissionId)) then
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
            self:DispatchMissionInfo(selfId, targetId, self.script_id,
                                     self.g_MissionId)
        end
    end
end

function edali_zhidao_0205:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) ~= self.g_Name then
            caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
        end
    end
end

function edali_zhidao_0205:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 2 then
        return 1
    else
        return 0
    end
end

function edali_zhidao_0205:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Làm quen bằng hữu mới", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId,
                            self.g_SignPost["x"], self.g_SignPost["z"],
                            self.g_SignPost["tip"])
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end

function edali_zhidao_0205:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId,elf.g_SignPost["tip"])
end

function edali_zhidao_0205:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_zhidao_0205:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId,  self.g_MissionId)
    if bRet ~= 1 then return 0 end
    return 1
end

function edali_zhidao_0205:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 100)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Làm quen bằng hữu mới", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(210207, "OnDefaultEvent", selfId, targetId)
    end
end

function edali_zhidao_0205:OnKillObject(selfId, objdataId) end

function edali_zhidao_0205:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0205:OnItemChanged(selfId, itemdataId) end

return edali_zhidao_0205
