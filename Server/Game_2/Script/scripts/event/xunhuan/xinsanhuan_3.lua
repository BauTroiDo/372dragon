local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local xinsanhuan_3 = class("xinsanhuan_3", script_base)
local gbk = require "wire_charset"
xinsanhuan_3.script_id = 050222
xinsanhuan_3.g_MissionId = 1258
xinsanhuan_3.g_Name = "何悦"
xinsanhuan_3.g_MissionKind = 8
xinsanhuan_3.g_MissionLevel = 10000
xinsanhuan_3.g_MissionName = "Dung Nham Chi Địa"
xinsanhuan_3.g_MissionInfo = "    "
xinsanhuan_3.g_MissionTarget = "    #{LLFBM_80918_3}"
xinsanhuan_3.g_SubmitInfo = "#{LLFB_80816_53}"
xinsanhuan_3.g_IsMissionOkFail = 0
xinsanhuan_3.g_IsKillBossFire = 1
xinsanhuan_3.g_Param_sceneid = 3
xinsanhuan_3.g_Custom = {
    {["id"] = "已杀死：#r  火焰妖魔", ["num"] = 1}
}

xinsanhuan_3.g_xuanfouzhu = 40004454
xinsanhuan_3.g_MonsterSuiCong = "妖魔随从"
xinsanhuan_3.g_BossHuoYanYao = "火焰妖魔"
xinsanhuan_3.MonsterSuiCongIDTbl = {13240, 13241, 13242, 13243, 13244, 13245, 13246, 13247, 13248, 13249}
xinsanhuan_3.BossHuoYanYaoIDTbl = {13260, 13261, 13262, 13263, 13264, 13265, 13266, 13267, 13268, 13269}
xinsanhuan_3.g_BossHuoYanYaoPos = {67, 48}
xinsanhuan_3.g_MonsterSuiCongPos = {
    {187, 176},
    {172, 187},
    {187, 165},
    {164, 174},
    {148, 185},
    {152, 193},
    {144, 160},
    {208, 154},
    {151, 174},
    {134, 155},
    {181, 168},
    {177, 146},
    {143, 128},
    {153, 124},
    {151, 113},
    {171, 117},
    {187, 94},
    {191, 80},
    {204, 97},
    {212, 102},
    {207, 60},
    {191, 54},
    {184, 61},
    {162, 49},
    {152, 53},
    {143, 77},
    {149, 72},
    {147, 77},
    {106, 214},
    {97, 218},
    {89, 202},
    {78, 208},
    {74, 204},
    {65, 212},
    {45, 203},
    {70, 174},
    {84, 164},
    {75, 151},
    {62, 150},
    {68, 142},
    {58, 118},
    {69, 115},
    {89, 113},
    {98, 110},
    {91, 98},
    {54, 114},
    {43, 105},
    {52, 99},
    {69, 105},
    {80, 84},
    {85, 81},
    {97, 89},
    {105, 76},
    {51, 80},
    {45, 73},
    {80, 74},
    {97, 62},
    {50, 60},
    {69, 55},
    {73, 51},
    {44, 49},
    {56, 42},
    {48, 32},
    {43, 34},
    {67, 28},
    {77, 35},
    {85, 38},
    {102, 31},
    {106, 40},
    {108, 49},
    {72, 39},
    {186, 156},
    {147, 199},
    {137, 211},
    {130, 190},
    {139, 163},
    {211, 175},
    {216, 177},
    {220, 167},
    {67, 88},
    {64, 91},
    {91, 130},
    {85, 133},
    {179, 101},
    {186, 104},
    {139, 91},
    {215, 88},
    {176, 53},
    {135, 96},
    {139, 52},
    {135, 56},
    {133, 206},
    {221, 198},
    {215, 192},
    {206, 199},
    {194, 205},
    {191, 213},
    {196, 193},
    {185, 198},
    {205, 182},
    {220, 184},
    {177, 207},
    {188, 184},
    {172, 210},
    {172, 196},
    {226, 173},
    {175, 177},
    {177, 185},
    {197, 200},
    {205, 188},
    {224, 194},
    {182, 194},
    {201, 170},
    {212, 171},
    {160, 196},
    {159, 210},
    {205, 160},
    {220, 159},
    {165, 182},
    {149, 215},
    {174, 165},
    {157, 179},
    {143, 205},
    {137, 198},
    {144, 191},
    {155, 167},
    {178, 154},
    {195, 151},
    {213, 151},
    {135, 171},
    {142, 166},
    {157, 151},
    {158, 60},
    {173, 64},
    {201, 45},
    {190, 34},
    {199, 66},
    {161, 77},
    {141, 83},
    {156, 107},
    {162, 119},
    {203, 89},
    {177, 91},
    {195, 115},
    {134, 74},
    {144, 119},
    {162, 98},
    {190, 71},
    {141, 57},
    {211, 62},
    {159, 42},
    {196, 85},
    {71, 45},
    {49, 50},
    {65, 58},
    {80, 54},
    {82, 46},
    {74, 60},
    {56, 60},
    {62, 42},
    {52, 40},
    {80, 33},
    {84, 57},
    {43, 56},
    {46, 38},
    {63, 51},
    {68, 65},
    {58, 68},
    {85, 66},
    {94, 51},
    {71, 75},
    {53, 88},
    {102, 210},
    {91, 215},
    {71, 195},
    {62, 214},
    {51, 203},
    {66, 184},
    {84, 157},
    {52, 211},
    {77, 169},
    {76, 134},
    {214, 189},
    {221, 187},
    {207, 197},
    {217, 197},
    {201, 202},
    {221, 204},
    {208, 209},
    {215, 210}
}

xinsanhuan_3.g_NumText_Main = 2
xinsanhuan_3.g_NumText_EnterCopyScene = 3
xinsanhuan_3.g_CopySceneMap = "huomuchang.nav"
xinsanhuan_3.g_CopySceneArea = "huomuchang_area.ini"
xinsanhuan_3.g_CopySceneMonsterIni = "huomuchang_monster.ini"
xinsanhuan_3.g_client_res = 9267
xinsanhuan_3.g_CopySceneType = ScriptGlobal.FUBEN_RONGYANZHIDI
xinsanhuan_3.g_LimitMembers = 3
xinsanhuan_3.g_TickTime = 5
xinsanhuan_3.g_LimitTotalHoldTime = 360
xinsanhuan_3.g_CloseTick = 6
xinsanhuan_3.g_NoUserTime = 30
xinsanhuan_3.g_Fuben_X = 217
xinsanhuan_3.g_Fuben_Z = 221
xinsanhuan_3.g_Back_X = 295
xinsanhuan_3.g_Back_Z = 68
xinsanhuan_3.g_TakeTimes = 5

function xinsanhuan_3:OnDefaultEvent(selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    local numText = index
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if numText == self.g_NumText_Main then
            if self:LuaFnGetAvailableItemCount(selfId, self.g_xuanfouzhu) < 1 then
                self:BeginEvent(self.script_id)
                self:AddText("#{LLFB_80816_44}")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            elseif self:CheckAccept(selfId, targetId) > 0 then
                self:BeginEvent(self.script_id)
                self:AddText("#{LLFB_80816_45}")
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
                self:AddText("#{LLFB_80816_47}")
                self:AddNumText("Đến Dung Nham Chi Địa", 10, self.g_NumText_EnterCopyScene)
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

function xinsanhuan_3:CheckConflictMission(selfId)
    if self:IsHaveMission(selfId, 1256) then
        return 1
    end
    if self:IsHaveMission(selfId, 1257) then
        return 1
    end
    return 0
end

function xinsanhuan_3:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckConflictMission(selfId) == 1 then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, self.g_NumText_Main)
end

function xinsanhuan_3:CheckAccept(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:CheckConflictMission(selfId) == 1 then
        return 0
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("  #{LLFB_80816_49}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    local DayTimes, oldDate, nowDate, takenTimes
    DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_DAYTIME)
    oldDate = DayTimes % 100000
    takenTimes = math.floor(DayTimes / 100000)
    nowDate = self:GetDayTime()
    if nowDate ~= oldDate then
        takenTimes = 0
        self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_DAYTIME, nowDate)
    end
    if takenTimes >= self.g_TakeTimes then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_3}")
        return 0
    end
    --[[local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_LAST)
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
    if self:LuaFnGetAvailableItemCount(selfId, self.g_xuanfouzhu) < 1 then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_44}")
        return 0
    end
    return 1
end

function xinsanhuan_3:OnAccept(selfId, targetId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_DAYTIME)
    local takenTimes = math.floor(DayTimes / 100000)
    DayTimes = (takenTimes + 1) * 100000 + self:GetDayTime()
    self:DungeonDone(selfId, 6)
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_DAYTIME, DayTimes)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsKillBossFire, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLFB_80816_47}")
    self:AddNumText("Đến Dung Nham Chi Địa", 10, self.g_NumText_EnterCopyScene)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function xinsanhuan_3:AcceptEnterCopyScene(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        if copysceneid >= 0 then
            if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) == 2 then
                self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_46}")
            elseif self:IsCanEnterCopyScene(copysceneid, selfId) then
                local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
                self:NewWorld(selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
            else
                self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_46}")
            end
            return
        end
        if not self:LuaFnHasTeam(selfId) then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_48}")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_10}")
            return
        end
        local teamMemberCount = self:GetTeamMemberCount(selfId)
        local nearMemberCount = self:GetNearTeamCount(selfId)
        if not nearMemberCount or nearMemberCount < self.g_LimitMembers then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_49}")
            return
        end
        if not teamMemberCount or teamMemberCount ~= nearMemberCount then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_12}")
            return
        end
        local outmessage = "#{FB0}"
        local issatisfy = 1
        local memberID = 0
        local isAccept = 0
        local Acceptmessage = ""
        for i = 1, nearMemberCount do
            memberID = self:GetNearTeamMember(selfId, i)
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
        config.params[7] = mylevel
        config.params[8] = iniLevel
        config.params[9] = 0
        config.params[10] = 0
        config.params[11] = 0
        config.params[12] = 0
        config.params[13] = 0
        config.params[14] = 0
        config.params[15] = 0
        config.params[16] = mylevel
        config.event_area = self.g_CopySceneArea
        config.monsterfile = self.g_CopySceneMonsterIni
        config.sn 		 = self:LuaFnGenCopySceneSN()
        local bRetSceneID = self:LuaFnCreateCopyScene(config)
        if bRetSceneID > 0 then
            self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
            self:AuditXinSanHuanCreateFuben(selfId, 3)
        else
            self:NotifyFailTips(selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        end
    end
end

function xinsanhuan_3:OnCopySceneReady(destsceneId)
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

function xinsanhuan_3:OnPlayerEnter(selfId)
end

function xinsanhuan_3:OnDie(objId, selfId)
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
    if szName == self.g_BossHuoYanYao then
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Mục tiêu nhiệm vụ hoàn thành")
                self:NotifyFailTips(mems[i], "Đã giết" .. self.g_BossHuoYanYao .. "： 1/1")
                if self:IsHaveMission(mems[i], self.g_MissionId) then
                    local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                    self:SetMissionByIndex(mems[i], misIndex, self.g_IsKillBossFire, 1)
                    self:SetMissionByIndex(mems[i], misIndex, self.g_IsMissionOkFail, 1)
                    self:LuaFnAddSalaryPoint(mems[i], 10, 1)
                end
            end
        end
        self:LuaFnAddSweepPointByID(selfId, 6, 1)
        local BroadcastMsg = string.format(gbk.fromutf8("#W#{_INFOUSR%s}#{LLFB_80816_51}#{LLFB_80816_52}"), gbk.fromutf8(self:GetName(selfId)))
        self:BroadMsgByChatPipe(selfId, BroadcastMsg, 4)
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
end

function xinsanhuan_3:OnKillObject(selfId, objdataId, objId)
    local name = self:GetMonsterNamebyDataId(objdataId)
    if name == self.g_BossHuoYanYao then
        local num = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, num do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddSweepPointByID(mems[i], 6, 6)
        end
    end
end

function xinsanhuan_3:OnHumanDie(selfId, killerId)
end

function xinsanhuan_3:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function xinsanhuan_3:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText("Tốt, tiếp tục")
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function xinsanhuan_3:OnAbandon(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
	local have_count = self:LuaFnGetAvailableItemCount(selfId, self.g_xuanfouzhu)
	if have_count > 0 then
		self:LuaFnDelAvailableItem(selfId, self.g_xuanfouzhu, have_count)
	end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_LAST, CurTime)
    self:DelMission(selfId, self.g_MissionId)
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    local sceneId = self:get_scene_id()
    if sceneId == copyscene and fubentype == self.g_CopySceneType then
        self:NotifyFailTips(selfId, "Nhiệm vụ thất bại!")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function xinsanhuan_3:OnCopySceneTimer(nowTime)
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
        local mylevel = self:LuaFnGetCopySceneData_Param(7)
        local iniLevel = self:LuaFnGetCopySceneData_Param(8)
        local HuoYanYaoID = self.BossHuoYanYaoIDTbl[1]
        if self.BossHuoYanYaoIDTbl[iniLevel] then
            HuoYanYaoID = self.BossHuoYanYaoIDTbl[iniLevel]
        end
        local SuiCongID = self.MonsterSuiCongIDTbl[1]
        if self.MonsterSuiCongIDTbl[iniLevel] then
            SuiCongID = self.MonsterSuiCongIDTbl[iniLevel]
        end
        local monsterID =
            self:LuaFnCreateMonster(
            HuoYanYaoID,
            self.g_BossHuoYanYaoPos[1],
            self.g_BossHuoYanYaoPos[2],
            14,
            269,
            050222
        )
        self:SetLevel(monsterID, mylevel + 3)
        self:SetCharacterName(monsterID, self.g_BossHuoYanYao)
        self:MonsterTalk(monsterID, "Dung Nham Chi Địa", "Kẻ tự tiện xông vào nơi này, ắt sẽ bị thiêu thành tro bụi!")
        for i = 1, #(self.g_MonsterSuiCongPos) do
            monsterID =
                self:LuaFnCreateMonster(
                SuiCongID,
                self.g_MonsterSuiCongPos[i][1],
                self.g_MonsterSuiCongPos[i][2],
                14,
                -1,
                050222
            )
            self:SetLevel(monsterID, mylevel)
            self:SetCharacterName(monsterID, self.g_MonsterSuiCong)
        end
    else
        local oldteamid = self:LuaFnGetCopySceneData_Param(6)
        for i = 1, membercount do
            if
                self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and
                    oldteamid ~= self:GetTeamId(mems[i])
             then
                self:NotifyFailTips(mems[i], "Ngươi không ở trong đội ngũ chính xác, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        if (TickCount * self.g_TickTime) % 60 == 0 and (TickCount * self.g_TickTime + 60) % 120 == 0 then
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    local Minute = math.floor((360 - TickCount) * self.g_TickTime / 60)
                    self:NotifyFailTips(mems[i], "Còn lại" .. Minute .. "Phút")
                end
            end
        end
    end
end

function xinsanhuan_3:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) ~= 1 then
        return 0
    end
    if self:LuaFnGetAvailableItemCount(selfId, self.g_xuanfouzhu) < 1 then
        return 0
    end
    return 1
end

function xinsanhuan_3:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckSubmit(selfId) == 1 then
		local have_count = self:LuaFnGetAvailableItemCount(selfId, self.g_xuanfouzhu)
		if have_count > 0 then
			if self:LuaFnDelAvailableItem(selfId, self.g_xuanfouzhu, have_count) then
				self:DelMission(selfId, self.g_MissionId)
				local exp = self:GetLevel(selfId) * 3323 - 45613
				if exp < 1 then
					exp = 1
				end
				self:AddExp(selfId, exp)
				self:LuaFnAddMissionHuoYueZhi(selfId, 11)
				self:LuaFnAuditQuest(selfId, "Nhiệm vụ Lâu Lan Liên Hoàn Dung Nham Chi Địa")
			end
		end
    end
end

function xinsanhuan_3:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function xinsanhuan_3:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function xinsanhuan_3:CheckAllXinfaLevel(selfId, level)
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

function xinsanhuan_3:CalSweepData(selfId)
    local drop_items
    local award_exp = 0
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local mylevel = self:GetLevel(selfId)
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
    local SuiCongID = self.MonsterSuiCongIDTbl[1]
    if self.MonsterSuiCongIDTbl[iniLevel] then
        SuiCongID = self.MonsterSuiCongIDTbl[iniLevel]
    end
    for i = 1, #(self.g_MonsterSuiCongPos) do
        award_exp = award_exp + self:CalMonsterAwardExp(SuiCongID)
    end
    local HuoYanYaoID = self.BossHuoYanYaoIDTbl[1]
    if self.BossHuoYanYaoIDTbl[iniLevel] then
        HuoYanYaoID = self.BossHuoYanYaoIDTbl[iniLevel]
    end
    if HuoYanYaoID then
        drop_items = self:CalMonsterDropItems(HuoYanYaoID)
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_DAYTIME)
    local takenTimes = math.floor(DayTimes / 100000)
    DayTimes = (takenTimes + 1) * 100000 + self:GetDayTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_3_DAYTIME, DayTimes)
    return drop_items, award_exp
end

return xinsanhuan_3
