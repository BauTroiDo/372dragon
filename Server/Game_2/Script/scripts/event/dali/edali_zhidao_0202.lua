local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0202 = class("edali_zhidao_0202", script_base)
edali_zhidao_0202.script_id = 210202
edali_zhidao_0202.g_Position_X = 110.0841
edali_zhidao_0202.g_Position_Z = 158.7671
edali_zhidao_0202.g_SceneID = 2
edali_zhidao_0202.g_AccomplishNPC_Name = "杜子腾"
edali_zhidao_0202.g_MissionId = 442
edali_zhidao_0202.g_MissionIdPre = 441
edali_zhidao_0202.g_Name = "杜子腾"
edali_zhidao_0202.g_ItemId = 30101001
edali_zhidao_0202.g_ItemNeedNum = 1
edali_zhidao_0202.g_MissionKind = 13
edali_zhidao_0202.g_MissionLevel = 1
edali_zhidao_0202.g_IfMissionElite = 0
edali_zhidao_0202.g_DemandItem = {{["id"] = 30101001, ["num"] = 1}}

edali_zhidao_0202.g_IsMissionOkFail = 1
edali_zhidao_0202.g_MissionName = "Cái bánh bao đầu tiên"
edali_zhidao_0202.g_MissionInfo_1 = "  #R"
edali_zhidao_0202.g_MissionInfo_2 = "#{event_dali_0004}"
edali_zhidao_0202.g_MissionTarget = "#{xinshou_002}"
edali_zhidao_0202.g_MissionContinue = "Ngươi đã làm ra #YBánh Bao#W rồi ư?"
edali_zhidao_0202.g_MissionComplete =
    "  Ừm, làm tốt lắm. Xem ra thiên phú nấu nướng của ngươi không phải dạng vừa đâu."
edali_zhidao_0202.g_MoneyBonus = 200000
edali_zhidao_0202.g_SignPost = {["x"] = 110, ["z"] = 159, ["tip"] = "杜子腾"}

edali_zhidao_0202.g_RadioItemBonus = {
    {["id"] = 30304030, ["num"] = 1}, {["id"] = 30304031, ["num"] = 1}
}

function edali_zhidao_0202:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionContinue)
        for i, item in pairs(self.g_DemandItem) do
            self:AddItemDemand(item["id"], item["num"])
        end
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        local PlayerName = self:GetName(selfId)
        local PlayerSex = self:GetSex(selfId)
        if PlayerSex == 0 then
            PlayerSex = "Cô nương"
        else
            PlayerSex = "Thiếu hiệp"
        end
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo_1 .. PlayerName .. PlayerSex ..
                         self.g_MissionInfo_2)
        self:AddText("#{M_MUBIAO}")
        self:AddText(self.g_MissionTarget)
        for i, item in pairs(self.g_RadioItemBonus) do
            self:AddItemBonus(item["id"], item["num"])
        end
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id,
                                 self.g_MissionId)
    end
end

function edali_zhidao_0202:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_zhidao_0202:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 1 then
        return 1
    else
        return 0
    end
end

function edali_zhidao_0202:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp Nhận Nhiệm Vụ: Bánh Bao Đầu Tiên", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId,
                            self.g_SignPost["x"], self.g_SignPost["z"],
                            self.g_SignPost["tip"])
end

function edali_zhidao_0202:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_zhidao_0202:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyJZBonus(self.g_MoneyBonus)
    for i, item in pairs(self.g_RadioItemBonus) do
        self:AddRadioItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id,
                                     self.g_MissionId)
end

function edali_zhidao_0202:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId,
                                         self.g_MissionId)
    if bRet ~= 1 then return 0 end
    for i, item in pairs(self.g_DemandItem) do
        local itemCount = self:GetItemCount(selfId, item["id"])
        if itemCount < item["num"] then return 0 end
    end
    return 1
end

function edali_zhidao_0202:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_RadioItemBonus) do
            if item["id"] == selectRadioId then
                self:AddItem(item["id"], item["num"])
            end
        end
        local ret = self:EndAddItem(selfId)
        local DelRet = 1
        for i, item in pairs(self.g_DemandItem) do
            if not self:DelItem(selfId, item["id"], item["num"]) then
                DelRet = 0
            end
        end
        if DelRet == 0 then
            self:Msg2Player(selfId, "#YKhấu Trừ Bánh Bao Thất Bại", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            self:BeginEvent(self.script_id)
            local strText = "Khấu trừ bánh bao thất bại, có phải bị khóa rồi không?"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        if ret then
            self:AddMoney(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 20)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:AddItemListToHuman(selfId)
                self:Msg2Player(selfId, "#YHoàn thành Nhiệm Vụ: Bánh Bao Đầu Tiên", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                self:CallScriptFunction(210203, "OnDefaultEvent", selfId,
                                        targetId)
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

function edali_zhidao_0202:OnKillObject(selfId, objdataId) end

function edali_zhidao_0202:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0202:OnItemChanged(selfId, itemdataId)
    if itemdataId == 30101001 then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
    end
end

return edali_zhidao_0202
