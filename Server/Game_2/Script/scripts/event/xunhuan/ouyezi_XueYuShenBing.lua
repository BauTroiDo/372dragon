local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ouyezi_XueYuShenBing = class("ouyezi_XueYuShenBing", script_base)
ouyezi_XueYuShenBing.script_id = 500503
ouyezi_XueYuShenBing.g_Position_X = 266.2833
ouyezi_XueYuShenBing.g_Position_Z = 140.0340
ouyezi_XueYuShenBing.g_SceneID = 1
ouyezi_XueYuShenBing.g_AccomplishNPC_Name = "欧冶子"
ouyezi_XueYuShenBing.g_MissionId = 420
ouyezi_XueYuShenBing.g_MissionIdNext = 420
ouyezi_XueYuShenBing.g_Name = "欧冶子"
ouyezi_XueYuShenBing.g_MissionKind = 55
ouyezi_XueYuShenBing.g_MissionLevel = 10000
ouyezi_XueYuShenBing.g_IfMissionElite = 0
ouyezi_XueYuShenBing.g_IsMissionOkFail = 0
ouyezi_XueYuShenBing.g_RandomCustom = {
    {["id"] = "Đã giết quái vật", ["numNeeded"] = 3, ["numComplete"] = 1}
}

ouyezi_XueYuShenBing.g_MissionName = "Huyết Dục Thần Binh"
ouyezi_XueYuShenBing.g_MissionInfo = "Chú tạo Thần Khí"
ouyezi_XueYuShenBing.g_MissionTarget = "#{XYSB_20070928_010}"
ouyezi_XueYuShenBing.g_ContinueInfo = "#{XYSB_20070928_009}"
ouyezi_XueYuShenBing.g_MissionComplete =
    "Chuyện ta giao cho ngươi đã làm xong chưa?"
ouyezi_XueYuShenBing.g_MaxRound = 0
ouyezi_XueYuShenBing.g_ControlScript = 001066
ouyezi_XueYuShenBing.g_MissionScriptID = 2
ouyezi_XueYuShenBing.g_KillMonsterCount = 3
ouyezi_XueYuShenBing.g_KillCountIng = 4
ouyezi_XueYuShenBing.g_EventList = {}

ouyezi_XueYuShenBing.g_XueXiZhuZaoInfo = "Học đúc Thần Khí"
ouyezi_XueYuShenBing.g_WeaponIdx = 11
ouyezi_XueYuShenBing.g_Weapon_ATTACK_P = 1
ouyezi_XueYuShenBing.g_Weapon_ATTACK_M = 2
ouyezi_XueYuShenBing.g_Weapon_DEFENCE_P = 3
ouyezi_XueYuShenBing.g_Weapon_DEFENCE_M = 4
ouyezi_XueYuShenBing.g_Weapon_MISS = 5
ouyezi_XueYuShenBing.g_Weapon_HIT = 6
ouyezi_XueYuShenBing.g_ITEM_APT_LEVEL = 16
ouyezi_XueYuShenBing.g_KillMONSTER_COUNT = 5000
ouyezi_XueYuShenBing.g_WeaponLevelMin = 40
ouyezi_XueYuShenBing.g_WeaponLevelMax = 150
ouyezi_XueYuShenBing.g_AcceptLowLevel = 40
ouyezi_XueYuShenBing.g_Impact_Accept_Mission = 18
ouyezi_XueYuShenBing.g_Impact_Complete_Mission = 48
ouyezi_XueYuShenBing.g_ItemBonus = {
    {["id"] = 30505700, ["num"] = 1, ["sqlvl"] = 42},
    {["id"] = 30505701, ["num"] = 1, ["sqlvl"] = 52},
    {["id"] = 30505702, ["num"] = 1, ["sqlvl"] = 62},
    {["id"] = 30505703, ["num"] = 1, ["sqlvl"] = 72},
    {["id"] = 30505704, ["num"] = 1, ["sqlvl"] = 82},
    {["id"] = 30505705, ["num"] = 1, ["sqlvl"] = 92}
}

ouyezi_XueYuShenBing.g_RadioItemBonus = {
    {["id"] = 30302400, ["num"] = 1}, {["id"] = 30302401, ["num"] = 1},
    {["id"] = 30302402, ["num"] = 1}, {["id"] = 30302403, ["num"] = 1}
}

ouyezi_XueYuShenBing.g_SubMissionTypeEnum = {["killMonster"] = 1}

function ouyezi_XueYuShenBing:OnDefaultEvent(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local ItemLevel = self:GetMissionData(selfId, define.MD_ENUM.MD_MISSHENBING_WEAPONLEVEL)
        local shenqilvl
        if ItemLevel >= self.g_WeaponLevelMin and ItemLevel <
            self.g_WeaponLevelMin + 10 then
            shenqilvl = self.g_ItemBonus[1]["sqlvl"]
        elseif ItemLevel >= self.g_WeaponLevelMin + 10 and ItemLevel <
            self.g_WeaponLevelMin + 20 then
            shenqilvl = self.g_ItemBonus[2]["sqlvl"]
        elseif ItemLevel >= self.g_WeaponLevelMin + 20 and ItemLevel <
            self.g_WeaponLevelMin + 30 then
            shenqilvl = self.g_ItemBonus[3]["sqlvl"]
        elseif ItemLevel >= self.g_WeaponLevelMin + 30 and ItemLevel <
            self.g_WeaponLevelMin + 40 then
            shenqilvl = self.g_ItemBonus[4]["sqlvl"]
        elseif ItemLevel >= self.g_WeaponLevelMin + 40 and ItemLevel <
            self.g_WeaponLevelMin + 50 then
            shenqilvl = self.g_ItemBonus[5]["sqlvl"]
        elseif ItemLevel >= self.g_WeaponLevelMin + 50 then
            shenqilvl = self.g_ItemBonus[6]["sqlvl"]
        else
            shenqilvl = self.g_ItemBonus[1]["sqlvl"]
        end
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText("#{XYSB_20070928_009}")
        self:AddText("#r#G Nhiệm vụ này tương ứng Cấp độ Thần Khí:" .. shenqilvl)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,
                                       self.g_MissionId, bDone)
    else
        if self:LuaFnGetLevel(selfId) < self.g_AcceptLowLevel then
            self:BeginEvent(self.script_id)
            self:AddText("#{XYSB_20070928_002}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return 0
        end
        self:AcceptMission(selfId, targetId)
    end
end

function ouyezi_XueYuShenBing:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return 0 end
    caller:AddNumTextWithTarget(self.script_id, self.g_XueXiZhuZaoInfo, 6, 115)
end

function ouyezi_XueYuShenBing:CheckAccept(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYSB_20070928_009}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText("#{XYSB_20070928_003}")
    self:EndEvent()
    local bDone = 2
    self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,
                                   self.g_MissionId, bDone)
    return 1
end

function ouyezi_XueYuShenBing:GetKillCountByLevel(iItemLevel)
    local iCount = 5000
    if (iItemLevel >= 40 and iItemLevel < 50) then
        iCount = 3000
    elseif (iItemLevel >= 50 and iItemLevel < 60) then
        iCount = 4000
    end
    return iCount
end

function ouyezi_XueYuShenBing:OnAccept(selfId, targetId, scriptId, iItemLevel)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 1,
                                 0, 0)
    if not bAdd then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        local LogInfo = string.format(
                            "[ShenBing]error: x500503_OnAccept( sceneId=%d, GUID=%0X ), bAdd=%d",
                            self:LuaFnObjId2Guid(selfId), bAdd)
        self:MissionLog(LogInfo)
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 2, scriptId)
    local iKillCount = self:GetKillCountByLevel(iItemLevel)
    self:SetMissionByIndex(selfId, misIndex, 3, iKillCount)
    self:SetMissionByIndex(selfId, misIndex, 1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                       self.g_Impact_Accept_Mission, 0)
    return 1
end

function ouyezi_XueYuShenBing:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
    else
        return 0
    end
end

function ouyezi_XueYuShenBing:OnContinue(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:LuaFnGetLevel(selfId) < self.g_AcceptLowLevel then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId) ~= 1 then return 0 end
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    for i, item in pairs(self.g_RadioItemBonus) do
        self:AddRadioItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function ouyezi_XueYuShenBing:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, 0) > 0 then return 1 end
    return 0
end

function ouyezi_XueYuShenBing:OnSubmit(selfId, targetId, selectRadioId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:LuaFnGetLevel(selfId) < self.g_AcceptLowLevel then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId) ~= 1 then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        local LogInfo = string.format(
                            "[ShenBing]error: x500503_OnSubmit( sceneId=%d, GUID=%0X ), x500503_CheckSubmit=%d",
                            self:LuaFnObjId2Guid(selfId),
                            self:CheckSubmit(selfId))
        self:MissionLog(LogInfo)
        return 0
    end
    local ItemLevel = self:GetMissionData(selfId, define.MD_ENUM.MD_MISSHENBING_WEAPONLEVEL)
    local shenjieID
    if ItemLevel >= self.g_WeaponLevelMin and ItemLevel < self.g_WeaponLevelMin +
        10 then
        shenjieID = self.g_ItemBonus[1]["id"]
    elseif ItemLevel >= self.g_WeaponLevelMin + 10 and ItemLevel <
        self.g_WeaponLevelMin + 20 then
        shenjieID = self.g_ItemBonus[2]["id"]
    elseif ItemLevel >= self.g_WeaponLevelMin + 20 and ItemLevel <
        self.g_WeaponLevelMin + 30 then
        shenjieID = self.g_ItemBonus[3]["id"]
    elseif ItemLevel >= self.g_WeaponLevelMin + 30 and ItemLevel <
        self.g_WeaponLevelMin + 40 then
        shenjieID = self.g_ItemBonus[4]["id"]
    elseif ItemLevel >= self.g_WeaponLevelMin + 40 and ItemLevel <
        self.g_WeaponLevelMin + 50 then
        shenjieID = self.g_ItemBonus[5]["id"]
    elseif ItemLevel >= self.g_WeaponLevelMin + 50 then
        shenjieID = self.g_ItemBonus[6]["id"]
    else
        shenjieID = self.g_ItemBonus[1]["id"]
    end
    if selectRadioId == self.g_RadioItemBonus[1]["id"] or selectRadioId ==
        self.g_RadioItemBonus[2]["id"] or selectRadioId ==
        self.g_RadioItemBonus[3]["id"] or selectRadioId ==
        self.g_RadioItemBonus[4]["id"] then
        self:BeginAddItem()
        self:AddItem(shenjieID, 2)
        local ret1 = self:EndAddItem(selfId)
        if ret1 then
            self:TryRecieveItem(selfId, shenjieID, 1)
            self:TryRecieveItem(selfId, selectRadioId, 1)
        else
            self:BeginEvent(self.script_id)
            local strText =
                "Túi đồ hoặc Ô Nguyên liệu không đủ chỗ trống, xin hãy thu xếp rồi quay lại nhận."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
        if not self:DelMission(selfId, self.g_MissionId) then
            self:MissionLog("[ShenBing]error: x500503_OnSubmit..DelMission")
            return 0
        end
        if self:IsHaveMission(selfId, self.g_MissionIdNext) then
            self:DelMission(selfId, self.g_MissionIdNext)
        end
        self:BeginEvent(self.script_id)
        self:AddText(
            "  Làm tốt lắm, đây có Tàn Khuyết Thần Tiết, xem như là phần thưởng của ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                           self.g_Impact_Complete_Mission, 0)
    else
        self:BeginEvent(self.script_id)
        local strText = "Lĩnh phần thưởng thất bại, xin lĩnh lại."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
end

function ouyezi_XueYuShenBing:OnKillObject(selfId, objdataId, objId)
    local num = self:GetMonsterOwnerCount(objId)
    for i = 1, num do
        local humanObjId = self:GetMonsterOwnerID(objId, i)
        if self:IsHaveMission(humanObjId, self.g_MissionId) then
            local misIndex = self:GetMissionIndexByID(humanObjId,
                                                      self.g_MissionId)
            if self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then
                local PlayerLevel = self:GetLevel(humanObjId)
                local MonsterLevel = self:GetLevel(objId)
                if ((PlayerLevel - MonsterLevel >= 0) and
                    (PlayerLevel - MonsterLevel < 10)) or
                    ((MonsterLevel - PlayerLevel >= 0) and
                        (MonsterLevel - PlayerLevel < 10)) then
                    local demandKillCount =
                        self:GetMissionParam(humanObjId, misIndex, 3)
                    local killedCount = self:GetMissionParam(humanObjId,
                                                             misIndex, 1)
                    killedCount = killedCount + 1
                    local ItemLevel = self:GetMissionData(humanObjId, define.MD_ENUM.MD_MISSHENBING_WEAPONLEVEL)
                    local iLevelCount = self:GetKillCountByLevel(ItemLevel)
                    if (iLevelCount < demandKillCount) then
                        demandKillCount = iLevelCount
                        self:SetMissionByIndex(humanObjId, misIndex, 3,
                                               demandKillCount)
                    end
                    if (iLevelCount < killedCount) then
                        killedCount = iLevelCount
                    end
                    self:SetMissionByIndex(humanObjId, misIndex, 1, killedCount)
                    self:BeginEvent(self.script_id)
                    local str = string.format("Đã tiêu diệt %s%d/%d", "Quái vật",
                                            killedCount, demandKillCount)
                    self:AddText(str)
                    self:EndEvent()
                    self:DispatchMissionTips(humanObjId)
                    if killedCount >= demandKillCount then
                        self:SetMissionByIndex(humanObjId, misIndex, 0, 1)
                    end
                end
            end
        end
    end
end

function ouyezi_XueYuShenBing:OnEnterArea(selfId, zoneId) end

function ouyezi_XueYuShenBing:OnItemChanged(selfId, itemdataId) end

function ouyezi_XueYuShenBing:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ouyezi_XueYuShenBing:SubmitDialog(selfId, rand) end

function ouyezi_XueYuShenBing:SubmitDialog(selfId, rand) end

function ouyezi_XueYuShenBing:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function ouyezi_XueYuShenBing:GetEventMissionId(selfId)
    self:MissionLog(
        "[ShenBing]x500503_GetEventMissionId..x500503_g_MissionId=" ..
            self.g_MissionId)
    return self.g_MissionId
end

function ouyezi_XueYuShenBing:AcceptMission(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        self:MissionLog(
            "[ShenBing]error: x500503_AcceptMission..LuaFnGetName=" ..
                self:LuaFnGetName(targetId))
        return 0
    end
    local PlayerName = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{XYSB_20070928_007}" .. PlayerName .. "#{XYSB_20070928_008}")
    self:AddText("#{M_SHOUHUO}")
    self:AddText("#{XYSB_20070930_012}")
    for i, item in pairs(self.g_RadioItemBonus) do
        self:AddRadioItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function ouyezi_XueYuShenBing:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3)
    if scriptId ~= self.script_id then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        self:MissionLog("[ShenBing]error: x500503_OnMissionCheck..scriptId=" ..
                            scriptId)
        return 0
    end
    if self:LuaFnGetName(npcid) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        self:MissionLog(
            "[ShenBing]error: x500503_OnMissionCheck..LuaFnGetName=" ..
                self:LuaFnGetName(npcid))
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYSB_20070928_009}")
        self:EndEvent()
        self:DispatchEventList(selfId, npcid)
        return 0
    end
    if self:LuaFnGetLevel(selfId) < self.g_AcceptLowLevel then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYSB_20070928_002}")
        self:EndEvent()
        self:DispatchEventList(selfId, npcid)
        return 0
    end
    local index
    local ItemLevel
    local ItemID
    local PlayerLevel = self:GetLevel(selfId)
    for i = 1, 3 do
        if i == 1 then
            index = index1
        elseif i == 2 then
            index = index2
        elseif i == 3 then
            index = index3
        else
            index = index1
        end
        if index < 100 then
            ItemLevel = self:GetBagItemLevel(selfId, index)
            ItemID = self:LuaFnGetItemTableIndexByIndex(selfId, index)
            local attack_p = self:GetItemApt(selfId, index,
                                             self.g_Weapon_ATTACK_P)
            local attack_m = self:GetItemApt(selfId, index,
                                             self.g_Weapon_ATTACK_M)
            local isJudge = self:LuaFnIsJudgeApt(selfId, index)
            local EquipType = self:GetItemEquipPoint(ItemID)
            if EquipType ~= 0 then
                self:NotifyTip(selfId, "#{XYSB_20070928_014}")
                return 0
            end
            if ItemLevel < self.g_WeaponLevelMin then
                self:NotifyTip(selfId, "#{XYSB_20070928_014}")
                return 0
            end
            if ItemLevel > PlayerLevel then
                self:NotifyTip(selfId, "#{XYSB_20070928_015}")
                return 0
            end
            if not isJudge then
                self:NotifyTip(selfId, "#{XYSB_20070928_017}")
                return 0
            end
            if attack_p < self.g_ITEM_APT_LEVEL or attack_m <
                self.g_ITEM_APT_LEVEL then
                self:NotifyTip(selfId, "#{XYSB_20070928_016}")
                return 0
            end
            if not self:LuaFnIsItemAvailable(selfId, index) then
                self:NotifyTip(selfId, "#{XYSB_20070928_018}")
                return 0
            end
            local accres = self:OnAccept(selfId, npcid, scriptId, ItemLevel)
            if accres > 0 then
                local ret = self:EraseItem(selfId, index)
                if ret then
                    self:SetMissionData(selfId, define.MD_ENUM.MD_MISSHENBING_WEAPONLEVEL, ItemLevel)
                    return 1
                else
                    self:BeginEvent(self.script_id)
                    local strText = string.format("Xóa Vũ khí thất bại")
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchEventList(selfId, -1)
                end
            end
            self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
            self:MissionLog(
                "[ShenBing]error: x500503_OnMissionCheck..index..accres=" ..
                    accres)
            return 0
        end
    end
    self:NotifyTip(selfId, "Lĩnh nhiệm vụ thất bại: Vũ khí không đạt tiêu chuẩn")
end

return ouyezi_XueYuShenBing
