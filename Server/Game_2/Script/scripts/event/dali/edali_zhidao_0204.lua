local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0204 = class("edali_zhidao_0204", script_base)
edali_zhidao_0204.script_id = 210204
edali_zhidao_0204.g_Position_X = 160.0895
edali_zhidao_0204.g_Position_Z = 156.9309
edali_zhidao_0204.g_SceneID = 2
edali_zhidao_0204.g_AccomplishNPC_Name = "赵天师"
edali_zhidao_0204.g_MissionId = 444
edali_zhidao_0204.g_MissionIdPre = 443
edali_zhidao_0204.g_Name = "赵天师"
edali_zhidao_0204.g_MissionKind = 13
edali_zhidao_0204.g_MissionLevel = 1
edali_zhidao_0204.g_IfMissionElite = 0
edali_zhidao_0204.g_MissionName = "Đệ Nhất Phong Thư Giới Thiệu"
edali_zhidao_0204.g_MissionInfo = "#{event_dali_0006}"
edali_zhidao_0204.g_MissionTarget =
    "Hồi #GĐại Lý#W thành Ngũ Hoa Đàn tìm #GTriệu Thiên Sư#W#{_INFOAIM160,157,2,Triệu Thiên Sư}.#b#G(Xin hãy dùng chuột trái chọn tọa độ có gạch dưới để giúp ngài tìm được NPC này)#l"
edali_zhidao_0204.g_MissionComplete = "#{event_dali_0007}"
edali_zhidao_0204.g_MoneyBonus = 300000
edali_zhidao_0204.g_SignPost = {["x"] = 160, ["z"] = 156, ["tip"] = "赵天师"}

edali_zhidao_0204.g_ItemBonus = {{["id"] = 40002108, ["num"] = 1}}

edali_zhidao_0204.g_Custom = {{["id"] = "已找到赵天师", ["num"] = 1}}

edali_zhidao_0204.g_IsMissionOkFail = 1
function edali_zhidao_0204:OnDefaultEvent(selfId, targetId)
    if (self:IsMissionHaveDone(selfId, self.g_MissionId)) then
        return
    elseif (self:IsHaveMission(selfId, self.g_MissionId)) then
        if self:GetName(targetId) == self.g_Name then
            self:OnContinue(selfId, targetId)
        end
    elseif self:CheckAccept(selfId) then
        if self:GetName(targetId) ~= self.g_Name then
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
end

function edali_zhidao_0204:OnEnumerate(caller, selfId, targetId, arg, index)
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

function edali_zhidao_0204:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 1 then
        return 1
    else
        return 0
    end
end

function edali_zhidao_0204:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Đệ Nhất Phong Thư Giới Thiệu", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId,
                            self.g_SignPost["x"], self.g_SignPost["z"],
                            self.g_SignPost["tip"])
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end

function edali_zhidao_0204:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId,
                            self.g_SignPost["tip"])
end

function edali_zhidao_0204:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    for i, item in pairs(self.g_ItemBonus) do
        self:AddItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id,
                                     self.g_MissionId)
end

function edali_zhidao_0204:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
    return 1
end

function edali_zhidao_0204:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItem(item["id"], item["num"])
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            self:AddMoneyJZ(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 30)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:AddItemListToHuman(selfId)
            end
            self:Msg2Player(selfId, "#YHoàn thành nhiệm vụ: Đệ Nhất Phong Thư Giới Thiệu", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi đã đầy, không thể hoàn thành nhiệm vụ"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function edali_zhidao_0204:OnKillObject(selfId, objdataId) end

function edali_zhidao_0204:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0204:OnItemChanged(selfId, itemdataId) end

return edali_zhidao_0204
