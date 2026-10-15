local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local gbk = require "wire_charset"
local script_base = require "script_base"
local xinsanhuan_1 = class("xinsanhuan_1", script_base)
xinsanhuan_1.script_id = 050220
xinsanhuan_1.g_MissionId = 1256
xinsanhuan_1.g_Name = "何悦"
xinsanhuan_1.g_MissionKind = 8
xinsanhuan_1.g_MissionLevel = 10000
xinsanhuan_1.g_MissionName = "Hoàng Kim Chi Liên"
xinsanhuan_1.g_MissionInfo = "    "
xinsanhuan_1.g_MissionTarget = "    #{LLFBM_80918_1}"
xinsanhuan_1.g_SubmitInfo = "#{LLFB_80816_19}"
xinsanhuan_1.g_MissionComplete = "#{LLFB_80902_1}"
xinsanhuan_1.g_IsMissionOkFail = 0
xinsanhuan_1.g_IsSmallMonster = 1
xinsanhuan_1.g_IsBossNiuQu = 2
xinsanhuan_1.g_IsBossNiuQi = 3
xinsanhuan_1.g_IsBossWang = 4
xinsanhuan_1.g_IsFindGoods = 5
xinsanhuan_1.g_Param_sceneid = 6
xinsanhuan_1.g_Custom = {
    {["id"] = "已杀死：#r  玄雷坡土匪", ["num"] = 60},
    {["id"] = "  牛曲", ["num"] = 1},
    {["id"] = "  牛奇", ["num"] = 1},
    {["id"] = "  王阎", ["num"] = 1},
    {["id"] = "已找到：#r  黄金之链", ["num"] = 1}
}

xinsanhuan_1.g_huangjinzhilian = 40004453
xinsanhuan_1.g_heyuanxin = 40004460
xinsanhuan_1.g_SmallMonster = "玄雷坡土匪"
xinsanhuan_1.g_NiuQu = "牛曲"
xinsanhuan_1.g_NiuQi = "牛奇"
xinsanhuan_1.g_BossWang = "王阎"
xinsanhuan_1.SmallMonsterIDTbl = {13000, 13001, 13002, 13003, 13004, 13005, 13006, 13007, 13008, 13009}
xinsanhuan_1.NiuQuIDTbl = {13020, 13021, 13022, 13023, 13024, 13025, 13026, 13027, 13028, 13029}
xinsanhuan_1.NiuQiIDTbl = {13040, 13041, 13042, 13043, 13044, 13045, 13046, 13047, 13048, 13049}
xinsanhuan_1.BossWangIDTbl = {13060, 13061, 13062, 13063, 13064, 13065, 13066, 13067, 13068, 13069}

xinsanhuan_1.g_SmallMonsterAPos = {
    {124, 201},
    {128, 201},
    {136, 201},
    {142, 201},
    {148, 197},
    {148, 193},
    {148, 189},
    {148, 186},
    {148, 181},
    {143, 174},
    {138, 174},
    {132, 174},
    {126, 174},
    {159, 183},
    {159, 189}
}

xinsanhuan_1.g_SmallMonsterBPos = {
    {55, 85},
    {64, 85},
    {75, 85},
    {86, 84},
    {97, 84},
    {107, 84},
    {107, 70},
    {97, 71},
    {85, 69},
    {74, 68},
    {64, 68},
    {55, 68},
    {53, 56},
    {75, 57},
    {85, 58},
    {56, 45},
    {75, 46},
    {85, 46},
    {61, 37},
    {66, 37}
}

xinsanhuan_1.g_SmallMonsterCPos = {
    {165, 43},
    {171, 43},
    {168, 45},
    {166, 49},
    {172, 49},
    {157, 61},
    {164, 61},
    {160, 64},
    {157, 68},
    {164, 67},
    {176, 60},
    {182, 61},
    {179, 63},
    {176, 66},
    {182, 66},
    {173, 79},
    {178, 81},
    {175, 82},
    {171, 84},
    {177, 86},
    {197, 68},
    {205, 70},
    {200, 72},
    {196, 74},
    {204, 76}
}

xinsanhuan_1.g_NumText_Main = 1
xinsanhuan_1.g_NumText_EnterCopyScene = 2
xinsanhuan_1.g_CopySceneMap = "xuanmuchang.nav"
xinsanhuan_1.g_CopySceneArea = "xuanmuchang_area.ini"
xinsanhuan_1.g_CopySceneMonsterIni = "xuanmuchang_monster.ini"
xinsanhuan_1.g_client_res = 265
xinsanhuan_1.g_CopySceneType = ScriptGlobal.FUBEN_HUANGJINZHILIAN
xinsanhuan_1.g_LimitMembers = 3
xinsanhuan_1.g_TickTime = 5
xinsanhuan_1.g_LimitTotalHoldTime = 360
xinsanhuan_1.g_CloseTick = 6
xinsanhuan_1.g_NoUserTime = 30
xinsanhuan_1.g_Fuben_X = 38
xinsanhuan_1.g_Fuben_Z = 220
xinsanhuan_1.g_Back_X = 295
xinsanhuan_1.g_Back_Z = 68
xinsanhuan_1.g_TakeTimes = 5



function xinsanhuan_1:OnDefaultEvent(selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    local numText = index
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if numText == self.g_NumText_Main then
            if self:CheckAccept(selfId, targetId) > 0 then
                self:BeginEvent(self.script_id)
                self:AddText("#{LLFB_80816_2}")
                self:EndEvent()
                self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
            end
        end
    else
        if numText == self.g_NumText_Main then
            local bDone = self:CheckSubmit(selfId)
            self:BeginEvent(self.script_id)
            if bDone == 1 then
                self:AddText(self.g_SubmitInfo)
            else
                self:AddText("#{LLFB_80816_8}")
                self:AddNumText("Đến Huyền Lôi Pha", 10, self.g_NumText_EnterCopyScene)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
            self:EndEvent()
            self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
        elseif numText == self.g_NumText_EnterCopyScene then
            self:AcceptEnterCopyScene(selfId, targetId)
        end
    end
end

function xinsanhuan_1:CheckConflictMission(selfId)
    for missionId = 1256 + 1, 1258 do
        if self:IsHaveMission(selfId, missionId) then
            return 1
        end
    end
    return 0
end

function xinsanhuan_1:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckConflictMission(selfId) == 1 then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, self.g_NumText_Main)
end

function xinsanhuan_1:CheckAccept(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:CheckConflictMission(selfId) == 1 then
        return 0
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("  #{LLFB_80816_11}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    local DayTimes, oldDate, nowDate, takenTimes
    DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_DAYTIME)
    oldDate = DayTimes % 100000
    takenTimes = math.floor(DayTimes / 100000)
    nowDate = self:GetDayTime()
    if nowDate ~= oldDate then
        takenTimes = 0
        self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_DAYTIME, nowDate)
    end
    if takenTimes >= self.g_TakeTimes then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_3}")
        return 0
    end
    --[[local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_LAST)
    local CurTime = self:GetQuarterTime()
    if iTime + 1 >= CurTime then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_4}")
        return 0
    end]]
    if self:GetLevel(selfId) < 75 then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_5}")
        return 0
    end
    if self:CheckAllXinFaLevel_Ex(selfId, 45) ~= 1 then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_5}")
        return 0
    end
    if self:GetMissionCount(selfId) >= 20 then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_6}")
        return 0
    end
    return 1
end

function xinsanhuan_1:OnAccept(selfId, targetId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    local num = self:LuaFnGetAvailableItemCount(selfId, self.g_huangjinzhilian)
    if num > 0 then
        self:LuaFnDelAvailableItem(selfId, self.g_huangjinzhilian, num)
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_DAYTIME)
    local takenTimes = math.floor(DayTimes / 100000)
    DayTimes = (takenTimes + 1) * 100000 + self:GetDayTime()
    self:DungeonDone(selfId, 4)
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_DAYTIME, DayTimes)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsSmallMonster, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsBossNiuQu, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsBossNiuQi, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsBossWang, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsFindGoods, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLFB_80816_8}")
    self:AddNumText("Đến Huyền Lôi Pha", 10, self.g_NumText_EnterCopyScene)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function xinsanhuan_1:AcceptEnterCopyScene(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        if copysceneid >= 0 then
            if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) == 2 then
                self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_7}")
            elseif self:IsCanEnterCopyScene(copysceneid, selfId) then
                local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
                self:NewWorld(selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
            else
                self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_7}")
            end
            return
        end
        if not self:LuaFnHasTeam(selfId) then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_9}")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_10}")
            return
        end
        local teamMemberCount = self:GetTeamMemberCount(selfId)
        local nearMemberCount = self:GetNearTeamCount(selfId)
        if not nearMemberCount or nearMemberCount < self.g_LimitMembers then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_11}")
            return
        end
        if not teamMemberCount or teamMemberCount ~= nearMemberCount then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_12}")
            return
        end
        local outmessage = "#{FB0}"
        local issatisfy = 1
        local isAccept = 0
        local Acceptmessage = ""
        for i = 1, nearMemberCount  do
            local memberID = self:GetNearTeamMember(selfId, i)
            outmessage = outmessage .. "#r#BĐội viên  " .. self:GetName(memberID)
            if self:GetLevel(memberID) >= 75 then
                outmessage = outmessage .. "#{FB1}"
            else
                outmessage = outmessage .. "#{FB2}"
                issatisfy = 0
            end
            if self:CheckAllXinFaLevel_Ex(memberID, 45) == 1 then
                outmessage = outmessage .. "#{FB3}"
            else
                outmessage = outmessage .. "#{FB4}"
                issatisfy = 0
            end
            if self:IsHaveMission(memberID, self.g_MissionId) then
                misIndex = self:GetMissionIndexByID(memberID, self.g_MissionId)
                if self:GetMissionParam(memberID, misIndex, self.g_IsMissionOkFail) == 0 then
                    if self:GetMissionParam(memberID, misIndex, self.g_Param_sceneid) == -1 then
                        outmessage = outmessage .. "#{FB5}"
                    else
                        outmessage = outmessage .. "#{FB6}"
                        issatisfy = 0
                        if isAccept == 0 then
                            Acceptmessage = "#G" .. self:GetName(memberID)
                        else
                            Acceptmessage = Acceptmessage .. "#W、#G" .. self:GetName(memberID)
                        end
                        isAccept = 1
                    end
                else
                    outmessage = outmessage .. "#{FB6}"
                    issatisfy = 0
                end
            else
                outmessage = outmessage .. "#{FB6}"
                issatisfy = 0
            end
        end
        if isAccept == 1 then
            Acceptmessage = "#{FB7}" .. Acceptmessage .. "#{FB8}"
            self:NotifyFailBox(selfId, targetId, Acceptmessage)
            return
        end
        if issatisfy == 0 then
            self:NotifyFailBox(selfId, targetId, outmessage)
            return
        end
        local mylevel = 0
        local memId
        local tempMemlevel = 0
        local level0 = 0
        local level1 = 0
        for i = 1, nearMemberCount  do
            memId = self:GetNearTeamMember(selfId, i)
            tempMemlevel = self:GetLevel(memId)
            level0 = level0 + (tempMemlevel ^ 4)
            level1 = level1 + (tempMemlevel ^ 3)
        end
        if level1 == 0 then
            mylevel = 0
        else
            mylevel = level0 / level1
        end
        if nearMemberCount == -1 then
            mylevel = self:GetLevel(selfId)
        end
        local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
        local iniLevel
        if mylevel < 10 then
            iniLevel = 1
        elseif mylevel < PlayerMaxLevel then
            iniLevel = math.floor((mylevel - 75) / 5) + 1
            if iniLevel < 0 then
                iniLevel = 1
            elseif iniLevel > 10 then
                iniLevel = 10
            end
        else
            iniLevel = 10
        end
        local smallmonsterId = self.SmallMonsterIDTbl[1]
        if self.SmallMonsterIDTbl[iniLevel] then
            smallmonsterId = self.SmallMonsterIDTbl[iniLevel]
        end
        local NiuquId = self.NiuQuIDTbl[1]
        if self.NiuQuIDTbl[iniLevel] then
            NiuquId = self.NiuQuIDTbl[iniLevel]
        end
        local NiuqiId = self.NiuQiIDTbl[1]
        if self.NiuQiIDTbl[iniLevel] then
            NiuqiId = self.NiuQiIDTbl[iniLevel]
        end
        local BossWangID = self.BossWangIDTbl[1]
        if self.BossWangIDTbl[iniLevel] then
            BossWangID = self.BossWangIDTbl[iniLevel]
        end
        local leaderguid = self:LuaFnObjId2Guid(selfId)
        local config = {}
        config.navmapname = self.g_CopySceneMap
        config.client_res = self.g_client_res
        config.teamleader = leaderguid
        config.NoUserCloseTime = 0
        config.Timer = self.g_TickTime * 1000
        config.params = {}
        config.params[0] = self.g_CopySceneType
        config.params[1] = self.script_id
        config.params[2] = 0
        config.params[3] = -1
        config.params[4] = 0
        config.params[5] = 0
        config.params[6] = self:GetTeamId( selfId )
        config.params[7] = 0
        config.params[8] = 0
        config.params[9] = 0
        config.params[10] = 0
        config.params[11] = 0
        config.params[12] = smallmonsterId
        config.params[13] = NiuquId
        config.params[14] = NiuqiId
        config.params[15] = BossWangID
        config.params[16] = mylevel
        config.event_area = self.g_CopySceneArea
        config.monsterfile = self.g_CopySceneMonsterIni
        config.sn 		 = self:LuaFnGenCopySceneSN()
        local bRetSceneID = self:LuaFnCreateCopyScene(config)
        if bRetSceneID > 0 then
            self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
            self:AuditXinSanHuanCreateFuben(selfId, 1)
        else
            self:NotifyFailTips(selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        end
    end
end

function xinsanhuan_1:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if leaderObjId == -1 then
        return
    end
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
        return
    end
    local members = {}
    local validmembercount = 0
    local nearMemberCount = self:GetNearTeamCount(leaderObjId)
    for i = 1, nearMemberCount  do
        local member = self:GetNearTeamMember(leaderObjId, i)
        if self:IsHaveMission(member, self.g_MissionId) then
            validmembercount = validmembercount + 1
            members[validmembercount] = member
        end
    end
    local misIndex
    for i = 1, validmembercount do
        if self:IsHaveMission(members[i], self.g_MissionId) then
            local misIndex = self:GetMissionIndexByID(members[i], self.g_MissionId)
            if self:LuaFnIsCanDoScriptLogic(members[i]) then
                self:SetMissionByIndex(members[i], misIndex, self.g_Param_sceneid, destsceneId)
                self:NewWorld(members[i], destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
            end
        end
    end
end

function xinsanhuan_1:OnPlayerEnter(selfId)
end

function xinsanhuan_1:OnDie(objId, selfId)
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
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then
        return
    end
    local num = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}
    for i = 1, num do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    local szName = self:GetName(objId)
    if szName == self.g_SmallMonster then
        local KilledMonsterNum = self:LuaFnGetCopySceneData_Param(7)
        KilledMonsterNum = KilledMonsterNum + 1
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Đã giết" .. szName .. "： " .. KilledMonsterNum .. "/60")
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                self:SetMissionByIndex(mems[i], misIndex, self.g_IsSmallMonster, KilledMonsterNum)
            end
        end
        self:LuaFnSetCopySceneData_Param(7, KilledMonsterNum)
    elseif szName == self.g_NiuQu then
        self:LuaFnSetCopySceneData_Param(8, 1)
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Đã giết" .. szName .. "： 1/1")
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                self:SetMissionByIndex(mems[i], misIndex, self.g_IsBossNiuQu, 1)
            end
        end
        local otherflag = self:LuaFnGetCopySceneData_Param(9)
        local nMonsterNum = self:GetMonsterCount()
        if otherflag == 0 then
            for i = 1, nMonsterNum do
                local MonsterId = self:GetMonsterObjID(i)
                self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, 5960, 0)
                if self:GetName(MonsterId) == self.g_NiuQi then
                    self:MonsterTalk(MonsterId, "Huyền Lôi Pha", "Đại ca, huynh đệ sẽ báo thù cho huynh!")
                end
            end
        else
            for i = 1, nMonsterNum do
                local MonsterId = self:GetMonsterObjID(i)
                self:LuaFnCancelSpecificImpact(MonsterId, 5959)
                self:LuaFnCancelSpecificImpact(MonsterId, 5960)
            end
        end
    elseif szName == self.g_NiuQi then
        self:LuaFnSetCopySceneData_Param(9, 1)
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Đã giết" .. szName .. "： 1/1")
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                self:SetMissionByIndex(mems[i], misIndex, self.g_IsBossNiuQi, 1)
            end
        end
        local otherflag = self:LuaFnGetCopySceneData_Param(8)
        local nMonsterNum = self:GetMonsterCount()
        if otherflag == 0 then
            for i = 1, nMonsterNum do
                local MonsterId = self:GetMonsterObjID(i)
                self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, 5960, 0)
                if self:GetName(MonsterId) == self.g_NiuQu then
                    self:MonsterTalk(MonsterId, "Huyền Lôi Pha", "Huynh đệ, đại ca sẽ báo thù cho đệ!")
                end
            end
        else
            for i = 1, nMonsterNum do
                local MonsterId = self:GetMonsterObjID(i)
                self:LuaFnCancelSpecificImpact(MonsterId, 5959)
                self:LuaFnCancelSpecificImpact(MonsterId, 5960)
            end
        end
    elseif szName == self.g_BossWang then
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Đã giết" .. szName .. "： 1/1")
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                self:SetMissionByIndex(mems[i], misIndex, self.g_IsBossWang, 1)
                self:AddMonsterDropItem(objId, mems[i], self.g_huangjinzhilian)
            end
        end
        self:LuaFnAddSweepPointByID(selfId, 4, 1)
        local BroadcastMsg = string.format(gbk.fromutf8("#{LLFB_80816_17}#W#{_INFOUSR%s}#{LLFB_80816_18}"), gbk.fromutf8(self:GetName(selfId)))
        self:BroadMsgByChatPipe(selfId, BroadcastMsg, 4)
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
end

function xinsanhuan_1:OnKillObject(selfId, objdataId, objId)
    local name = self:GetMonsterNamebyDataId(objdataId)
    if name == self.g_BossWang then
        local num = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, num do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddSweepPointByID(mems[i], 4, 6)
        end
    end
end

function xinsanhuan_1:OnHumanDie(selfId, killerId)
end

function xinsanhuan_1:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function xinsanhuan_1:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText("Tốt, tiếp tục")
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function xinsanhuan_1:OnAbandon(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_LAST, CurTime)
    self:DelMission(selfId, self.g_MissionId)
    local num = self:LuaFnGetAvailableItemCount(selfId, self.g_huangjinzhilian)
    if num > 0 then
        self:LuaFnDelAvailableItem(selfId, self.g_huangjinzhilian, num)
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    local sceneId = self:get_scene_id()
    if sceneId == copyscene and fubentype == self.g_CopySceneType then
        self:NotifyFailTips(selfId, "Nhiệm vụ thất bại!")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function xinsanhuan_1:OnCopySceneTimer(nowTime)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    for i = 1, membercount do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount >= self.g_CloseTick then
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:Exit(mems[i])
                end
            end
        else
            local strText = string.format("Ngươi sẽ rời khỏi Phó bản sau %d giây.", (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:NotifyFailTips(mems[i], strText)
                end
            end
        end
    elseif TickCount == self.g_LimitTotalHoldTime then
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Thời gian nhiệm vụ đã hết, rời khỏi cảnh....")
                if self:IsHaveMission(mems[i], self.g_MissionId) then
                    local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                    if self:GetMissionParam(mems[i], misIndex, self.g_IsMissionOkFail) ~= 1 then
                        self:SetMissionByIndex(mems[i], misIndex, self.g_IsMissionOkFail, 2)
                    end
                end
                self:Exit(mems[i])
            end
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    elseif TickCount == 1 then
        local smallmonsterId = self:LuaFnGetCopySceneData_Param(12)
        local NiuquId = self:LuaFnGetCopySceneData_Param(13)
        local NiuqiId = self:LuaFnGetCopySceneData_Param(14)
        local mylevel = self:LuaFnGetCopySceneData_Param(16)
        for i = 1, #(self.g_SmallMonsterAPos) do
            if self.g_SmallMonsterAPos[i] then
                local monsterID =
                    self:LuaFnCreateMonster(
                    smallmonsterId,
                    self.g_SmallMonsterAPos[i][1],
                    self.g_SmallMonsterAPos[i][2],
                    14,
                    -1,
                    050220
                )
                self:SetLevel(monsterID, mylevel)
                self:SetCharacterName(monsterID, self.g_SmallMonster)
                self:LuaFnSendSpecificImpactToUnit(monsterID, monsterID, monsterID, 5959, 0)
            end
        end
        for i = 1, #(self.g_SmallMonsterBPos) do
            if self.g_SmallMonsterBPos[i] then
                local monsterID =
                    self:LuaFnCreateMonster(
                    smallmonsterId,
                    self.g_SmallMonsterBPos[i][1],
                    self.g_SmallMonsterBPos[i][2],
                    14,
                    -1,
                    050220
                )
                self:SetLevel(monsterID, mylevel)
                self:SetCharacterName(monsterID, self.g_SmallMonster)
                self:LuaFnSendSpecificImpactToUnit(monsterID, monsterID, monsterID, 5959, 0)
            end
        end
        for i = 1, #(self.g_SmallMonsterCPos) do
            if self.g_SmallMonsterCPos[i] then
                local monsterID =
                    self:LuaFnCreateMonster(
                    smallmonsterId,
                    self.g_SmallMonsterCPos[i][1],
                    self.g_SmallMonsterCPos[i][2],
                    14,
                    -1,
                    050220
                )
                self:SetLevel(monsterID, mylevel)
                self:SetCharacterName(monsterID, self.g_SmallMonster)
                self:LuaFnSendSpecificImpactToUnit(monsterID, monsterID, monsterID, 5959, 0)
            end
        end
        local monsterID = self:LuaFnCreateMonster(NiuquId, 168, 184, 14, -1, 050220)
        self:SetLevel(monsterID, mylevel + 2)
        self:SetCharacterName(monsterID, self.g_NiuQu)
        monsterID = self:LuaFnCreateMonster(NiuqiId, 65, 34, 14, -1, 050220)
        self:SetLevel(monsterID, mylevel + 2)
        self:SetCharacterName(monsterID, self.g_NiuQi)
    else
        local oldteamid = self:LuaFnGetCopySceneData_Param(6)
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and
                    oldteamid ~= self:GetTeamId(mems[i])
             then
                self:NotifyFailTips(mems[i], "Ngươi không ở trong đội ngũ chính xác, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        local monsternum = self:LuaFnGetCopySceneData_Param(7)
        local iskillNiuQu = self:LuaFnGetCopySceneData_Param(8)
        local iskillNiuQi = self:LuaFnGetCopySceneData_Param(9)
        local isBossWang = self:LuaFnGetCopySceneData_Param(10)
        local NotifyTime = self:LuaFnGetCopySceneData_Param(11)
        if (TickCount * self.g_TickTime) % 60 == 0 and (TickCount * self.g_TickTime + 60) % 120 == 0 then
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    local Minute = math.floor((360 - TickCount) * self.g_TickTime / 60)
                    self:NotifyFailTips(mems[i], "Còn lại" .. Minute .. "Phút")
                end
            end
        end
        if monsternum >= 60 and iskillNiuQu == 1 and iskillNiuQi == 1 and isBossWang == 0 then
            local BossWangId = self:LuaFnGetCopySceneData_Param(15)
            local mylevel = self:LuaFnGetCopySceneData_Param(16)
            local monsterID = self:LuaFnCreateMonster(BossWangId, 200, 48, 14, 262, 050220)
            self:SetLevel(monsterID, mylevel + 3)
            self:SetCharacterName(monsterID, self.g_BossWang)
            self:MonsterTalk(monsterID, "Huyền Lôi Pha", "Oa nha nha, kẻ nào dám xông vào Huyền Lôi Pha của ta?! Mau đến nạp mạng!")
            self:LuaFnSetCopySceneData_Param(10, 1)
        end
    end
end

function xinsanhuan_1:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) ~= 1 then
        return 0
    end
    if self:LuaFnGetAvailableItemCount(selfId, self.g_huangjinzhilian) < 1 then
        return 0
    end
    return 1
end

function xinsanhuan_1:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckSubmit(selfId) == 1 then
        self:NotifyFailBox(selfId, targetId, self.g_MissionComplete)
        if self:LuaFnDelAvailableItem(selfId, self.g_huangjinzhilian, 1) then
            self:BeginAddItem()
            self:AddItem(self.g_heyuanxin, 1)
            local ret = self:EndAddItem(selfId)
            if ret then
                self:AddItemListToHuman(selfId)
                self:DelMission(selfId, self.g_MissionId)
                self:LuaFnAuditQuest(selfId, "Nhiệm Vụ Liên Hoàn Lâu Lan: Chuỗi Vàng")
            else
                self:NotifyFailTips(selfId, "Ngươi củahành trang đã đầy.")
            end
        end
    end
end

function xinsanhuan_1:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function xinsanhuan_1:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function xinsanhuan_1:CheckAllXinfaLevel(selfId, level)
    local nMenpai = self:GetMenPai(selfId)
    if nMenpai == 9 then return 0 end
    for i = 1, 6 do
        local xinfa
        if nMenpai < 9 then
            xinfa = nMenpai * 6 + i
        else
            xinfa = nMenpai * 6 + (i + 3)
        end
        local nXinfaLevel = self:LuaFnGetXinFaLevel(selfId, xinfa)
        if nXinfaLevel < level then
            return 0
        end
    end
    return 0
end

function xinsanhuan_1:PickupItem(selfId, itemId, bagidx)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    if itemId ~= self.g_huangjinzhilian then
        return
    end
    self:NotifyFailTips(selfId, "Đã tìm thấy Dây Chuyền Hoàng Kim: 1/1")
    self:NotifyFailTips(selfId, "Mục tiêu nhiệm vụ hoàn thành")
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsFindGoods, 1)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 1)
end

function xinsanhuan_1:CalSweepData(selfId)
    local drop_items
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    local mylevel = self:GetLevel(selfId)
    if mylevel < 10 then
        iniLevel = 1
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor((mylevel - 75) / 5) + 1
        if iniLevel < 0 then
            iniLevel = 1
        elseif iniLevel > 10 then
            iniLevel = 10
        end
    else
        iniLevel = 10
    end
    local monster_file = string.format(self.g_CopySceneMonsterIni, iniLevel)
    monster_file = self:ParserIniFile(monster_file)
    local monster_count = monster_file.info.monstercount
    local award_exp = 0
    for i = 0, monster_count - 1 do
        local key = string.format("monster%d", i)
        local monster = monster_file[key]
        if monster then
            award_exp = award_exp + self:CalMonsterAwardExp(monster.type)
        end
    end
    local BossWangID = self.BossWangIDTbl[1]
    if self.BossWangIDTbl[iniLevel] then
        BossWangID = self.BossWangIDTbl[iniLevel]
    end
    if BossWangID then
        drop_items = self:CalMonsterDropItems(BossWangID)
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_DAYTIME)
    local takenTimes = math.floor(DayTimes / 100000)
    DayTimes = (takenTimes + 1) * 100000 + self:GetDayTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_1_DAYTIME, DayTimes)
    return drop_items, award_exp
end

return xinsanhuan_1
