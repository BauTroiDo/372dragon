local skynet = require "skynet"
local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
local packet_def = require "game.packet"
local script_base = require "script_base"
local chengzhu = class("chengzhu", script_base)

chengzhu.g_VersionStamp = "chengzhu.lua@2026-03-17_2320"
chengzhu.g_SAFE_UI_MODE = 0
pcall(function()
	skynet.logi("load " .. tostring(chengzhu.g_VersionStamp))
end)

chengzhu.script_id = 000157

chengzhu.g_LuoyangSceneId = 0
chengzhu.g_NpcGuid = 3455608

chengzhu.g_BuffChallenge = 9672
chengzhu.g_BuffWorship = 9673

chengzhu.g_CostChallenge = 50000
chengzhu.g_CostWorship = 30000
chengzhu.g_HourlyRevenueMoney = 10000000
chengzhu.g_ChallengeFailProtectSec = 3600
chengzhu.g_MinChallengeLevel = 112
chengzhu.g_MinChallengeMaxHp = 200000

chengzhu.g_WID_CityLordGuid = 991000001
chengzhu.g_WID_LastClaimTs = 991000002
chengzhu.g_WID_LastClaimGuid = 991000003
chengzhu.g_WID_LastClaimDayKey = 991000004
chengzhu.g_WID_LastClaimWorshipSnapshot = 991000005
chengzhu.g_WID_LastClaimTaxSnapshot = 991000006
chengzhu.g_WID_LastClaimTotal = 991000007
chengzhu.g_WID_CityLordBossSpawnDayKey = 991000008
chengzhu.g_WID_CityLordPortraitId = 991000020
chengzhu.g_WID_CityLordModelId = 991000021
chengzhu.g_WID_CityLordFashionDepotIndex = 991000022
chengzhu.g_WID_CityLordAppearanceValid = 991000023
chengzhu.g_EnableCityLordModelId = 0
chengzhu.g_WID_WorshipIncomeBase = 991100000
chengzhu.g_WID_TaxBase = 990000000

chengzhu.g_WID_PendingChallengeChallengerGuid = 991000010
chengzhu.g_WID_PendingChallengeLordGuid = 991000011
chengzhu.g_WID_PendingChallengeExpireTs = 991000012
chengzhu.g_WID_PendingChallengeAccepted = 991000013
chengzhu.g_WID_ChallengeBattleActive = 991000014

chengzhu.g_LuoyangTransferSceneId = 0
chengzhu.g_LuoyangTransferX = 82
chengzhu.g_LuoyangTransferZ = 177

chengzhu.g_MDEX_WorshipDay = 9001
chengzhu.g_MDEX_WorshipCount = 9002
chengzhu.g_MDEX_ChallengeFailProtectTs = 9003

chengzhu.g_ChallengeScriptId = 806013

chengzhu.g_CityLordBossMonsterId = 11353
chengzhu.g_CityLordBossX = 91
chengzhu.g_CityLordBossZ = 185
-- chengzhu.g_CityLordBossMaxHp = 111111
chengzhu.g_CityLordBossMaxHp = 200000000
chengzhu.g_CityLordBossLiveMs = 60 * 60 * 1000
chengzhu.g_CityLordBossDropBoxCount = 20
chengzhu.g_CityLordBossDropItems = {
    {id = 20600004, count = 10}, -- 琉璃明珠
    {id = 38008220, count = 2}, -- 天地明珠
    {id = 38008160, count = 100},  -- 物品3
    {id = 38003158, count = 3},  -- 物品4
    -- {id = 20310224, count = 2},  -- 物品5
    -- {id = 20310225, count = 1}   -- 物品6
}
chengzhu.g_CityLordBossChestMonsterId = 5011
chengzhu.g_CityLordBossChestName = "Rương BOSS thành chủ"
chengzhu.g_CityLordBossChestTitle = "宝箱"
chengzhu.g_CityLordBossChestFlagIndex = 15
chengzhu.g_CityLordBossChestFlagValue = 11353
chengzhu.g_CityLordBossChestScatter = 8

function chengzhu:GetTodayDayKey()
    return tonumber(os.date("%y%m%d")) or 0
end

function chengzhu:CheckChallengeRequirement(selfId)
    local level = tonumber(self:GetLevel(selfId)) or 0
    if level < self.g_MinChallengeLevel then
        self:notify_tips(selfId, string.format("Cần đạt cấp %d mới khiêu chiến thành chủ được", self.g_MinChallengeLevel))
        return false
    end

    local maxHp = tonumber(self:GetMaxHp(selfId)) or 0
    if maxHp <= self.g_MinChallengeMaxHp then
        self:notify_tips(selfId, string.format("Giới hạn máu phải trên %d mới khiêu chiến thành chủ được", self.g_MinChallengeMaxHp))
        return false
    end

    return true
end

function chengzhu:SyncCityLordBuffOnObj(selfId)
    local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    local have = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_BuffChallenge)
    if myGuid > 0 and myGuid == lordGuid then
        if not have then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_BuffChallenge, 0)
        end
    else
        if have then
            self:CancelCityLordBuffOnObj(selfId, self.g_BuffChallenge)
        end
    end
end

function chengzhu:EnsurePendingChallengeDaemon()
    if self._pending_challenge_daemon_running then
        return
    end
    self._pending_challenge_daemon_running = true
    local function tick()
        local ok = xpcall(function()
            local cGuid, lGuid, eTs = self:GetPendingChallengeRaw()
            if cGuid <= 0 or lGuid <= 0 or eTs <= 0 then
                self._pending_challenge_daemon_running = false
                return
            end
            if os.time() > eTs then
                self._pending_challenge_daemon_running = false
                local ok2, err2 = xpcall(function()
                    self:SettlePendingChallengeTimeout(cGuid, lGuid)
                end, debug.traceback)
                if not ok2 then
                    skynet.loge("chengzhu:daemon SettlePendingChallengeTimeout err=" .. tostring(err2))
                    pcall(self.TrySetNewCityLord, self, cGuid, lGuid)
                end
                return
            end
            skynet.timeout(500, tick)
        end, debug.traceback)
        if not ok then
            self._pending_challenge_daemon_running = false
        end
    end
    skynet.timeout(500, tick)
end

function chengzhu:EnsurePendingChallengeEngineTimer(selfId)
    if not selfId or selfId <= 0 then
        return
    end
    if self._pending_challenge_engine_timer_started then
        return
    end
    if type(self.SetTimer) ~= "function" or type(self.CheckTimer) ~= "function" then
        return
    end
    local ok = pcall(function()
        self:SetTimer(selfId, self.script_id, "OnPendingChallengeTimer", 1000)
        self._pending_challenge_engine_timer_started = true
    end)
    if not ok then
        return
    end
end

function chengzhu:OnPendingChallengeTimer(sceneId, nowTime)
    local ok = xpcall(function()
        local challengerGuid, lordGuid, expireTs = self:GetPendingChallengeRaw()
        if challengerGuid <= 0 or lordGuid <= 0 or expireTs <= 0 then
            return
        end
        if os.time() <= expireTs then
            return
        end
        self:SettlePendingChallengeTimeout(challengerGuid, lordGuid)
    end, debug.traceback)
    if not ok then
        return
    end
end

function chengzhu:TrySetNewCityLord(challengerGuid, oldLordGuid)
    challengerGuid = tonumber(challengerGuid) or 0
    oldLordGuid = tonumber(oldLordGuid) or 0
    if challengerGuid <= 0 then
        return false
    end

    self:SetCityLordGuid(challengerGuid)
    self:ClearPendingChallenge()
    self:SetChallengeBattleActive(false)
    self:ResetRevenueClaimBaseline(challengerGuid, 0)

    self:CancelBuffOnGuid(oldLordGuid, self.g_BuffChallenge)
    self:CancelBuffOnGuid(challengerGuid, self.g_BuffChallenge)
	self:SyncCityLordBuffOnGuid(challengerGuid)

    local challengerObjId = self:LuaFnGuid2ObjId(challengerGuid)
    if challengerObjId and challengerObjId > 0 and self:LuaFnIsObjValid(challengerObjId) then
        self:LuaFnSendSpecificImpactToUnit(challengerObjId, challengerObjId, challengerObjId, self.g_BuffChallenge, 0)
    end

    self:RefreshNpcNameTitle()
    return true
end

function chengzhu:SanitizeCityLordAppearance(portrait_id, model_id, fashion_depot_index)
    portrait_id = math.floor(tonumber(portrait_id) or 0)
    model_id = math.floor(tonumber(model_id) or 0)
    fashion_depot_index = math.floor(tonumber(fashion_depot_index) or 0)

    if portrait_id < 0 then
        portrait_id = 0
    end
    if model_id <= 0 then
        model_id = 0
    end
    if fashion_depot_index < 0 or fashion_depot_index > 32767 then
        fashion_depot_index = 0
    end
    return portrait_id, model_id, fashion_depot_index
end

function chengzhu:ProcSpawnCityLordBoss(selfId)
    if not self:IsInLuoyang(selfId) then
        self:notify_tips(selfId, "Chỉ thi triển được ở Lạc Dương")
        return
    end

    local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    if myGuid <= 0 or myGuid ~= lordGuid then
        self:notify_tips(selfId, "Chỉ thành chủ Lạc Dương mới thả được")
        return
    end

    local dayKey = self:GetTodayDayKey()
    if dayKey <= 0 then
        self:notify_tips(selfId, "Thi triển thất bại")
        return
    end

    local lastSpawnDayKey = self:GetWorldValueEx(self.g_WID_CityLordBossSpawnDayKey)
    if lastSpawnDayKey == dayKey then
        self:notify_tips(selfId, "BOSS thành chủ hôm nay đã thả")
        return
    end

    local mstId = self:LuaFnCreateMonster(self.g_CityLordBossMonsterId, self.g_CityLordBossX, self.g_CityLordBossZ, 4, define.INVAILD_ID, self.script_id)
    mstId = tonumber(mstId) or 0
    if mstId <= 0 then
        self:notify_tips(selfId, "Thi triển thất bại")
        return
    end

    self:SetCharacterTitle(mstId, "BOSS thành chủ")
    self:LuaFnSetLifeTimeAttrRefix_MaxHP(mstId, self.g_CityLordBossMaxHp)
    self:SetHp(mstId, self.g_CityLordBossMaxHp)
    self:SetCharacterDieTime(mstId, self.g_CityLordBossLiveMs)

    do
        local boss = self.scene and self.scene:get_obj_by_id(mstId)
        if boss and boss.set_unconstrained_monster then
            pcall(boss.set_unconstrained_monster, boss, 1)
        end
        if boss and boss.send_refresh_attrib then
            pcall(boss.send_refresh_attrib, boss)
        end
    end

    self:SetWorldValueEx(self.g_WID_CityLordBossSpawnDayKey, dayKey)

    local lordName = self:GetCityLordName()
    if lordName == "" then
        lordName = "洛阳城主"
    end
    local globalSCA = string.format("@*;SrvMsg;SCA:#RBOSS thành chủ#Whiện thân Hiệu Trường Lạc Dương! Do#G%s#Wthả (tọa độ %d,%d), các dũng sĩ mau tới thảo phạt!", lordName, self.g_CityLordBossX, self.g_CityLordBossZ)
    local globalChat = string.format("【BOSS thành chủ】#RBOSS thành chủ#Wđã làm mới ở Hiệu Trường Lạc Dương!#G%s#Wthả (%d,%d), mau tới khiêu chiến!", lordName, self.g_CityLordBossX, self.g_CityLordBossZ)
    self:AddGlobalCountNews(globalSCA)
    self:AddGlobalCountNews(globalChat)

    self:notify_tips(selfId, "BOSS thành chủ đã thả")
end

function chengzhu:OnDie(selfId, killerId)
    local ok = pcall(function()
        if self:GetMonsterDataID(selfId) ~= self.g_CityLordBossMonsterId then
            return
        end

        local killerName = ""
        if killerId and tonumber(killerId) and tonumber(killerId) > 0 and self:LuaFnIsObjValid(tonumber(killerId)) then
            killerName = self:LuaFnGetName(tonumber(killerId))
        end

        local obj = self.scene:get_obj_by_id(selfId)
        if not obj then
            return
        end
        local pos = obj:get_world_pos()
        local x = tonumber(pos.x) or self.g_CityLordBossX
        local z = tonumber(pos.y) or self.g_CityLordBossZ

        local used = {}
        for i = 1, self.g_CityLordBossDropBoxCount do
            local bx, bz
            for _ = 1, 20 do
                bx = x + math.random(-self.g_CityLordBossChestScatter, self.g_CityLordBossChestScatter)
                bz = z + math.random(-self.g_CityLordBossChestScatter, self.g_CityLordBossChestScatter)
                local key = tostring(bx) .. "," .. tostring(bz)
                if not used[key] then
                    used[key] = true
                    break
                end
            end

            local boxId = self:LuaFnCreateMonster(self.g_CityLordBossChestMonsterId, bx, bz, 3, 0, self.script_id)
            boxId = tonumber(boxId) or 0
            if boxId > 0 then
                self:SetCharacterName(boxId, self.g_CityLordBossChestName)
                self:SetCharacterTitle(boxId, self.g_CityLordBossChestTitle)
                self:SetCharacterDieTime(boxId, self.g_CityLordBossLiveMs)
                self:LuaFnSetNpcIntParameter(boxId, self.g_CityLordBossChestFlagIndex, self.g_CityLordBossChestFlagValue)

                local chest = self.scene and self.scene:get_obj_by_id(boxId)
                if chest and chest.set_unconstrained_monster then
                    pcall(chest.set_unconstrained_monster, chest, 1)
                end
            end
        end

        local msg
        if killerName ~= "" then
            msg = string.format("@*;SrvMsg;SCA:#RBOSS thành chủ#Wđã bị#G%s#Wđánh bại! Rơi#Y%d#Wquái rương (mở nhận#GLưu Ly Minh Châu#W,#GThiên Địa Minh Châu#W).", killerName, self.g_CityLordBossDropBoxCount)
        else
            msg = string.format("@*;SrvMsg;SCA:#RBOSS thành chủ#Wđã bị đánh bại! Rơi#Y%d#Wquái rương (mở nhận#GLong Uyên Thiên Công Hạp#W,#GTrầm Mộc Văn Nghệ Hạp#W).", self.g_CityLordBossDropBoxCount)
        end
       
        
    end)
    if not ok then
        return
    end
end

function chengzhu:OnActivateConditionCheck(selfId, activatorId)
    if self:GetMonsterDataID(selfId) ~= self.g_CityLordBossChestMonsterId then
        return 1
    end
    if self:MonsterAI_GetIntParamByIndex(selfId, self.g_CityLordBossChestFlagIndex) ~= self.g_CityLordBossChestFlagValue then
        return 1
    end
    if self:LuaFnGetPropertyBagSpace(activatorId) < 2 then
        self:BeginEvent(self.script_id)
        self:AddText("Túi hành trang không đủ chỗ")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    return 1
end

function chengzhu:OnActivateDeplete(selfId, activatorId)
    return 1
end

function chengzhu:OnActivateEffectOnce(selfId, activatorId)
    if self:GetMonsterDataID(selfId) ~= self.g_CityLordBossChestMonsterId then
        return 1
    end
    if self:MonsterAI_GetIntParamByIndex(selfId, self.g_CityLordBossChestFlagIndex) ~= self.g_CityLordBossChestFlagValue then
        return 1
    end

    local dropItems = self.g_CityLordBossDropItems
    if not dropItems or #dropItems == 0 then
        self:notify_tips(activatorId, "Rương trống")
        return 0
    end
    
    local randomIndex = math.random(1, #dropItems)
    local selectedItem = dropItems[randomIndex]
    local bag = self:TryRecieveItemWithCount(activatorId, selectedItem.id, selectedItem.count, true)
    if bag == -1 then
        self:notify_tips(activatorId, "Túi hành trang không đủ chỗ")
        return 0
    end

    self:notify_tips(activatorId, "nhận được vật phẩm")

    self:LuaFnDeleteMonster(selfId)
    return 1
end

function chengzhu:OnActivateEffectEachTick(selfId, activatorId)
    return 1
end

function chengzhu:OnActivateActionStart(selfId, activatorId)
    return 1
end

function chengzhu:OnActivateCancel(selfId, activatorId)
    return 0
end

function chengzhu:OnActivateInterrupt(selfId, activatorId)
    return 0
end

function chengzhu:ProcClearPendingChallenge(selfId)
    if self:LuaFnGetName(selfId) ~= "小天" then
        return
    end
    self:ClearPendingChallenge()
    self:SetChallengeBattleActive(false)
    self:notify_tips(selfId, "Đã xóa đếm giờ khiêu chiến hiện tại")
end

function chengzhu:ProcClearTestRecords(selfId)
    if self:LuaFnGetName(selfId) ~= "小天" then
        return
    end

    self:SetWorldValueEx(self.g_WID_CityLordBossSpawnDayKey, 0)
    self:SetWorldValueEx(self.g_WID_CityLordPortraitId, 0)
    self:SetWorldValueEx(self.g_WID_CityLordModelId, 0)
    self:SetWorldValueEx(self.g_WID_CityLordFashionDepotIndex, 0)
    self:SetWorldValueEx(self.g_WID_CityLordAppearanceValid, 0)
    self:SetChallengeBattleActive(false)
    self:SetMissionDataEx(selfId, self.g_MDEX_WorshipDay, 0)
    self:SetMissionDataEx(selfId, self.g_MDEX_WorshipCount, 0)
    self:SetMissionDataEx(selfId, self.g_MDEX_ChallengeFailProtectTs, 0)

    self:notify_tips(selfId, "Đã xóa: ghi chép thả BOSS, ghi chép bái lạy")
end

function chengzhu:GetWorldValueEx(wid)
    local v = self:LuaFnGetWorldGlobalDataEx(wid)
    v = tonumber(v) or 0
    return v
end

function chengzhu:SetWorldValueEx(wid, value)
    value = tonumber(value) or 0
    self:LuaFnSetWorldGlobalDataEx(wid, value)
end

function chengzhu:GetCityLordGuid()
    return self:GetWorldValueEx(self.g_WID_CityLordGuid)
end

function chengzhu:SetCityLordGuid(guid)
    guid = tonumber(guid) or 0
    self:SetWorldValueEx(self.g_WID_CityLordGuid, guid)
end

function chengzhu:IsChallengeBattleActive()
    return self:GetWorldValueEx(self.g_WID_ChallengeBattleActive) == 1
end

function chengzhu:SetChallengeBattleActive(active)
    self:SetWorldValueEx(self.g_WID_ChallengeBattleActive, active and 1 or 0)
end

function chengzhu:GetChallengeFailProtectRemain(selfId)
    local nowTs = os.time()
    local protectTs = tonumber(self:GetMissionDataEx(selfId, self.g_MDEX_ChallengeFailProtectTs)) or 0
    local remainSec = protectTs - nowTs
    if remainSec < 0 then
        remainSec = 0
    end
    return remainSec, protectTs
end

function chengzhu:SetChallengeFailProtect(selfId, protectTs)
    protectTs = tonumber(protectTs) or 0
    if protectTs < 0 then
        protectTs = 0
    end
    self:SetMissionDataEx(selfId, self.g_MDEX_ChallengeFailProtectTs, protectTs)
end

function chengzhu:SetChallengeFailProtectOnObj(selfId, protectTs)
    selfId = tonumber(selfId) or 0
    if selfId <= 0 then
        return
    end
    self:SetChallengeFailProtect(selfId, protectTs)
end

function chengzhu:ResetRevenueClaimBaseline(claimGuid, lastTotal)
    local nowTs = os.time()
    local dayKey = self:GetTodayDayKey()
    local curWorship = 0
    claimGuid = tonumber(claimGuid) or 0
    lastTotal = tonumber(lastTotal) or 0
    if dayKey > 0 then
        curWorship = self:GetWorldValueEx(self.g_WID_WorshipIncomeBase + dayKey)
    end
    self:SetWorldValueEx(self.g_WID_LastClaimTs, nowTs)
    self:SetWorldValueEx(self.g_WID_LastClaimGuid, claimGuid)
    self:SetWorldValueEx(self.g_WID_LastClaimDayKey, dayKey)
    self:SetWorldValueEx(self.g_WID_LastClaimWorshipSnapshot, curWorship)
    self:SetWorldValueEx(self.g_WID_LastClaimTaxSnapshot, 0)
    self:SetWorldValueEx(self.g_WID_LastClaimTotal, lastTotal)
end

function chengzhu:IsGuidOnline(guid)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return false
    end
    local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
    if not ok then
        return false
    end
    return user ~= nil
end

function chengzhu:CancelBuffOnGuid(guid, buffId)
    guid = tonumber(guid) or 0
    buffId = tonumber(buffId) or 0
    if guid <= 0 or buffId <= 0 then
        return
    end
    local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
    if ok and user and user.uinfo and user.uinfo.sceneid and user.uinfo.m_objID then
        local scene = string.format(".SCENE_%d", tonumber(user.uinfo.sceneid) or 0)
        pcall(skynet.send, scene, "lua", "char_excute_Script", self.script_id, "CancelCityLordBuffOnObj", tonumber(user.uinfo.m_objID) or 0, buffId)
    end
end

function chengzhu:SendPacketToGuid(guid, packet)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return false
    end
    skynet.send(".world", "lua", "send_to_online_user_by_guid", guid, packet)
    return true
end

function chengzhu:SendUICommandToGuid(guid, uiIndex, intValues, strValues)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return false
    end

    local msg = packet_def.GCUICommand.new()
    msg.m_Param = {}
    msg.m_Param.m_aIntValue = {}
    msg.m_Param.m_aStrOffset = {}

    intValues = intValues or {}
    msg.m_Param.m_IntCount = #intValues
    for i = 1, msg.m_Param.m_IntCount do
        msg.m_Param.m_aIntValue[i] = tonumber(intValues[i]) or 0
    end

    strValues = strValues or {}
    msg.m_Param.m_StrCount = #strValues
    if msg.m_Param.m_StrCount > 0 then
        local strs = {}
        local len = 0
        for i = 1, msg.m_Param.m_StrCount do
            strs[i] = gbk.fromutf8(tostring(strValues[i] or "")) .. string.char(0)
            len = len + string.len(strs[i])
            table.insert(msg.m_Param.m_aStrOffset, len - 1)
        end
        msg.m_Param.m_aStrValue = table.concat(strs)
    else
        msg.m_Param.m_aStrValue = ""
    end

    msg.m_nUIIndex = tonumber(uiIndex) or 0
    msg.unknow = 0
    return self:SendPacketToGuid(guid, msg)
end

function chengzhu:SendConfirmToGuid(guid, funcName, text)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return false
    end

    local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
    if not ok or not user or not user.uinfo or not user.uinfo.sceneid or not user.uinfo.m_objID then
        return false
    end

    local sceneId = tonumber(user.uinfo.sceneid) or 0
    local objId = tonumber(user.uinfo.m_objID) or 0
    if sceneId < 0 or objId <= 0 then
        return false
    end

	-- 直接在目标场景执行弹窗，保证无论城主在哪个位置都能弹出
	if sceneId == self:GetSceneID() then
		pcall(self.PopupConfirmOnObj, self, objId, objId, funcName, text)
		return true
	end

	local scene = string.format(".SCENE_%d", sceneId)
	pcall(skynet.send, scene, "lua", "char_excute_Script", self.script_id, "PopupConfirmOnObj", objId, objId, funcName, text)
	return true
end

function chengzhu:OnScenePlayerEnter(selfId)
    self:CheckPendingChallengeTimeout()

    do
        local challengerGuid, lordGuid, expireTs = self:GetPendingChallengeRaw()
        if challengerGuid > 0 and lordGuid > 0 and expireTs > 0 and os.time() < expireTs then
            local myGuid = self:LuaFnObjId2Guid(selfId)
            if myGuid > 0 and (myGuid == challengerGuid or myGuid == lordGuid) then
                local key = tostring(challengerGuid) .. ":" .. tostring(lordGuid) .. ":" .. tostring(expireTs)
                if self._pending_challenge_schedule_key ~= key then
                    self._pending_challenge_schedule_key = key
                    self:SchedulePendingChallengeTimeout(challengerGuid, lordGuid, expireTs)
                    self:StartPendingChallengeWatcher(challengerGuid, lordGuid, expireTs)
                end
                self:EnsurePendingChallengeDaemon()
            end
        end
    end

    self:SyncCityLordBuffOnObj(selfId)
end

function chengzhu:SyncCityLordBuffOnGuid(guid)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return
    end
    local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
    if ok and user and user.uinfo and user.uinfo.sceneid and user.uinfo.m_objID then
        local scene = string.format(".SCENE_%d", tonumber(user.uinfo.sceneid) or 0)
        pcall(skynet.send, scene, "lua", "char_excute_Script", self.script_id, "SyncCityLordBuffOnObj", tonumber(user.uinfo.m_objID) or 0)
    end
end

function chengzhu:SettlePendingChallengeTimeout(challengerGuid, lordGuid)
    challengerGuid = tonumber(challengerGuid) or 0
    lordGuid = tonumber(lordGuid) or 0
    if challengerGuid <= 0 or lordGuid <= 0 then
        return false
    end

	local oldLordText = "Ngươi thua khiêu chiến thành chủ Lạc Dương, ngôi thành chủ đổi chủ"
	pcall(function()
		local lordObjId = self:LuaFnGuid2ObjId(lordGuid)
		if lordObjId and lordObjId > 0 and self:LuaFnIsObjValid(lordObjId) then
			self:notify_tips(lordObjId, oldLordText)
		end
	end)
	pcall(function()
		local msg = packet_def.GCChat.new()
		msg.ChatType = define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA
		msg.Sourceid = define.INVAILD_ID
		msg.unknow_2 = 1
		msg:set_content(gbk.fromutf8("@*;SrvMsg;SCA:" .. oldLordText))
		self:SendPacketToGuid(lordGuid, msg)
	end)
	pcall(function()
		self:LuaFnSendMailToGUID(lordGuid, oldLordText)
	end)

	local challengerText = "Do thành chủ cũ không kịp ứng chiến, bạn đã thay thế thành thành chủ mới"
	pcall(function()
		local challengerObjId = self:LuaFnGuid2ObjId(challengerGuid)
		if challengerObjId and challengerObjId > 0 and self:LuaFnIsObjValid(challengerObjId) then
			self:notify_tips(challengerObjId, challengerText)
		end
	end)
	pcall(function()
		local msg = packet_def.GCChat.new()
		msg.ChatType = define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA
		msg.Sourceid = define.INVAILD_ID
		msg.unknow_2 = 1
		msg:set_content(gbk.fromutf8("@*;SrvMsg;SCA:" .. challengerText))
		self:SendPacketToGuid(challengerGuid, msg)
	end)
	pcall(function()
		self:LuaFnSendMailToGUID(challengerGuid, challengerText)
	end)

	pcall(function()
		local challengerName = "Người khiêu chiến"
		local lordName = "洛阳城主"
		local cuinfo = self:GetPlayerInfoByGuid(challengerGuid)
		if cuinfo and cuinfo.name and cuinfo.name ~= "" then
			challengerName = cuinfo.name
		end
		local luinfo = self:GetPlayerInfoByGuid(lordGuid)
		if luinfo and luinfo.name and luinfo.name ~= "" then
			lordName = luinfo.name
		end
		local globalSCA = string.format("@*;SrvMsg;SCA:#R【Khiêu chiến thành chủ】#WThành chủ#G%s#Wquá giờ không ứng chiến,#G%s#Wkế nhiệm thành chủ Lạc Dương!", lordName, challengerName)
		local globalChat = string.format("【Khiêu chiến thành chủ】Thành chủ %s quá giờ không ứng chiến, %s kế nhiệm thành chủ Lạc Dương!", lordName, challengerName)
		self:AddGlobalCountNews(globalSCA)
		self:AddGlobalCountNews(globalChat)
	end)

	local ok = false
	pcall(function()
		ok = self:TrySetNewCityLord(challengerGuid, lordGuid) and true or false
	end)
	return ok
end

function chengzhu:StartPendingChallengeWatcher(challengerGuid, lordGuid, expireTs)
    challengerGuid = tonumber(challengerGuid) or 0
    lordGuid = tonumber(lordGuid) or 0
    expireTs = tonumber(expireTs) or 0
    if challengerGuid <= 0 or lordGuid <= 0 or expireTs <= 0 then
        return
    end
    if self._pending_challenge_watcher_running then
        return
    end
    self._pending_challenge_watcher_running = true
    local function tick()
        local ok = xpcall(function()
            local cGuid, lGuid, eTs = self:GetPendingChallengeRaw()
            if cGuid <= 0 or lGuid <= 0 or eTs <= 0 then
                self._pending_challenge_watcher_running = false
                return
            end
            if os.time() > eTs then
                self._pending_challenge_watcher_running = false
                self:SettlePendingChallengeTimeout(cGuid, lGuid)
                return
            end
            skynet.timeout(500, tick)
        end, debug.traceback)
        if not ok then
            self._pending_challenge_watcher_running = false
        end
    end
    skynet.timeout(500, tick)
end

function chengzhu:CheckPendingChallengeTimeout()
    local challengerGuid, lordGuid, expireTs = self:GetPendingChallengeRaw()
    if challengerGuid <= 0 or lordGuid <= 0 or expireTs <= 0 then
        return false
    end
    if os.time() <= expireTs then
        return false
    end
    local ok, err = xpcall(function()
        self:SettlePendingChallengeTimeout(challengerGuid, lordGuid)
    end, debug.traceback)
    if not ok then
        skynet.loge("chengzhu:CheckPendingChallengeTimeout err=" .. tostring(err))
        self:ClearPendingChallenge()
        return false
    end
    return true
end

function chengzhu:OnLuoyangSceneTimer(selfId)
    if not selfId or selfId <= 0 then
        return
    end

    -- 定期检查场景中所有玩家的城主BUFF
    local lordGuid = self:GetCityLordGuid()
    if lordGuid > 0 then
        local scene = self.scene
        if scene then
            local players = scene:get_all_players()
            if players then
                for _, player in ipairs(players) do
                    local playerId = player:get_id()
                    if playerId and playerId > 0 then
                        local myGuid = self:LuaFnObjId2Guid(playerId)
                        local have = self:LuaFnHaveImpactOfSpecificDataIndex(playerId, self.g_BuffChallenge)
                        if have and myGuid ~= lordGuid then
                            self:CancelCityLordBuffOnObj(playerId, self.g_BuffChallenge)
                        end
                    end
                end
            end
        end
    end

    local challengerGuid, lordGuid2, expireTs = self:GetPendingChallengeRaw()
    if challengerGuid <= 0 or lordGuid2 <= 0 or expireTs <= 0 then
        return
    end
    if os.time() <= expireTs then
        return
    end

    self:SettlePendingChallengeTimeout(challengerGuid, lordGuid2)
end

function chengzhu:SchedulePendingChallengeTimeout(challengerGuid, lordGuid, expireTs)
    challengerGuid = tonumber(challengerGuid) or 0
    lordGuid = tonumber(lordGuid) or 0
    expireTs = tonumber(expireTs) or 0
    if challengerGuid <= 0 or lordGuid <= 0 or expireTs <= 0 then
        return
    end

    local delaySec = expireTs - os.time()
    if delaySec < 0 then
        delaySec = 0
    end
    local delayTick = math.floor(delaySec * 100)
    if delayTick < 1 then
        delayTick = 1
    end

    skynet.timeout(delayTick, function()
        local ok, err = xpcall(function()
            local cGuid, lGuid, eTs = self:GetPendingChallengeRaw()
            if cGuid ~= challengerGuid or lGuid ~= lordGuid or eTs ~= expireTs then
                return
            end
            if os.time() <= eTs then
                return
            end
            self:SettlePendingChallengeTimeout(challengerGuid, lordGuid)
        end, debug.traceback)
        if not ok then
            skynet.loge("chengzhu:SchedulePendingChallengeTimeout err=" .. tostring(err))
            self:ClearPendingChallenge()
            return
        end
    end)
end

function chengzhu:PopupConfirmOnObj(selfId, targetId, funcName, text)
    targetId = tonumber(targetId) or define.INVAILD_ID
    funcName = tostring(funcName or "")
    text = tostring(text or "")

    self:BeginUICommand()
    self:UICommand_AddInt(self.script_id)
    self:UICommand_AddInt(targetId)
    self:UICommand_AddStr(funcName)
    self:UICommand_AddStr(text)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 24)
end

function chengzhu:CityLordTransferToLuoyang(selfId, targetId)
    self:ProcRespondTransfer(selfId)
end

function chengzhu:CancelCityLordBuffOnObj(selfId, buffId)
    buffId = tonumber(buffId) or 0
    if buffId <= 0 then
        return
    end
    selfId = tonumber(selfId) or 0
    if selfId <= 0 then
        return
    end
    
    self:LuaFnCancelSpecificImpact(selfId, buffId)
    local obj = self.scene and self.scene:get_obj_by_id(selfId)
    if obj then
        obj:impact_cancel_impact_in_specific_data_index(buffId)
    end
end

function chengzhu:SendDirectEventWindowToGuid(guid, text, buttons)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return false
    end

    local targetObjId = define.INVAILD_ID
    do
        local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
        if ok and user and user.uinfo and user.uinfo.m_objID then
            targetObjId = tonumber(user.uinfo.m_objID) or define.INVAILD_ID
        end
    end

    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = 0
    ret.target_id = targetObjId
    ret.event = {}

    local e1 = {}
    e1.flag = 2
    e1.str = gbk.fromutf8(text or "")
    e1.type = 0
    e1.index = 0
    e1.script_id = self.script_id
    e1.split = -1
    e1.len = string.len(e1.str)
    table.insert(ret.event, e1)

    if type(buttons) == "table" then
        for _, b in ipairs(buttons) do
            local e = {}
            e.flag = 1
            e.type = b.type or -1
            e.index = tonumber(b.index) or 0
            e.script_id = self.script_id
            e.split = -1
            e.str = gbk.fromutf8(b.text or "")
            e.len = string.len(e.str)
            table.insert(ret.event, e)
        end
    end

    ret.size = #ret.event
    self:SendPacketToGuid(guid, ret)
    return true
end

function chengzhu:GetPendingChallengeRaw()
    local challengerGuid = self:GetWorldValueEx(self.g_WID_PendingChallengeChallengerGuid)
    local lordGuid = self:GetWorldValueEx(self.g_WID_PendingChallengeLordGuid)
    local expireTs = self:GetWorldValueEx(self.g_WID_PendingChallengeExpireTs)
    if challengerGuid <= 0 or lordGuid <= 0 or expireTs <= 0 then
        return 0, 0, 0
    end
    return challengerGuid, lordGuid, expireTs
end

function chengzhu:GetPendingChallenge()
    local challengerGuid, lordGuid, expireTs = self:GetPendingChallengeRaw()
    if challengerGuid <= 0 or lordGuid <= 0 or expireTs <= 0 then
        return 0, 0, 0
    end
    if os.time() > expireTs then
        local ok = xpcall(function()
			self:SettlePendingChallengeTimeout(challengerGuid, lordGuid)
		end, debug.traceback)
		if not ok then
			self:ClearPendingChallenge()
		end
		return 0, 0, 0
    end
    return challengerGuid, lordGuid, expireTs
end

function chengzhu:SetPendingChallenge(challengerGuid, lordGuid, expireTs)
    challengerGuid = tonumber(challengerGuid) or 0
    lordGuid = tonumber(lordGuid) or 0
    expireTs = tonumber(expireTs) or 0
    self:SetWorldValueEx(self.g_WID_PendingChallengeChallengerGuid, challengerGuid)
    self:SetWorldValueEx(self.g_WID_PendingChallengeLordGuid, lordGuid)
    self:SetWorldValueEx(self.g_WID_PendingChallengeExpireTs, expireTs)
end

function chengzhu:ClearPendingChallenge()
	self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 0)
    self:SetPendingChallenge(0, 0, 0)
end

function chengzhu:GetPlayerInfoByGuid(guid)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return nil
    end
    local ok, uinfo = pcall(skynet.call, ".world", "lua", "get_player_info", guid)
    if not ok then
        return nil
    end
    return uinfo
end

function chengzhu:GetCityLordName()
    local guid = self:GetCityLordGuid()
    if guid <= 0 then
        return ""
    end
    local uinfo = self:GetPlayerInfoByGuid(guid)
    if not uinfo then
        return ""
    end
    return uinfo.name or ""
end

function chengzhu:RefreshNpcNameTitle(npcId)
    npcId = tonumber(npcId) or 0
    if npcId <= 0 then
        local ok, nid = pcall(self.LuaFnGuid2ObjId, self, self.g_NpcGuid)
        if ok then
            npcId = tonumber(nid) or 0
        end
    end
    if npcId <= 0 then
        return
    end
    if not self:LuaFnIsObjValid(npcId) then
        return
    end

    local title = "洛阳城主"
    local name = self:GetCityLordName()
    if name == "" then
        name = "Tạm thời không có"
    end

    self:SetCharacterTitle(npcId, title)
    self:SetCharacterName(npcId, name)

    local npc = self.scene and self.scene:get_obj_by_id(npcId)
    if npc and npc.send_refresh_attrib then
        pcall(npc.send_refresh_attrib, npc)
    end
end

function chengzhu:IsInLuoyang(selfId)
    local sceneId = self:GetSceneID()
    return sceneId == 0 or sceneId == 1311
end

function chengzhu:IsObjInCurrentScene(objId)
	objId = tonumber(objId) or 0
	if objId <= 0 then
		return false
	end
	if not self.scene or type(self.scene.get_obj_by_id) ~= "function" then
		return false
	end
	local obj = self.scene:get_obj_by_id(objId)
	return obj ~= nil
end

function chengzhu:GetObjSceneId(objId)
	objId = tonumber(objId) or 0
	if objId <= 0 then
		return -1
	end
	local sceneId = -1
	pcall(function()
		if type(_G.GetSceneID) == "function" then
			sceneId = tonumber(_G.GetSceneID(objId)) or -1
		end
	end)
	if sceneId and sceneId >= 0 then
		return sceneId
	end
	pcall(function()
		if type(self.GetSceneID) == "function" then
			sceneId = tonumber(self:GetSceneID(objId)) or -1
		end
	end)
	return tonumber(sceneId) or -1
end

function chengzhu:IsObjInLuoyang(objId)
	local sceneId = self:GetObjSceneId(objId)
	return sceneId == 0 or sceneId == 1311
end

function chengzhu:NormalizeHumanObjId(selfId)
	selfId = tonumber(selfId) or 0
	if selfId <= 0 then
		return 0
	end
	local isValid = false
	pcall(function()
		if type(self.LuaFnIsObjValid) == "function" then
			isValid = self:LuaFnIsObjValid(selfId) and true or false
		end
	end)
	if isValid then
		return selfId
	end
	local objId = 0
	pcall(function()
		objId = tonumber(self:LuaFnGuid2ObjId(selfId)) or 0
	end)
	if objId > 0 then
		return objId
	end
	pcall(function()
		local ok, user = pcall(skynet.call, ".world", "lua", "find_user", selfId)
		if ok and user and user.uinfo and user.uinfo.m_objID then
			local objId2 = tonumber(user.uinfo.m_objID) or 0
			if objId2 > 0 then
				objId = objId2
			end
		end
	end)
	if objId > 0 then
		return objId
	end
	return 0
end

function chengzhu:SendSrvMsgToGuid(guid, text)
	guid = tonumber(guid) or 0
	if guid <= 0 or type(text) ~= "string" or text == "" then
		return
	end
	pcall(function()
		local msg = packet_def.GCChat.new()
		msg.ChatType = define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA
		msg.Sourceid = define.INVAILD_ID
		msg.unknow_2 = 1
		msg:set_content("@*;SrvMsg;SCA:" .. text)
		self:SendPacketToGuid(guid, msg)
	end)
end

function chengzhu:CostBindYuanBaoChecked(selfId, count)
    count = tonumber(count) or 0
    if count <= 0 then
        return false
    end
    local have = self:GetBindYuanBao(selfId)
    have = tonumber(have) or 0
    if have < count then
        return false
    end
    self:LuaFnCostBindYuanBao(selfId, count)
    return true
end

function chengzhu:OnDefaultEvent(selfId, targetId)
    local ok, err = xpcall(function()
        self:CheckPendingChallengeTimeout()
        self:EnsurePendingChallengeDaemon()
        self:EnsurePendingChallengeEngineTimer(selfId)
        self:RefreshNpcNameTitle(targetId)
        
        -- 检查并同步城主BUFF
        self:SyncCityLordBuffOnObj(selfId)

        local lordName = self:GetCityLordName()
        if lordName == "" then
            lordName = "Tạm thời không có"
        end

        local myGuid = self:LuaFnObjId2Guid(selfId)
        local lordGuid = self:GetCityLordGuid()
        local challengerGuid, pendingLordGuid = self:GetPendingChallenge()

        self:BeginEvent(self.script_id)
        --self:AddText(string.format("SCRIPT:%s", tostring(self.g_VersionStamp)))
        self:AddText(string.format("#YThành chủ Lạc Dương hiện tại:#H%s", lordName))
		 self:AddText(string.format("#HBổng lộc hôm nay:#G1000#Hkim/#G1#Hgiờ"))
        if myGuid > 0 and myGuid == lordGuid and challengerGuid > 0 and pendingLordGuid == lordGuid then
            self:AddNumText("Bắt đầu ứng chiến (10 giây vào lôi đài)", 6, 5)
        end
        if myGuid > 0 and myGuid == lordGuid then
            --self:AddNumText("释放城主BOSS", 6, 11)
            self:AddNumText("Nhận bù BUFF thành chủ", 6, 13)
        end
        if self:LuaFnGetName(selfId) == "小天" then
            self:AddNumText("Xóa đếm giờ khiêu chiến hiện tại", 6, 8)
            self:AddNumText("Test xóa ghi chép", 6, 12)
        end
        self:AddNumText("Khiêu chiến thành chủ", 6, 0)
       -- self:AddNumText("膜拜城主", 6, 1)
        self:AddNumText("Nhận thu nhập thành chủ", 6, 2)
        self:AddNumText("Giới thiệu hệ thống", 6, 3)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end, debug.traceback)
    if not ok then
        self:notify_tips(selfId, "Script thành chủ bất thường, xin báo quản trị")
        skynet.loge("chengzhu:OnDefaultEvent err=" .. tostring(err))
    end
end

function chengzhu:ProcChallenge(selfId)
    self:CheckPendingChallengeTimeout()
	self:EnsurePendingChallengeDaemon()
	self:EnsurePendingChallengeEngineTimer(selfId)
    if not self:CheckChallengeRequirement(selfId) then
        return
    end
    if not self:IsInLuoyang(selfId) then
        self:notify_tips(selfId, "Chỉ thao tác được ở Lạc Dương")
        return
    end

    local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()

    if lordGuid <= 0 then
        if not self:IsInLuoyang(selfId) then
            self:notify_tips(selfId, "Chỉ khiêu chiến được ở Lạc Dương")
            return
        end
        self:TrySetNewCityLord(myGuid, 0)
        self:notify_tips(selfId, "Ngươi đã thành thành chủ Lạc Dương")
        return
    end

    if myGuid == lordGuid then
        self:notify_tips(selfId, "Ngươi đã là thành chủ Lạc Dương")
        return
    end

    local protectRemain = self:GetChallengeFailProtectRemain(selfId)
    if protectRemain > 0 then
        local minute = math.floor(protectRemain / 60)
        local sec = protectRemain % 60
        self:notify_tips(selfId, string.format("Đang bảo hộ khiêu chiến, xin thử lại sau %d phút %d giây", minute, sec))
        return
    end

    if self:IsChallengeBattleActive() then
        self:notify_tips(selfId, "Lôi đài đang có khiêu chiến, xin thử lại sau")
        return
    end

    if not self:IsGuidOnline(lordGuid) then
        self:notify_tips(selfId, "Thành chủ offline, ngươi thành thành chủ Lạc Dương mới")
        self:TrySetNewCityLord(myGuid, lordGuid)
        return
    end

    local challengerGuid, pendingLordGuid, expireTs = self:GetPendingChallenge()
    if challengerGuid > 0 and expireTs > 0 then
        self:notify_tips(selfId, "Hiện có khiêu chiến đang diễn ra")
        return
    end

    if not self:CostBindYuanBaoChecked(selfId, self.g_CostChallenge) then
        self:notify_tips(selfId, "Không đủ Nguyên bảo để trói")
        return
    end

    local challengerName = self:LuaFnGetName(selfId)
    local lordName = self:GetCityLordName()
    if lordName == "" then
        lordName = "洛阳城主"
    end

    local text = string.format("#G%s#Wkhiêu chiến thành chủ với ngươi, xin về Hiệu Trường ứng chiến trong 10 phút, quá giờ mất tư cách thành chủ (bấm xác nhận về ngay)", challengerName)

    local globalSCA = string.format("@*;SrvMsg;SCA:#G%s#Wkhiêu chiến thành chủ Lạc Dương#R%s#W! Thành chủ xin về Hiệu Trường ứng chiến trong 10 phút, quá giờ mất tư cách.", challengerName, lordName)
    local globalChat = string.format("【Khiêu chiến thành chủ】#G%s#Wkhiêu chiến thành chủ Lạc Dương#R%s#W!#Y(ứng chiến trong 10 phút)#W", challengerName, lordName)
    self:AddGlobalCountNews(globalSCA)
    self:AddGlobalCountNews(globalChat)

    do
        local msg = packet_def.GCChat.new()
        msg.ChatType = define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA
        msg.Sourceid = define.INVAILD_ID
        msg.unknow_2 = 1
        msg:set_content(gbk.fromutf8("@*;SrvMsg;SCA:" .. text))
        self:SendPacketToGuid(lordGuid, msg)
    end

    do
        local msg = packet_def.GCChat.new()
        msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_TELL
        msg.Sourceid = selfId
        msg.unknow_3 = 1
        msg:set_source_name(challengerName)
        local lordName = self:GetCityLordName()
        if lordName ~= "" then
            msg:set_dest_name(lordName)
        end
        msg:set_content(gbk.fromutf8(text))
        self:SendPacketToGuid(lordGuid, msg)
    end

    self:LuaFnSendMailToGUID(lordGuid, text)

    local expireTs = os.time() + 600
    self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 0)
    self:SetPendingChallenge(myGuid, lordGuid, expireTs)
    self:SchedulePendingChallengeTimeout(myGuid, lordGuid, expireTs)
    self:StartPendingChallengeWatcher(myGuid, lordGuid, expireTs)
    self:EnsurePendingChallengeDaemon()
    self:EnsurePendingChallengeEngineTimer(selfId)

    self:SendConfirmToGuid(lordGuid, "CityLordTransferToLuoyang", text)

    self:notify_tips(selfId, "Yêu cầu khiêu chiến đã gửi, chờ thành chủ ứng chiến")
    self:notify_tips(selfId, "Trong khiêu chiến không rời Lạc Dương được")
end

function chengzhu:ProcRespond(selfId, targetId)
	selfId = self:NormalizeHumanObjId(selfId)
	if not selfId or selfId <= 0 then
		pcall(function()
			self:notify_tips(selfId, "Ứng chiến thất bại: không nhận diện được nhân vật")
		end)
		pcall(function()
			self:LuaFnSendMailToGUID(tonumber(selfId) or 0, "Ứng chiến thất bại: không nhận diện được nhân vật")
		end)
		return
	end
	local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    if myGuid <= 0 or myGuid ~= lordGuid then
        self:notify_tips(selfId, "Chỉ thành chủ mới ứng chiến được")
        return
    end

    local challengerGuid, pendingLordGuid = self:GetPendingChallenge()
    if challengerGuid <= 0 or pendingLordGuid ~= lordGuid then
        self:notify_tips(selfId, "Hiện không có khiêu chiến chờ xử lý")
		pcall(function()
			self:LuaFnSendMailToGUID(lordGuid, "Hiện không có khiêu chiến chờ xử lý")
		end)
        return
    end
	local challengerId = self:LuaFnGuid2ObjId(challengerGuid)
	if not challengerId or challengerId <= 0 or (not self:IsObjInLuoyang(challengerId)) then
		self:ClearPendingChallenge()
		self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 0)
		self:notify_tips(selfId, "Người khiêu chiến đã rời Lạc Dương, hủy khiêu chiến")
		self:LuaFnSendMailToGUID(lordGuid, "Người khiêu chiến đã rời Lạc Dương, đã hủy")
		return
	end
	self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 1)

    self:BeginEvent(self.script_id)
    self:AddText("Truyền tống ngay về Lạc Dương ứng chiến?")
    self:AddNumText("Truyền tống ngay", 6, 6)
    self:AddNumText("Tạm không truyền tống", 6, 7)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function chengzhu:ProcRespondTransfer(selfId)
	local rawSelfId = tonumber(selfId) or 0
	selfId = self:NormalizeHumanObjId(selfId)
	if not selfId or selfId <= 0 then
		pcall(function()
			self:notify_tips(rawSelfId, "Truyền tống ứng chiến thất bại: không nhận diện được nhân vật")
		end)
		pcall(function()
			self:LuaFnSendMailToGUID(rawSelfId, "Truyền tống ứng chiến thất bại: không nhận diện được nhân vật")
		end)
		return
	end
	local myGuid = self:LuaFnObjId2Guid(selfId)
	local lordGuid = self:GetCityLordGuid()
	if myGuid <= 0 or myGuid ~= lordGuid then
		self:notify_tips(selfId, "Chỉ thành chủ mới ứng chiến được")
		return
	end
	local challengerGuid, pendingLordGuid = self:GetPendingChallenge()
	if challengerGuid <= 0 or pendingLordGuid ~= lordGuid then
		self:notify_tips(selfId, "Hiện không có khiêu chiến chờ xử lý")
		return
	end
	-- 只负责把城主传回洛阳，不在这里判定挑战者是否仍在洛阳
	-- 挑战是否取消，统一放到“开始应战”(ProcStartBattle)里处理
	self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 1)
	pcall(function()
		self:notify_tips(selfId, "Đang truyền tống về Lạc Dương")
	end)
	self:CallScriptFunction((400900), "TransferFunc", selfId, self.g_LuoyangTransferSceneId, self.g_LuoyangTransferX, self.g_LuoyangTransferZ)
end

function chengzhu:ProcStartBattle(selfId)
	local rawSelfId = tonumber(selfId) or 0
	selfId = self:NormalizeHumanObjId(selfId)
	if not selfId or selfId <= 0 then
		pcall(function()
			self:notify_tips(rawSelfId, "Bắt đầu ứng chiến thất bại: không nhận diện được nhân vật")
		end)
		return
	end
	local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    if myGuid <= 0 or myGuid ~= lordGuid then
        self:notify_tips(selfId, "Chỉ thành chủ mới ứng chiến được")
        return
    end
	local okRun, errRun = xpcall(function()
		-- 直接读取world value，避免触发SettlePendingChallengeTimeout
		local challengerGuid = tonumber(self:GetWorldValueEx(self.g_WID_PendingChallengeChallengerGuid)) or 0
		local pendingLordGuid = tonumber(self:GetWorldValueEx(self.g_WID_PendingChallengeLordGuid)) or 0
		if challengerGuid <= 0 or pendingLordGuid ~= lordGuid then
			self:notify_tips(selfId, "Hiện không có khiêu chiến chờ xử lý")
			return
		end

		-- 先获取挑战者objId
		local challengerId = 0
		pcall(function()
			challengerId = tonumber(self:LuaFnGuid2ObjId(challengerGuid)) or 0
		end)

		-- 判断挑战者是否在洛阳，用pcall保护
		local challengerInLuoyang = false
		pcall(function()
			if challengerId and challengerId > 0 then
				local valid = self:LuaFnIsObjValid(challengerId)
				if valid then
					challengerInLuoyang = self:IsObjInLuoyang(challengerId)
				end
			end
		end)

		if (not challengerInLuoyang) then
			self:ClearPendingChallenge()
			self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 0)
			self:notify_tips(selfId, "Người khiêu chiến đã rời Lạc Dương, hủy khiêu chiến")
			-- 发送邮件通知城主
			pcall(function()
				self:LuaFnSendMailToGUID(myGuid, "Do người khiêu chiến rời Lạc Dương, lần này hủy, tư cách thành chủ của bạn giữ nguyên.")
			end)
			-- 发送邮件通知挑战者
			pcall(function()
				self:LuaFnSendMailToGUID(challengerGuid, "Do bạn rời Lạc Dương trong lúc chờ khiêu chiến, xử thua bỏ cuộc, ngôi thành chủ không đổi.")
			end)
			return
		end
		if not challengerId or challengerId <= 0 or (not self:LuaFnIsObjValid(challengerId)) then
			self:ClearPendingChallenge()
			self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 0)
			self:notify_tips(selfId, "Bắt đầu ứng chiến thất bại: không lấy được người khiêu chiến")
			return
		end
		self:SetWorldValueEx(self.g_WID_PendingChallengeAccepted, 1)
        self:SetChallengeBattleActive(true)

		self:ClearPendingChallenge()
		self:notify_tips(selfId, "10 giây sau vào lôi đài")
		self:notify_tips(challengerId, "10 giây sau vào lôi đài")

		skynet.timeout(1000, function()
			pcall(function()
				if not self:LuaFnIsObjValid(selfId) then
                    self:SetChallengeBattleActive(false)
					return
				end
				if not self:LuaFnIsObjValid(challengerId) then
                    self:SetChallengeBattleActive(false)
					return
				end
				self:CallScriptFunction(self.g_ChallengeScriptId, "DoChallenge", challengerId, selfId)
			end)
		end)
	end, debug.traceback)

	if not okRun then
		print("[chengzhu] ProcStartBattle ERROR: " .. tostring(errRun))
        self:SetChallengeBattleActive(false)
		self:notify_tips(selfId, "Script bắt đầu ứng chiến lỗi")
	end
end

function chengzhu:ProcWorship(selfId)
    if not self:IsInLuoyang(selfId) then
        self:notify_tips(selfId, "Chỉ thao tác được ở Lạc Dương")
        return
    end

    local lordGuid = self:GetCityLordGuid()
    if lordGuid <= 0 then
        self:notify_tips(selfId, "Hiện chưa có thành chủ")
        return
    end

    local myGuid = self:LuaFnObjId2Guid(selfId)
    if myGuid == lordGuid then
        self:notify_tips(selfId, "Không thể bái lạy bản thân")
        return
    end

    local day = self:GetDayTime()
    local lastDay = self:GetMissionDataEx(selfId, self.g_MDEX_WorshipDay)
    lastDay = tonumber(lastDay) or 0
    local count = self:GetMissionDataEx(selfId, self.g_MDEX_WorshipCount)
    count = tonumber(count) or 0

    if lastDay ~= day then
        lastDay = day
        count = 0
        self:SetMissionDataEx(selfId, self.g_MDEX_WorshipDay, lastDay)
        self:SetMissionDataEx(selfId, self.g_MDEX_WorshipCount, 0)
    end

    if count >= 1 then
        self:notify_tips(selfId, "Hôm nay đã bái lạy")
        return
    end

    if not self:CostBindYuanBaoChecked(selfId, self.g_CostWorship) then
        self:notify_tips(selfId, "Không đủ Nguyên bảo để trói")
        return
    end

    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_BuffWorship, 0)

    self:SetMissionDataEx(selfId, self.g_MDEX_WorshipCount, count + 1)

    local dayKey = self:GetTodayDayKey()
    if dayKey > 0 then
        local wid = self.g_WID_WorshipIncomeBase + dayKey
        local income = self:GetWorldValueEx(wid)
        self:SetWorldValueEx(wid, income + self.g_CostWorship)
    end

    self:notify_tips(selfId, "Bái lạy thành công")
end

function chengzhu:ParseDayKey(dayKey)
    dayKey = tonumber(dayKey) or 0
    if dayKey <= 0 then
        return 0, 0, 0
    end
    local yy = math.floor(dayKey / 10000)
    local mm = math.floor(dayKey / 100) % 100
    local dd = dayKey % 100
    return 2000 + yy, mm, dd
end

function chengzhu:CalcPeriodIncome(lastDayKey, snapWorship, snapTax, curDayKey)
    lastDayKey = tonumber(lastDayKey) or 0
    snapWorship = tonumber(snapWorship) or 0
    snapTax = tonumber(snapTax) or 0
    curDayKey = tonumber(curDayKey) or 0

    if curDayKey <= 0 then
        return 0, 0
    end

    if lastDayKey <= 0 then
        local worship = self:GetWorldValueEx(self.g_WID_WorshipIncomeBase + curDayKey)
        local tax = self:GetWorldValueEx(self.g_WID_TaxBase + curDayKey)
        return worship, tax
    end

    if lastDayKey == curDayKey then
        local worship = self:GetWorldValueEx(self.g_WID_WorshipIncomeBase + curDayKey) - snapWorship
        local tax = self:GetWorldValueEx(self.g_WID_TaxBase + curDayKey) - snapTax
        if worship < 0 then worship = 0 end
        if tax < 0 then tax = 0 end
        return worship, tax
    end

    local worship = self:GetWorldValueEx(self.g_WID_WorshipIncomeBase + lastDayKey) - snapWorship
    local tax = self:GetWorldValueEx(self.g_WID_TaxBase + lastDayKey) - snapTax
    if worship < 0 then worship = 0 end
    if tax < 0 then tax = 0 end

    local year, month, day = self:ParseDayKey(lastDayKey)
    local ts = os.time({ year = year, month = month, day = day, hour = 0, min = 0, sec = 0 })
    if ts then
        ts = ts + 86400
        for _ = 1, 120 do
            local dk = tonumber(os.date("%y%m%d", ts)) or 0
            if dk <= 0 then
                break
            end
            worship = worship + self:GetWorldValueEx(self.g_WID_WorshipIncomeBase + dk)
            tax = tax + self:GetWorldValueEx(self.g_WID_TaxBase + dk)
            if dk == curDayKey then
                break
            end
            ts = ts + 86400
        end
    end

    return worship, tax
end

function chengzhu:GetRevenueInfo()
    local curDayKey = self:GetTodayDayKey()
    local lastDayKey = self:GetWorldValueEx(self.g_WID_LastClaimDayKey)
    local snapWorship = self:GetWorldValueEx(self.g_WID_LastClaimWorshipSnapshot)
    local lastTotal = self:GetWorldValueEx(self.g_WID_LastClaimTotal)
    local nowTs = os.time()
    local lastClaimTs = self:GetWorldValueEx(self.g_WID_LastClaimTs)
    if lastClaimTs <= 0 or lastClaimTs > nowTs then
        lastClaimTs = nowTs
    end
    local elapsedSec = nowTs - lastClaimTs
    if elapsedSec < 0 then
        elapsedSec = 0
    end
    local elapsedHour = math.floor(elapsedSec / 3600)
    local hourlyIncome = elapsedHour * self.g_HourlyRevenueMoney

    local worship = self:CalcPeriodIncome(lastDayKey, snapWorship, 0, curDayKey)
    local worshipIncome = math.floor(worship * 0.5)
    local total = worshipIncome + hourlyIncome

    return {
        curDayKey = curDayKey,
        lastDayKey = lastDayKey,
        lastClaimTs = lastClaimTs,
        elapsedHour = elapsedHour,
        hourlyIncome = hourlyIncome,
        worship = worship,
        worshipIncome = worshipIncome,
        tax = 0,
        taxIncome = 0,
        total = total,
        lastTotal = lastTotal,
    }
end

function chengzhu:ProcClaimRevenue(selfId, targetId)
    if not self:IsInLuoyang(selfId) then
        self:notify_tips(selfId, "Chỉ thao tác được ở Lạc Dương")
        return
    end

    local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    if myGuid <= 0 or myGuid ~= lordGuid then
        self:notify_tips(selfId, "Chỉ thành chủ Lạc Dương mới nhận được")
        return
    end

    local info = self:GetRevenueInfo()

    self:BeginEvent(self.script_id)
    self:AddText("Chi tiết thu nhập thành chủ:")
    self:AddText(string.format("Thu nhập nhận lần trước: %d", info.lastTotal))
    self:AddText(string.format("Tổng thu nhập nhận được: %d", info.total))
    self:AddText(string.format("Bổng lộc: mỗi giờ %d kim#r#G(tích lũy %d giờ, tính vào %d)", self.g_HourlyRevenueMoney, info.elapsedHour, info.hourlyIncome))
    self:AddText(string.format("Thu nhập bái lạy: %d (tính vào %d)", info.worship, info.worshipIncome))
    if info.total > 0 then
        self:AddNumText("Xác định lĩnh", 6, 9)
    end
    self:AddNumText("Chờ thêm chút", 6, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function chengzhu:ProcClaimRevenueConfirm(selfId)
    if not self:IsInLuoyang(selfId) then
        self:notify_tips(selfId, "Chỉ thao tác được ở Lạc Dương")
        return
    end

    local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    if myGuid <= 0 or myGuid ~= lordGuid then
        self:notify_tips(selfId, "Chỉ thành chủ Lạc Dương mới nhận được")
        return
    end

    local info = self:GetRevenueInfo()
    if info.total <= 0 then
        self:notify_tips(selfId, "Hôm nay chưa có thu nhập")
        return
    end

    self:AddMoney(selfId, info.total)
    self:ResetRevenueClaimBaseline(myGuid, info.total)
    self:notify_tips(selfId, string.format("Nhận thành công, được %d bổng lộc", info.total))
end

function chengzhu:ProcIntro(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(string.format("#YĐiều kiện khiêu chiến#W: đạt cấp %d, và giới hạn máu trên %d.", self.g_MinChallengeLevel, self.g_MinChallengeMaxHp))
    self:AddText("#BThuyết minh hệ thống thành chủ Lạc Dương#W")
    self:AddText("#G1. Khiêu chiến thành chủ#W: tốn 50000 nguyên bảo khóa, thành chủ online thì khiêu chiến lôi đài được, thắng thành thành chủ mới.")
    self:AddText("#G2. Bái lạy thành chủ#W: tốn 30000 nguyên bảo khóa, mỗi ngày bái một lần và nhận BUFF bái lạy.")
    self:AddText("#G3. Thu nhập thành chủ#W: gồm hai phần bổng lộc và thu nhập bái lạy.")
    self:AddText("#YBổng lộc#W: mỗi giờ 1000, tính theo giờ chẵn, nhận xong đếm lại.")
    self:AddText("#YThu nhập bái lạy#W: tính 50% thu nhập bái lạy.")
    self:AddText("#G4. BOSS thành chủ#W: thành chủ mỗi ngày thả 1 BOSS ở Hiệu Trường Lạc Dương (91,185), toàn server chỉ 1 lần/ngày; đánh bại rơi 20 quái rương.")
    self:AddText("#G5. Giới thiệu BUFF#W:")
    self:AddText("#RBUFF thành chủ#W: 4 thuộc tính +500, 4 kháng +88, giới hạn máu +50000.")
    self:AddText("#RBUFF bái lạy#W: 4 thuộc tính +200, giới hạn máu +50000.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function chengzhu:ProcGrantCityLordBuff(selfId)
    local myGuid = self:LuaFnObjId2Guid(selfId)
    local lordGuid = self:GetCityLordGuid()
    
    if myGuid <= 0 or myGuid ~= lordGuid then
        self:notify_tips(selfId, "Ngươi không phải thành chủ, không nhận bù BUFF thành chủ được")
        return
    end
    
    -- 清除旧BUFF
    self:CancelCityLordBuffOnObj(selfId, self.g_BuffChallenge)
    -- 添加新BUFF
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_BuffChallenge, 0)
    self:notify_tips(selfId, "Nhận bù BUFF thành chủ thành công")
end

function chengzhu:OnEventRequest(selfId, targetId, arg, index)
    xpcall(function()
		if self.g_SAFE_UI_MODE == 1 then
			return
		end

        local eventIndex = tonumber(index)
        local eventArg = tonumber(arg)
        if not eventIndex and eventArg then
            eventIndex = eventArg
        end
        if eventIndex ~= 0 and eventIndex ~= 1 and eventIndex ~= 2 and eventIndex ~= 3 and eventIndex ~= 4 and eventIndex ~= 5 and eventIndex ~= 6 and eventIndex ~= 7 and eventIndex ~= 8 and eventIndex ~= 9 and eventIndex ~= 10 and eventIndex ~= 11 and eventIndex ~= 12 and eventIndex ~= 13 and eventIndex ~= 20 and eventIndex ~= 21 then
            if eventArg == 0 or eventArg == 1 or eventArg == 2 or eventArg == 3 or eventArg == 4 or eventArg == 5 or eventArg == 6 or eventArg == 7 or eventArg == 8 or eventArg == 9 or eventArg == 10 or eventArg == 11 or eventArg == 12 or eventArg == 13 or eventArg == 20 or eventArg == 21 then
                eventIndex = eventArg
            end
        end

        if eventIndex == 0 then
            self:ProcChallenge(selfId)
        elseif eventIndex == 1 then
            self:ProcWorship(selfId)
        elseif eventIndex == 2 then
            self:ProcClaimRevenue(selfId, targetId)
        elseif eventIndex == 3 then
            self:ProcIntro(selfId, targetId)
        elseif eventIndex == 4 then
            return
        elseif eventIndex == 5 then
			pcall(function()
				local raw = tonumber(selfId) or 0
				if raw > 0 then
					self:LuaFnSendMailToGUID(raw, "Nhận click bắt đầu ứng chiến")
				end
				local objId = self:NormalizeHumanObjId(selfId)
				if objId and objId > 0 then
					local guid = tonumber(self:LuaFnObjId2Guid(objId)) or 0
					if guid > 0 and guid ~= raw then
						self:LuaFnSendMailToGUID(guid, "Nhận click bắt đầu ứng chiến")
					end
				end
			end)
            self:ProcStartBattle(selfId)
        elseif eventIndex == 6 then
            self:ProcRespondTransfer(selfId)
        elseif eventIndex == 7 then
            return
        elseif eventIndex == 8 then
            self:ProcClearPendingChallenge(selfId)
        elseif eventIndex == 9 then
            self:ProcClaimRevenueConfirm(selfId)
        elseif eventIndex == 10 then
            self:OnDefaultEvent(selfId, targetId)
        elseif eventIndex == 11 then
            self:ProcSpawnCityLordBoss(selfId)
        elseif eventIndex == 12 then
            self:ProcClearTestRecords(selfId)
        elseif eventIndex == 13 then
            self:ProcGrantCityLordBuff(selfId)
        elseif eventIndex == 20 then
            self:ProcRespondTransfer(selfId)
        elseif eventIndex == 21 then
            return
        end
    end, function(err)
        skynet.error(string.format("chengzhu:OnEventRequest error: %s", tostring(err)))
    end)
end

return chengzhu
