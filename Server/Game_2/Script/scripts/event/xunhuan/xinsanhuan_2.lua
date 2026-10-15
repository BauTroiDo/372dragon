local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local gbk = require "wire_charset"
local xinsanhuan_2 = class("xinsanhuan_2", script_base)
xinsanhuan_2.script_id = 050221
xinsanhuan_2.g_MissionId = 1257
xinsanhuan_2.g_Name = "刘盾"
xinsanhuan_2.g_MissionKind = 8
xinsanhuan_2.g_MissionLevel = 10000
xinsanhuan_2.g_MissionName = "Huyền Phật Châu"
xinsanhuan_2.g_MissionInfo = "    "
xinsanhuan_2.g_MissionTarget = "    #{LLFBM_80918_2}"
xinsanhuan_2.g_SubmitInfo = "#{LLFB_80816_43}"
xinsanhuan_2.g_MissionComplete = "#{LLFB_80902_2}"
xinsanhuan_2.g_IsMissionOkFail = 0
xinsanhuan_2.g_IsBossYaoWang = 1
xinsanhuan_2.g_IsFindGoods = 2
xinsanhuan_2.g_Param_sceneid = 3
xinsanhuan_2.g_Custom = {
    {["id"] = "已杀死：#r  洪棘妖王", ["num"] = 1},
    {["id"] = "已找到：#r  玄佛珠", ["num"] = 1}
}

xinsanhuan_2.g_heyuanxin = 40004460
xinsanhuan_2.g_xuanfouzhu = 40004454
xinsanhuan_2.g_Monster15ID = "毒障小怪"
xinsanhuan_2.g_Monster10ID = "泽地毒蛛"
xinsanhuan_2.g_BossID = {"撕风魔", "破焰尊者", "裂地行者", "武玄将", "五毒魔使"}

xinsanhuan_2.g_YinMoZhuID = {40004456, 40004459, 40004458, 40004455, 40004457}

xinsanhuan_2.g_BossYaoWang = "洪棘妖王"
xinsanhuan_2.Monster15IDTbl = {13080, 13081, 13082, 13083, 13084, 13085, 13086, 13087, 13088, 13089}

xinsanhuan_2.Monster10IDTbl = {13100, 13101, 13102, 13103, 13104, 13105, 13106, 13107, 13108, 13109}

xinsanhuan_2.BossIDTbl = {
    {13120, 13121, 13122, 13123, 13124, 13125, 13126, 13127, 13128, 13129},
    {13200, 13201, 13202, 13203, 13204, 13205, 13206, 13207, 13208, 13209},
    {13140, 13141, 13142, 13143, 13144, 13145, 13146, 13147, 13148, 13149},
    {13160, 13161, 13162, 13163, 13164, 13165, 13166, 13167, 13168, 13169},
    {13180, 13181, 13182, 13183, 13184, 13185, 13186, 13187, 13188, 13189}
}

xinsanhuan_2.BossYaoWangIDTbl = {13220, 13221, 13222, 13223, 13224, 13225, 13226, 13227, 13228, 13229}

xinsanhuan_2.g_BossTalk = {"Kẻ nào dám quấy nhiễu ta nghỉ ngơi?!", "Nơi đây sẽ là chốn yên nghỉ ngàn thu của các ngươi!", "Kẻ tự tiện xông vào lãnh địa của ta, chết!", "Lại thêm một kẻ đến nạp mạng!", "Ha ha, cuối cùng lại có thể giãn gân cốt rồi!"}

xinsanhuan_2.g_YaoWangTalk = "Tiểu bối phương nào dám giết con ta, có dám đến nạp mạng không?!"
xinsanhuan_2.g_Pos = {
    {
        ["left"] = {130, 191},
        ["right"] = {137, 200}
    },
    {
        ["left"] = {68, 132},
        ["right"] = {77, 142}
    },
    {
        ["left"] = {77, 65},
        ["right"] = {87, 73}
    },
    {
        ["left"] = {176, 158},
        ["right"] = {188, 169}
    },
    {
        ["left"] = {175, 62},
        ["right"] = {188, 72}
    }
}

xinsanhuan_2.g_BossYaoWangPos = {127, 118}

xinsanhuan_2.g_BossPos = {
    {132, 196},
    {72, 135},
    {83, 72},
    {182, 166},
    {181, 72}
}

xinsanhuan_2.g_monster15Pos = {
    {132, 199},
    {136, 200},
    {138, 196},
    {135, 192},
    {134, 189},
    {128, 192},
    {127, 197},
    {126, 202},
    {142, 202},
    {142, 196},
    {140, 190},
    {124, 195},
    {136, 187},
    {130, 204},
    {143, 192},
    {75, 136},
    {74, 144},
    {77, 138},
    {68, 142},
    {64, 138},
    {69, 128},
    {79, 128},
    {79, 131},
    {82, 139},
    {76, 146},
    {65, 143},
    {73, 133},
    {73, 129},
    {64, 133},
    {71, 140},
    {85, 73},
    {82, 75},
    {77, 75},
    {78, 79},
    {79, 68},
    {80, 66},
    {84, 64},
    {87, 67},
    {89, 69},
    {74, 70},
    {76, 62},
    {80, 60},
    {88, 62},
    {89, 76},
    {93, 68},
    {183, 168},
    {182, 172},
    {178, 168},
    {179, 163},
    {177, 160},
    {180, 158},
    {187, 160},
    {189, 163},
    {190, 168},
    {185, 156},
    {174, 166},
    {191, 161},
    {178, 173},
    {187, 173},
    {191, 172},
    {184, 74},
    {182, 78},
    {179, 75},
    {179, 83},
    {190, 76},
    {194, 74},
    {191, 63},
    {188, 60},
    {180, 61},
    {177, 62},
    {173, 68},
    {194, 62},
    {175, 74},
    {184, 58},
    {171, 63}
}

xinsanhuan_2.g_monster10Pos = {
    {132, 199},
    {136, 200},
    {138, 196},
    {135, 192},
    {134, 189},
    {128, 192},
    {127, 197},
    {126, 202},
    {142, 202},
    {142, 196},
    {75, 136},
    {74, 144},
    {77, 138},
    {68, 142},
    {64, 138},
    {69, 128},
    {79, 128},
    {79, 131},
    {82, 139},
    {76, 146},
    {85, 73},
    {82, 75},
    {77, 75},
    {78, 79},
    {79, 68},
    {80, 66},
    {84, 64},
    {87, 67},
    {89, 69},
    {74, 70},
    {183, 168},
    {182, 172},
    {178, 168},
    {179, 163},
    {177, 160},
    {180, 158},
    {187, 160},
    {189, 163},
    {190, 168},
    {185, 156},
    {184, 74},
    {182, 78},
    {179, 75},
    {179, 83},
    {190, 76},
    {194, 74},
    {191, 63},
    {188, 60},
    {180, 61},
    {177, 62}
}

xinsanhuan_2.g_NumText_Main = 1
xinsanhuan_2.g_NumText_EnterCopyScene = 2
xinsanhuan_2.g_CopySceneMap = "dumuchang.nav"
xinsanhuan_2.g_CopySceneArea = "dumuchang_area.ini"
xinsanhuan_2.g_CopySceneMonsterIni = "dumuchang_monster.ini"
xinsanhuan_2.g_client_res = 9266
xinsanhuan_2.g_CopySceneType = ScriptGlobal.FUBEN_XUANFOUZHU
xinsanhuan_2.g_LimitMembers = 3
xinsanhuan_2.g_TickTime = 5
xinsanhuan_2.g_LimitTotalHoldTime = 360
xinsanhuan_2.g_CloseTick = 6
xinsanhuan_2.g_NoUserTime = 30
xinsanhuan_2.g_Fuben_X = 220
xinsanhuan_2.g_Fuben_Z = 217
xinsanhuan_2.g_Back_X = 122
xinsanhuan_2.g_Back_Z = 56
xinsanhuan_2.g_TakeTimes = 5

function xinsanhuan_2:OnDefaultEvent(selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    local numText = index
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if numText == self.g_NumText_Main then
            if self:LuaFnGetAvailableItemCount(selfId, self.g_heyuanxin) < 1 then
                self:BeginEvent(self.script_id)
                self:AddText("#{LLFB_80816_21}")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            elseif self:CheckAccept(selfId, targetId) > 0 then
                self:BeginEvent(self.script_id)
                self:AddText("#{LLFB_80816_22}")
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
                self:AddText("#{LLFB_80816_24}")
                self:AddNumText("Tiến về Độc Chướng Trạch Địa", 10, self.g_NumText_EnterCopyScene)
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

function xinsanhuan_2:CheckConflictMission(selfId)
    if self:IsHaveMission(selfId, 1256) then
        return 1
    end
    if self:IsHaveMission(selfId, 1258) then
        return 1
    end
    return 0
end

function xinsanhuan_2:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckConflictMission(selfId) == 1 then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, self.g_NumText_Main)
end

function xinsanhuan_2:CheckAccept(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:CheckConflictMission(selfId) == 1 then
        return 0
    end
    local DayTimes, oldDate, nowDate, takenTimes
    DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_DAYTIME)
    oldDate = DayTimes % 100000
    takenTimes = math.floor(DayTimes / 100000)
    nowDate = self:GetDayTime()
    if nowDate ~= oldDate then
        takenTimes = 0
        self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_DAYTIME, nowDate)
    end
    if takenTimes >= self.g_TakeTimes then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_3}")
        return 0
    end
    --[[local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_LAST)
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
    if self:LuaFnGetTaskItemBagSpace(selfId) < 1 then
        self:NotifyFailTips(selfId, "Thiếu một ô không gian vật phẩm nhiệm vụ")
        return 0
    end
    if self:LuaFnGetAvailableItemCount(selfId, self.g_heyuanxin) < 1 then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_21}")
        return 0
    end
    return 1
end

function xinsanhuan_2:OnAccept(selfId, targetId)
    if not self:LuaFnDelAvailableItem(selfId, self.g_heyuanxin, 1) then
        self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_21}")
        return
    end
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_DAYTIME)
    local takenTimes = math.floor(DayTimes / 100000)
    DayTimes = (takenTimes + 1) * 100000 + self:GetDayTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_DAYTIME, DayTimes)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsBossYaoWang, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsFindGoods, 0)
    for i = 1, #(self.g_YinMoZhuID) do
        local num = self:LuaFnGetAvailableItemCount(selfId, self.g_YinMoZhuID[i])
        if num > 0 then
            self:LuaFnDelAvailableItem(selfId, self.g_YinMoZhuID[i], num)
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText("#{LLFB_80816_24}")
    self:AddNumText("Tiến về Độc Chướng Trạch Địa", 10, self.g_NumText_EnterCopyScene)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function xinsanhuan_2:AcceptEnterCopyScene(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        if copysceneid >= 0 then
            if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) == 2 then
                self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_23}")
            elseif self:IsCanEnterCopyScene(copysceneid, selfId) then
                local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
                self:NewWorld(selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
            else
                self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_23}")
            end
            return
        end
        if not self:LuaFnHasTeam(selfId) then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_25}")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_10}")
            return
        end
        local teamMemberCount = self:GetTeamMemberCount(selfId)
        local nearMemberCount = self:GetNearTeamCount(selfId)
        if not nearMemberCount or nearMemberCount < self.g_LimitMembers then
            self:NotifyFailBox(selfId, targetId, "#{LLFB_80816_26}")
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
        for i = 1, nearMemberCount  do
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
                local misIndex = self:GetMissionIndexByID(memberID, self.g_MissionId)
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
        config.params[7] = 0
        config.params[8] = 0
        config.params[9] = 0
        config.params[10] = 0
        config.params[11] = 0
        config.params[12] = 0
        config.params[13] = 0
        config.params[14] = 0
        config.params[15] = 0
        config.params[16] = 0
        config.event_area = self.g_CopySceneArea
        config.monsterfile = self.g_CopySceneMonsterIni
        config.sn 		 = self:LuaFnGenCopySceneSN()
        local bRetSceneID = self:LuaFnCreateCopyScene(config)
        if bRetSceneID > 0 then
            self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
            self:AuditXinSanHuanCreateFuben(selfId, 2)
        else
            self:NotifyFailTips(selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        end
    end
end

function xinsanhuan_2:OnCopySceneReady(destsceneId)
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
    local i, nearMemberCount, member
    local members = {}
    local validmembercount = 0
    nearMemberCount = self:GetNearTeamCount(leaderObjId)
    for i = 1, nearMemberCount  do
        member = self:GetNearTeamMember(leaderObjId, i)
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

function xinsanhuan_2:OnPlayerEnter(selfId)
end

function xinsanhuan_2:OnDie(objId, selfId)
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
    for i = 1, #(self.g_BossID) do
        if szName == self.g_BossID[i] then
            local dropthing = 0
            if i == 1 then
                dropthing = self.g_YinMoZhuID[3]
            elseif i == 2 then
            elseif i == 3 then
                dropthing = self.g_YinMoZhuID[5]
            elseif i == 4 then
                dropthing = self.g_YinMoZhuID[2]
            elseif i == 5 then
                dropthing = self.g_YinMoZhuID[4]
            end
            for j = 1, num do
                if self:LuaFnIsObjValid(mems[j]) and self:LuaFnIsCanDoScriptLogic(mems[j]) then
                    self:NotifyFailTips(mems[j], "Đã giết" .. self.g_BossID[i] .. "： 1/1")
                end
            end
            if i == 2 then
                self:LuaFnSetCopySceneData_Param(14, 1)
            else
                for j = 1, num do
                    if self:LuaFnIsObjValid(mems[j]) and self:LuaFnIsCanDoScriptLogic(mems[j]) then
                        self:AddMonsterDropItem(objId, mems[j], dropthing)
                    end
                end
            end
            return
        end
    end
    if szName == self.g_BossYaoWang then
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], "Đã giết" .. self.g_BossYaoWang .. "： 1/1")
                if self:IsHaveMission(mems[i], self.g_MissionId) then
                    local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                    self:SetMissionByIndex(mems[i], misIndex, self.g_IsBossYaoWang, 1)
                end
                self:AddMonsterDropItem(objId, mems[i], self.g_xuanfouzhu)
            end
        end
        self:LuaFnAddSweepPointByID(selfId, 5, 1)
        local BroadcastMsg = string.format(gbk.fromutf8("#{LLFB_80816_41}#W#{_INFOUSR%s}#{LLFB_80816_42}"), gbk.fromutf8(self:GetName(selfId)))
        self:BroadMsgByChatPipe(selfId, BroadcastMsg, 4)
        self:LuaFnSetCopySceneData_Param(4, 1)
        return
    end
end

function xinsanhuan_2:OnKillObject(selfId, objdataId, objId)
    local name = self:GetMonsterNamebyDataId(objdataId)
    if name == self.g_BossYaoWang then
        local num = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, num do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddSweepPointByID(mems[i], 5, 6)
        end
    end
end

function xinsanhuan_2:OnHumanDie(selfId, killerId)
end

function xinsanhuan_2:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function xinsanhuan_2:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText("Tốt, tiếp tục")
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function xinsanhuan_2:OnAbandon(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_LAST, CurTime)
    self:DelMission(selfId, self.g_MissionId)
    for i = 1, #(self.g_YinMoZhuID) do
        local num = self:LuaFnGetAvailableItemCount(selfId, self.g_YinMoZhuID[i])
        if num > 0 then
            self:LuaFnDelAvailableItem(selfId, self.g_YinMoZhuID[i], num)
        end
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    local sceneId = self:get_scene_id()
    if sceneId == copyscene and fubentype == self.g_CopySceneType then
        self:NotifyFailTips(selfId, "Nhiệm vụ thất bại!")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function xinsanhuan_2:OnCopySceneTimer(nowTime)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}
    for i = 1, membercount  do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount >= self.g_CloseTick then
            for i = 1, membercount  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:Exit(mems[i])
                end
            end
        else
            local strText = string.format("Ngươi sẽ rời khỏi Phó bản sau %d giây.", (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
            for i = 1, membercount  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:NotifyFailTips(mems[i], strText)
                end
            end
        end
    elseif TickCount == 1 then
        for i = 1, 5 do
            self:GenerateMonster(i)
        end
    elseif TickCount == self.g_LimitTotalHoldTime then
        for i = 1, membercount  do
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
    else
        local oldteamid = self:LuaFnGetCopySceneData_Param(6)
        for i = 1, membercount  do
            if
                self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and
                    oldteamid ~= self:GetTeamId(mems[i])
             then
                self:NotifyFailTips(mems[i], "Ngươi không ở trong đội ngũ chính xác, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        local isFireBoss = self:LuaFnGetCopySceneData_Param(14)
        local isYaoWang = self:LuaFnGetCopySceneData_Param(15)
        local NotifyTime = self:LuaFnGetCopySceneData_Param(16)
        local isPreNotify = 0
        if (TickCount * self.g_TickTime) % 60 == 0 and (TickCount * self.g_TickTime + 60) % 120 == 0 then
            isPreNotify = 1
            for i = 1, membercount  do
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    local Minute = math.floor((360 - TickCount) * self.g_TickTime / 60)
                    self:NotifyFailTips(mems[i], "Còn lại" .. Minute .. "Phút")
                end
            end
        end
        if TickCount < 180 and isFireBoss == 1 then
            if NotifyTime == 0 then
                for i = 1, membercount  do
                    if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                        local Minute = 0
                        if 180 - TickCount < 12 then
                            Minute = 1
                        else
                            Minute = math.floor((180 - TickCount) * self.g_TickTime / 60)
                        end
                        self:NotifyFailTips(mems[i], "#{LLFB_80819_6}" .. Minute .. "#{LLFB_80819_7}")
                    end
                end
                self:LuaFnSetCopySceneData_Param(16, TickCount)
            end
        elseif TickCount >= 180 and isFireBoss == 1 and isYaoWang == 0 then
            local mylevel = self:LuaFnGetCopySceneData_Param(7)
            local iniLevel = self:LuaFnGetCopySceneData_Param(8)
            local YaoWangID = self.BossYaoWangIDTbl[1]
            if self.BossYaoWangIDTbl[iniLevel] then
                YaoWangID = self.BossYaoWangIDTbl[iniLevel]
            end
            local monsterID =
                self:LuaFnCreateMonster(YaoWangID, self.g_BossYaoWangPos[1], self.g_BossYaoWangPos[2], 14, 268, 050221)
            self:SetLevel(monsterID, mylevel + 3)
            self:SetCharacterName(monsterID, self.g_BossYaoWang)
            self:MonsterTalk(monsterID, "Độc Chướng Trạch Địa", self.g_YaoWangTalk)
            self:LuaFnSetCopySceneData_Param(15, 1)
        end
        if isFireBoss == 1 and isYaoWang == 0 then
            local mylevel = self:LuaFnGetCopySceneData_Param(7)
            local iniLevel = self:LuaFnGetCopySceneData_Param(8)
            local YaoWangID = self.BossYaoWangIDTbl[1]
            if self.BossYaoWangIDTbl[iniLevel] then
                YaoWangID = self.BossYaoWangIDTbl[iniLevel]
            end
            local monsterID =
                self:LuaFnCreateMonster(YaoWangID, self.g_BossYaoWangPos[1], self.g_BossYaoWangPos[2], 14, 268, 050221)
            self:SetLevel(monsterID, mylevel + 3)
            self:SetCharacterName(monsterID, self.g_BossYaoWang)
            self:MonsterTalk(monsterID, "Độc Chướng Trạch Địa", self.g_YaoWangTalk)
            self:LuaFnSetCopySceneData_Param(15, 1)
        end
    end
end

function xinsanhuan_2:CheckSubmit(selfId)
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

function xinsanhuan_2:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckSubmit(selfId) == 1 then
        self:NotifyFailBox(selfId, targetId, self.g_MissionComplete)
        for i = 1, #(self.g_YinMoZhuID) do
            local num = self:LuaFnGetAvailableItemCount(selfId, self.g_YinMoZhuID[i])
            if num > 0 then
                self:LuaFnDelAvailableItem(selfId, self.g_YinMoZhuID[i], num)
            end
        end
        self:DelMission(selfId, self.g_MissionId)
        self:LuaFnAuditQuest(selfId, "Lâu Lan Liên Hoàn nhiệm vụ Huyền Phật Châu")
    end
end

function xinsanhuan_2:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function xinsanhuan_2:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function xinsanhuan_2:CheckAllXinfaLevel(selfId, level)
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

function xinsanhuan_2:IsMonster(selfId, flag)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        self:NotifyFailTips(selfId, "#{LLFB_80816_31}")
        return 0
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then
        self:NotifyFailTips(selfId, "#{LLFB_80816_31}")
        return 0
    end
    local nMonsterNum = self:GetMonsterCount()
    local nAliveMonsterNum = nMonsterNum
    for i = 1, nMonsterNum do
        local MonsterId = self:GetMonsterObjID(i)
        if (self:LuaFnIsCharacterLiving(MonsterId)) or (self:GetName(MonsterId) == "任道清") then
            nAliveMonsterNum = nAliveMonsterNum - 1
        end
    end
    if nAliveMonsterNum > 0 then
        self:NotifyFailTips(selfId, "#{LLFB_80819_5}")
        return 0
    end
    local posX, posZ = self:GetWorldPos(selfId)
    local inpostype = -1
    for i = 1, #(self.g_Pos) do
        if
            self.g_Pos[i]["left"][1] <= posX and posX <= self.g_Pos[i]["right"][1] and self.g_Pos[i]["left"][2] <= posZ and
                posZ <= self.g_Pos[i]["right"][2]
         then
            inpostype = i
            break
        end
    end
    if inpostype == -1 then
        self:NotifyFailTips(selfId, "#{LLFB_80816_31}")
        return 0
    end
    return 1
end

function xinsanhuan_2:GenerateMonster(flag)
    local ret = 0
    local inpostype = flag
    if flag >= 1 and flag <= 5 then
        local mylevel = self:LuaFnGetCopySceneData_Param(7)
        local iniLevel = self:LuaFnGetCopySceneData_Param(8)
        local isboss = self:LuaFnGetCopySceneData_Param(8 + flag)
        local monsterID = 0
        local monster15ID = self.Monster15IDTbl[1]
        if self.Monster15IDTbl[iniLevel] then
            monster15ID = self.Monster15IDTbl[iniLevel]
        end
        local monster10ID = self.Monster10IDTbl[1]
        if self.Monster10IDTbl[iniLevel] then
            monster10ID = self.Monster10IDTbl[iniLevel]
        end
        local bossID = self.BossIDTbl[flag][1]
        if self.BossIDTbl[flag][iniLevel] then
            bossID = self.BossIDTbl[flag][iniLevel]
        end
        if inpostype == flag then
            if isboss == 0 then
                for i = (flag - 1) * 15 + 1, flag * 15 do
                    monsterID =
                        self:LuaFnCreateMonster(
                        monster15ID,
                        self.g_monster15Pos[i][1],
                        self.g_monster15Pos[i][2],
                        14,
                        -1,
                        050221
                    )
                    self:SetLevel(monsterID, mylevel)
                    self:SetCharacterName(monsterID, self.g_Monster15ID)
                end
                local extAIScript = -1
                if flag == 1 then
                    extAIScript = 263
                elseif flag == 2 then
                    extAIScript = 267
                elseif flag == 3 then
                    extAIScript = 264
                elseif flag == 4 then
                    extAIScript = 265
                elseif flag == 5 then
                    extAIScript = 266
                end
                monsterID =
                    self:LuaFnCreateMonster(
                    bossID,
                    self.g_BossPos[flag][1],
                    self.g_BossPos[flag][2],
                    14,
                    extAIScript,
                    050221
                )
                self:SetLevel(monsterID, mylevel + 2)
                self:SetCharacterName(monsterID, self.g_BossID[flag])
                self:MonsterTalk(monsterID, "Độc Chướng Trạch Địa", self.g_BossTalk[flag])
                self:LuaFnSetCopySceneData_Param(8 + flag, 1)
                ret = 1
            else
                for i = (flag - 1) * 10 + 1, flag * 10 do
                    monsterID =
                        self:LuaFnCreateMonster(
                        monster10ID,
                        self.g_monster10Pos[i][1],
                        self.g_monster10Pos[i][2],
                        14,
                        -1,
                        050221
                    )
                    self:SetLevel(monsterID, mylevel)
                    self:SetCharacterName(monsterID, self.g_Monster10ID)
                end
            end
        else
            for i = (inpostype - 1) * 10 + 1, inpostype * 10 do
                monsterID =
                    self:LuaFnCreateMonster(
                    monster10ID,
                    self.g_monster10Pos[i][1],
                    self.g_monster10Pos[i][2],
                    14,
                    -1,
                    050221
                )
                self:SetLevel(monsterID, mylevel)
                self:SetCharacterName(monsterID, self.g_Monster10ID)
            end
        end
    end
    return ret
end

function xinsanhuan_2:PickupItem(selfId, itemId, bagidx)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    if itemId ~= self.g_xuanfouzhu then
        return
    end
    self:NotifyFailTips(selfId, "Đã tìm thấy Huyền Phật Châu: 1/1")
    self:NotifyFailTips(selfId, "Mục tiêu nhiệm vụ hoàn thành")
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsFindGoods, 1)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 1)
end

function xinsanhuan_2:CalSweepData(selfId)
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
    local YaoWangID = self.BossYaoWangIDTbl[1]
    if self.BossYaoWangIDTbl[iniLevel] then
        YaoWangID = self.BossYaoWangIDTbl[iniLevel]
    end
    if YaoWangID then
        drop_items = self:CalMonsterDropItems(YaoWangID)
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_DAYTIME)
    local takenTimes = math.floor(DayTimes / 100000)
    DayTimes = (takenTimes + 1) * 100000 + self:GetDayTime()
    self:DungeonDone(selfId, 5)
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINSANHUAN_2_DAYTIME, DayTimes)
    return drop_items, award_exp
end

return xinsanhuan_2
