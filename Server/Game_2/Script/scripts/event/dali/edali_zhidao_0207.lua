local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0207 = class("edali_zhidao_0207", script_base)
edali_zhidao_0207.script_id = 210207
edali_zhidao_0207.g_Position_X = 147.4986
edali_zhidao_0207.g_Position_Z = 146.2925
edali_zhidao_0207.g_SceneID = 2
edali_zhidao_0207.g_AccomplishNPC_Name = "钱龙"
edali_zhidao_0207.g_MissionId = 447
edali_zhidao_0207.g_MissionIdPre = 445
edali_zhidao_0207.g_Name = "钱龙"
edali_zhidao_0207.g_MissionKind = 13
edali_zhidao_0207.g_MissionLevel = 2
edali_zhidao_0207.g_IfMissionElite = 0
edali_zhidao_0207.g_IsMissionOkFail = 0
edali_zhidao_0207.g_Custom = {
    {["id"] = "已连续答对钱龙的五个问题", ["num"] = 1}
}

edali_zhidao_0207.g_MissionName = "Lần đầu hỏi đáp"
edali_zhidao_0207.g_MissionInfo = "#{event_dali_0010}"
edali_zhidao_0207.g_MissionTarget =
    "Liên tiếp trả lời đúng năm câu hỏi của #RTiền Long#W#{_INFOAIM145,139,2,Tiền Long}. #b#G(Xin hãy dùng chuột trái điểm vào tọa độ có gạch dưới, để giúp bạn tìm được NPC đó)#l"
edali_zhidao_0207.g_MissionComplete =
    "  Khổng Tử từng nói, đứa trẻ này có thể dạy dỗ được. Chúc mừng con đã qua cửa! Số tiền này là ta tặng con để làm lộ phí giang hồ."
edali_zhidao_0207.g_MoneyBonus = 400000
edali_zhidao_0207.g_SignPost = {["x"] = 145, ["z"] = 138, ["tip"] = "钱龙"}

edali_zhidao_0207.g_ItemBonus = {{["id"] = 10110000, ["num"] = 1}}

function edali_zhidao_0207:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local num = self:GetMissionParam(selfId, misIndex, 1)
        if num < 1 then
            self:CallScriptFunction(311100, "OnDefaultEvent", selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionComplete)
            self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            local bDone = self:CheckSubmit(selfId)
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,
                                           self.g_MissionId, bDone)
        end
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
        self:DispatchMissionInfo(selfId, targetId, self.script_id,
                                 self.g_MissionId)
    end
end

function edali_zhidao_0207:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_zhidao_0207:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 2 then
        return 1
    else
        return 0
    end
end

function edali_zhidao_0207:OnAccept(selfId, targetId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:CallScriptFunction(311100, "OnDefaultEvent", selfId, targetId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Lần đầu Vấn Đáp", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction( define.SCENE_SCRIPT_ID, "AskTheWay", selfId,
                            self.g_SignPost["x"], self.g_SignPost["z"],
                            self.g_SignPost["tip"])
end

function edali_zhidao_0207:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction( define.SCENE_SCRIPT_ID, "DelSignpost", selfId,
                            self.g_SignPost["tip"])
end

function edali_zhidao_0207:OnContinue(selfId, targetId)
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

function edali_zhidao_0207:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId,
                                         self.g_MissionId)
    if bRet ~= 1 then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local num = self:GetMissionParam(selfId, misIndex, 1)
    if num < 1 then
        return 0
    else
        return 1
    end
end

function edali_zhidao_0207:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItem(item["id"], item["num"])
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            self:AddMoneyJZ(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 100)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:AddItemListToHuman(selfId)
                self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Lần đầu Vấn Đáp", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                self:CallScriptFunction(210208, "OnDefaultEvent", selfId,
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

function edali_zhidao_0207:OnKillObject(selfId, objdataId) end

function edali_zhidao_0207:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0207:OnItemChanged(selfId, itemdataId) end

return edali_zhidao_0207
