local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0201 = class("edali_zhidao_0201", script_base)
edali_zhidao_0201.script_id = 210201
edali_zhidao_0201.g_Position_X = 110.0841
edali_zhidao_0201.g_Position_Z = 158.7671
edali_zhidao_0201.g_SceneID = 2
edali_zhidao_0201.g_AccomplishNPC_Name = "杜子腾"
edali_zhidao_0201.g_MissionId = 441
edali_zhidao_0201.g_MissionIdPre = 440
edali_zhidao_0201.g_Name = "杜子腾"
edali_zhidao_0201.g_ItemId = 40002110
edali_zhidao_0201.g_ItemNeedNum = 1
edali_zhidao_0201.g_MissionKind = 13
edali_zhidao_0201.g_MissionLevel = 1
edali_zhidao_0201.g_IfMissionElite = 0
edali_zhidao_0201.g_IsMissionOkFail = 0
edali_zhidao_0201.g_MissionName = "Lần đầu giao hàng"
edali_zhidao_0201.g_MissionInfo = "#{event_dali_0003}"
edali_zhidao_0201.g_MissionTarget =
    "Hãy đem #Ymột rương đồ bếp#W giao cho #GĐại Lý thành phía tây Đại Lộ Phía Tây#Ykhách điếm#Wcủa lão bản #RĐỗ Tử Đằng#W#{_INFOAIM110,159,2,Đỗ Tử Đằng}.#b#G(Xin hãy dùng chuột trái chọn tọa độ có gạch dưới, giúp ngài tìm được NPC này)#l"
edali_zhidao_0201.g_MissionComplete =
    "  Ngươi thật sự là giải ta khỏi cơn nguy cấp, ta đang rất cần rương #Yđồ bếp#W này!"
edali_zhidao_0201.g_MoneyBonus = 150000
edali_zhidao_0201.g_SignPost = {["x"] = 110, ["z"] = 159, ["tip"] = "杜子腾"}

edali_zhidao_0201.g_DemandItem = {{["id"] = 40002110, ["num"] = 1}}

edali_zhidao_0201.g_IsMissionOkFail = 1
function edali_zhidao_0201:OnDefaultEvent(selfId, targetId)
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

function edali_zhidao_0201:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
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

function edali_zhidao_0201:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 1 then
        return 1
    else
        return 0
    end
end

function edali_zhidao_0201:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:BeginAddItem()
    self:AddItem(self.g_ItemId, self.g_ItemNeedNum)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:Msg2Player(selfId, "#YChấp nhận nhiệm vụ: Lần đầu đưa hàng", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId,
                                self.g_SignPost["x"], self.g_SignPost["z"],
                                self.g_SignPost["tip"])
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
    else
        self:BeginEvent(self.script_id)
        local strText = "Hành trang đã đầy, không thể chấp nhận nhiệm vụ"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function edali_zhidao_0201:OnAbandon(selfId)
    local res = self:DelMission(selfId, self.g_MissionId)
    if res > 0 then
        for i, item in pairs(self.g_DemandItem) do
            self:DelItem(selfId, item["id"], item["num"])
        end
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
    end
end

function edali_zhidao_0201:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_zhidao_0201:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
    for i, item in pairs(self.g_DemandItem) do
        local itemCount = self:GetItemCount(selfId, item["id"])
        if itemCount < item["num"] then return 0 end
    end
    return 1
end

function edali_zhidao_0201:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        for i, item in pairs(self.g_DemandItem) do
            self:DelItem(selfId, item["id"], item["num"])
        end
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        self:AddMoneyJZ(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, 15)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Lần đầu đưa hàng", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(210202, "OnDefaultEvent", selfId, targetId)
    end
end

function edali_zhidao_0201:OnKillObject(selfId, objdataId) end

function edali_zhidao_0201:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0201:OnItemChanged(selfId, itemdataId) end

return edali_zhidao_0201
