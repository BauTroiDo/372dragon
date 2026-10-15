local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0200 = class("edali_zhidao_0200", script_base)
edali_zhidao_0200.script_id = 210200
edali_zhidao_0200.g_Position_X = 216.6208
edali_zhidao_0200.g_Position_Z = 133.6347
edali_zhidao_0200.g_SceneID = 2
edali_zhidao_0200.g_AccomplishNPC_Name = "蒲良"
edali_zhidao_0200.g_MissionId = 1401
edali_zhidao_0200.g_Name = "赵天师"
edali_zhidao_0200.g_MissionKind = 13
edali_zhidao_0200.g_MissionLevel = 1
edali_zhidao_0200.g_IfMissionElite = 0
edali_zhidao_0200.g_MissionName = "Vũ khí đầu tiên"
edali_zhidao_0200.g_MissionInfo_1 = "  Đây không phải là #R"
edali_zhidao_0200.g_MissionInfo_2 = "#{event_dali_0001}"
edali_zhidao_0200.g_MissionTarget = "#{xinshou_001}"
edali_zhidao_0200.g_MissionComplete = "#{event_dali_0002}"
edali_zhidao_0200.g_MoneyBonus = 1
edali_zhidao_0200.g_SignPost = { ["x"] = 216, ["z"] = 135, ["tip"] = "蒲良" }

edali_zhidao_0200.g_ItemBonus = { ["id"] = 30101001, ["num"] = 10 }

edali_zhidao_0200.g_RadioItemBonus = {
    { ["id"] = 10101000, ["num"] = 1 }, { ["id"] = 10102000, ["num"] = 1 },
    { ["id"] = 10104000, ["num"] = 1 }, { ["id"] = 10103000, ["num"] = 1 },
    { ["id"] = 10106016, ["num"] = 1 }, { ["id"] = 10107016, ["num"] = 1 },
}

edali_zhidao_0200.g_Custom = { { ["id"] = "已找到蒲良", ["num"] = 1 } }

edali_zhidao_0200.g_IsMissionOkFail = 1
function edali_zhidao_0200:OnDefaultEvent(selfId, targetId)
    if (self:IsMissionHaveDone(selfId, self.g_MissionId)) then
        return
    elseif (self:IsHaveMission(selfId, self.g_MissionId)) then
        if self:GetName(targetId) == self.g_AccomplishNPC_Name then
            self:OnContinue(selfId, targetId)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) == self.g_Name then
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
                self:AddRadioItemBonus(item["id"], item["num"])
            end
            self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, self.script_id,
                self.g_MissionId)
        end
    end
end

function edali_zhidao_0200:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) and self:GetName(targetId) == self.g_AccomplishNPC_Name then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
    elseif self:CheckAccept(selfId) > 0 and self:GetName(targetId) == self.g_Name then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 2)
    end
end

function edali_zhidao_0200:CheckAccept(selfId)
    if self:GetLevel(selfId) >= self.g_MissionLevel and not self:IsHaveMission(selfId, self.g_MissionId) then
        return 1
    else
        return 0
    end
end

function edali_zhidao_0200:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    self:notify_tips(selfId, "#YTiếp nhận nhiệm vụ: Vũ khí Đầu Tiên")
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId,
        self.g_SignPost["x"], self.g_SignPost["z"],
        self.g_SignPost["tip"])
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
    self:SetMissionByIndex(selfId, misIndex, 1, 1)
end

function edali_zhidao_0200:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_zhidao_0200:OnContinue(selfId, targetId)
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

function edali_zhidao_0200:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
    return 1
end

function edali_zhidao_0200:OnSubmit(selfId, targetId, selectRadioId)
    if not self:IsHaveMission(selfId,self.g_MissionId) then return end
    local valid=false
    for _,item in ipairs(self.g_RadioItemBonus)do if item.id==selectRadioId then valid=true;break end end
    if not valid then return end
    if self:CheckSubmit(selfId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_RadioItemBonus) do
            if item["id"] == selectRadioId then
                self:AddItem(item["id"], item["num"])
            end
        end
        self:AddItem(30101001, 10)
        local ret = self:EndAddItem(selfId)
        if ret then
            if not self:AddItemListToHuman(selfId) then return end
            self:AddMoneyJZ(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 70 * 10)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                
                self:notify_tips(selfId, "#YHoàn thành nhiệm vụ: Vũ khí Đầu Tiên")
                self:CallScriptFunction(210256, "OnDefaultEvent", selfId,
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

function edali_zhidao_0200:OnKillObject(selfId, objdataId) end

function edali_zhidao_0200:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0200:OnItemChanged(selfId, itemdataId) end

return edali_zhidao_0200
