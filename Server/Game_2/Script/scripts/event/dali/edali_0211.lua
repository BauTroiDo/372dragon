local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0211 = class("edali_0211", script_base)
edali_0211.script_id = 210211
edali_0211.g_Position_X = 172.7304
edali_0211.g_Position_Z = 146.4640
edali_0211.g_SceneID = 2
edali_0211.g_AccomplishNPC_Name = "孙八爷"
edali_0211.g_MissionIdPre = 450
edali_0211.g_MissionId = 451
edali_0211.g_Name = "孙八爷"
edali_0211.g_ItemId = 30505062
edali_0211.g_MissionKind = 13
edali_0211.g_MissionLevel = 3
edali_0211.g_IfMissionElite = 0
edali_0211.g_IsMissionOkFail = 0
edali_0211.g_MissionName = "Pháo hoa nở rộ rồi!"
edali_0211.g_MissionInfo = "#{event_dali_0013}"
edali_0211.g_MissionTarget = "#{xinshou_003}"
edali_0211.g_ContinueInfo = "  Pháo hoa đã được đốt chưa?"
edali_0211.g_MissionComplete = "#{event_dali_0015}"
edali_0211.g_ItemBonus = {{["id"] = 10111000, ["num"] = 1}}
edali_0211.g_SignPost = {["x"] = 173, ["z"] = 147, ["tip"] = "孙八爷"}
edali_0211.g_MoneyBonus = 550000
edali_0211.g_SignPost_1 = {["x"] = 82, ["z"] = 220, ["tip"] = "Điểm đốt pháo hoa"}
edali_0211.g_Custom = {{["id"] = "已燃放传讯焰火", ["num"] = 1}}
edali_0211.g_TreasureAddress = {{["scene"] = 2, ["x"] = 82, ["z"] = 220}}
function edali_0211:OnDefaultEvent(selfId, targetId)
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
        self:AddText("#{M_MUBIAO}#r")
        self:AddText(self.g_MissionTarget)
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItemBonus(item["id"], item["num"])
        end
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function edali_0211:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0211:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 3 then
        return 1
    else
        return 0
    end
end

function edali_0211:OnAccept(selfId)
    if self:CheckAccept(selfId) <= 0 then return end
    local SceneNum = self.g_TreasureAddress[1]["scene"]
    local X = self.g_TreasureAddress[1]["x"]
    local Z = self.g_TreasureAddress[1]["z"]
    self:BeginAddItem()
    self:AddItem(self.g_ItemId, 1)
    local ret = self:EndAddItem(selfId)
    if not ret then
        self:Msg2Player(selfId, "#YTúi nhiệm vụ của ngươi đã đầy.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    else
        local ret1 = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 1)
        if ret1 then
            local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
            self:SetMissionByIndex(selfId, misIndex, 0, 0)
            self:SetMissionByIndex(selfId, misIndex, 2, SceneNum)
            self:SetMissionByIndex(selfId, misIndex, 3, X)
            self:SetMissionByIndex(selfId, misIndex, 4, Z)
            self:AddItemListToHuman(selfId)
            self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Pháo hoa rực rỡ rồi!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            local sceneId = self:get_scene_id()
            self:Msg2Player(selfId,"@*;flagPOS;" .. sceneId .. ";" .. X .. ";" .. Z ..  ";" .. "Điểm đốt pháo hoa", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            self:Msg2Player(selfId,"@*;flashPOS;" .. sceneId .. ";" .. X .. ";" .. Z .. ";" .. "Điểm đốt pháo hoa", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi nhận được Truyền Tấn Pháo Hoa.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2,
                                    self.g_SignPost_1["x"],
                                    self.g_SignPost_1["z"],
                                    self.g_SignPost_1["tip"])
        else
            self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
    end
end

function edali_0211:OnAbandon(selfId)
    local res = self:DelMission(selfId, self.g_MissionId)
    if res then
        local sceneId = self:get_scene_id()
        self:DelItem(selfId, self.g_ItemId, 1)
        self:Msg2Player(selfId, "@*;flagNPCdel;" .. sceneId .. ";" .. "Điểm đốt pháo hoa", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(selfId, "@*;flashNPCdel;" .. sceneId .. ";" .. "Điểm đốt pháo hoa", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end

function edali_0211:OnContinue(selfId, targetId)
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

function edali_0211:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId,  self.g_MissionId)
    if bRet ~= 1 then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self.g_MissionCondition = self:GetMissionParam(selfId, misIndex, 0)
    if self.g_MissionCondition >= 1 then
        return 1
    else
        return 0
    end
end

function edali_0211:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItem(item["id"], item["num"])
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            self:AddMoneyJZ(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 400)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:AddItemListToHuman(selfId)
                self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Pháo hoa rực rỡ rồi!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                self:CallScriptFunction(210212, "OnDefaultEvent", selfId, targetId)
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

function edali_0211:OnKillObject(selfId, objdataId) end

function edali_0211:OnEnterArea(selfId, zoneId) end

function edali_0211:OnItemChanged(selfId, itemdataId) end

function edali_0211:OnUseItem(selfId, BagIndex)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self.g_MissionCondition = self:GetMissionParam(selfId, misIndex, 0)
    local scene = self:GetMissionParam(selfId, misIndex, 2)
    local treasureX = self:GetMissionParam(selfId, misIndex, 3)
    local treasureZ = self:GetMissionParam(selfId, misIndex, 4)
    if self.g_MissionCondition == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Thi triển Truyền Tấn Diễm Hỏa thành công")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId)
    local Distance = math.floor(math.sqrt((treasureX - PlayerX) *
                                        (treasureX - PlayerX) +
                                        (treasureZ - PlayerZ) *
                                        (treasureZ - PlayerZ)))
    local sceneId = self:get_scene_id()
    if sceneId == scene or sceneId == 71 or sceneId == 72 then
    else
        self:BeginEvent(self.script_id)
        self:AddText("Dường như không thể thi triển Truyền Tấn Diễm Hỏa tại cảnh này")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    if Distance > 5 then
        self:BeginEvent(self.script_id)
        self:AddText("Khoảng cách đến chỗ thi triển Truyền Tấn Diễm Hỏa còn" .. Distance .. "gạo")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    elseif Distance <= 5 then
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2,
                                self.g_SignPost["x"], self.g_SignPost["z"],
                                self.g_SignPost["tip"])
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 34825, 0)
        self:BeginEvent(self.script_id)
        self:AddText(
            "Đệ tử các Môn phái lớn nghe tin liền vội vã đến, mau trở về tìm Tôn Bát Gia đi.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:DelItem(selfId, self.g_ItemId, 1)
    end
end

return edali_0211
