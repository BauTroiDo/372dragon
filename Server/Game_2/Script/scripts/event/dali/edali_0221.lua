local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0221 = class("edali_0221", script_base)
edali_0221.script_id = 210221
edali_0221.g_MissionIdPre = 700
edali_0221.g_MissionId = 701
edali_0221.g_Name = "云飘飘"
edali_0221.g_MissionKind = 13
edali_0221.g_MissionLevel = 7
edali_0221.g_IfMissionElite = 0
edali_0221.g_IsMissionOkFail = 0
edali_0221.g_MissionName = "Bắt được Trân thú rồi!"
edali_0221.g_MissionInfo = "#{event_dali_0029}"
edali_0221.g_MissionTarget = "#{event_dali_0030}"
edali_0221.g_ContinueInfo = "Ngươi đã bắt được Tiểu Áp Tử rồi sao?"
edali_0221.g_MissionComplete = "#{event_dali_0031}"
edali_0221.g_SignPost = {["x"] = 275, ["z"] = 50, ["tip"] = "黄眉僧"}
edali_0221.g_MoneyBonus = 950000
edali_0221.g_Param_ok = 0
edali_0221.g_PetDataID = 558
function edali_0221:OnDefaultEvent(selfId, targetId)
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

function edali_0221:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0221:CheckAccept(selfId)
    if self:GetLevel(selfId) >= self.g_MissionLevel then
        return 1
    else
        return 0
    end
end

function edali_0221:OnAccept(selfId)
    self:AddMissionEx(selfId, self.g_MissionId, self.script_id)
    self:SetMissionEvent(selfId, self.g_MissionId, 3)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_Param_ok, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Bắt Trân thú thôi!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2,self.g_SignPost["x"], self.g_SignPost["z"], self.g_SignPost["tip"])
end

function edali_0221:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    local petcount = self:LuaFnGetPetCount(selfId)
    for i = 1, petcount do
        local petdataid = self:LuaFnGetPet_DataID(selfId, i)
        if petdataid == self.g_PetDataID then
            self:LuaFnDeletePet(selfId, i)
        end
    end
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0221:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)

end

function edali_0221:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
    local nPetCount = self:LuaFnGetPetCount(selfId)
    for i = 1, nPetCount do
        local nPetId = self:LuaFnGetPet_DataID(selfId, i)
        if nPetId == 558 then return 1 end
    end
    return 0
end

function edali_0221:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) < 1 then return end
    local ret0 = self:DelMission(selfId, self.g_MissionId)
    if ret0 then
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 700)
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Bắt Trân thú rồi!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(210223, "OnDefaultEvent", selfId, targetId)
        self:BeginEvent(self.script_id)
        local strText = "hoàn thành nhiệm vụ: Bắt được Trân thú rồi!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function edali_0221:OnKillObject(selfId, objdataId, objId) end

function edali_0221:OnEnterArea(selfId, zoneId) end

function edali_0221:OnItemChanged(selfId, itemdataId) end

function edali_0221:OnPetChanged(selfId, petdataId)
    if petdataId == self.g_PetDataID then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_ok, 1)
        self:BeginEvent(self.script_id)
        local strText = "Bắt được Trân thú rồi, nhiệm vụ hoàn thành!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function edali_0221:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet) end
function edali_0221:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet) end

return edali_0221
