-- 各擂台对应的 脚本
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local leitai = class("leitai", script_base)

leitai.script_id = 806013

leitai.g_CopyScene = "leitai_2.nav"
leitai.g_client_res = 92
leitai.event_area = "leitai_2_area.ini"
leitai.g_Pos = { x = 31, z = 32, offset = 3.53 }
leitai.g_CopySceneCloseTime = 3000
leitai.g_TickTime = 5000
leitai.g_BeginTick = 3
leitai.g_CloseTick = 3
leitai.g_PvpRuler = 9
local FUBEN_PVP_LEITAI = 993
leitai.g_CopySceneType = FUBEN_PVP_LEITAI

leitai.g_Camp = { self = 10, target = 11 }

leitai.g_BackPos = { sceneId = 0, x = 91, z = 185 }

leitai.g_Buff = 112
leitai.g_BuffID_ClearChgBodyBuff = 84

leitai.g_BuffCityLordStatus = 9672

leitai.g_WID_CityLordGuid = 991000001
leitai.g_WID_ChallengeBattleActive = 991000014
leitai.g_WID_CityLordPortraitId = 991000020
leitai.g_WID_CityLordModelId = 991000021
leitai.g_WID_CityLordFashionDepotIndex = 991000022
leitai.g_WID_CityLordAppearanceValid = 991000023
leitai.g_MDEX_ChallengeFailProtectTs = 9003
leitai.g_ChallengeFailProtectSec = 3600

function leitai:GetWorldValueEx(wid)
    local v = self:LuaFnGetWorldGlobalDataEx(wid)
    v = tonumber(v) or 0
    return v
end

function leitai:SetWorldValueEx(wid, value)
    value = tonumber(value) or 0
    self:LuaFnSetWorldGlobalDataEx(wid, value)
end

function leitai:GetCityLordGuid()
    return self:GetWorldValueEx(self.g_WID_CityLordGuid)
end

function leitai:SetCityLordGuid(guid)
    guid = tonumber(guid) or 0
    self:SetWorldValueEx(self.g_WID_CityLordGuid, guid)
end

function leitai:SetChallengeBattleActive(active)
    self:SetWorldValueEx(self.g_WID_ChallengeBattleActive, active and 1 or 0)
end

function leitai:SetChallengeFailProtectByGuid(guid)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return false
    end
    local protectTs = os.time() + self.g_ChallengeFailProtectSec
    local challengerId = tonumber(self:LuaFnGuid2ObjId(guid)) or 0
    if challengerId <= 0 or (not self:LuaFnIsObjValid(challengerId)) then
        local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
        if ok and user and user.uinfo and user.uinfo.sceneid and user.uinfo.m_objID then
            local scene = string.format(".SCENE_%d", tonumber(user.uinfo.sceneid) or 0)
            pcall(skynet.send, scene, "lua", "char_excute_Script", 000157, "SetChallengeFailProtectOnObj", tonumber(user.uinfo.m_objID) or 0, protectTs)
            return true
        end
        return false
    end
    self:SetMissionDataEx(challengerId, self.g_MDEX_ChallengeFailProtectTs, protectTs)
    return true
end

function leitai:GetPlayerNameByGuid(guid)
    guid = tonumber(guid) or 0
    if guid <= 0 then
        return ""
    end
    local ok, uinfo = pcall(skynet.call, ".world", "lua", "get_player_info", guid)
    if not ok or not uinfo then
        return ""
    end
    return uinfo.name or ""
end

function leitai:GetChallengerGuid()
    return self:LuaFnGetCopySceneData_TeamLeader()
end

function leitai:GetTargetGuid()
    return self:LuaFnGetCopySceneData_Param(3)
end

function leitai:IsSettled()
    return (tonumber(self:LuaFnGetCopySceneData_Param(8)) or 0) == 1
end

function leitai:SetSettled()
    self:LuaFnSetCopySceneData_Param(8, 1)
end

function leitai:GetOneAliveHumanBySide(side)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, membercount do
        local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
            if self:GetMySide(playerId) == side then
                return playerId
            end
        end
    end
    return 0
end

function leitai:GetOneHumanBySide(side)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, membercount do
        local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(playerId) then
            if self:GetMySide(playerId) == side then
                return playerId
            end
        end
    end
    return 0
end

function leitai:CancelBuffOnGuid(guid, buffId)
    guid = tonumber(guid) or 0
    buffId = tonumber(buffId) or 0
    if guid <= 0 or buffId <= 0 then
        return
    end
    local ok, user = pcall(skynet.call, ".world", "lua", "find_user", guid)
    if ok and user and user.uinfo and user.uinfo.sceneid and user.uinfo.m_objID then
        local scene = string.format(".SCENE_%d", tonumber(user.uinfo.sceneid) or 0)
        pcall(skynet.send, scene, "lua", "char_excute_Script", 000157, "CancelCityLordBuffOnObj", tonumber(user.uinfo.m_objID) or 0, buffId)
    end
end

function leitai:DoSettlement(winnerSide)
    if self:IsSettled() then
        return
    end
    self:SetSettled()
    self:SetChallengeBattleActive(false)

    local challengerGuid = self:GetChallengerGuid()
    local targetGuid = self:GetTargetGuid()

    local challengerName = self:GetPlayerNameByGuid(challengerGuid)
    local targetName = self:GetPlayerNameByGuid(targetGuid)

    if challengerName == "" then
        challengerName = "Bên khiêu chiến"
    end
    if targetName == "" then
        targetName = "Bên thủ đài"
    end

    if winnerSide == 1 then
        local oldLordGuid = self:GetCityLordGuid()
        self:SetCityLordGuid(challengerGuid)

        do
            local winnerObjId = self:GetOneAliveHumanBySide(1)
            if winnerObjId and winnerObjId > 0 then
                local human = self:get_scene():get_obj_by_id(winnerObjId)
                if human then
                    local portrait_id = math.floor(tonumber(human.get_portrait_id and human:get_portrait_id() or 0) or 0)
                    local model_id = math.floor(tonumber(human.get_model_id and human:get_model_id() or 0) or 0)
                    local fashion_depot_index = math.floor(tonumber(human.get_fashion_depot_index and human:get_fashion_depot_index() or 0) or 0)

                    if portrait_id < 0 then
                        portrait_id = 0
                    end
                    if model_id <= 0 then
                        model_id = 0
                    end
                    if fashion_depot_index < 0 or fashion_depot_index > 32767 then
                        fashion_depot_index = 0
                    end

                    self:SetWorldValueEx(self.g_WID_CityLordPortraitId, portrait_id)
                    self:SetWorldValueEx(self.g_WID_CityLordModelId, model_id)
                    self:SetWorldValueEx(self.g_WID_CityLordFashionDepotIndex, fashion_depot_index)
                    self:SetWorldValueEx(self.g_WID_CityLordAppearanceValid, 1)
                end
            end
        end

        local msg = string.format("%s khiêu chiến %s thành công, thành thành chủ Lạc Dương mới", challengerName, targetName)
        self:SceneBroadcastMsg(msg)

        do
            local globalSCA = string.format("@*;SrvMsg;SCA:【Khiêu chiến thành chủ】#G%s#Wkhiêu chiến#R%s#Wthành công, thành thành chủ Lạc Dương mới!", challengerName, targetName)
            local globalChat = string.format("【Khiêu chiến thành chủ】#G%s#Wkhiêu chiến#R%s#Wthành công, thành thành chủ Lạc Dương!", challengerName, targetName)
            self:AddGlobalCountNews(globalSCA)
            self:AddGlobalCountNews(globalChat)
        end

        self:LuaFnSendMailToGUID(challengerGuid, "Chúc mừng ngươi thắng khiêu chiến, thành thành chủ Lạc Dương mới")
        self:LuaFnSendMailToGUID(targetGuid, "Ngươi thua khiêu chiến thành chủ Lạc Dương, ngôi thành chủ đổi chủ")

        local challengerObjId = self:GetOneHumanBySide(1)
        local targetObjId = self:GetOneHumanBySide(2)

        if challengerObjId and challengerObjId > 0 then
            self:LuaFnCancelSpecificImpact(challengerObjId, self.g_BuffCityLordStatus)
        end
        if targetObjId and targetObjId > 0 then
            self:LuaFnCancelSpecificImpact(targetObjId, self.g_BuffCityLordStatus)
        end

        self:CancelBuffOnGuid(oldLordGuid, self.g_BuffCityLordStatus)
        self:CancelBuffOnGuid(targetGuid, self.g_BuffCityLordStatus)

        local winnerObjId = self:GetOneAliveHumanBySide(1)
        if winnerObjId and winnerObjId > 0 then
            self:LuaFnSendSpecificImpactToUnit(winnerObjId, winnerObjId, winnerObjId, self.g_BuffCityLordStatus, 0)
            self:LuaFnSendMailToAllFriend(winnerObjId, msg)
        end

        pcall(skynet.send, string.format(".SCENE_%d", 0), "lua", "agent_command_call_script", 000157, "RefreshNpcNameTitle")
        pcall(skynet.send, string.format(".SCENE_%d", 1311), "lua", "agent_command_call_script", 000157, "RefreshNpcNameTitle")
    elseif winnerSide == 2 then
        local msg = string.format("%s khiêu chiến %s thất bại, thành chủ Lạc Dương không đổi", challengerName, targetName)
        self:SceneBroadcastMsg(msg)

        do
            local globalSCA = string.format("@*;SrvMsg;SCA:【Khiêu chiến thành chủ】#G%s#Wkhiêu chiến#R%s#Wthất bại, thành chủ Lạc Dương không đổi.", challengerName, targetName)
            local globalChat = string.format("【Khiêu chiến thành chủ】#G%s#Wkhiêu chiến#R%s#Wthất bại, thành chủ Lạc Dương không đổi.", challengerName, targetName)
            self:AddGlobalCountNews(globalSCA)
            self:AddGlobalCountNews(globalChat)
        end

        self:SetChallengeFailProtectByGuid(challengerGuid)
        self:LuaFnSendMailToGUID(challengerGuid, "Tiếc rằng ngươi thua, trong 1 giờ không khiêu chiến thành chủ lại được")
        self:LuaFnSendMailToGUID(targetGuid, "Ngươi thủ đài thành công, ngôi thành chủ giữ nguyên")
    end
end

function leitai:DoChallenge(selfId, targetId)
    local CreatorGUID = self:LuaFnObjId2Guid(selfId)
    local TargetGUID = self:LuaFnObjId2Guid(targetId)
    local config = {}
    config.navmapname = self.g_CopyScene
    config.client_res = self.g_client_res
    config.teamleader = CreatorGUID
    config.NoUserCloseTime = self.g_CopySceneCloseTime
    config.PvpRule = self.g_PvpRuler
    config.Timer = self.g_TickTime
    config.params = {}
    config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
    config.params[2] = 0
    config.params[3] = TargetGUID
    config.params[4] = 0
    config.params[5] = 0
    config.params[6] = 0
    config.params[7] = 0
    config.params[8] = 0
    config.eventfile = self.event_area
    config.sn = skynet.time()

    local CopySceneID = self:LuaFnCreateCopyScene(config)
    if CopySceneID <= 0 then
        self:SetChallengeBattleActive(false)
        self:notify_tips(selfId, "Lôi đài quá chật chội, không thể chứa thêm người Chiến đấu")
        return false
    end
    self:SetChallengeBattleActive(true)
    return true
end

function leitai:GetSelfTeamId()
    return self:LuaFnGetCopySceneData_Param(6) / 10
end

function leitai:GetTargetTeamId()
    return self:LuaFnGetCopySceneData_Param(7) / 10
end

function leitai:GetSelfMembersCount()
    local selfInfo = self:LuaFnGetCopySceneData_Param(6)
    selfInfo = selfInfo - selfInfo / 10 * 10
    if selfInfo < 0 then
        selfInfo = -selfInfo
    end
    return selfInfo
end

function leitai:ModifySelfMembersCount(count)
    local selfInfo = self:LuaFnGetCopySceneData_Param(6)

    if selfInfo < 0 then
        count = -count
    end
    self:LuaFnSetCopySceneData_Param(6, selfInfo + count)
end

function leitai:GetTargetMembersCount()
    local TargetInfo = self:LuaFnGetCopySceneData_Param(7)
    TargetInfo = TargetInfo - TargetInfo / 10 * 10
    if TargetInfo < 0 then
        TargetInfo = -TargetInfo
    end
    return TargetInfo
end

function leitai:ModifyTargetMembersCount(count)
    local TargetInfo = self:LuaFnGetCopySceneData_Param(7)
    if TargetInfo < 0 then
        count = -count
    end
    self:LuaFnSetCopySceneData_Param(7, TargetInfo + count)
end

function leitai:CalcPosOffset()
    local offset = self.g_Pos.offset * math.random(100) / 100
    if math.random(0, 1) > 0 then
        offset = -offset
    end
    return offset
end

function leitai:OnCopySceneReady(destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    local selfId = self:LuaFnGuid2ObjId(self:LuaFnGetCopySceneData_TeamLeader(destsceneId))
    local targetId = self:LuaFnGuid2ObjId(self:LuaFnGetCopySceneData_Param(destsceneId, 3))
    local members = {}

    -- 只传送挑战者和城主，不传送队友
    table.insert(members, selfId)
    table.insert(members, targetId)

    for _, member in ipairs(members) do
        if self:LuaFnIsCanDoScriptLogic(member) then
            self:LuaFnSendSpecificImpactToUnit(member, member, member, self.g_Buff, 0)
            self:NewWorld(member, destsceneId, sn, self.g_Pos.x + self:CalcPosOffset(), self.g_Pos.z + self:CalcPosOffset(), self.g_client_res)
        end
    end
end

function leitai:GetMySide(selfId)
    local MyGUID = self:LuaFnObjId2Guid(selfId)
    local ChallengerGUID = self:LuaFnGetCopySceneData_TeamLeader()
    local targetGUID = self:LuaFnGetCopySceneData_Param(3)
    local MySide
    if MyGUID == ChallengerGUID then
        MySide = 1
    elseif MyGUID == targetGUID then
        MySide = 2
    else
        local MyTeamId = self:GetTeamId(selfId)
        local selfTeamId = self:GetSelfTeamId()
        if MyTeamId == selfTeamId then
            MySide = 1
        else
            MySide = 2
        end
    end
    return MySide
end

function leitai:OnPlayerEnter(selfId)
    local MySide = self:GetMySide(selfId)
    if MySide == 1 then
        self:SetUnitCampID(selfId, self.g_Camp.self)
    else
        self:SetUnitCampID(selfId, self.g_Camp.target)
    end

    self:SetPlayerDefaultReliveInfo(selfId, 0.1, nil, 0, self.g_BackPos.sceneId, self.g_BackPos.x, self.g_BackPos.z)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_BuffID_ClearChgBodyBuff, 0)
    self:LuaFnAddMissionHuoYueZhi(selfId, 23)

    local human = self:get_scene() and self:get_scene():get_obj_by_id(selfId)
    if human then
        local hpMax = tonumber(human.get_max_hp and human:get_max_hp() or 0) or 0
        local mpMax = tonumber(human.get_max_mp and human:get_max_mp() or 0) or 0
        local rageMax = tonumber(human.get_max_rage and human:get_max_rage() or 0) or 0
        if hpMax > 0 and human.set_hp then
            human:set_hp(hpMax)
        end
        if mpMax > 0 and human.set_mp then
            human:set_mp(mpMax)
        end
        if rageMax > 0 and human.set_rage then
            human:set_rage(rageMax)
        end
        if human.send_refresh_attrib then
            human:send_refresh_attrib()
        end
    end

    self:LuaFnChallengeRefreshSkillCoolDown(selfId)
end

function leitai:LeaveScene(selfId)
    self:SetUnitCampID(selfId, -1)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 83, 0)
    self:CallScriptFunction((400900), "TransferFunc", selfId, self.g_BackPos.sceneId, self.g_BackPos.x, self.g_BackPos.z)
end

function leitai:OnPlayerLeave(selfId)
    self:LuaFnChallengeRestoreSkillCoolDown(selfId)
end

function leitai:OnHumanDie(selfId, killerId)
end

function leitai:OnCopySceneTimer(nowTime)
    local tick = self:LuaFnGetCopySceneData_Param(2)
    tick = tick + 1
    self:LuaFnSetCopySceneData_Param(2, tick)

    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)

        if self.g_CloseTick <= leaveTickCount then
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, membercount do
                local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
                    self:LeaveScene(playerId)
                end
            end
        else
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local strText = string.format("Lôi đài sẽ đóng sau %d giây nữa", (self.g_CloseTick - leaveTickCount) * self.g_TickTime / 1000)
            for i = 1, membercount do
                local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
                    self:notify_tips(playerId, strText)
                end
            end
        end
    elseif tick > self.g_BeginTick then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local selfCount = 0
        local targetCount = 0

        for i = 1, membercount do
            local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
                if self:GetMySide(playerId) == 1 then
                    selfCount = selfCount + 1
                else
                    targetCount = targetCount + 1
                end
            end
        end

        if selfCount < 1 or targetCount < 1 then
            if selfCount >= 1 and targetCount < 1 then
                self:DoSettlement(1)
            elseif targetCount >= 1 and selfCount < 1 then
                self:DoSettlement(2)
            else
                self:SetChallengeBattleActive(false)
            end
            self:LuaFnSetCopySceneData_Param(4, 1)
        else
            return
        end

        local strText = "so tài kết thúc, lôi đài sắp đóng"
        for i = 1, membercount do
            local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
                self:notify_tips(playerId, strText)
            end
        end
    else
        if tick ~= 0 then
            return
        end
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local strText = "Bắt đầu tỷ thí"

        for i = 1, membercount do
            local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
                self:notify_tips(playerId, strText)
            end
        end
    end
end

return leitai
