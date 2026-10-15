local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0226 = class("edali_0226", script_base)
edali_0226.script_id = 210226
edali_0226.g_MissionId = 706
edali_0226.g_MissionIdPre = 705
edali_0226.g_Name = "段延庆"
edali_0226.g_MissionKind = 13
edali_0226.g_MissionLevel = 8
edali_0226.g_IfMissionElite = 0
edali_0226.g_IsMissionOkFail = 0
edali_0226.g_MissionName = "Tặng màn thầu"
edali_0226.g_MissionInfo =
    "  [Thì ra ngươi vì cáo thị kia mà đến của. Ta không cùng ngươi nói lời thừa. Đằng kia có một #RTiểu khất cái#W sắp chết đói rồi, ngươi tìm cái #Ymàn thầu#W mang đến cho hắn đi.]"
edali_0226.g_MissionTarget = "#{event_dali_0037}"
edali_0226.g_ContinueInfo =
    "  [Ngươi đã đem #Ymàn thầu#W đưa đến tay #RTiểu khất cái#W rồi sao?]"
edali_0226.g_MissionComplete =
    "  [Ừm, xem ra ngươi, người trẻ tuổi này, vẫn là một người có thể tạo.]"
edali_0226.g_SignPost = {["x"] = 199, ["z"] = 256, ["tip"] = "小乞丐"}
edali_0226.g_Custom = {{["id"] = "给小乞丐送馒头！", ["num"] = 1}}
edali_0226.g_MoneyBonus = 1150000
function edali_0226:OnDefaultEvent(selfId, targetId)
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

function edali_0226:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0226:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 8 then
        return 1
    else
        return 0
    end
end

function edali_0226:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    self:TryRecieveItem(selfId, 30101001, true)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Giao bánh bao", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2, self.g_SignPost["x"], self.g_SignPost["z"], self.g_SignPost["tip"])
end

function edali_0226:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0226:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0226:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local num = self:GetMissionParam(selfId, misIndex, 0)
    if num == 1 then return 1 end
    return 0
end

function edali_0226:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 400)
        local ret = self:DelMission(selfId, self.g_MissionId)
        if ret then
            self:MissionCom(selfId, self.g_MissionId)
            self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Giao bánh bao", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            self:CallScriptFunction(210227, "OnDefaultEvent", selfId, targetId)
        end
    end
end

function edali_0226:OnKillObject(selfId, objdataId) end

function edali_0226:OnEnterArea(selfId, zoneId) end

function edali_0226:OnItemChanged(selfId, itemdataId) end

return edali_0226
