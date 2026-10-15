local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0213 = class("edali_0213", script_base)
edali_0213.script_id = 210213
edali_0213.g_Position_X = 160.0895
edali_0213.g_Position_Z = 156.9309
edali_0213.g_SceneID = 2
edali_0213.g_AccomplishNPC_Name = "赵天师"
edali_0213.g_MissionId = 453
edali_0213.g_Name = "赵天师"
edali_0213.g_MissionKind = 13
edali_0213.g_MissionLevel = 4
edali_0213.g_IfMissionElite = 0
edali_0213.g_DemandKill = { { ["id"] = 719, ["num"] = 8 }}
edali_0213.g_MissionName = "Lần đầu giết quái"
edali_0213.g_MissionInfo = "#{event_dali_0018}"
edali_0213.g_MissionTarget = "#{event_dali_0019}"
edali_0213.g_ContinueInfo = "Ngươi đã giết 8 con #RThục đạo bạch viên#W rồi ư?"
edali_0213.g_MissionComplete = "  Làm tốt lắm, hiện tại #Gđống đá bãi cát#Wcủa #RThục đạo bạch viên#W sẽ không dám dễ dàng tập kích bách tính nữa."
edali_0213.g_SignPost = { ["x"] = 160, ["z"] = 156, ["tip"] = "赵天师" }
edali_0213.g_MoneyBonus = 65000
edali_0213.g_ItemBonus = { { ["id"] = 30008066, ["num"] = 1 }, { ["id"] = 30101001, ["num"] = 5 }}
edali_0213.g_DemandTrueKill = { { ["name"] = "蜀道白猿", ["num"] = 8 }}
edali_0213.g_IsMissionOkFail = 1

function edali_0213:OnDefaultEvent(selfId, targetId)
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
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItemBonus(item["id"], item["num"])
        end
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function edali_0213:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    end

    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
    end
end

function edali_0213:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 4 then
        return 1
    else
        return 0
    end
end

function edali_0213:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Lần đầu giết quái", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)

    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, self.g_SignPost["x"], self.g_SignPost["z"],
        self.g_SignPost["tip"])

    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 7, 71, 250, "Bạch viên")

    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 75, 71, 250, "Bạch viên")

    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 76, 71, 250, "Bạch viên")
end

function edali_0213:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)

    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0213:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    for i, item in pairs(self.g_ItemBonus) do
        self:AddItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0213:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local num = self:GetMissionParam(selfId, misIndex, 1)
    if num == self.g_DemandTrueKill[1]["num"] then
        return 1
    end
    return 0
end

function edali_0213:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItem(item["id"], item["num"])
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            self:AddMoneyJZ(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 1200)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:AddItemListToHuman(selfId)
                self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Lần đầu giết quái", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi đã đầy, không thể hoàn thành nhiệm vụ"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function edali_0213:OnKillObject(selfId, objdataId, objId)
    if self:GetName(objId) == self.g_DemandTrueKill[1]["name"] then
        local num = self:GetNearHumanCount(objId)
        for j = 1, num do
            local humanObjId = self:GetNearHuman(objId, j)
            if self:IsHaveMission(humanObjId, self.g_MissionId) then
                local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
                local nNum = self:GetMissionParam(humanObjId, misIndex, 1)
                if nNum < self.g_DemandTrueKill[1]["num"] then
                    if nNum == self.g_DemandTrueKill[1]["num"] - 1 then
                        self:SetMissionByIndex(humanObjId, misIndex, 0, 1)
                    end
                    self:SetMissionByIndex(humanObjId, misIndex, 1, nNum + 1)
                    self:BeginEvent(self.script_id)
                    local strText = string.format("Đã giết Thục đạo bạch viên %d/8", self:GetMissionParam(humanObjId, misIndex, 1))
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(humanObjId)
                end
            end
        end
    end
end

function edali_0213:OnEnterArea(selfId, zoneId)

end

function edali_0213:OnItemChanged(selfId, itemdataId)

end

return edali_0213
