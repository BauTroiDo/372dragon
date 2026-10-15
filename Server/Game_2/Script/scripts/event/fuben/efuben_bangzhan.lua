local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local efuben_bangzhan = class("efuben_bangzhan", script_base)
efuben_bangzhan.script_id = 402047
efuben_bangzhan.g_Name = "周然"
efuben_bangzhan.g_MissionName = "Đến Chiến Trường Trác Lộc Cổ"
efuben_bangzhan.g_SubmitInfo = "#{BHXZ_081103_115}"
efuben_bangzhan.g_NumText_EnterCopyScene = 1
efuben_bangzhan.g_GetPrizeTitle = 2
efuben_bangzhan.g_GetPrizeTitle_Kill = 3
efuben_bangzhan.g_GetPrizeTitle_Flag = 4
efuben_bangzhan.g_GetPrizeTitle_Source = 5
efuben_bangzhan.g_CopySceneMap = "zhuluKVK.nav"
efuben_bangzhan.g_CopySceneArea = "zhuluKVK_area.ini"
efuben_bangzhan.g_CopySceneMonsterIni = "zhuluKVK_monster.ini"
efuben_bangzhan.g_CopySceneGrowPointData = "zhuluKVK_growpoint.txt"
efuben_bangzhan.g_CopySceneGrowSetUp = "zhuluKVK_growpointsetup.txt"
efuben_bangzhan.g_CopySceneType = ScriptGlobal.FUBEN_BANGZHAN
efuben_bangzhan.g_MaxMembers = 25
efuben_bangzhan.g_TickTime = 1
efuben_bangzhan.g_StartPoint = 60 * 5 + 5
efuben_bangzhan.g_LimitTotalHoldTime = 60 * 40 + efuben_bangzhan.g_StartPoint
efuben_bangzhan.g_CloseTick = 30 + 1
efuben_bangzhan.g_NoUserTime = 10
efuben_bangzhan.g_PvpRuler = 3
efuben_bangzhan.g_BackTick = 10
efuben_bangzhan.g_TankMaxEnemyNum = 15
efuben_bangzhan.g_TankMaxFriendNum = 20
efuben_bangzhan.g_Fuben_A_X = 47
efuben_bangzhan.g_Fuben_A_Z = 39
efuben_bangzhan.g_Fuben_B_X = 203
efuben_bangzhan.g_Fuben_B_Z = 215
efuben_bangzhan.g_ALive_A_X = 51
efuben_bangzhan.g_ALive_A_Z = 26
efuben_bangzhan.g_ALive_B_X = 205
efuben_bangzhan.g_ALive_B_Z = 227
efuben_bangzhan.g_Back_X = 262
efuben_bangzhan.g_Back_Z = 51
efuben_bangzhan.g_Exit_SceneID = 409
efuben_bangzhan.g_Win_X = 32
efuben_bangzhan.g_Win_Z = 16
efuben_bangzhan.g_Fail_X = 32
efuben_bangzhan.g_Fail_Z = 41
efuben_bangzhan.g_Win_PerHonour = 100
efuben_bangzhan.g_Fail_TotalHonour = 2000
efuben_bangzhan.g_Fail_PerMaxHonour = 100
efuben_bangzhan.g_client_res = 270
efuben_bangzhan.g_PrizeMsg = {"#{BHXZ_081103_120}", "#{BHXZ_081103_121}", "#{BHXZ_081103_122}"}

efuben_bangzhan.g_FailMsg = "#{BHXZ_081103_123}"
efuben_bangzhan.g_PrizeFlag = {ScriptGlobal.MF_BangZhan_Kill_Flag, ScriptGlobal.MF_BangZhan_Flag_Flag, ScriptGlobal.MF_BangZhan_Source_Flag}

efuben_bangzhan.g_PrizeBuff = {31549, 31548, 31547}

efuben_bangzhan.g_PrizeTitle = {
    {["AwardPos"] = 15, ["SetPos"] = 39, ["Index"] = 320},
    {["AwardPos"] = 16, ["SetPos"] = 40, ["Index"] = 321},
    {["AwardPos"] = 17, ["SetPos"] = 41, ["Index"] = 322}
}

efuben_bangzhan.g_GuildPoint_KillOtherPlayer = 0
efuben_bangzhan.g_GuildPoint_KillTower = 2
efuben_bangzhan.g_GuildPoint_KillTankPlayer = 3
efuben_bangzhan.g_GuildPoint_KillPlatform = 5
efuben_bangzhan.g_IsSetOverFlag = 9
efuben_bangzhan.g_OpenFlagSelfIDIndex = 10
efuben_bangzhan.g_OpenFlagStartTime = 11
efuben_bangzhan.g_FlagRemainedTime = 12
efuben_bangzhan.g_A_FirstTankManSelfID = 13
efuben_bangzhan.g_A_SecondTankManSelfID = 14
efuben_bangzhan.g_B_FirstTankManSelfID = 15
efuben_bangzhan.g_B_SecondTankManSelfID = 16
efuben_bangzhan.g_A_FirstTankBuff = 17
efuben_bangzhan.g_A_SecondTankBuff = 18
efuben_bangzhan.g_B_FirstTankBuff = 19
efuben_bangzhan.g_B_SecondTankBuff = 20
efuben_bangzhan.g_A_FirstTankPos = 21
efuben_bangzhan.g_A_SecondTankPos = 22
efuben_bangzhan.g_B_FirstTankPos = 23
efuben_bangzhan.g_B_SecondTankPos = 24
efuben_bangzhan.g_A_TankColdTime = 25
efuben_bangzhan.g_B_TankColdTime = 26
efuben_bangzhan.g_A_BroadcastTick = 27
efuben_bangzhan.g_B_BroadcastTick = 28
efuben_bangzhan.g_A_numIndex = 0
efuben_bangzhan.g_B_numIndex = 1
efuben_bangzhan.g_A_KillManNumIndex = 12
efuben_bangzhan.g_B_KillManNumIndex = 13
efuben_bangzhan.g_A_KillBuildingNumIndex = 14
efuben_bangzhan.g_B_KillBuildingNumIndex = 15
efuben_bangzhan.g_A_TotalPointIndex = 18
efuben_bangzhan.g_B_TotalPointIndex = 19
efuben_bangzhan.g_Human_TotalPointIndex = 0
efuben_bangzhan.g_Human_KillManIndex = 1
efuben_bangzhan.g_Human_KillBuildingIndex = 2
efuben_bangzhan.g_Human_FlagIndex = 3
efuben_bangzhan.g_Human_ResourceNumIndex = 4
efuben_bangzhan.g_TankBuff = {31577, 31578, 31579, 31580, 31581, 31582, 31583, 31584, 31585, 31586}

efuben_bangzhan.g_AttrBuff = {31567, 31568, 31569, 31570, 31571, 31572, 31573, 31574, 31575, 31576}

efuben_bangzhan.g_PanGuTankAttackBuff = 31551
efuben_bangzhan.g_LightBuff = {79, 80, 81, 82}

efuben_bangzhan.g_TankFriendBuff = {
    {31553, 31554},
    {31556, 31557},
    {31559, 31560},
    {31562, 31563}
}

efuben_bangzhan.g_TankEnemyBuff = {31552, 31555, 31558, 31561}

efuben_bangzhan.g_ImmuneControlBuff = 10474
efuben_bangzhan.g_SheepBuff = 31550
efuben_bangzhan.g_TankID = {13334, 13335, 13336, 13337, 13338, 13339, 13340, 13341, 13342, 13343}

efuben_bangzhan.g_PhysicsAttack_Buff = {
    {["value"] = 16000, ["buff"] = 31587},
    {["value"] = 18000, ["buff"] = 31588},
    {["value"] = 20000, ["buff"] = 31589},
    {["value"] = 22500, ["buff"] = 31590},
    {["value"] = 26000, ["buff"] = 31591},
    {["value"] = 30000, ["buff"] = 31592},
    {["value"] = 300000, ["buff"] = 31593}
}

efuben_bangzhan.g_MagicAttack_Buff = {
    {["value"] = 16000, ["buff"] = 31594},
    {["value"] = 18000, ["buff"] = 31595},
    {["value"] = 20000, ["buff"] = 31596},
    {["value"] = 22500, ["buff"] = 31597},
    {["value"] = 26000, ["buff"] = 31598},
    {["value"] = 30000, ["buff"] = 31599},
    {["value"] = 300000, ["buff"] = 31600}
}

efuben_bangzhan.g_ColdFire_Buff = {
    {["value"] = 100, ["buff"] = 31601},
    {["value"] = 230, ["buff"] = 31602},
    {["value"] = 420, ["buff"] = 31603},
    {["value"] = 840, ["buff"] = 31604},
    {["value"] = 1680, ["buff"] = 31605},
    {["value"] = 2380, ["buff"] = 31606},
    {["value"] = 200000, ["buff"] = 31607}
}

efuben_bangzhan.g_LightPoison_Buff = {
    {["value"] = 100, ["buff"] = 31608},
    {["value"] = 230, ["buff"] = 31609},
    {["value"] = 420, ["buff"] = 31610},
    {["value"] = 840, ["buff"] = 31611},
    {["value"] = 1680, ["buff"] = 31612},
    {["value"] = 2380, ["buff"] = 31613},
    {["value"] = 200000, ["buff"] = 31614}
}

efuben_bangzhan.g_LingShiID = {30900051, 30900052, 30900053, 30900054, 30900055}

efuben_bangzhan.g_TankName = {"Thanh Long Chiến Xa", "Bạch Hổ Chiến Xa", "Chu Tước Chiến Xa", "Huyền Ô Chiến Xa", "Bàn Cổ Chiến Xa", "Thanh Long Chiến Xa", "Bạch Hổ Chiến Xa", "Chu Tước Chiến Xa", "Huyền Ô Chiến Xa", "Bàn Cổ Chiến Xa"}

efuben_bangzhan.g_ColdTime = 60
efuben_bangzhan.g_A_Platform = "炎黄台"
efuben_bangzhan.g_A_FenXiang_Tower = "炎黄焚香塔"
efuben_bangzhan.g_A_LuoXing_Tower = "炎黄落星塔"
efuben_bangzhan.g_A_Flag = "炎黄战旗"
efuben_bangzhan.g_B_Platform = "蚩尤台"
efuben_bangzhan.g_B_FenXiang_Tower = "蚩尤焚香塔"
efuben_bangzhan.g_B_LuoXing_Tower = "蚩尤落星塔"
efuben_bangzhan.g_B_Flag = "蚩尤战旗"
function efuben_bangzhan:OnDefaultEvent(selfId, targetId, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    local numText = index
    if numText == self.g_NumText_EnterCopyScene then
        self:AcceptEnterCopyScene(selfId, targetId)
    elseif numText == self.g_GetPrizeTitle then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_116}")
        self:AddNumText("Liên Trảm Cuồng Khách", 4, self.g_GetPrizeTitle_Kill)
        self:AddNumText("Siêu Cấp Kỳ Thủ", 4, self.g_GetPrizeTitle_Flag)
        self:AddNumText("Sưu Bảo Chuyên Gia", 4, self.g_GetPrizeTitle_Source)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif numText == self.g_GetPrizeTitle_Kill then
        local bHave = self:GetMissionFlag(selfId, self.g_PrizeFlag[1])
        if bHave == 1 then
            self:SetMissionFlag(selfId, self.g_PrizeFlag[1], 0)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_PrizeBuff[1], 0)
            self:LuaFnAwardTitle(selfId, self.g_PrizeTitle[1]["AwardPos"], self.g_PrizeTitle[1]["Index"], 7 * 24)
            self:SetCurTitle(selfId, self.g_PrizeTitle[1]["SetPos"], self.g_PrizeTitle[1]["Index"])
            self:LuaFnAddNewAgname(selfId, self.g_PrizeTitle[1]["SetPos"], self.g_PrizeTitle[1]["Index"])
            self:LuaFnDispatchAllTitle(selfId)
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_145}" .. "\"Liêm Trảm Cuồng Khách\"" .. "#{BHXZ_081103_146}")
            if self:GetHumanGuildID(selfId) ~= -1 then
                local message = string.format("@*;SrvMsg;GLD:#{_INFOUSR%s}#{BHXZ_090116_01}", self:LuaFnGetName(selfId))
                message = gbk.fromutf8(message)
                self:BroadMsgByChatPipe(selfId, message, 6)
            end
            local guid = self:LuaFnObjId2Guid(selfId)
            local log = string.format("type=%d", 1)
            self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_TITLE_BUFF, guid, log)
        else
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_117}")
        end
    elseif numText == self.g_GetPrizeTitle_Flag then
        local bHave = self:GetMissionFlag(selfId, self.g_PrizeFlag[2])
        if bHave == 1 then
            self:SetMissionFlag(selfId, self.g_PrizeFlag[2], 0)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_PrizeBuff[2], 0)
            self:LuaFnAwardTitle(selfId, self.g_PrizeTitle[2]["AwardPos"], self.g_PrizeTitle[2]["Index"], 7 * 24)
            self:SetCurTitle(selfId, self.g_PrizeTitle[2]["SetPos"], self.g_PrizeTitle[2]["Index"])
            self:LuaFnAddNewAgname(selfId, self.g_PrizeTitle[2]["SetPos"], self.g_PrizeTitle[2]["Index"])
            self:LuaFnDispatchAllTitle(selfId)
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_145}" .. "\"Siêu Cấp Kỳ Thủ\"" .. "#{BHXZ_081103_146}")
            if self:GetHumanGuildID(selfId) ~= -1 then
                local message = string.format("@*;SrvMsg;GLD:#{_INFOUSR%s}#{BHXZ_090116_02}", self:LuaFnGetName(selfId))
                message = gbk.fromutf8(message)
                self:BroadMsgByChatPipe(selfId, message, 6)
            end
            local guid = self:LuaFnObjId2Guid(selfId)
            local log = string.format("type=%d", 2)
            self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_TITLE_BUFF, guid, log)
        else
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_117}")
        end
    elseif numText == self.g_GetPrizeTitle_Source then
        local bHave = self:GetMissionFlag(selfId, self.g_PrizeFlag[3])
        if bHave == 1 then
            self:SetMissionFlag(selfId, self.g_PrizeFlag[3], 0)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_PrizeBuff[3], 0)
            self:LuaFnAwardTitle(selfId, self.g_PrizeTitle[3]["AwardPos"], self.g_PrizeTitle[3]["Index"], 7 * 24)
            self:SetCurTitle(selfId, self.g_PrizeTitle[3]["SetPos"], self.g_PrizeTitle[3]["Index"])
            self:LuaFnAddNewAgname(selfId, self.g_PrizeTitle[3]["SetPos"], self.g_PrizeTitle[3]["Index"])
            self:LuaFnDispatchAllTitle(selfId)
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_145}" .. "\"Cao Thủ Săn Bảo\"" .. "#{BHXZ_081103_146}")
            if self:GetHumanGuildID(selfId) ~= -1 then
                local message = string.format("@*;SrvMsg;GLD:#{_INFOUSR%s}#{BHXZ_090116_03}", self:LuaFnGetName(selfId))
                message = gbk.fromutf8(message)
                self:BroadMsgByChatPipe(selfId, message, 6)
            end
            local guid = self:LuaFnObjId2Guid(selfId)
            local log = string.format("type=%d", 3)
            self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_TITLE_BUFF, guid, log)
        else
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_117}")
        end
    end
end

function efuben_bangzhan:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, self.g_NumText_EnterCopyScene)
    caller:AddNumTextWithTarget(self.script_id, "Lĩnh danh hiệu", 4, self.g_GetPrizeTitle)
end

function efuben_bangzhan:AcceptEnterCopyScene(selfId, targetId)
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_SheepBuff) then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_105}")
        return
    end
    for i = 1, #(self.g_PrizeFlag) do
        if self:GetMissionFlag(selfId, self.g_PrizeFlag[i]) == 1 then
            self:NotifyFailTips(selfId, "#{BHXZ_081103_106}")
            return
        end
    end
    local guildid = self:GetHumanGuildID(selfId)
    if guildid == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_19}")
        return
    end
    local guildIDApply, guildIDApplied, CopySceneId = self:GetGuildWarApply(guildid)
    if not guildIDApply or not guildIDApplied or not CopySceneId or guildIDApply == -1 or guildIDApplied == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_18}")
        return
    end
    if CopySceneId >= 0 then
        if guildid == guildIDApply then
            local GuildInt = self:GetGuildIntNum(guildid, self.g_A_numIndex)
            if GuildInt >= self.g_MaxMembers or GuildInt == -1 then
                self:NotifyFailTips(selfId, "#{BHXZ_081103_107}")
                return
            end
            self:BeginEvent(self.script_id)
            self:AddText(self.g_SubmitInfo)
            self:EndEvent()
            self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, 0)
        else
            local GuildInt = self:GetGuildIntNum(guildid, self.g_B_numIndex)
            if GuildInt >= self.g_MaxMembers or GuildInt == -1 then
                self:NotifyFailTips(selfId, "#{BHXZ_081103_107}")
                return
            end
            self:BeginEvent(self.script_id)
            self:AddText(self.g_SubmitInfo)
            self:EndEvent()
            self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, 0)
        end
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText(self.g_SubmitInfo)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, 0)
end

function efuben_bangzhan:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_SheepBuff) then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_105}")
        return
    end
    for i = 1, #(self.g_PrizeFlag) do
        if self:GetMissionFlag(selfId, self.g_PrizeFlag[i]) == 1 then
            self:NotifyFailTips(selfId, "#{BHXZ_081103_106}")
            return
        end
    end
    local guildid = self:GetHumanGuildID(selfId)
    if guildid == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_19}")
        return
    end
    local guildIDApply, guildIDApplied, CopySceneId = self:GetGuildWarApply(guildid)
    if not guildIDApply or not guildIDApplied or not CopySceneId or guildIDApply == -1 or guildIDApplied == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_18}")
        return
    end
    if CopySceneId >= 0 then
        local sn = self:LuaFnGetCopySceneData_Sn(CopySceneId)
        if guildid == guildIDApply then
            local GuildInt = self:GetGuildIntNum(guildid, self.g_A_numIndex)
            if GuildInt >= self.g_MaxMembers or GuildInt == -1 then
                self:NotifyFailTips(selfId, "#{BHXZ_081103_107}")
                return
            end
            self:NewWorld(selfId, CopySceneId, sn, self.g_Fuben_A_X, self.g_Fuben_A_Z, self.g_client_res)
        else
            local GuildInt = self:GetGuildIntNum(guildid, self.g_B_numIndex)
            if GuildInt >= self.g_MaxMembers or GuildInt == -1 then
                self:NotifyFailTips(selfId, "#{BHXZ_081103_107}")
                return
            end
            self:NewWorld(selfId, CopySceneId, sn, self.g_Fuben_B_X, self.g_Fuben_B_Z, self.g_client_res)
        end
        return
    end
    local firstmenguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = self.g_CopySceneMap
    config.teamleader = firstmenguid
    config.NoUserCloseTime = 0
	config.Timer = self.g_TickTime * 1000
	config.params = {}
	config.params[0] = self.g_CopySceneType						-- 设置副本类型
	config.params[1] = self.script_id
    config.params[2] = 0
    config.params[3] = -1
    config.params[4] = 0
    config.params[5] = 0
    config.params[6] = guildIDApply * 10000 + guildIDApplied
    config.params[7] = 0
    config.params[8] = 0
    config.params[self.g_IsSetOverFlag] = 0
    config.params[self.g_OpenFlagSelfIDIndex] = 0
    config.params[self.g_OpenFlagStartTime] = 0
    config.params[self.g_FlagRemainedTime] = 0
    config.params[self.g_A_FirstTankManSelfID] = 0
    config.params[self.g_A_SecondTankManSelfID] = 0
    config.params[self.g_B_FirstTankManSelfID] = 0
    config.params[self.g_B_SecondTankManSelfID] = 0
    config.params[self.g_A_FirstTankBuff] = 0
    config.params[self.g_A_SecondTankBuff] = 0
    config.params[self.g_B_FirstTankBuff] = 0
    config.params[self.g_B_SecondTankBuff] = 0
    config.params[self.g_A_FirstTankPos] = 0
    config.params[self.g_A_SecondTankPos] = 0
    config.params[self.g_B_FirstTankPos] = 0
    config.params[self.g_B_SecondTankPos] = 0
    config.params[self.g_A_TankColdTime] = 0
    config.params[self.g_B_TankColdTime] = 0
    config.params[self.g_A_BroadcastTick] = 0
    config.params[self.g_B_BroadcastTick] = 0
    config.eventfile = self.g_CopySceneArea
    config.monsterfile = self.g_CopySceneMonsterIni
    config.growpointdata = self.g_CopySceneGrowPointData
    config.growpointsetup = self.g_CopySceneGrowSetUp
    config.PvpRule = self.g_PvpRuler
    config.client_res = self.g_client_res
    config.sn 		 = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    if bRetSceneID > 0 then
        self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
        self:SetGuildWarApplySceneID(guildid, bRetSceneID)
        self:NotifyGuildBattle(selfId, 0, guildIDApply, guildIDApplied)
        local log =
            string.format("HumanGuildID=%d,Apply_GuildID=%d,Applied_GuildID=%d", guildid, guildIDApply, guildIDApplied)
        self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_CREATEFUBEN, firstmenguid, log)
    else
        self:NotifyFailTips(selfId, "#{BHXZ_081103_17}")
    end
end

function efuben_bangzhan:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local firstmanguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local firstmanObjId = self:LuaFnGuid2ObjId(firstmanguid)
    if firstmanObjId == -1 then
        return
    end
    if not self:LuaFnIsCanDoScriptLogic(firstmanObjId) then
        return
    end
    local totalguildid = self:LuaFnGetCopySceneData_Param(destsceneId, 6)
    local Aguildid = math.floor(totalguildid / 10000)
    local guildid = self:GetHumanGuildID(firstmanObjId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    if guildid == Aguildid then
        self:NewWorld(firstmanObjId, destsceneId, sn, self.g_Fuben_A_X, self.g_Fuben_A_Z)
    else
        self:NewWorld(firstmanObjId, destsceneId, sn, self.g_Fuben_B_X, self.g_Fuben_B_Z)
    end
end

function efuben_bangzhan:OnPlayerEnter(selfId)
    local buf = self:HaveTankBuff(selfId)
    if buf ~= 0 then
        self:LuaFnCancelSpecificImpact(selfId, buf)
    end
    local guildid = self:GetHumanGuildID(selfId)
    if self:IsGuildFull(guildid) == 1 then
        self:NotifyFailTips(selfId, "#{BHXZ_081103_107}")
        self:SetCanChangeScene(selfId, 1)
        self:Exit(selfId)
        return
    end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 and self:LuaFnGetCopySceneData_Param(5) >= self.g_CloseTick then
        self:NotifyFailTips(selfId, "Lần chinh thảo bang hội này đã kết thúc.")
        self:SetCanChangeScene(selfId, 1)
        self:Exit(selfId)
        return
    end
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    if guildid == Aguildid then
        if self:LuaFnGetCopySceneData_Param(7) == 1 then
            self:SetUnitCampID(selfId, 10 + Aguildid)
        end
        self:SetPlayerDefaultReliveInfoEx(selfId, 0.1, 0, 0, self.g_ALive_A_X, self.g_ALive_A_Z, self.script_id)
    elseif guildid == Bguildid then
        if self:LuaFnGetCopySceneData_Param(7) == 1 then
            self:SetUnitCampID(selfId, 11 + Aguildid)
        end
        self:SetPlayerDefaultReliveInfoEx(selfId, 0.1, 0, 0, self.g_ALive_B_X, self.g_ALive_B_Z, self.script_id)
    else
        self:NotifyFailTips(selfId, "Ngươi không ở trong bang phái chính xác, không thể tiến vào!")
        self:SetCanChangeScene(selfId, 1)
        self:Exit(selfId)
        return
    end
    if self:GetCurTitle(selfId) ~= 23 then
        self:NotifyFailTips(selfId, "#{BHXZ_081205_1}")
        self:Msg2Player(selfId, "#{BHXZ_081205_1}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    self:SetCurTitle(selfId, 23, 0)
    self:LuaFnAddNewAgname(selfId, 23, 0)
end

function efuben_bangzhan:OnDie(objId, selfId)
    local objType = self:GetCharacterType(selfId)
    if objType == "pet" then
        selfId = self:GetPetCreator(selfId)
    end
    if selfId == -1 then
        return
    end
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then
        return
    end
    local isStartPoint = self:LuaFnGetCopySceneData_Param(7)
    if isStartPoint == 0 then
        return
    end
    local num = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}
    for i = 1, num do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    local szName = self:GetName(objId)
    if szName == self.g_A_FenXiang_Tower or szName == self.g_A_LuoXing_Tower then
        if self:IsCommonBGuild(selfId) == 0 then
            return
        end
        local humanguildid = self:GetHumanGuildID(selfId)
        local point = self:GetGuildWarPoint(self.g_GuildPoint_KillTower)
        self:AddBGuildPoint(selfId, humanguildid, point)
        local alreadynum = self:GetGuildIntNum(humanguildid, self.g_B_KillBuildingNumIndex)
        self:SetGuildIntNum(humanguildid, self.g_B_KillBuildingNumIndex, alreadynum + 1)
        self:AddHumanGuildArrayInt(selfId, self.g_Human_KillBuildingIndex, 1)
    elseif szName == self.g_B_FenXiang_Tower or szName == self.g_B_LuoXing_Tower then
        if self:IsCommonAGuild(selfId) == 0 then
            return
        end
        local humanguildid = self:GetHumanGuildID(selfId)
        local point = self:GetGuildWarPoint(self.g_GuildPoint_KillTower)
        self:AddAGuildPoint(selfId, humanguildid, point)
        local alreadynum = self:GetGuildIntNum(humanguildid, self.g_A_KillBuildingNumIndex)
        self:SetGuildIntNum(humanguildid, self.g_A_KillBuildingNumIndex, alreadynum + 1)
        self:AddHumanGuildArrayInt(selfId, self.g_Human_KillBuildingIndex, 1)
    elseif szName == self.g_A_Platform then
        if self:IsCommonBGuild(selfId) == 0 then
            return
        end
        local humanguildid = self:GetHumanGuildID(selfId)
        local point = self:GetGuildWarPoint(self.g_GuildPoint_KillPlatform)
        self:AddBGuildPoint(selfId, humanguildid, point)
        local alreadynum = self:GetGuildIntNum(humanguildid, self.g_B_KillBuildingNumIndex)
        self:SetGuildIntNum(humanguildid, self.g_B_KillBuildingNumIndex, alreadynum + 1)
        self:AddHumanGuildArrayInt(selfId, self.g_Human_KillBuildingIndex, 1)
    elseif szName == self.g_B_Platform then
        if self:IsCommonAGuild(selfId) == 0 then
            return
        end
        local humanguildid = self:GetHumanGuildID(selfId)
        local point = self:GetGuildWarPoint(self.g_GuildPoint_KillPlatform)
        self:AddAGuildPoint(selfId, humanguildid, point)
        local alreadynum = self:GetGuildIntNum(humanguildid, self.g_A_KillBuildingNumIndex)
        self:SetGuildIntNum(humanguildid, self.g_A_KillBuildingNumIndex, alreadynum + 1)
        self:AddHumanGuildArrayInt(selfId, self.g_Human_KillBuildingIndex, 1)
    end
    local msg =
        self:LuaFnGetGuildName(selfId) ..
        "#{BHXZ_081103_125}" .. self:GetName(selfId) .. "#{BHXZ_081103_126}" .. szName .. "。"
    for i = 1, num do
        if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
            self:NotifyFailTips(mems[i], msg)
            self:Msg2Player(mems[i], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
    end
end

function efuben_bangzhan:OnRelive(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 78, 100)
end

function efuben_bangzhan:OnHumanDie(selfId, killerId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then
        return
    end
    local isStartPoint = self:LuaFnGetCopySceneData_Param(7)
    if isStartPoint == 0 then
        return
    end
    local num = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    for i = 1, num  do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    local humanguildid = self:GetHumanGuildID(selfId)
    if humanguildid == Aguildid then
        local objType = self:GetCharacterType(killerId)
        local otherselfId
        if objType == "human" then
            otherselfId = killerId
        elseif objType == "pet" then
            otherselfId = self:GetPetCreator(killerId)
            if otherselfId == -1 then
                otherselfId = 0
            end
        else
            otherselfId = 0
        end
        local alreadykillnum = self:GetGuildIntNum(humanguildid, self.g_B_KillManNumIndex)
        self:SetGuildIntNum(humanguildid, self.g_B_KillManNumIndex, alreadykillnum + 1)
        local Tankbuf = self:HaveTankBuff(selfId)
        if otherselfId > 0 then
            self:AddHumanGuildArrayInt(otherselfId, self.g_Human_KillManIndex, 1)
            if Tankbuf == 0 then
                self:Msg2Player(otherselfId, "#{BHXZ_081103_127}" .. self:GetName(selfId) .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
        if Tankbuf and Tankbuf ~= 0 then
            if selfId == self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankManSelfID) then
                self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankManSelfID, 0)
                self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankBuff, 0)
                self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankPos, 0)
            elseif selfId == self:LuaFnGetCopySceneData_Param(self.g_A_SecondTankManSelfID) then
                self:LuaFnSetCopySceneData_Param(self.g_A_SecondTankManSelfID, 0)
                self:LuaFnSetCopySceneData_Param(self.g_A_SecondTankBuff, 0)
                self:LuaFnSetCopySceneData_Param(self.g_A_SecondTankPos, 0)
            end
            self:LuaFnSetCopySceneData_Param(self.g_A_TankColdTime, self.g_ColdTime)
            local tankpoint = self:GetGuildWarPoint(self.g_GuildPoint_KillTankPlayer)
            self:AddBGuildPoint(otherselfId, Bguildid, tankpoint)
            local msg = ""
            if otherselfId > 0 then
                msg =
                    self:LuaFnGetGuildName(otherselfId) ..
                    "#{BHXZ_081103_125}" ..
                        self:GetName(otherselfId) ..
                            "#{BHXZ_081103_126}" .. self.g_TankName[Tankbuf - self.g_AttrBuff[1] + 1] .. "。"
            else
                msg =
                    self:LuaFnGetGuildName(selfId) ..
                    "#{BHXZ_081103_125}" .. self.g_TankName[Tankbuf - self.g_AttrBuff[1] + 1] .. "Đã bị đối phương phá hủy rồi."
            end
            for i = 1, num  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:NotifyFailTips(mems[i], msg)
                    self:Msg2Player(mems[i], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                end
            end
        else
            local point = self:GetGuildWarPoint(self.g_GuildPoint_KillOtherPlayer)
            self:AddBGuildPoint(otherselfId, Bguildid, point)
        end
    elseif humanguildid == Bguildid then
        local objType = self:GetCharacterType(killerId)
        local otherselfId = 0
        if objType == "human" then
            otherselfId = killerId
        elseif objType == "pet" then
            otherselfId = self:GetPetCreator(killerId)
            if otherselfId == -1 then
                otherselfId = 0
            end
        else
            otherselfId = 0
        end
        local alreadykillnum = self:GetGuildIntNum(humanguildid, self.g_A_KillManNumIndex)
        self:SetGuildIntNum(humanguildid, self.g_A_KillManNumIndex, alreadykillnum + 1)
        local Tankbuf = self:HaveTankBuff(selfId)
        if otherselfId > 0 then
            self:AddHumanGuildArrayInt(otherselfId, self.g_Human_KillManIndex, 1)
            if Tankbuf == 0 then
                self:Msg2Player(otherselfId, "#{BHXZ_081103_127}" .. self:GetName(selfId) .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
        if Tankbuf and Tankbuf ~= 0 then
            if selfId == self:LuaFnGetCopySceneData_Param(self.g_B_FirstTankManSelfID) then
                self:LuaFnSetCopySceneData_Param(self.g_B_FirstTankManSelfID, 0)
                self:LuaFnSetCopySceneData_Param(self.g_B_FirstTankBuff, 0)
                self:LuaFnSetCopySceneData_Param(self.g_B_FirstTankPos, 0)
            elseif selfId == self:LuaFnGetCopySceneData_Param(self.g_B_SecondTankManSelfID) then
                self:LuaFnSetCopySceneData_Param(self.g_B_SecondTankManSelfID, 0)
                self:LuaFnSetCopySceneData_Param(self.g_B_SecondTankBuff, 0)
                self:LuaFnSetCopySceneData_Param(self.g_B_SecondTankPos, 0)
            end
            self:LuaFnSetCopySceneData_Param(self.g_B_TankColdTime, self.g_ColdTime)
            local tankpoint = self:GetGuildWarPoint(self.g_GuildPoint_KillTankPlayer)
            self:AddAGuildPoint(otherselfId, Aguildid, tankpoint)
            local msg = ""
            if otherselfId > 0 then
                msg =
                    self:LuaFnGetGuildName(otherselfId) ..
                    "#{BHXZ_081103_125}" ..
                        self:GetName(otherselfId) ..
                            "#{BHXZ_081103_126}" .. self.g_TankName[Tankbuf - self.g_AttrBuff[1] + 1] .. "。"
            else
                msg =
                    self:LuaFnGetGuildName(selfId) ..
                    "#{BHXZ_081103_125}" .. self.g_TankName[Tankbuf - self.g_AttrBuff[1] + 1] .. "Đã bị đối phương phá hủy rồi."
            end
            for i = 1, num  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:NotifyFailTips(mems[i], msg)
                    self:Msg2Player(mems[i], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                end
            end
        else
            local point = self:GetGuildWarPoint(self.g_GuildPoint_KillOtherPlayer)
            self:AddAGuildPoint(otherselfId, Aguildid, point)
        end
    end
end

function efuben_bangzhan:NotifyPoint(humanguildid, point)
    local num = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}
    for i = 1, num  do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    for i = 1, num  do
        if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and self:GetHumanGuildID(mems[i]) == humanguildid then
            self:NotifyFailTips(mems[i], "#{BHXZ_081103_66}" .. point)
        end
    end
end

function efuben_bangzhan:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function efuben_bangzhan:ClearLingShi(selfId)
    for i = 1, #(self.g_LingShiID) do
        local num = self:LuaFnGetAvailableItemCount(selfId, self.g_LingShiID[i])
        if num > 0 then
            self:LuaFnDelAvailableItem(selfId, self.g_LingShiID[i], num)
        end
    end
end

function efuben_bangzhan:OnCopySceneTimer(nowTime)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}
    for i = 1, membercount  do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    local FlagRemainTime = self:LuaFnGetCopySceneData_Param(self.g_FlagRemainedTime)
    if FlagRemainTime > 0 then
        FlagRemainTime = FlagRemainTime - 1
        self:LuaFnSetCopySceneData_Param(self.g_FlagRemainedTime, FlagRemainTime)
        if FlagRemainTime <= 0 then
            local nMonsterNum = self:GetMonsterCount()
            for i = 1, nMonsterNum do
                local nMonsterId = self:GetMonsterObjID(i)
                local MonsterName = self:GetName(nMonsterId)
                if MonsterName == self.g_A_Flag or MonsterName == self.g_B_Flag then
                    self:LuaFnDeleteMonster(nMonsterId)
                    local msg = MonsterName .. "#{BHXZ_081103_128}"
                    for j = 1, membercount do
                        if self:LuaFnIsObjValid(mems[j])  and self:LuaFnIsCanDoScriptLogic(mems[j]) then
                            self:NotifyFailTips(mems[j], msg)
                            self:Msg2Player(mems[j], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                        end
                    end
                end
            end
        end
    end
    local AColdTime = self:LuaFnGetCopySceneData_Param(self.g_A_TankColdTime)
    if AColdTime > 0 then
        AColdTime = AColdTime - 1
        self:LuaFnSetCopySceneData_Param(self.g_A_TankColdTime, AColdTime)
    end
    local BColdTime = self:LuaFnGetCopySceneData_Param(self.g_B_TankColdTime)
    if BColdTime > 0 then
        BColdTime = BColdTime - 1
        self:LuaFnSetCopySceneData_Param(self.g_B_TankColdTime, BColdTime)
    end
    if TickCount == 1 then
        local nNpcNum = self:GetMonsterCount()
        for i = 1, nNpcNum do
            local nNpcId = self:GetMonsterObjID(i)
            local name = self:GetName(nNpcId)
            if name == self.g_A_Platform or name == self.g_A_FenXiang_Tower or name == self.g_A_LuoXing_Tower or
                    name == self.g_B_Platform or
                    name == self.g_B_FenXiang_Tower or
                    name == self.g_B_LuoXing_Tower
             then
                self:LuaFnSendSpecificImpactToUnit(nNpcId, nNpcId, nNpcId, self.g_ImmuneControlBuff, 0)
            end
        end
    end
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    if 1 then
        local nNpcNum = self:GetMonsterCount()
        for i = 1, nNpcNum do
            local nNpcId = self:GetMonsterObjID(i)
            local name = self:GetName(nNpcId)
            local broadcast = 0
            local setindex = 0
            local guild = 0
            local iscontinue = 1
            if name == self.g_A_Platform then
                broadcast = self:LuaFnGetCopySceneData_Param(self.g_A_BroadcastTick)
                setindex = self.g_A_BroadcastTick
                guild = Aguildid
            elseif name == self.g_B_Platform then
                broadcast = self:LuaFnGetCopySceneData_Param(self.g_B_BroadcastTick)
                setindex = self.g_B_BroadcastTick
                guild = Bguildid
            else
                iscontinue = 0
            end
            if iscontinue == 1 then
                local nMaxHp = self:GetMaxHp(nNpcId)
                local nHp = self:GetHp(nNpcId)
                local downpercent = ""
                if nHp <= nMaxHp * 0.9 and broadcast == 0 then
                    downpercent = "90％"
                    self:LuaFnSetCopySceneData_Param(setindex, 1)
                elseif nHp <= nMaxHp * 0.5 and broadcast == 1 then
                    downpercent = "50％"
                    self:LuaFnSetCopySceneData_Param(setindex, 2)
                elseif nHp <= nMaxHp * 0.1 and broadcast == 2 then
                    downpercent = "10％"
                    self:LuaFnSetCopySceneData_Param(setindex, 3)
                end
                if downpercent ~= "" then
                    local msg =
                        "#{BHXZ_081103_148}" .. name .. "#{BHXZ_081103_149}" .. downpercent .. "#{BHXZ_081103_150}"
                    for j = 1, membercount do
                        if
                            self:LuaFnIsObjValid(mems[j]) and self:LuaFnIsCanDoScriptLogic(mems[j]) and
                                self:GetHumanGuildID(mems[j]) == guild
                         then
                            self:NotifyFailTips(mems[j], msg)
                            self:Msg2Player(mems[j], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                        end
                    end
                end
            end
        end
    end
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount >= self.g_CloseTick then
            local IsSetOverFlag = self:LuaFnGetCopySceneData_Param(self.g_IsSetOverFlag)
            if IsSetOverFlag == 0 then
                self:LuaFnSetCopySceneData_Param(self.g_IsSetOverFlag, 1)
                local Apoint = self:GetGuildIntNum(Aguildid, self.g_A_TotalPointIndex)
                local Bpoint = self:GetGuildIntNum(Bguildid, self.g_B_TotalPointIndex)
                local AGuildcount = 0
                local BGuildcount = 0
                local KillMax = 0
                local FlagMax = 0
                local SourceMax = 0
                local PrizeSelfId = {0, 0, 0}
                for i = 1, membercount  do
                    if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                        self:NotifyBattleScore(mems[i])
                        local guildid = self:GetHumanGuildID(mems[i])
                        local KillNum = self:GetHumanGuildInt(mems[i], self.g_Human_KillManIndex)
                        local FlagNum = self:GetHumanGuildInt(mems[i], self.g_Human_FlagIndex)
                        local SourceNum = self:GetHumanGuildInt(mems[i], self.g_Human_ResourceNumIndex)
                        if KillNum > KillMax then
                            KillMax = KillNum
                            PrizeSelfId[1] = mems[i]
                        end
                        if FlagNum > FlagMax then
                            FlagMax = FlagNum
                            PrizeSelfId[2] = mems[i]
                        end
                        if SourceNum > SourceMax then
                            SourceMax = SourceNum
                            PrizeSelfId[3] = mems[i]
                        end
                        if guildid == Aguildid then
                            AGuildcount = AGuildcount + 1
                        elseif guildid == Bguildid then
                            BGuildcount = BGuildcount + 1
                        end
                    end
                end
                local AFailHonour = 0
                if AGuildcount ~= 0 then
                    AFailHonour = math.floor(self.g_Fail_TotalHonour / AGuildcount)
                end
                local BFailHonour = 0
                if BGuildcount ~= 0 then
                    BFailHonour = math.floor(self.g_Fail_TotalHonour / BGuildcount)
                end
                if AFailHonour > self.g_Fail_PerMaxHonour then
                    AFailHonour = self.g_Fail_PerMaxHonour
                end
                if BFailHonour > self.g_Fail_PerMaxHonour then
                    BFailHonour = self.g_Fail_PerMaxHonour
                end
                local isAWin = 0
                if Apoint > Bpoint then
                    isAWin = 1
                    local log =
                        string.format(
                        "WinGuildID=%d,WinTotalHonour=%d,FailGuildID=%d,FailTotalHonour=%d",
                        Aguildid,
                        self.g_Win_PerHonour * AGuildcount,
                        Bguildid,
                        BFailHonour * BGuildcount
                    )
                    self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_HONOUR, -1, log)
                else
                    isAWin = 0
                    local log =
                        string.format(
                        "WinGuildID=%d,WinTotalHonour=%d,FailGuildID=%d,FailTotalHonour=%d",
                        Bguildid,
                        self.g_Win_PerHonour * BGuildcount,
                        Aguildid,
                        AFailHonour * AGuildcount
                    )
                    self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_HONOUR, -1, log)
                end
                for i = 1, #(PrizeSelfId) do
                    if PrizeSelfId[i] ~= 0 then
                        self:SetMissionFlag(PrizeSelfId[i], self.g_PrizeFlag[i], 1)
                        self:LuaFnSendSystemMail(self:GetName(PrizeSelfId[i]), self.g_PrizeMsg[i])
                    end
                end
                for i = 1, membercount  do
                    if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                        local Tankbuf = self:HaveTankBuff(mems[i])
                        if Tankbuf and Tankbuf ~= 0 then
                            self:LuaFnCancelSpecificImpact(mems[i], Tankbuf)
                        end
                        self:ClearLingShi(mems[i])
                        for j = self.g_Human_TotalPointIndex, self.g_Human_ResourceNumIndex do
                            self:SetHumanGuildInt(mems[i], j, 0)
                        end
                        local guildid = self:GetHumanGuildID(mems[i])
                        if guildid == Aguildid then
                            if isAWin == 1 then
                                self:AddHonour(mems[i], self.g_Win_PerHonour)
                                self:NewWorld(mems[i], self.g_Exit_SceneID, nil, self.g_Win_X, self.g_Win_Z)
                            else
                                self:AddHonour(mems[i], AFailHonour)
                                self:SetCurTitle(mems[i], 23, 0)
                                self:LuaFnSendSystemMail(self:GetName(mems[i]), self.g_FailMsg)
                                self:LuaFnSendSpecificImpactToUnit(mems[i], mems[i], mems[i], self.g_SheepBuff, 0)
                                self:NewWorld(mems[i], self.g_Exit_SceneID, nil, self.g_Fail_X, self.g_Fail_Z)
                            end
                        elseif guildid == Bguildid then
                            if isAWin == 0 then
                                self:AddHonour(mems[i], self.g_Win_PerHonour)
                                self:NewWorld(mems[i], self.g_Exit_SceneID, nil, self.g_Win_X, self.g_Win_Z)
                            else
                                self:AddHonour(mems[i], BFailHonour)
                                self:SetCurTitle(mems[i], 23, 0)
                                self:LuaFnSendSystemMail(self:GetName(mems[i]), self.g_FailMsg)
                                self:LuaFnSendSpecificImpactToUnit(mems[i], mems[i], mems[i], self.g_SheepBuff, 0)
                                self:NewWorld(mems[i], self.g_Exit_SceneID, nil, self.g_Fail_X, self.g_Fail_Z)
                            end
                        else
                            self:Exit(mems[i])
                        end
                    end
                end
            else
                for i = 1, membercount  do
                    if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                        local Tankbuf = self:HaveTankBuff(mems[i])
                        if Tankbuf and Tankbuf ~= 0 then
                            self:LuaFnCancelSpecificImpact(mems[i], Tankbuf)
                        end
                        self:ClearLingShi(mems[i])
                        for j = self.g_Human_TotalPointIndex, self.g_Human_ResourceNumIndex do
                            self:SetHumanGuildInt(mems[i], j, 0)
                        end
                        self:Exit(mems[i])
                    end
                end
            end
            return
        else
            local strText = string.format("Ngươi sẽ rời khỏi Phó bản sau %d giây.", (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
            for i = 1, membercount  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:NotifyFailTips(mems[i], strText)
                end
            end
        end
    end
    if TickCount == (self.g_LimitTotalHoldTime - self.g_CloseTick) then
        self:LuaFnSetCopySceneData_Param(4, 1)
    elseif TickCount == self.g_StartPoint then
        self:LuaFnSetCopySceneData_Param(7, 1)
        for i = 1, membercount  do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "#{BHXZ_081103_108}")
                self:Msg2Player(mems[i], "#{BHXZ_081103_108}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                local guildid = self:GetHumanGuildID(mems[i])
                if guildid == Aguildid then
                    self:SetUnitCampID(mems[i], 10 + Aguildid)
                elseif guildid == Bguildid then
                    self:SetUnitCampID(mems[i], 11 + Aguildid)
                else
                    self:NotifyFailTips(mems[i], "#{BHXZ_081103_147}")
                    self:ClearLingShi(mems[i])
                    self:Exit(mems[i])
                end
            end
        end
        local nNpcNum = self:GetMonsterCount()
        for i = 1, nNpcNum do
            local nNpcId = self:GetMonsterObjID(i)
            local name = self:GetName(nNpcId)
            if name == self.g_A_Platform or name == self.g_A_FenXiang_Tower or name == self.g_A_LuoXing_Tower then
                self:SetUnitCampID(nNpcId, Aguildid + 10)
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            elseif name == self.g_B_Platform or name == self.g_B_FenXiang_Tower or name == self.g_B_LuoXing_Tower then
                self:SetUnitCampID(nNpcId, Aguildid + 11)
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            end
        end
    else
        if TickCount < self.g_StartPoint then
            local RemainTick = self.g_StartPoint - TickCount
            if RemainTick % 60 == 0 then
                for i = 1, membercount  do
                    if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                        self:NotifyFailTips(
                            mems[i],
                            "#{BHXZ_081103_129}" .. math.floor(RemainTick / 60) .. "#{BHXZ_081103_130}"
                        )
                    end
                end
            end
            if RemainTick <= self.g_BackTick then
                for i = 1, membercount  do
                    if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                        self:NotifyFailTips(mems[i], "#{BHXZ_081103_129}" .. RemainTick .. "#{BHXZ_081103_131}")
                    end
                end
            end
        end
        local modtick = TickCount % 5
        if TickCount >= self.g_StartPoint and modtick == 0 then
            local nNpcNum = self:GetMonsterCount()
            local PosX = 0
            local PosZ = 0
            for i = 1, nNpcNum do
                local nNpcId = self:GetMonsterObjID(i)
                local name = self:GetName(nNpcId)
                if name == self.g_A_LuoXing_Tower or name == self.g_B_LuoXing_Tower then
                    if self:GetHp(nNpcId) > 0 then
                        PosX = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1067, nNpcId, PosX, PosZ, 15, 0)
                    end
                elseif name == self.g_A_FenXiang_Tower or name == self.g_B_FenXiang_Tower then
                    if self:GetHp(nNpcId) > 0 then
                        PosX = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1068, nNpcId, PosX, PosZ, 15, 0)
                    end
                end
            end
        end
        if TickCount >= self.g_StartPoint and modtick == 1 then
            local nNpcNum = self:GetMonsterCount()
            local PosX = 0
            local PosZ = 0
            for i = 1, nNpcNum do
                local nNpcId = self:GetMonsterObjID(i)
                local name = self:GetName(nNpcId)
                if name == self.g_A_FenXiang_Tower or name == self.g_B_FenXiang_Tower then
                    if self:GetHp(nNpcId) > 0 then
                        PosX = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1069, nNpcId, PosX, PosZ, 15, 0)
                    end
                end
            end
        end
        local TankInfo = {
            {},
            {},
            {},
            {}
        }

        local modtick10 = (TickCount % 10)
        local modtick12 = (TickCount % 12)
        for i = 0, 3 do
            local tankman = self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankManSelfID + i)
            local PosX = 0
            local PosZ = 0
            TankInfo[i + 1]["selfId"] = tankman
            TankInfo[i + 1]["type"] = 0
            TankInfo[i + 1]["impactfriendnum"] = 0
            TankInfo[i + 1]["impactenemynum"] = 0
            TankInfo[i + 1]["x"] = 0
            TankInfo[i + 1]["z"] = 0
            if tankman ~= 0 then
                if self:LuaFnIsObjValid(tankman) and self:LuaFnIsCanDoScriptLogic(tankman) then
                    local buff = self:HaveTankBuff(tankman)
                    if buff == 0 then
                        TankInfo[i + 1]["type"] = 0
                    else
                        TankInfo[i + 1]["type"] = buff - self.g_AttrBuff[1] + 1
                        if TankInfo[i + 1]["type"] > 5 then
                            TankInfo[i + 1]["type"] = TankInfo[i + 1]["type"] - 5
                        end
                    end
                    if buff == 0 then
                        local oldbuff = self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankBuff + i)
                        local totalpos = self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankPos + i)
                        PosX = math.floor(totalpos / 10000)
                        PosZ = totalpos % 10000
                        if oldbuff > 0 then
                            local selfIdindex = 0
                            if i == 0 or i == 1 then
                                selfIdindex =
                                    self:CallScriptFunction(
                                    600051,
                                    "FindTankManIndex",
                                    Aguildid,
                                    oldbuff - self.g_AttrBuff[1] + 1
                                )
                            else
                                selfIdindex =
                                    self:CallScriptFunction(
                                    600051,
                                    "FindTankManIndex",
                                    Bguildid,
                                    oldbuff - self.g_AttrBuff[1] + 1
                                )
                            end
                            if selfIdindex > 0 and PosX > 0 and PosZ > 0 then
                                local monsterID =
                                    self:LuaFnCreateMonster(
                                    self.g_TankID[oldbuff - self.g_AttrBuff[1] + 1],
                                    PosX,
                                    PosZ,
                                    3,
                                    -1,
                                    402302
                                )
                                self:LuaFnSendSpecificImpactToUnit(
                                    monsterID,
                                    monsterID,
                                    monsterID,
                                    self.g_ImmuneControlBuff,
                                    0
                                )
                            end
                        end
                        self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankManSelfID + i, 0)
                        self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankBuff + i, 0)
                        self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankPos + i, 0)
                    else
                        PosX = self:GetWorldPos(tankman)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_FirstTankPos + i,
                            math.floor(PosX) * 10000 + math.floor(PosZ)
                        )
                        TankInfo[i + 1]["x"] = PosX
                        TankInfo[i + 1]["z"] = PosZ
                        if i == 0 or i == 1 then
                            if modtick12 == 7 and TankInfo[i + 1]["type"] == 1 then
                                self:LuaFnSendSpecificImpactToUnit(
                                    tankman,
                                    tankman,
                                    tankman,
                                    self.g_LightBuff[TankInfo[i + 1]["type"]],
                                    0
                                )
                            elseif modtick10 == 8 and 2 <= TankInfo[i + 1]["type"] and TankInfo[i + 1]["type"] <= 4 then
                                self:LuaFnSendSpecificImpactToUnit(
                                    tankman,
                                    tankman,
                                    tankman,
                                    self.g_LightBuff[TankInfo[i + 1]["type"]],
                                    0
                                )
                            end
                        else
                            if modtick12 == 1 and TankInfo[i + 1]["type"] == 1 then
                                self:LuaFnSendSpecificImpactToUnit(
                                    tankman,
                                    tankman,
                                    tankman,
                                    self.g_LightBuff[TankInfo[i + 1]["type"]],
                                    0
                                )
                            elseif modtick10 == 3 and 2 <= TankInfo[i + 1]["type"] and TankInfo[i + 1]["type"] <= 4 then
                                self:LuaFnSendSpecificImpactToUnit(
                                    tankman,
                                    tankman,
                                    tankman,
                                    self.g_LightBuff[TankInfo[i + 1]["type"]],
                                    0
                                )
                            end
                        end
                    end
                else
                    local oldbuff = self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankBuff + i)
                    local totalpos = self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankPos + i)
                    PosX = math.floor(totalpos / 10000)
                    PosZ = totalpos % 10000
                    if oldbuff > 0 then
                        local selfIdindex = 0
                        if i == 0 or i == 1 then
                            selfIdindex =
                                self:CallScriptFunction(
                                600051,
                                "FindTankManIndex",
                                Aguildid,
                                oldbuff - self.g_AttrBuff[1] + 1
                            )
                        else
                            selfIdindex =
                                self:CallScriptFunction(
                                600051,
                                "FindTankManIndex",
                                Bguildid,
                                oldbuff - self.g_AttrBuff[1] + 1
                            )
                        end
                        if selfIdindex > 0 and PosX > 0 and PosZ > 0 then
                            local monsterID =
                                self:LuaFnCreateMonster(
                                self.g_TankID[oldbuff - self.g_AttrBuff[1] + 1],
                                PosX,
                                PosZ,
                                3,
                                -1,
                                402302
                            )
                            self:LuaFnSendSpecificImpactToUnit(
                                monsterID,
                                monsterID,
                                monsterID,
                                self.g_ImmuneControlBuff,
                                0
                            )
                        end
                    end
                    self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankManSelfID + i, 0)
                    self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankBuff + i, 0)
                    self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankPos + i, 0)
                end
            end
        end
        local Acount = 0
        local Bcount = 0
        local AGuildName = ""
        local BGuildName = ""
        for i = 1, membercount  do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                local guildid = self:GetHumanGuildID(mems[i])
                local Tankbuf = self:HaveTankBuff(mems[i])
                local isalive = self:LuaFnIsCharacterLiving(mems[i])
                local xx, zz = self:GetWorldPos(mems[i])
                if guildid == Aguildid then
                    Acount = Acount + 1
                    if AGuildName == "" then
                        AGuildName = self:LuaFnGetGuildName(mems[i])
                    end
                    if modtick10 == 3 and Tankbuf == 0 and isalive then
                        for j = 1, 2 do
                            if
                                TankInfo[j]["impactfriendnum"] < self.g_TankMaxFriendNum and
                                    (TankInfo[j]["type"] == 2 or TankInfo[j]["type"] == 3 or TankInfo[j]["type"] == 4) and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][1],
                                    0
                                )
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][2],
                                    0
                                )
                                TankInfo[j]["impactfriendnum"] = TankInfo[j]["impactfriendnum"] + 1
                            end
                        end
                        for j = 3, 4 do
                            if
                                (TankInfo[j]["type"] == 2 or TankInfo[j]["type"] == 3 or TankInfo[j]["type"] == 4) and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                if TankInfo[j]["impactenemynum"] < self.g_TankMaxEnemyNum then
                                    self:LuaFnSendSpecificImpactToUnit(
                                        TankInfo[j]["selfId"],
                                        TankInfo[j]["selfId"],
                                        mems[i],
                                        self.g_TankEnemyBuff[TankInfo[j]["type"]],
                                        0
                                    )
                                    TankInfo[j]["impactenemynum"] = TankInfo[j]["impactenemynum"] + 1
                                end
                                local Addbuff = self:AttackBuffByHuman(TankInfo[j]["selfId"], TankInfo[j]["type"])
                                self:LuaFnSendSpecificImpactBySkillToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    Addbuff,
                                    0
                                )
                            end
                        end
                    end
                    if modtick12 == 1 and Tankbuf == 0 and isalive == 1 then
                        for j = 1, 2 do
                            if
                                TankInfo[j]["impactfriendnum"] < self.g_TankMaxFriendNum and TankInfo[j]["type"] == 1 and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][1],
                                    0
                                )
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][2],
                                    0
                                )
                                TankInfo[j]["impactfriendnum"] = TankInfo[j]["impactfriendnum"] + 1
                            end
                        end
                        for j = 3, 4 do
                            if
                                TankInfo[j]["type"] == 1 and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                if TankInfo[j]["impactenemynum"] < self.g_TankMaxEnemyNum then
                                    self:LuaFnSendSpecificImpactToUnit(
                                        TankInfo[j]["selfId"],
                                        TankInfo[j]["selfId"],
                                        mems[i],
                                        self.g_TankEnemyBuff[TankInfo[j]["type"]],
                                        0
                                    )
                                    TankInfo[j]["impactenemynum"] = TankInfo[j]["impactenemynum"] + 1
                                end
                                local Addbuff = self:AttackBuffByHuman(TankInfo[j]["selfId"], TankInfo[j]["type"])
                                self:LuaFnSendSpecificImpactBySkillToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    Addbuff,
                                    0
                                )
                            end
                        end
                    end
                elseif guildid == Bguildid then
                    Bcount = Bcount + 1
                    if BGuildName == "" then
                        BGuildName = self:LuaFnGetGuildName(mems[i])
                    end
                    if modtick10 == 8 and Tankbuf == 0 and isalive == 1 then
                        for j = 1, 2 do
                            if
                                (TankInfo[j]["type"] == 2 or TankInfo[j]["type"] == 3 or TankInfo[j]["type"] == 4) and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                if TankInfo[j]["impactenemynum"] < self.g_TankMaxEnemyNum then
                                    self:LuaFnSendSpecificImpactToUnit(
                                        TankInfo[j]["selfId"],
                                        TankInfo[j]["selfId"],
                                        mems[i],
                                        self.g_TankEnemyBuff[TankInfo[j]["type"]],
                                        0
                                    )
                                    TankInfo[j]["impactenemynum"] = TankInfo[j]["impactenemynum"] + 1
                                end
                                local Addbuff = self:AttackBuffByHuman(TankInfo[j]["selfId"], TankInfo[j]["type"])
                                self:LuaFnSendSpecificImpactBySkillToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    Addbuff,
                                    0
                                )
                            end
                        end
                        for j = 3, 4 do
                            if
                                TankInfo[j]["impactfriendnum"] < self.g_TankMaxFriendNum and
                                    (TankInfo[j]["type"] == 2 or TankInfo[j]["type"] == 3 or TankInfo[j]["type"] == 4) and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][1],
                                    0
                                )
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][2],
                                    0
                                )
                                TankInfo[j]["impactfriendnum"] = TankInfo[j]["impactfriendnum"] + 1
                            end
                        end
                    end
                    if modtick12 == 7 and Tankbuf == 0 and isalive == 1 then
                        for j = 1, 2 do
                            if
                                TankInfo[j]["type"] == 1 and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                if TankInfo[j]["impactenemynum"] < self.g_TankMaxEnemyNum then
                                    self:LuaFnSendSpecificImpactToUnit(
                                        TankInfo[j]["selfId"],
                                        TankInfo[j]["selfId"],
                                        mems[i],
                                        self.g_TankEnemyBuff[TankInfo[j]["type"]],
                                        0
                                    )
                                    TankInfo[j]["impactenemynum"] = TankInfo[j]["impactenemynum"] + 1
                                end
                                local Addbuff = self:AttackBuffByHuman(TankInfo[j]["selfId"], TankInfo[j]["type"])
                                self:LuaFnSendSpecificImpactBySkillToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    Addbuff,
                                    0
                                )
                            end
                        end
                        for j = 3, 4 do
                            if
                                TankInfo[j]["impactfriendnum"] < self.g_TankMaxFriendNum and TankInfo[j]["type"] == 1 and
                                    (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                        (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                        15 * 15
                             then
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][1],
                                    0
                                )
                                self:LuaFnSendSpecificImpactToUnit(
                                    TankInfo[j]["selfId"],
                                    TankInfo[j]["selfId"],
                                    mems[i],
                                    self.g_TankFriendBuff[TankInfo[j]["type"]][2],
                                    0
                                )
                                TankInfo[j]["impactfriendnum"] = TankInfo[j]["impactfriendnum"] + 1
                            end
                        end
                    end
                else
                    if Tankbuf and Tankbuf ~= 0 then
                        self:LuaFnCancelSpecificImpact(mems[i], Tankbuf)
                    end
                    self:NotifyFailTips(mems[i], "#{BHXZ_081103_147}")
                    self:ClearLingShi(mems[i])
                    self:Exit(mems[i])
                end
            end
        end
        self:SetGuildIntNum(Aguildid, self.g_A_numIndex, Acount)
        self:SetGuildIntNum(Bguildid, self.g_B_numIndex, Bcount)
        if
            TickCount == (self.g_StartPoint + 10 * 60) or TickCount == (self.g_StartPoint + 20 * 60) or
                TickCount == (self.g_StartPoint + 30 * 60)
         then
            local Apoint = self:GetGuildIntNum(Aguildid, self.g_A_TotalPointIndex)
            local Bpoint = self:GetGuildIntNum(Bguildid, self.g_B_TotalPointIndex)
            if AGuildName == "" then
                AGuildName = Aguildid .. "số"
            end
            if BGuildName == "" then
                BGuildName = Bguildid .. "số"
            end
            local leadmsg = ""
            if Apoint > Bpoint then
                leadmsg = AGuildName .. "#{BHXZ_081103_132}"
            else
                leadmsg = BGuildName .. "#{BHXZ_081103_132}"
            end
            local msg =
                "#{BHXZ_081103_133}" ..
                math.floor((TickCount - self.g_StartPoint) / 60) ..
                    "#{BHXZ_081103_134}" ..
                        AGuildName ..
                            "#{BHXZ_081103_135}" ..
                                Acount ..
                                    "#{BHXZ_081103_136}" ..
                                        Apoint ..
                                            "！" ..
                                                BGuildName ..
                                                    "#{BHXZ_081103_135}" ..
                                                        Bcount .. "#{BHXZ_081103_136}" .. Bpoint .. "！" .. leadmsg
            for i = 1, membercount  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:NotifyFailTips(mems[i], msg)
                    self:Msg2Player(mems[i], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                end
            end
        end
        for j = 1, 4 do
            if TankInfo[j]["type"] == 5 and modtick10 == 4 then
                local nNpcNum = self:GetMonsterCount()
                local attckindex = 0
                if j == 1 or j == 2 then
                    attckindex = 3
                else
                    attckindex = 1
                end
                for i = 1, nNpcNum do
                    local nNpcId = self:GetMonsterObjID(i)
                    local name = self:GetName(nNpcId)
                    local xx, zz = self:GetWorldPos(nNpcId)
                    if
                        (((j == 3 or j == 4) and
                            (name == self.g_A_LuoXing_Tower or name == self.g_A_FenXiang_Tower or
                                name == self.g_A_Platform)) or
                            ((j == 1 or j == 2) and
                                (name == self.g_B_LuoXing_Tower or name == self.g_B_FenXiang_Tower or
                                    name == self.g_B_Platform))) and
                            self:GetHp(nNpcId) > 0 and
                            (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                15 * 15
                     then
                        self:LuaFnSendSpecificImpactToUnit(
                            TankInfo[j]["selfId"],
                            TankInfo[j]["selfId"],
                            nNpcId,
                            self.g_PanGuTankAttackBuff,
                            0
                        )
                    end
                end
                for i = attckindex, attckindex + 1 do
                    local xx, zz = self:GetWorldPos(TankInfo[i]["selfId"])
                    if
                        TankInfo[i]["type"] ~= 0 and self:GetHp(TankInfo[i]["selfId"]) > 0 and
                            (TankInfo[j]["x"] - xx) * (TankInfo[j]["x"] - xx) +
                                (TankInfo[j]["z"] - zz) * (TankInfo[j]["z"] - zz) <
                                15 * 15
                     then
                        self:LuaFnSendSpecificImpactToUnit(
                            TankInfo[j]["selfId"],
                            TankInfo[j]["selfId"],
                            TankInfo[i]["selfId"],
                            self.g_PanGuTankAttackBuff,
                            0
                        )
                    end
                end
            end
        end
    end
end

function efuben_bangzhan:OnImpactFadeOut(selfId, impactId)
    local tanktype = impactId - self.g_AttrBuff[1] + 1
    self:LuaFnCancelSpecificImpact(selfId, self.g_TankBuff[tanktype])
    self:LuaFnCancelSpecificImpact(selfId, self.g_ImmuneControlBuff)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= ScriptGlobal.FUBEN_BANGZHAN then
        return
    end
    if self:LuaFnGetCopySceneData_Param(7) == 0 then
        return
    end
    local isAguild = 0
    if selfId == self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankManSelfID) then
        isAguild = 1
        self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankManSelfID, 0)
        self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankBuff, 0)
        self:LuaFnSetCopySceneData_Param(self.g_A_FirstTankPos, 0)
    elseif selfId == self:LuaFnGetCopySceneData_Param(self.g_A_SecondTankManSelfID) then
        isAguild = 1
        self:LuaFnSetCopySceneData_Param(self.g_A_SecondTankManSelfID, 0)
        self:LuaFnSetCopySceneData_Param(self.g_A_SecondTankBuff, 0)
        self:LuaFnSetCopySceneData_Param(self.g_A_SecondTankPos, 0)
    elseif selfId == self:LuaFnGetCopySceneData_Param(self.g_B_FirstTankManSelfID) then
        isAguild = 0
        self:LuaFnSetCopySceneData_Param(self.g_B_FirstTankManSelfID, 0)
        self:LuaFnSetCopySceneData_Param(self.g_B_FirstTankBuff, 0)
        self:LuaFnSetCopySceneData_Param(self.g_B_FirstTankPos, 0)
    elseif selfId == self:LuaFnGetCopySceneData_Param(self.g_B_SecondTankManSelfID) then
        isAguild = 0
        self:LuaFnSetCopySceneData_Param(self.g_B_SecondTankManSelfID, 0)
        self:LuaFnSetCopySceneData_Param(self.g_B_SecondTankBuff, 0)
        self:LuaFnSetCopySceneData_Param(self.g_B_SecondTankPos, 0)
    else
        return
    end
    self:Msg2Player(selfId, "#{BHXZ_081103_137}" .. self.g_TankName[tanktype] .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    if self:GetHp(selfId) >= math.floor(self:GetMaxHp(selfId) * 0.2) then
        local selfIdindex = self:CallScriptFunction(600051, "FindTankManIndex", isAguild, tanktype)
        if selfIdindex > 0 then
            local PosX, PosZ = self:GetWorldPos(selfId)
            local monsterID = self:LuaFnCreateMonster(self.g_TankID[tanktype], PosX, PosZ, 3, -1, 402302)
            self:LuaFnSendSpecificImpactToUnit(monsterID, monsterID, monsterID, self.g_ImmuneControlBuff, 0)
        end
    else
        local num = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, num  do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
        end
        local msg = self:GetName(selfId) .. "#{BHXZ_090112_38}"
        for i = 1, num  do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], msg)
            end
        end
        self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;GLD:#{BHXZ_090112_39}", 6)
        if isAguild == 1 then
            self:LuaFnSetCopySceneData_Param(self.g_A_TankColdTime, self.g_ColdTime)
            local tankpoint = self:GetGuildWarPoint(self.g_GuildPoint_KillTankPlayer)
            self:AddBGuildPoint(0, Bguildid, tankpoint)
            local alreadykillnum = self:GetGuildIntNum(Bguildid, self.g_B_KillManNumIndex)
            self:SetGuildIntNum(Bguildid, self.g_B_KillManNumIndex, alreadykillnum + 1)
        else
            self:LuaFnSetCopySceneData_Param(self.g_B_TankColdTime, self.g_ColdTime)
            local tankpoint = self:GetGuildWarPoint(self.g_GuildPoint_KillTankPlayer)
            self:AddAGuildPoint(0, Aguildid, tankpoint)
            local alreadykillnum = self:GetGuildIntNum(Aguildid, self.g_A_KillManNumIndex)
            self:SetGuildIntNum(Aguildid, self.g_A_KillManNumIndex, alreadykillnum + 1)
        end
    end
end

function efuben_bangzhan:HaveTankBuff(selfId)
    for i = 1, #(self.g_AttrBuff) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_AttrBuff[i]) then
            return self.g_AttrBuff[i]
        end
    end
    return 0
end

function efuben_bangzhan:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function efuben_bangzhan:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function efuben_bangzhan:IsGuildFull(guildid)
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    for i = 1, membercount  do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    local Acount = 0
    local Bcount = 0
    for i = 1, membercount  do
        if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
            local guildid = self:GetHumanGuildID(mems[i])
            if guildid == Aguildid then
                Acount = Acount + 1
            end
        end
    end
    Bcount = membercount - Acount
    if guildid == Aguildid then
        if Acount > self.g_MaxMembers then
            return 1
        else
            return 0
        end
    elseif guildid == Bguildid then
        if Bcount > self.g_MaxMembers then
            return 1
        else
            return 0
        end
    else
        return 0
    end
end

function efuben_bangzhan:IsCommonAGuild(selfId)
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    local humanguildid = self:GetHumanGuildID(selfId)
    if Aguildid == humanguildid then
        return 1
    end
    return 0
end

function efuben_bangzhan:IsCommonBGuild(selfId)
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    local humanguildid = self:GetHumanGuildID(selfId)
    if Bguildid == humanguildid then
        return 1
    end
    return 0
end

function efuben_bangzhan:AddAGuildPoint(selfId, guildid, addpoint)
    local point = self:GetGuildIntNum(guildid, self.g_A_TotalPointIndex)
    point = point + addpoint
    self:NotifyPoint(guildid, point)
    self:SetGuildIntNum(guildid, self.g_A_TotalPointIndex, point)
    if selfId > 0 then
        self:AddHumanGuildArrayInt(selfId, self.g_Human_TotalPointIndex, addpoint)
    end
end

function efuben_bangzhan:AddBGuildPoint(selfId, guildid, addpoint)
    local point = self:GetGuildIntNum(guildid, self.g_B_TotalPointIndex)
    point = point + addpoint
    self:NotifyPoint(guildid, point)
    self:SetGuildIntNum(guildid, self.g_B_TotalPointIndex, point)
    if selfId > 0 then
        self:AddHumanGuildArrayInt(selfId, self.g_Human_TotalPointIndex, addpoint)
    end
end

function efuben_bangzhan:AddHumanGuildArrayInt(selfId, ArrayIntIndex, addvalue)
    local value = self:GetHumanGuildInt(selfId, ArrayIntIndex)
    value = value + addvalue
    self:SetHumanGuildInt(selfId, ArrayIntIndex, value)
end

function efuben_bangzhan:AddHonour(selfId, addHonour)
    if addHonour > 0 then
        local Honour = self:GetHonour(selfId)
        Honour = Honour + addHonour
        self:SetHonour(selfId, Honour)
    end
end

function efuben_bangzhan:ClearMonsterByName(szName)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == szName then
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
end

function efuben_bangzhan:AttackBuffByHuman(selfId, TankType)
    if TankType == 1 then
        local PhysicsAttack = self:GetHumanAttr(selfId, 1)
        local nMax = #(self.g_PhysicsAttack_Buff)
        for i = 1, nMax do
            if PhysicsAttack <= self.g_PhysicsAttack_Buff[i]["value"] then
                return self.g_PhysicsAttack_Buff[i]["buff"]
            end
        end
        if PhysicsAttack >= self.g_PhysicsAttack_Buff[nMax]["value"] then
            return self.g_PhysicsAttack_Buff[nMax]["buff"]
        end
    elseif TankType == 2 then
        local MagicAttack = self:GetHumanAttr(selfId, 2)
        local nMax = #(self.g_MagicAttack_Buff)
        for i = 1, nMax do
            if MagicAttack <= self.g_MagicAttack_Buff[i]["value"] then
                return self.g_MagicAttack_Buff[i]["buff"]
            end
        end
        if MagicAttack >= self.g_MagicAttack_Buff[nMax]["value"] then
            return self.g_MagicAttack_Buff[nMax]["buff"]
        end
    elseif TankType == 3 then
        local cold = self:GetHumanAttr(selfId, 3)
        local fire = self:GetHumanAttr(selfId, 4)
        local nMax = #(self.g_ColdFire_Buff)
        for i = 1, nMax do
            if (cold + fire) <= self.g_ColdFire_Buff[i]["value"] then
                return self.g_ColdFire_Buff[i]["buff"]
            end
        end
        if (cold + fire) >= self.g_ColdFire_Buff[nMax]["value"] then
            return self.g_ColdFire_Buff[nMax]["buff"]
        end
    elseif TankType == 4 then
        local light = self:GetHumanAttr(selfId, 5)
        local poison = self:GetHumanAttr(selfId, 6)
        local nMax = #(self.g_LightPoison_Buff)
        for i = 1, nMax do
            if (light + poison) <= self.g_LightPoison_Buff[i]["value"] then
                return self.g_LightPoison_Buff[i]["buff"]
            end
        end
        if (light + poison) >= self.g_LightPoison_Buff[nMax]["value"] then
            return self.g_LightPoison_Buff[nMax]["buff"]
        end
    end
    return 0
end

return efuben_bangzhan
