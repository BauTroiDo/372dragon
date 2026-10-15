local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0224 = class("edali_0224", script_base)
edali_0224.script_id = 210224
edali_0224.g_Position_X = 160.0895
edali_0224.g_Position_Z = 156.9309
edali_0224.g_SceneID = 2
edali_0224.g_AccomplishNPC_Name = "赵天师"
edali_0224.g_MissionId = 704
edali_0224.g_Name = "赵天师"
edali_0224.g_MissionKind = 13
edali_0224.g_MissionLevel = 8
edali_0224.g_IfMissionElite = 0
edali_0224.g_IsMissionOkFail = 0
edali_0224.g_MissionName = "Hãy đi xem bố cáo"
edali_0224.g_MissionInfo = "#{event_dali_0034}"
edali_0224.g_MissionTarget = "Đọc #GĐại Lý hoàng cung#W của #RBố Cáo Bài#W #{_INFOAIM148,40,2,-1}, sau đó trở về #GĐại Lý thành Ngũ Hoa Đàn#W tìm #RTriệu Thiên Sư#W #{_INFOAIM160,157,2,Triệu Thiên Sư}.#b#G(Hãy dùng chuột trái chọn tọa độ có gạch dưới, giúp bạn tìm được NPC này)#l"
edali_0224.g_ContinueInfo = "  Ngươi đã xem qua #YBố Cáo Bài#W chưa?"
edali_0224.g_MissionComplete = "  Ngươi đã xem qua #YBố Cáo Bài#W rồi chứ? Những kẻ xấu như vậy, nhất định phải nghiêm trị!"
edali_0224.g_SignPost = { ["x"] = 148, ["z"] = 40, ["tip"] = "布告牌" }
edali_0224.g_MoneyBonus = 10500
edali_0224.g_Custom = { { ["id"] = "已阅读公告牌", ["num"] = 1 }}
edali_0224.g_IsMissionOkFail = 1

function edali_0224:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_ContinueInfo)
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
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

function edali_0224:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
    end
end

function edali_0224:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 8 then
        return 1
    else
        return 0
    end
end

function edali_0224:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, 0)
    self:Msg2Player(selfId, "#YNhận nhiệm vụ: Đến xem cáo thị", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, self.g_SignPost["x"], self.g_SignPost["z"],
        self.g_SignPost["tip"])
end

function edali_0224:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0224:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0224:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local num = self:GetMissionParam(selfId, misIndex, 0)
    if num == 1 then
        return 1
    end
    return 0
end

function edali_0224:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 100)
        local ret = self:DelMission(selfId, self.g_MissionId)
        if ret then
            self:MissionCom(selfId, self.g_MissionId)
            self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Đến xem cáo thị", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            self:CallScriptFunction(210225, "OnDefaultEvent", selfId, targetId)
        end
    end
end

function edali_0224:OnKillObject(selfId, objdataId)

end

function edali_0224:OnEnterArea(selfId, zoneId)

end

function edali_0224:OnItemChanged(selfId, itemdataId)

end

return edali_0224
