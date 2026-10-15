local class = require "class"
local define = require "define"
local script_base = require "script_base"
local exihu_648 = class("exihu_648", script_base)
exihu_648.script_id = 212100
exihu_648.g_MissionId = 648
exihu_648.g_Name = "苏飞"
exihu_648.g_MissionKind = 41
exihu_648.g_MissionLevel = 25
exihu_648.g_IfMissionElite = 0
exihu_648.g_MissionName = "Tô Phi của Thế Giới"
exihu_648.g_MissionInfo = "#{Mis_K_Xihu_1000042}"
exihu_648.g_MissionTarget = "#{MIS_TAR_ADD_010}"
exihu_648.g_ContinueInfo = "  Ngươi đã giết #WMạch Hữu Nhân#W rồi sao?"
exihu_648.g_MissionComplete =
    "  Đa tạ ngươi, thế giới mới, tựa hồ ngay trước mắt ta."
exihu_648.g_MoneyBonus = 1800
exihu_648.g_exp = 18000
exihu_648.g_Custom = {{["id"] = "已杀死麦友仁", ["num"] = 1}}
exihu_648.g_IsMissionOkFail = 0
exihu_648.g_RadioItemBonus = {
    {["id"] = 10412063, ["num"] = 1}, {["id"] = 10413065, ["num"] = 1},
    {["id"] = 10402065, ["num"] = 1}
}
function exihu_648:OnDefaultEvent(selfId, targetId)
    if (self:IsMissionHaveDone(selfId, self.g_MissionId)) then
        return
    elseif (self:IsHaveMission(selfId, self.g_MissionId)) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_ContinueInfo)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo)
        self:AddText("#{M_MUBIAO}")
        self:AddText(self.g_MissionTarget)
        self:AddText("#{M_SHOUHUO}")
        self:AddMoneyBonus(self.g_MoneyBonus)
        for i, item in pairs(self.g_RadioItemBonus) do
            self:AddRadioItemBonus(item["id"], item["num"])
        end
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function exihu_648:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function exihu_648:CheckAccept(selfId)
    if not self:IsMissionHaveDone(selfId, 645) then
        return 0
    elseif not  self:IsMissionHaveDone(selfId, 646) then
        return 0
    elseif not  self:IsMissionHaveDone(selfId, 647) then
        return 0
    end
    if self:GetLevel(selfId) >= self.g_MissionLevel then
        return 1
    else
        return 0
    end
end

function exihu_648:OnAccept(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    local nMonsterNum = self:GetMonsterCount()
    for ii = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(ii)
        if self:GetName(nMonsterId) == "麦友仁" then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi hiện tại không thể tiếp nhận nhiệm vụ này.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:Msg2Player(selfId, "#Y Tiếp nhận nhiệm vụ" .. self.g_MissionName, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:BeginEvent(self.script_id)
    local strText = "#Y Tiếp nhận nhiệm vụ " .. self.g_MissionName
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    local nMonsterId = self:LuaFnCreateMonster(509, 161, 262, 5, 0, -1)
    self:LuaFnSendSpecificImpactToUnit(nMonsterId, nMonsterId, nMonsterId, 44, 3)
    self:CallScriptFunction((200060), "Duibai", "麦友仁", "Tây Hồ", "Tô Phi! Ngươi là kẻ thấp kém như con sâu cái kiến, cũng dám vọng tưởng lay động sự thống trị của Yển Sư sao? Tô Phi! Ngày này năm sau chính là ngày giỗ của ngươi!")
    self:SetUnitReputationID(selfId, nMonsterId, 29)
    self:SetMonsterFightWithNpcFlag(nMonsterId, 0)
    self:SetCharacterDieTime(nMonsterId, 600000)
end

function exihu_648:OnSceneTimer(selfId) end

function exihu_648:OnAbandon(selfId) self:DelMission(selfId, self.g_MissionId) end

function exihu_648:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    for i, item in pairs(self.g_RadioItemBonus) do
        self:AddRadioItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function exihu_648:CheckSubmit(selfId)
    local missionId = self.g_MissionId
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local bComplete = self:GetMissionParam(selfId, misIndex, 0)
    if bComplete > 0 then
        return 1
    else
        return 0
    end
end

function exihu_648:OnSubmit(selfId, targetId, selectRadioId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    if self:CheckSubmit(selfId) <= 0 then return end
    self:BeginAddItem()
    for i, item in pairs(self.g_RadioItemBonus) do
        if item["id"] == selectRadioId then
            self:AddItem(item["id"], item["num"])
        end
    end
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Túi đã đầy, không thể hoàn thành nhiệm vụ")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function exihu_648:OnKillObject(selfId, objdataId, objId)
    local missionId = self.g_MissionId
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    if monsterName == "麦友仁" then
        self:CallScriptFunction((200060), "Duibai", "苏飞", "Tây Hồ", "Bọn huynh đệ Thủy Quỷ! Hôm nay, chính là hôm nay! Chúng ta tự do rồi! Chúng ta không còn là nô lệ nữa!")
        local num = self:GetMonsterOwnerCount(objId)
        for j = 1, num do
            local humanObjId = self:GetMonsterOwnerID(objId, j)
            if self:IsHaveMission(humanObjId, missionId) then
                local misIndex = self:GetMissionIndexByID(humanObjId, missionId)
                if self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then
                    self:BeginEvent(self.script_id)
                    local strText = string.format("Đã tiêu diệt Mạch Hữu Nhân: 1/1")
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(humanObjId)
                    self:SetMissionByIndex(humanObjId, misIndex, 0, 1)
                    self:SetMissionByIndex(humanObjId, misIndex, 1, 1)
                end
            end
        end
    end
end

function exihu_648:OnEnterArea(selfId, zoneId) end

function exihu_648:OnItemChanged(selfId, itemdataId) end

return exihu_648
