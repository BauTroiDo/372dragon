local gbk = require "wire_charset"
local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local field_fastness = class("field_fastness", script_base)
field_fastness.script_id = 050102
field_fastness.g_MissionId = 1262
field_fastness.g_Name = "钱宏宇"
field_fastness.g_MissionKind = 8
field_fastness.g_MissionLevel = 10000
field_fastness.g_MissionName = "Tiễu phỉ"
field_fastness.g_MissionInfo = "    Cuối cùng cũng tìm thấy sào huyệt của phỉ đồ rồi, %s, dưới đó còn có nhiệm vụ quan trọng hơn giao cho ngươi. Hãy đi giết Thủ lĩnh phỉ đồ Cát Vinh, vì gia viên của chúng ta!"
field_fastness.g_MissionTarget = "    Tiền Hoành Vũ ở Tô Châu#{_INFOAIM62,162,1,Tiền Hoành Vũ}bảo ngươi giết chết phỉ đồ Thủ lĩnh Cát Vinh.#r    #{FQSH_090206_01}"
field_fastness.g_ContinueInfo = "    Lần này đến sào huyệt phỉ đồ diệt phỉ tất sẽ gặp muôn vàn khó khăn, %s, ngươi đã chuẩn bị sẵn sàng chưa?"
field_fastness.g_SubmitInfo = "    Nhiệm vụ làm đến đâu rồi?"
field_fastness.g_MissionComplete = "    Xin chúc mừng #Yđiện hạ#W %s, cảm tạ ngài đã đích thân tiêu diệt #Gphỉ thủ#W, mang lại thái bình cho chúng ta. Xin nhận lấy những #Yphần thưởng#W này."
field_fastness.g_IsMissionOkFail = 0
field_fastness.g_DemandKill = {
    {["id"] = 4130, ["num"] = 1}
}

field_fastness.g_Param_sceneid = 2
field_fastness.g_k = 3323
field_fastness.g_b = 45613
field_fastness.g_DemandKillGroup = {0}

field_fastness.g_BossGroup = 0
field_fastness.g_Mail = 40004316
field_fastness.g_NumText_Main = 3
field_fastness.g_NumText_EnterCopyScene = 2
field_fastness.g_CopySceneMap = "yewai.nav"
field_fastness.g_CopyScenePatrolPoint = "yewai_patrolpoint.ini"
field_fastness.g_ClientRes = 3080
field_fastness.g_CopySceneArea = "yewai_area.ini"
field_fastness.g_CopySceneMonsterIni = "yewai_monster_%d.ini"
field_fastness.g_CopySceneType = ScriptGlobal.FUBEN_FEIZHAI
field_fastness.g_LimitMembers = 3
field_fastness.g_LevelLimit = 40
field_fastness.g_TickTime = 5
field_fastness.g_LimitTotalHoldTime = 360
field_fastness.g_CloseTick = 6
field_fastness.g_NoUserTime = 30
field_fastness.g_Fuben_X = 11
field_fastness.g_Fuben_Z = 24
field_fastness.g_Back_X = 60
field_fastness.g_Back_Z = 161
field_fastness.g_Fuben_Relive_X = 11
field_fastness.g_Fuben_Relive_Z = 24
field_fastness.g_BroadcastMsg = {
    "#Y" .. field_fastness.g_Name .. ": #PXin báo với mọi người một tin vui, #Yphỉ đồ Thủ lĩnh#W khét tiếng #{_BOSS47}#P, hôm nay đã bị #{_INFOUSR$N}#P đánh bại! Mọi người vỗ tay!",
    "#Y" .. field_fastness.g_Name .. ": #PHãy để chúng ta thỏa sức hoan hô, #Yphỉ đồ Thủ lĩnh#W #{_BOSS47}#P không thể tác oai tác quái nữa rồi, hắn đã chết dưới tay của #{_INFOUSR$N}#P, mọi người hoan hô đi!",
    "#Y" .. field_fastness.g_Name .. ":#{_BOSS47}#P đã chết! Từ hôm nay trở đi, chúng ta không cần phải sống trong lo sợ nữa! Hãy ca ngợi anh hùng của chúng ta: #{_INFOUSR$N}#P, ngươi thật thiên tài!"
}

field_fastness.g_TakeTimes = 5
field_fastness.g_RelationReward = 10
field_fastness.g_MaxRelation = 9999
function field_fastness:OnDefaultEvent(selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    local numText = index
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if numText == self.g_NumText_Main then
            if self:CheckAccept(selfId) > 0 then
                self:BeginEvent(self.script_id)
                self:AddText(self.g_MissionName)
                self:AddText(string.format(self.g_MissionInfo, self:GetName(selfId)))
                self:AddText("#{M_MUBIAO}")
                self:AddText(self.g_MissionTarget)
                self:EndEvent()
                self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
            end
        end
    else
        if numText == self.g_NumText_Main then
            local bDone = self:CheckSubmit(selfId)
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            if bDone == 1 then
                self:AddText(self.g_SubmitInfo)
            else
                self:AddText(string.format(self.g_ContinueInfo, self:GetName(selfId)))
                self:AskEnterCopyScene(selfId, targetId)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
            self:EndEvent()
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
        elseif numText == self.g_NumText_EnterCopyScene then
            self:AcceptEnterCopyScene(selfId, targetId)
        end
    end
end

function field_fastness:CheckConflictMission(selfId)
    for missionId = 1260, self.g_MissionId - 1 do
        if self:IsHaveMission(selfId, missionId) then
            return 1
        end
    end
    for missionId = self.g_MissionId + 1, 1269 do
        if self:IsHaveMission(selfId, missionId) then
            return 1
        end
    end
    return 0
end

function field_fastness:OnEnumerate(caller, selfId, targetId, arg, index)
    print("field_fastness:OnEnumerate =", caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckConflictMission(selfId) == 1 then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, self.g_NumText_Main)
end

function field_fastness:CheckAccept(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:CheckConflictMission(selfId) == 1 then
        return 0
    end
    --[[local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION3)
    local CurTime = self:GetQuarterTime()
    if iTime + 1 >= CurTime then
        self:NotifyFailTips(selfId, "放弃任务30分钟后才能再次接取")
        return 0
    end]]
    if not self:LuaFnGetAvailableItemCount(selfId, self.g_Mail) then
        self:NotifyFailTips(selfId, "    Yêu cầu #{_ITEM" .. self.g_Mail .. "}。")
        return 0
    end
    local DayTimes, oldDate, nowDate, takenTimes
    DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION3_TIMES)
    oldDate = DayTimes % 100000
    takenTimes = math.floor(DayTimes / 100000)
    nowDate = self:GetDayTime()
    if nowDate ~= oldDate then
        takenTimes = 0
    end
    if takenTimes >= self.g_TakeTimes then
        self:NotifyFailTips(selfId, "Hôm nay ngài đã vượt quá số lần lĩnh nhiệm vụ rồi." .. self.g_TakeTimes .. "Xin hãy quay lại lĩnh vào ngày mai.")
        return 0
    else
        DayTimes = nowDate + takenTimes * 100000
        self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION3_TIMES, DayTimes)
    end
    return 1
end

function field_fastness:AskEnterCopyScene(selfId, targetId)
    self:AddNumText("Đi đến Phỉ Trại nơi hoang dã.", 10, self.g_NumText_EnterCopyScene)
end

function field_fastness:OnAccept(selfId, targetId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetMissionCount(selfId) >= 20 then
            self:NotifyFailBox(selfId, targetId, "    Nhật ký nhiệm vụ đã đầy, không thể tiếp nhận thêm nhiệm vụ.")
            return
        end
        if self:GetLevel(selfId) < self.g_LevelLimit then
            self:NotifyFailBox(selfId, targetId, "    Cấp độ của ngài còn chưa đủ cấp 30, nhiệm vụ này quá nguy hiểm, hãy luyện tập thêm rồi quay lại.")
            return
        end
        if self:CheckConflictMission(selfId) == 1 then
            return
        end
        if not self:LuaFnDelAvailableItem(selfId, self.g_Mail, 1) then
            self:NotifyFailBox(selfId, targetId, "    Yêu cầu #{_ITEM" .. self.g_Mail .. "}。")
            return
        end
        self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
        if not self:IsHaveMission(selfId, self.g_MissionId) then
            return
        end
        local DayTimes
        DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION3_TIMES)
        DayTimes = DayTimes + 100000
        self:DungeonDone(selfId, 3)
        self:SetMissionData(selfId,  define.MD_ENUM.MD_ROUNDMISSION3_TIMES, DayTimes)
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(string.format(self.g_ContinueInfo, self:GetName(selfId)))
        self:AddText("#r    Ngươi đã tiếp nhận nhiệm vụ:" .. self.g_MissionName)
        self:AskEnterCopyScene(selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function field_fastness:AcceptEnterCopyScene(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
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
            self:NotifyFailBox(selfId, targetId, "    Ngươi một Cá nhân thế đơn lực bạc, chi bằng gọi thêm vài người giúp sức rồi quay lại.")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
            self:NotifyFailBox(selfId, targetId, "    Ta Yêu cầu có được đội trưởng xác nhận mới yên tâm để các ngươi đến Phỉ Trại.")
            return
        end
        local teamMemberCount = self:GetTeamMemberCount(selfId)
        local nearMemberCount = self:GetNearTeamCount(selfId)
        if not teamMemberCount or not nearMemberCount or teamMemberCount ~= nearMemberCount then
            self:NotifyFailBox(selfId, targetId, "    Đội viên của ngươi vẫn còn người chưa đến gần.")
            return
        end
        if nearMemberCount < self.g_LimitMembers then
            self:NotifyFailBox(selfId, targetId, "    Tiễu trừ gian tặc là việc không hề nhỏ, ta Yêu cầu vài vị bằng hữu có bản lĩnh tương đương giúp sức mới an tâm. (Trong đội ít nhất Yêu cầu ba nhân vật trên cấp 30)")
            return
        end
        if self:IsTeamFollow(selfId) then
            self:NotifyFailBox(selfId, targetId, "    Đội ngũ ở Trạng thái tổ đội theo sau không thể tiến vào Phó bản này.")
            return
        end
        local numerator, denominator = 0, 0
        local outNotAcceptMissionStr = "Trong đội của ngươi có thành viên ("
        local notAcceptMissionCount = 0
        local outDoingMissionStr = "Trong đội của ngươi có thành viên ("
        local doingMissionCount = 0
        for i = 1, nearMemberCount do
            local member = self:GetNearTeamMember(selfId, i)
            if not self:IsHaveMission(member, self.g_MissionId) then
                if notAcceptMissionCount == 0 then
                    outNotAcceptMissionStr = outNotAcceptMissionStr .. self:GetName(member)
                else
                    outNotAcceptMissionStr = outNotAcceptMissionStr .. "、" .. self:GetName(member)
                end
                notAcceptMissionCount = notAcceptMissionCount + 1
            end
            if notAcceptMissionCount == 0 then
                local misIndex = self:GetMissionIndexByID(member, self.g_MissionId)
                if self:GetMissionParam(member, misIndex, self.g_Param_sceneid) >= 0 then
                    if doingMissionCount == 0 then
                        outDoingMissionStr = outDoingMissionStr .. self:GetName(member)
                    else
                        outDoingMissionStr = outDoingMissionStr .. "、" .. self:GetName(member)
                    end
                    doingMissionCount = doingMissionCount + 1
                end
            end
            numerator = numerator + self:GetLevel(member) ^ 4
            denominator = denominator + self:GetLevel(member) ^ 3
        end
        if notAcceptMissionCount > 0 then
            outNotAcceptMissionStr = outNotAcceptMissionStr .. ") vẫn chưa nhận nhiệm vụ."
            self:NotifyFailBox(selfId, targetId, outNotAcceptMissionStr)
            return
        end
        if doingMissionCount > 0 then
            outDoingMissionStr = outDoingMissionStr .. ") Đã có người đang làm nhiệm vụ này rồi."
            self:NotifyFailBox(selfId, targetId, outDoingMissionStr)
            return
        end
        local mylevel
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
        local config = {}
        config.navmapname = self.g_CopySceneMap -- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
        config.client_res = self.g_ClientRes
        config.teamleader = leaderguid
        config.NoUserCloseTime = self.g_NoUserTime * 1000
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
        config.params[12] = 0
        config.params[13] = iniLevel / 10
        config.params[define.CopyScene_LevelGap] = mylevel - iniLevel
        config.eventfile = self.g_CopySceneArea
        config.patrolpoint = self.g_CopyScenePatrolPoint
        config.monsterfile = string.format(self.g_CopySceneMonsterIni, iniLevel)
        config.sn = self:LuaFnGenCopySceneSN()

        local bRetSceneID = self:LuaFnCreateCopyScene(config)
        if bRetSceneID > 0 then
            self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
        else
            self:NotifyFailTips(selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        end
    end
end

function field_fastness:OnCopySceneReady(destsceneId)
    local sceneid = self:get_scene_id()
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneid)
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
    if validmembercount < self.g_LimitMembers then
        self:NotifyFailTips(leaderObjId, "    Tiễu trừ gian tặc là việc không hề nhỏ, ta Yêu cầu vài vị bằng hữu có bản lĩnh tương đương giúp sức mới an tâm. (Trong đội ít nhất Yêu cầu ba nhân vật trên cấp 30)")
        return
    end
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    for i = 1, validmembercount do
        local misIndex = self:GetMissionIndexByID(members[i], self.g_MissionId)
        if self:LuaFnIsCanDoScriptLogic(members[i]) then
            self:SetMissionByIndex(members[i], misIndex, self.g_Param_sceneid, destsceneId)
            self:NewWorld(members[i], destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes)
        end
    end
end

function field_fastness:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, -1, 0, self.g_Fuben_Relive_X, self.g_Fuben_Relive_Z)
end

function field_fastness:OnKillObject(selfId, objdataId, objId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
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
    local GroupID = self:GetMonsterGroupID(objId)
    if GroupID == self.g_BossGroup then
        self:LuaFnSetCopySceneData_Param(12, 1)
        local BroadcastMsg = self.g_BroadcastMsg[math.random(#(self.g_BroadcastMsg))]
        BroadcastMsg = string.gsub(BroadcastMsg, "$N", self:GetName(selfId))
        BroadcastMsg = gbk.fromutf8(BroadcastMsg)
        self:BroadMsgByChatPipe(selfId, BroadcastMsg, 4)
    end
    local killedMonsterIndex, killedCount = 0, 0
    for i = 1, #(self.g_DemandKillGroup) do
        if GroupID == self.g_DemandKillGroup[i] then
            killedMonsterIndex = i
            killedCount = self:LuaFnGetCopySceneData_Param(7 + i - 1) + 1
            self:LuaFnSetCopySceneData_Param(7 + i - 1, killedCount)
            break
        end
    end
    if killedMonsterIndex == 0 then
        return
    end
    local maxKilledCount = self.g_DemandKill[killedMonsterIndex]["num"]
    local num = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    local strText = string.format("Đã giết %s: %d/%d", self:GetName(objId), killedCount, maxKilledCount)
    for i = 1, num do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(mems[i]) then
            self:NotifyFailTips(mems[i], strText)
            --self:Msg2Player(mems[i], strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
            self:SetMissionByIndex(mems[i], misIndex, killedMonsterIndex, killedCount)
        end
    end
    local leaveFlag = 1
    for i = 1, #(self.g_DemandKillGroup) do
        if self:LuaFnGetCopySceneData_Param(7 + i - 1) < self.g_DemandKill[i]["num"] then
            leaveFlag = 0
            break
        end
    end
    if leaveFlag == 1 then
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) then
                self:NotifyFailTips(mems[i], "Mục tiêu nhiệm vụ hoàn thành")
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                self:SetMissionByIndex(mems[i], misIndex, self.g_IsMissionOkFail, 1)
                self:LuaFnAddMissionHuoYueZhi(mems[i], 10)
                self:LuaFnAddSweepPointByID(mems[i], 3, 6)
            end
        end
    end
end

function field_fastness:OnHumanDie(selfId, killerId)
end

function field_fastness:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function field_fastness:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(string.format(self.g_MissionComplete, self:GetName(selfId)))
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function field_fastness:OnAbandon(selfId)
    if (not self:IsHaveMission(selfId, self.g_MissionId)) then
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION3, CurTime)
    self:DelMission(selfId, self.g_MissionId)
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    local sceneId = self:get_scene_id()
    if sceneId == copyscene and fubentype == self.g_CopySceneType then
        self:NotifyFailTips(selfId, "Nhiệm vụ thất bại!")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function field_fastness:OnCopySceneTimer(nowTime)
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
                if self:LuaFnIsObjValid(mems[i]) then
                    self:Exit(mems[i])
                end
            end
        else
            local strText = string.format("Ngươi sẽ rời khỏi Phó bản sau %d giây.", (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:NotifyFailTips(mems[i], strText)
                end
            end
        end
    elseif TickCount == self.g_LimitTotalHoldTime then
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) then
                self:NotifyFailTips(mems[i], "Thời gian nhiệm vụ đã hết, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    else
        local oldteamid = self:LuaFnGetCopySceneData_Param(6)
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) and oldteamid ~= self:GetTeamId(mems[i]) then
                self:NotifyFailTips(mems[i], "Ngươi không ở trong đội ngũ chính xác, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        if self.g_TickTime * TickCount % 60 < self.g_TickTime and TickCount < self.g_LimitTotalHoldTime then
            local str = "Còn lại " .. (self.g_LimitTotalHoldTime - TickCount) * self.g_TickTime / 60 .. " phút..."
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:NotifyFailTips(mems[i], str)
                end
            end
        end
    end
end

function field_fastness:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) ~= 1 then
        return 0
    end
    if self:LuaFnGetTaskItemBagSpace(selfId) < 1 then
        self:NotifyFailTips(selfId, "Thiếu một ô không gian vật phẩm nhiệm vụ")
        return 0
    end
    return 1
end

function field_fastness:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckSubmit(selfId) == 1 then
        self:NotifyFailBox(selfId, targetId, string.format(self.g_MissionComplete, self:GetName(selfId)))
        local exp = self:GetLevel(selfId) * self.g_k - self.g_b
        if exp < 1 then
            exp = 1
        end
        self:AddExp(selfId, exp)
        self:DelMission(selfId, self.g_MissionId)
        self:LuaFnAuditQuest(selfId, "Dã Ngoại Phỉ Trại")
        local strText = self.g_MissionName .. "Nhiệm vụ đã hoàn thành."
        self:NotifyFailTips(selfId, strText)
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        local newRelation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_QIANHONGYU) + self.g_RelationReward
        if self.g_MaxRelation < newRelation then
            newRelation = self.g_MaxRelation
        end
        self:LuaFnAddSweepPointByID(selfId, 3, 1)
        self:SetMissionData(selfId, define.MD_ENUM.MD_RELATION_QIANHONGYU, newRelation)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "PlaySoundEffect", selfId, 66)
    end
end

function field_fastness:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function field_fastness:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function field_fastness:CalSweepData(selfId)
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
    local boss_id
    for i = 0, monster_count - 1 do
        local key = string.format("monster%d", i)
        local monster = monster_file[key]
        if monster then
            award_exp = award_exp + self:CalMonsterAwardExp(monster.type)
            local monster_name = self:GetMonsterNamebyDataId(monster.type)
            if monster_name == "山寨大王" then
                boss_id = monster.type
            end
        end
    end
    if boss_id then
        drop_items = self:CalMonsterDropItems(boss_id)
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION3_TIMES)
    DayTimes = DayTimes + 100000
    self:SetMissionData(selfId,  define.MD_ENUM.MD_ROUNDMISSION3_TIMES, DayTimes)
    return drop_items, award_exp
end

return field_fastness
