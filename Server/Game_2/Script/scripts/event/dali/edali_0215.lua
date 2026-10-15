local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0215 = class("edali_0215", script_base)
edali_0215.script_id = 210215
edali_0215.g_MissionIdPre = 454
edali_0215.g_MissionId = 455
edali_0215.g_Name = "云飘飘"
edali_0215.g_MissionKind = 13
edali_0215.g_MissionLevel = 5
edali_0215.g_IfMissionElite = 0
edali_0215.g_MissionName = "Trân thú Thăng cấp rồi!"
edali_0215.g_MissionInfo = "#{event_dali_0021}"
edali_0215.g_MissionTarget = "#{event_dali_0022}"
edali_0215.g_ContinueInfo = "  Tiểu Thỏ Tử đã thăng đến cấp 2 chưa?"
edali_0215.g_MissionComplete = "#{event_dali_0023}"
edali_0215.g_SignPost = {["x"] = 263, ["z"] = 129, ["tip"] = "云飘飘"}
edali_0215.g_MoneyBonus = 750000
edali_0215.g_PetNeedLevel = 2
edali_0215.g_PetDataID = 559
function edali_0215:OnDefaultEvent(selfId, targetId)
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

function edali_0215:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId)then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0215:CheckAccept(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return 0 end
    if self:GetLevel(selfId) >= self.g_MissionLevel then
        return 1
    else
        return 0
    end
end

function edali_0215:OnAccept(selfId)
    if self:CheckAccept(selfId) ~= 1 then return end
    local ret = self:LuaFnCreatePetToHuman(selfId,self.g_PetDataID, -1, 0)
    if ret then
        self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
        self:BeginEvent(self.script_id)
        local strText = "Ngươi đã nhận được một Trân thú!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Trân thúThăng cấp rồi", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2, self.g_SignPost["x"], self.g_SignPost["z"], self.g_SignPost["tip"])
    end
end

function edali_0215:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    local petcount = self:LuaFnGetPetCount(selfId)
    for i = 1, petcount do
        local petdataid = self:LuaFnGetPet_DataID(selfId, i)
        if petdataid == self.g_PetDataID then
            self:LuaFnDeletePet(selfId, i)
        end
    end
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId,self.g_SignPost["tip"])
end

function edali_0215:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0215:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    local nPetCount = self:LuaFnGetPetCount(selfId)
    for i = 1, nPetCount do
        local nPetId = self:LuaFnGetPet_DataID(selfId, i)
        local nPetLevel = self:LuaFnGetPet_Level(selfId, i)
        if nPetId == 559 and nPetLevel >= 2 then return 1 end
    end
    return 0
end

function edali_0215:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) ~= 1 then return end
    self:AddMoneyJZ(selfId, self.g_MoneyBonus)
    self:LuaFnAddExp(selfId, 810)
    local ret0 = self:DelMission(selfId, self.g_MissionId)
    if ret0 then
        self:MissionCom(selfId, self.g_MissionId)
        self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Trân thúThăng cấp rồi",  define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(210216, "OnDefaultEvent", selfId, targetId)
    end
    self:BeginEvent(self.script_id)
    local strText = "hoàn thành nhiệm vụ"
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function edali_0215:OnKillObject(selfId, objdataId, objId) end

function edali_0215:OnEnterArea(selfId, zoneId) end

function edali_0215:OnItemChanged(selfId, itemdataId) end

function edali_0215:OnMissionCheck(selfId, npcid, scriptId, index1, index2,
                                   index3, indexpet) end

return edali_0215
