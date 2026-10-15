local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local boundary_between_song_and_liao = class("boundary_between_song_and_liao",
                                             script_base)
boundary_between_song_and_liao.script_id = 050100
boundary_between_song_and_liao.g_MissionId = 1260
boundary_between_song_and_liao.g_Name = "钱宏宇"
boundary_between_song_and_liao.g_MissionKind = 8
boundary_between_song_and_liao.g_MissionLevel = 10000
boundary_between_song_and_liao.g_MissionName = "Không thể để một ai chạy thoát"
boundary_between_song_and_liao.g_MissionInfo = "    "
boundary_between_song_and_liao.g_MissionTarget =
    "    Tiền Hoành Vũ ở Tô Châu#{_INFOAIM62,162,1,Tiền Hoành Vũ}bảo ngươi trong 30 phút dẫn dụ rồi giết chết Dư Độc.#r    #{FQSH_090206_01}"
boundary_between_song_and_liao.g_ContinueInfo =
    "    Trận chiến biên giới vô cùng quan trọng, tuyệt đối không thể khinh suất. Ngươi đã chuẩn bị sẵn sàng đến biên giới tiễu phỉ chưa?"
boundary_between_song_and_liao.g_SubmitInfo = "    Nhiệm vụ làm đến đâu rồi?"
boundary_between_song_and_liao.g_MissionComplete =
    "    Ngươi làm rất tốt, chúng ta có thể thông qua khối Lệnh Bài này tìm ra sào huyệt của bọn phỉ đồ. Hãy đến tiêu cục tìm Hoa Kiếm Vũ#{_INFOAIM251,109,1,Hoa Kiếm Vũ}, hắn có thể nói cho ngươi lai lịch của Lệnh Bài."
boundary_between_song_and_liao.g_IsMissionOkFail = 0
boundary_between_song_and_liao.g_DemandKill = {
    {["id"] = 4060, ["num"] = 50}, {["id"] = 4070, ["num"] = 10},
    {["id"] = 4080, ["num"] = 1}, {["id"] = 4090, ["num"] = 1},
    {["id"] = 4100, ["num"] = 1}
}

boundary_between_song_and_liao.g_Param_sceneid = 6
boundary_between_song_and_liao.g_DemandKillGroup = {4, 0, 1, 2, 3}

boundary_between_song_and_liao.g_DogfaceGroup = 0
boundary_between_song_and_liao.g_LittleBossGroup = 2
boundary_between_song_and_liao.g_ViceBossGroup = 1
boundary_between_song_and_liao.g_BossGroup = 3
boundary_between_song_and_liao.g_Token = 40004315
boundary_between_song_and_liao.g_NumText_Main = 1
boundary_between_song_and_liao.g_NumText_EnterCopyScene = 2
boundary_between_song_and_liao.g_ClientRes = 3079
boundary_between_song_and_liao.g_CopySceneMap = "songliao.nav"
boundary_between_song_and_liao.g_CopySceneArea = "songliao_area.ini"
boundary_between_song_and_liao.g_CopySceneMonsterIni = "songliao_monster_%d.ini"
boundary_between_song_and_liao.g_CopyScenePatrolPoint = "songliao_patrolpoint.ini"
boundary_between_song_and_liao.g_CopySceneType = ScriptGlobal.FUBEN_SONGLIAO
boundary_between_song_and_liao.g_LimitMembers = 3
boundary_between_song_and_liao.g_LevelLimit = 20
boundary_between_song_and_liao.g_TickTime = 5
boundary_between_song_and_liao.g_LimitTotalHoldTime = 360
boundary_between_song_and_liao.g_CloseTick = 6
boundary_between_song_and_liao.g_NoUserTime = 30
boundary_between_song_and_liao.g_LoadBossTick = 180
boundary_between_song_and_liao.g_LittleBoss = {
    4080, 4081, 4082, 4083, 4084, 4085, 4086, 4087, 4088, 4089, 34080, 34081,
    34082, 34083, 34084, 34085, 34086, 34087, 34088, 34089
}

boundary_between_song_and_liao.g_Dogface = {
    4070, 4071, 4072, 4073, 4074, 4075, 4076, 4077, 4078, 4079, 34070, 34071,
    34072, 34073, 34074, 34075, 34076, 34077, 34078, 34079
}

boundary_between_song_and_liao.g_DogfacePos = {
    {22, 70, 4}, {22, 70, 4}, {22, 70, 4}, {102, 67, 5}, {102, 67, 5},
    {102, 67, 5}, {75, 83, 6}, {75, 83, 6}, {49, 84, 7}, {49, 84, 7}
}

boundary_between_song_and_liao.g_Boss = {
    4100, 4101, 4102, 4103, 4104, 4105, 4106, 4107, 4108, 4109, 34100, 34101,
    34102, 34103, 34104, 34105, 34106, 34107, 34108, 34109
}

boundary_between_song_and_liao.g_Fuben_X = 60
boundary_between_song_and_liao.g_Fuben_Z = 9
boundary_between_song_and_liao.g_Back_X = 60
boundary_between_song_and_liao.g_Back_Z = 161
boundary_between_song_and_liao.g_Fuben_Relive_X = 60
boundary_between_song_and_liao.g_Fuben_Relive_Z = 15
boundary_between_song_and_liao.g_BroadcastMsg = {
    "#Y" .. boundary_between_song_and_liao.g_Name ..
        ": #{_BOSS45} đã chết rồi! Hắn đã bị anh hùng #{_INFOUSR$N} của chúng ta hạ gục! Kẻ nào sẽ đến chịu chết tiếp theo đây? #{_BOSS46}? Hay là #{_BOSS47}? Ha ha!",
    "#Y" .. boundary_between_song_and_liao.g_Name ..
        ": #{_INFOUSR$N} anh hùng của chúng ta, từ #GSong Liêu Biên Cảnh#P mang đến một tin tức vô cùng phấn khởi! Tên mã phỉ #Không từ thủ đoạn tàn ác #{_BOSS45} đã bị tiêu diệt!",
    "#Y" .. boundary_between_song_and_liao.g_Name ..
        ": #{_INFOUSR$N} anh hùng của chúng ta, mau tới xem đi! Một truyền kỳ sống, một đại hiệp #Chiến đấu hiệp của các đại hiệp, ồ yeah!"
}

boundary_between_song_and_liao.g_TakeTimes = 5
function boundary_between_song_and_liao:OnDefaultEvent(selfId, targetId, arg,
                                                       index)
    print("boundary_between_song_and_liao:OnDefaultEvent", selfId, targetId,
          arg, index)
    if self:GetName(targetId) ~= self.g_Name then return end
    local numText = index
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        print("numText =", numText, ";self.g_NumText_Main =",
              self.g_NumText_Main)
        if numText == self.g_NumText_Main then
            if self:CheckAccept(selfId) > 0 then
                self:BeginEvent(self.script_id)
                self:AddText(self.g_MissionName)
                self:AddText("    Cuối cùng cũng có người đến trừng trị bọn ác tặc này!")
                self:AddText(
                    "    Bọn phỉ đồ này ở biên cảnh vô cùng hung hãn, Đầu lĩnh là một tên mã phỉ tên là Dư Độc. Kẻ này vốn là kẻ bị Cái Bang ruồng bỏ, võ công cao cường lại cực giỏi dùng độc, chỉ có giết sạch hết tay chân của hắn đang giả dạng Lính Tống, Tống tướng mới có thể dụ hắn xuất hiện." ..
                        self:GetName(selfId) ..
                        "Để nhổ cỏ tận gốc đám phỉ đồ này, ngươi phải nhanh chóng tiêu diệt chúng, không được để một tên nào sống sót!")
                self:AddText("#{M_MUBIAO}")
                self:AddText(self.g_MissionTarget)
                self:EndEvent()
                self:DispatchMissionInfo(selfId, targetId, self.script_id,
                                         self.g_MissionId)
            end
        end
    else
        print("numText =", numText, ";self.g_NumText_Main =",
              self.g_NumText_Main)
        if numText == self.g_NumText_Main then
            local bDone = self:CheckSubmit(selfId)
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            print("bDone =", bDone)
            if bDone == 1 then
                self:AddText(self.g_SubmitInfo)
            else
                print("self.g_ContinueInfo =", self.g_ContinueInfo)
                self:AddText(self.g_ContinueInfo)
                self:AskEnterCopyScene(selfId, targetId)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
            self:EndEvent()
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,
                                           self.g_MissionId, bDone)
        elseif numText == self.g_NumText_EnterCopyScene then
            self:AcceptEnterCopyScene(selfId, targetId)
        end
    end
end

function boundary_between_song_and_liao:CheckConflictMission(selfId)
    for missionId = 1260, self.g_MissionId - 1 do
        if self:IsHaveMission(selfId, missionId) then return 1 end
    end
    for missionId = self.g_MissionId + 1, 1269 do
        if self:IsHaveMission(selfId, missionId) then return 1 end
    end
    return 0
end

function boundary_between_song_and_liao:OnEnumerate(caller, selfId, targetId,
                                                    arg, index)
    if self:GetName(targetId) ~= self.g_Name then return end
    if self:CheckConflictMission(selfId) == 1 then return end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4,
                                self.g_NumText_Main)
end

function boundary_between_song_and_liao:CheckAccept(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then return 0 end
    if self:CheckConflictMission(selfId) == 1 then return 0 end
    local DayTimes, oldDate, nowDate, takenTimes
    DayTimes =
        self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION1_TIMES)
    oldDate = DayTimes % 100000
    takenTimes = math.floor(DayTimes / 100000)
    nowDate = self:GetDayTime()
    if nowDate ~= oldDate then takenTimes = 0 end
    if takenTimes >= self.g_TakeTimes then
        self:NotifyFailTips(selfId,
                            "Hôm nay ngài đã vượt quá số lần lĩnh nhiệm vụ rồi." ..
                                self.g_TakeTimes ..
                                "Xin hãy quay lại lĩnh vào ngày mai.")
        return 0
    else
        DayTimes = nowDate + takenTimes * 100000
        self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION1_TIMES,
                            DayTimes)
    end
    return 1
end

function boundary_between_song_and_liao:AskEnterCopyScene(selfId, targetId)
    self:AddNumText("Đến biên cảnh", 10, self.g_NumText_EnterCopyScene)
end

function boundary_between_song_and_liao:OnAccept(selfId, targetId)
    print("boundary_between_song_and_liao:OnAccept =", selfId, targetId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetMissionCount(selfId) >= 20 then
            self:NotifyFailBox(selfId, targetId,
                               "    Nhật ký nhiệm vụ đã đầy, không thể tiếp nhận thêm nhiệm vụ.")
            return
        end
        if self:GetLevel(selfId) < self.g_LevelLimit then
            self:NotifyFailBox(selfId, targetId,
                               "    Cấp độ của ngươi còn chưa đủ cấp 30, không thể đảm đương nhiệm vụ này.")
            return
        end
        if self:CheckConflictMission(selfId) == 1 then return end
        self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
        if not self:IsHaveMission(selfId, self.g_MissionId) then return end
        local DayTimes
        DayTimes = self:GetMissionData(selfId,
                                       define.MD_ENUM.MD_ROUNDMISSION1_TIMES)
        DayTimes = DayTimes + 100000
        self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION1_TIMES, DayTimes)
        self:DungeonDone(selfId, 1)
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_ContinueInfo)
        self:AddText("#r    Ngươi đã tiếp nhận nhiệm vụ:" .. self.g_MissionName)
        self:AskEnterCopyScene(selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function boundary_between_song_and_liao:AcceptEnterCopyScene(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex,self.g_Param_sceneid)
        if copysceneid >= 0 then
            local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
            if self:IsCanEnterCopyScene(copysceneid, selfId) then
                self:NewWorld(selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes)
            else
                self:NotifyFailBox(selfId, targetId, "    Rất tiếc, nhiệm vụ của ngươi đã thất bại.")
            end
            return
        end
        if not self:LuaFnHasTeam(selfId) then
            self:NotifyFailBox(selfId, targetId, "    Việc tiễu phỉ không phải chuyện nhỏ, ngươi Yêu cầu phải có một đội ngũ hùng mạnh.")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
            self:NotifyFailBox(selfId, targetId, "    Ta Yêu cầu có được sự xác nhận của đội trưởng mới yên tâm để các ngươi đến biên cảnh.")
            return
        end
        local teamMemberCount = self:GetTeamMemberCount(selfId)
        local nearMemberCount = self:GetNearTeamCount(selfId)
        if not teamMemberCount or not nearMemberCount or teamMemberCount ~=
            nearMemberCount then
            self:NotifyFailBox(selfId, targetId, "    Đội viên của ngươi vẫn còn người chưa đến gần.")
            return
        end
        if nearMemberCount < self.g_LimitMembers then
            self:NotifyFailBox(selfId, targetId, "    Tiễu trừ gian tặc là việc không hề nhỏ, ta Yêu cầu vài vị bằng hữu có bản lĩnh tương đương giúp sức mới an tâm. (Trong đội ít nhất Yêu cầu ba nhân vật trên cấp 30)")
            return
        end
        local member, mylevel, numerator, denominator = 0, 0, 0, 0
        local outNotAcceptMissionStr = "Trong đội của ngươi có thành viên ("
        local notAcceptMissionCount = 0
        local outDoingMissionStr = "Trong đội của ngươi có thành viên ("
        local doingMissionCount = 0
        for i = 1, nearMemberCount do
            member = self:GetNearTeamMember(selfId, i)
            if not self:IsHaveMission(member, self.g_MissionId) then
                if notAcceptMissionCount == 0 then
                    outNotAcceptMissionStr =
                        outNotAcceptMissionStr .. self:GetName(member)
                else
                    outNotAcceptMissionStr =
                        outNotAcceptMissionStr .. "、" .. self:GetName(member)
                end
                notAcceptMissionCount = notAcceptMissionCount + 1
            end
            if notAcceptMissionCount == 0 then
                local misIndex = self:GetMissionIndexByID(member, self.g_MissionId)
                if self:GetMissionParam(member, misIndex, self.g_Param_sceneid) >=
                    0 then
                    if doingMissionCount == 0 then
                        outDoingMissionStr =
                            outDoingMissionStr .. self:GetName(member)
                    else
                        outDoingMissionStr =
                            outDoingMissionStr .. "、" .. self:GetName(member)
                    end
                    doingMissionCount = doingMissionCount + 1
                end
            end
            numerator = numerator + self:GetLevel(member) ^ 4
            denominator = denominator + self:GetLevel(member) ^ 3
        end
        if notAcceptMissionCount > 0 then
            outNotAcceptMissionStr = outNotAcceptMissionStr ..
                                         ") vẫn chưa nhận nhiệm vụ."
            self:NotifyFailBox(selfId, targetId, outNotAcceptMissionStr)
            return
        end
        if doingMissionCount > 0 then
            outDoingMissionStr = outDoingMissionStr ..
                                     ") Đã có người đang làm nhiệm vụ này rồi."
            self:NotifyFailBox(selfId, targetId, outDoingMissionStr)
            return
        end
        if denominator <= 0 then
            mylevel = 0
        else
            mylevel = numerator / denominator
        end
        local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
        local iniLevel
        if mylevel < 10 then
            iniLevel = 10
        elseif mylevel < PlayerMaxLevel then
            iniLevel = math.floor(mylevel / 10) * 10
        else
            iniLevel = PlayerMaxLevel
        end
        local leaderguid = self:LuaFnObjId2Guid(selfId)

        -- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
        local config = {}
        config.navmapname = self.g_CopySceneMap -- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
        config.client_res = self.g_ClientRes
        config.teamleader = leaderguid
        config.NoUserCloseTime = 1 * 1000
        config.Timer = self.g_TickTime * 1000
        config.params = {}
        config.params[0] = self.g_CopySceneType
        config.params[1] = self.script_id
        config.params[2] = 0
        config.params[3] = -1
        config.params[4] = 0
        config.params[5] = 0
        config.params[6] = self:GetTeamId(selfId)
        config.params[7] = 0
        config.params[8] = 0
        config.params[9] = 0
        config.params[10] = 0
        config.params[11] = 0
        config.params[12] = 0
        config.params[13] = iniLevel / 10
        config.params[14] = 0
        config.params[15] = 0
        config.params[19] = 0
        config.params[define.CopyScene_LevelGap] = mylevel - iniLevel
        config.eventfile = self.g_CopySceneArea
        config.patrolpoint = self.g_CopyScenePatrolPoint
        config.monsterfile = string.format(self.g_CopySceneMonsterIni, iniLevel)
        config.sn = self:LuaFnGenCopySceneSN()

        local bRetSceneID = self:LuaFnCreateCopyScene(config)
        if bRetSceneID > 0 then
            self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
        else
            self:NotifyFailTips(selfId,
                                "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        end
    end
end

function boundary_between_song_and_liao:OnCopySceneReady(destsceneId)
    local sceneid = self:get_scene_id()
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneid)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if leaderObjId == -1 then return end
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then return end
    local members = {}

    local validmembercount = 0
    local nearMemberCount = self:GetNearTeamCount(leaderObjId)
    for i = 1, nearMemberCount do
        local member = self:GetNearTeamMember(leaderObjId, i)
        if self:IsHaveMission(member, self.g_MissionId) then
            validmembercount = validmembercount + 1
            members[validmembercount] = member
        end
    end
    if validmembercount < self.g_LimitMembers then
        self:NotifyFailTips(leaderObjId, "    Tiễu trừ gian tặc là việc không hề nhỏ, ta Yêu cầu vài vị bằng hữu có bản lĩnh tương đương giúp sức mới an tâm. (Trong đội ít nhất Yêu cầu ba nhân vật trên cấp 30)")
        return
    end
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    for i = 1, validmembercount do
        local misIndex = self:GetMissionIndexByID(members[i], self.g_MissionId)
        if self:LuaFnIsCanDoScriptLogic(members[i]) then
            self:SetMissionByIndex(members[i], misIndex, self.g_Param_sceneid,destsceneId)
            self:NewWorld(members[i], destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes)
        end
    end
end

function boundary_between_song_and_liao:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, -1, 0, self.g_Fuben_Relive_X,
                                    self.g_Fuben_Relive_Z)
end

function boundary_between_song_and_liao:OnKillObject(selfId, objdataId, objId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then return end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then return end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then return end
    local GroupID = self:GetMonsterGroupID(objId)
    local killedMonsterIndex, killedCount = 0, 0
    for i = 1, #(self.g_DemandKillGroup) do
        if GroupID == self.g_DemandKillGroup[i] then
            killedMonsterIndex = i
            killedCount = self:LuaFnGetCopySceneData_Param(7 + i - 1) + 1
            self:LuaFnSetCopySceneData_Param(7 + i - 1, killedCount)
            break
        end
    end
    if killedMonsterIndex == 0 then return end
    if self.g_BossGroup == GroupID then
        local BroadcastMsg = self.g_BroadcastMsg[math.random(#(
                                                                 self.g_BroadcastMsg))]
        BroadcastMsg = string.gsub(BroadcastMsg, "$N", self:GetName(selfId))
        BroadcastMsg = gbk.fromutf8(BroadcastMsg)
        self:BroadMsgByChatPipe(selfId, BroadcastMsg, 4)
    end
    local maxKilledCount = self.g_DemandKill[killedMonsterIndex]["num"]
    local num = self:LuaFnGetCopyScene_HumanCount()
    local strText = string.format("Đã giết %s: %d/%d", self:GetName(objId),
                                killedCount, maxKilledCount)
    for i = 1, num do
        local humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(humanObjId) then
            self:NotifyFailTips(humanObjId, strText)
            --self:Msg2Player(humanObjId, strText,define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
            self:SetMissionByIndex(humanObjId, misIndex, killedMonsterIndex,
                                   killedCount)
            if self.g_BossGroup == GroupID then
                print("objId =", objId)
                self:AddMonsterDropItem(objId, humanObjId, self.g_Token)
                self:LuaFnAddSalaryPoint(selfId, 2, 1)
                self:LuaFnAddSweepPointByID(selfId, 1, 6)
                self:SetMissionByIndex(humanObjId, misIndex, self.g_IsMissionOkFail, 1)
            end
        end
    end
    if self.g_LittleBossGroup == GroupID then
        self:LuaFnSetCopySceneData_Param(12, 1)
    end
    local bigBossFlag = 1
    for i = 1, 4 do
        if self:LuaFnGetCopySceneData_Param(7 + i - 1) < self.g_DemandKill[i]["num"] then
            bigBossFlag = 0
            break
        end
    end
    if bigBossFlag == 1 then
        if self:LuaFnGetCopySceneData_Param(15) > 0 then return end
        local bossGrade = self:LuaFnGetCopySceneData_Param(13)
        if not self.g_Boss[bossGrade] then return end
        local LevelGap = self:LuaFnGetCopySceneData_Param(define.CopyScene_LevelGap)
        local bossId = self:LuaFnCreateMonster(self.g_Boss[bossGrade], 55, 67, 14, 126, -1)
        self:SetLevel(bossId, self:GetLevel(bossId) + LevelGap)
        self:SetCharacterTitle(bossId, "Biên Cảnh Đại Vương")
        self:SetMonsterGroupID(bossId, self.g_BossGroup)
        self:LuaFnSetCopySceneData_Param(15, 1)
    end
end

function boundary_between_song_and_liao:OnHumanDie(selfId, killerId) end

function boundary_between_song_and_liao:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function boundary_between_song_and_liao:OnAbandon(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex,
                                           self.g_Param_sceneid)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION1, CurTime)
    self:DelMission(selfId, self.g_MissionId)
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    local sceneid = self:get_scene_id()
    if sceneid == copyscene and fubentype == self.g_CopySceneType then
        self:NotifyFailTips(selfId, "Nhiệm vụ thất bại!")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function boundary_between_song_and_liao:OnCopySceneTimer(nowTime)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    for i = 1, membercount do mems[i] = self:LuaFnGetCopyScene_HumanObjId(i) end
    local LevelGap = self:LuaFnGetCopySceneData_Param(define.CopyScene_LevelGap)
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount >= self.g_CloseTick then
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:Exit(mems[i])
                end
            end
        else
            local strText = string.format("Ngươi sẽ rời khỏi Phó bản sau %d giây.",
                                        (self.g_CloseTick - leaveTickCount) *
                                            self.g_TickTime)
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:NotifyFailTips(mems[i], strText)
                end
            end
        end
    elseif TickCount == self.g_LimitTotalHoldTime then
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) then
                self:NotifyFailTips(mems[i],
                                    "Thời gian nhiệm vụ đã hết, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    else
        local oldteamid = self:LuaFnGetCopySceneData_Param(6)
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) and oldteamid ~=
                self:GetTeamId(mems[i]) then
                self:NotifyFailTips(mems[i],
                                    "Ngươi không ở trong đội ngũ chính xác, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        if (self.g_TickTime * TickCount % 60) < self.g_TickTime and TickCount <
            self.g_LimitTotalHoldTime then
            local str = "Còn lại " .. (self.g_LimitTotalHoldTime - TickCount) *
                            self.g_TickTime / 60 .. " phút..."
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:NotifyFailTips(mems[i], str)
                end
            end
        end
        local nSmall_Dog = self:LuaFnGetCopySceneData_Param(8)
        local nSmall_Fu = self:LuaFnGetCopySceneData_Param(19)
        local is_LittleBoss = 0
        if nSmall_Dog == 10 then is_LittleBoss = 1 end
        if TickCount == self.g_LoadBossTick or
            (is_LittleBoss == 1 and nSmall_Fu == 0) then
            local bossGrade = self:LuaFnGetCopySceneData_Param(13)
            if not self.g_LittleBoss[bossGrade] then return end
            local PosX, PosZ = 55, 66
            for i = 1, membercount do
                PosX = self:LuaFnGetWorldPos(mems[i])
                if self:LuaFnIsTeamLeader(mems[i]) then break end
            end
            local bossId = self:LuaFnCreateMonster(self.g_LittleBoss[bossGrade],
                                                   PosX, PosZ, 14, 124, -1)
            self:SetLevel(bossId, self:GetLevel(bossId) + LevelGap)
            self:LuaFnSetCopySceneData_Param(19, 1)
            self:SetMonsterGroupID(bossId, self.g_ViceBossGroup)
        end
        local flag = self:LuaFnGetCopySceneData_Param(12)
        if flag > 0 then
            if flag == 1 then
                self:LuaFnSetCopySceneData_Param(12, 2)
            elseif flag == 2 then
                self:LuaFnSetCopySceneData_Param(12, 0)
                local bossGrade = self:LuaFnGetCopySceneData_Param(13)
                if not self.g_Dogface[bossGrade] then return end
                for i = 1, #(self.g_DogfacePos) do
                    if self.g_DogfacePos[i] then
                        local dogfaceId = self:LuaFnCreateMonster(self.g_Dogface[bossGrade], self.g_DogfacePos[i][1], self.g_DogfacePos[i][2], 1, 4, -1)
                        self:SetLevel(dogfaceId, self:GetLevel(dogfaceId) + LevelGap)
                        self:SetMonsterGroupID(dogfaceId, self.g_DogfaceGroup)
                        self:SetPatrolId(dogfaceId, self.g_DogfacePos[i][3])
                    end
                end
            end
        end
        local monstercount = self:GetMonsterCount()
        local x, z = self:GetLastPatrolPoint(5)
        for i = 1, monstercount do
            local monsterId = self:GetMonsterObjID(i)
            local GroupID = self:GetMonsterGroupID(monsterId)
            if GroupID == self.g_DogfaceGroup and
                self:LuaFnIsCharacterLiving(monsterId) then
                local DogX, DogZ = self:GetWorldPos(monsterId)
                if (x - DogX) * (x - DogX) + (z - DogZ) * (z - DogZ) < 25 then
                    if self:LuaFnGetCopySceneData_Param(14) < 1 then
                        self:LuaFnSetCopySceneData_Param(14, 1)
                        for i = 1, membercount do
                            if self:LuaFnIsObjValid(mems[i]) then
                                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                                self:SetMissionByIndex(mems[i], misIndex, self.g_IsMissionOkFail, 2)
                                self:NotifyFailTips(mems[i],"Đào tẩu phỉ loại đã trốn thoát, tặc nhân đầu mục nghe phong thanh liền ẩn nặc, nhiệm vụ thất bại.")
                            end
                        end
                    end
                    self:LuaFnDeleteMonster(monsterId)
                end
            end
        end
    end
end

function boundary_between_song_and_liao:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id,
                                     self.g_MissionId)
end

function boundary_between_song_and_liao:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local nItemNum = self:GetItemCount(selfId, self.g_Token)
    if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) ~= 1 then
        return 0
    end
    if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) > 0 and nItemNum < 1 then
        return 1
    end
    if nItemNum > 0 then
        return 1
    end
end

function boundary_between_song_and_liao:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then return end
    if self:CheckSubmit(selfId) == 1 then
        local nItemNum = self:GetItemCount(selfId, self.g_Token)
        self:NotifyFailBox(selfId, targetId, self.g_MissionComplete)
        self:DelMission(selfId, self.g_MissionId)
        self:LuaFnAuditQuest(selfId, "Biên giới Tống Liêu")
        local strText = self.g_MissionName .. "Nhiệm vụ đã hoàn thành."
        if nItemNum < 1 then
            self:TryRecieveItem(selfId,self.g_Token)
        end
        self:NotifyFailTips(selfId, strText)
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:LuaFnAddSweepPointByID(selfId, 1, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "PlaySoundEffect",
                                selfId, 66)
    end
end

function boundary_between_song_and_liao:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function boundary_between_song_and_liao:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function boundary_between_song_and_liao:CalSweepData(selfId)
    local drop_items
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local mylevel = self:GetLevel(selfId)
    local iniLevel
    if mylevel < 10 then
        iniLevel = 10
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor(mylevel / 10) * 10
    else
        iniLevel = PlayerMaxLevel
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
    local grade = iniLevel / 10
    local boss_id = self.g_Boss[grade]
    if boss_id then
        drop_items = self:CalMonsterDropItems(boss_id)
    end
    local DayTimes, oldDate, nowDate, takenTimes
    DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION1_TIMES)
    oldDate = DayTimes % 100000
    takenTimes = math.floor(DayTimes / 100000)
    nowDate = self:GetDayTime()
    if nowDate ~= oldDate then takenTimes = 0 end
    takenTimes = takenTimes + 1
    DayTimes = nowDate + takenTimes * 100000
    self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION1_TIMES,
                        DayTimes)
    return drop_items, award_exp
end

return boundary_between_song_and_liao
