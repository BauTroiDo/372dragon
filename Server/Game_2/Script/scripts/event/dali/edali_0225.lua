local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0225 = class("edali_0225", script_base)
edali_0225.script_id = 210225
edali_0225.g_Position_X = 214.8831
edali_0225.g_Position_Z = 283.8709
edali_0225.g_SceneID = 2
edali_0225.g_AccomplishNPC_Name = "段延庆"
edali_0225.g_MissionId = 705
edali_0225.g_MissionIdPre = 704
edali_0225.g_Name = "段延庆"
edali_0225.g_MissionKind = 13
edali_0225.g_MissionLevel = 9
edali_0225.g_IfMissionElite = 0
edali_0225.g_MissionName = "段延庆"
edali_0225.g_MissionInfo = "#{event_dali_0035}"
edali_0225.g_MissionTarget = "Tìm thấy #RĐoàn Diên Khánh#W tại #GNgọc Nhĩ Hạng phía Đông Nam Đại Lý Thành#W #{_INFOAIM215,284,2,Đoàn Diên Khánh}.#b#G(Xin hãy dùng chuột trái để chọn tọa độ có gạch dưới, giúp ngài tìm thấy NPC này)#l"
edali_0225.g_MissionComplete = "#{event_dali_0036}"
edali_0225.g_MoneyBonus = 110000
edali_0225.g_SignPost = { ["x"] = 215, ["z"] = 284, ["tip"] = "段延庆" }
edali_0225.g_Custom = { { ["id"] = "已找到段延庆", ["num"] = 1 }}
edali_0225.g_IsMissionOkFail = 1

function edali_0225:OnDefaultEvent(selfId, targetId)
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

function edali_0225:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
        return
    end

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

function edali_0225:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 8 then
        return 1
    else
        return 0
    end
end

function edali_0225:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Đoàn Diên Khánh", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2, self.g_SignPost["x"], self.g_SignPost["z"],self.g_SignPost["tip"])
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end

function edali_0225:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0225:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0225:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    return 1
end

function edali_0225:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 100)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Đoàn Diên Khánh", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(210226, "OnDefaultEvent", selfId, targetId)
    end
end

function edali_0225:OnKillObject(selfId, objdataId)

end

function edali_0225:OnEnterZone(selfId, zoneId)

end

function edali_0225:OnItemChanged(selfId, itemdataId)

end

return edali_0225
