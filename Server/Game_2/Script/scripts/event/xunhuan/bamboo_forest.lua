local gbk = require "wire_charset"
local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local bamboo_forest = class("bamboo_forest", script_base)
bamboo_forest.script_id = 050101
bamboo_forest.g_MissionId = 1261
bamboo_forest.g_Name = "花剑雨"
bamboo_forest.g_MissionKind = 8
bamboo_forest.g_MissionLevel = 10000
bamboo_forest.g_MissionName = "Trừ hại"
bamboo_forest.g_MissionInfo = "    "
bamboo_forest.g_MissionTarget =
    "    Hoa Kiếm Vũ#{_INFOAIM251,108,1,Hoa Kiếm Vũ} ở Tô Châu bảo ngươi giết 80 con gấu hoang, rồi giết Huyễn Hùng.#r    #{FQSH_090206_01}"
bamboo_forest.g_ContinueInfo =
    "    Các ngươi đã chuẩn bị xong thì hãy đến trúc lâm tiêu diệt Hồng Hùng Vương!"
bamboo_forest.g_SubmitInfo = "    Nhiệm vụ làm đến đâu rồi?"
bamboo_forest.g_MissionComplete =
    "    Nếu các ngươi đã giết Huyễn Hùng rồi, vậy theo lời hẹn, ta cũng nên nói cho các ngươi biết lai lịch tấm Lệnh Bài này. Các ngươi đem phong thư này giao cho Tiền Hoành Vũ#{_INFOAIM62,162,1,Tiền Hoành Vũ}, hắn tự nhiên sẽ hiểu tất cả."
bamboo_forest.g_IsMissionOkFail = 0
bamboo_forest.g_DemandKill = {
    {["id"] = 4120, ["num"] = 1}, {["id"] = 4110, ["num"] = 80}
}

bamboo_forest.g_Param_sceneid = 3
bamboo_forest.g_DemandKillGroup = {2, 1}

bamboo_forest.g_BossGroup = 2
bamboo_forest.g_Token = 40004315
bamboo_forest.g_Mail = 40004316
bamboo_forest.g_NumText_Main = 1
bamboo_forest.g_NumText_EnterCopyScene = 2
bamboo_forest.g_CopySceneMap = "zhulin.nav"
bamboo_forest.g_CopySceneArea = "zhulin_area.ini"
bamboo_forest.g_CopyScenePatrolPoint = "zhulin_patrolpoint.ini"
bamboo_forest.g_ClientRes = 3081
bamboo_forest.g_CopySceneMonsterIni = "zhulin_monster_%d.ini"
bamboo_forest.g_CopySceneType = ScriptGlobal.FUBEN_ZHULIN
bamboo_forest.g_LimitMembers = 3
bamboo_forest.g_LevelLimit = 30
bamboo_forest.g_TickTime = 5
bamboo_forest.g_LimitTotalHoldTime = 360
bamboo_forest.g_CloseTick = 6
bamboo_forest.g_NoUserTime = 300
bamboo_forest.g_Fuben_X = 97
bamboo_forest.g_Fuben_Z = 113
bamboo_forest.g_Back_X = 250
bamboo_forest.g_Back_Z = 107
bamboo_forest.g_Fuben_Relive_X = 97
bamboo_forest.g_Fuben_Relive_Z = 113
bamboo_forest.g_BroadcastMsg = {
    "#Y" .. bamboo_forest.g_Name ..
        ": #W#{_INFOUSR$N}#Pđại hiệp mạnh thật, một quyền đánh bẹp#{_BOSS46}#P. Có#{_INFOUSR$N}#Pđại hiệp ở đây, tên trộm vặt nào dám ngông cuồng?",
    "#Y" .. bamboo_forest.g_Name ..
        ": #W#{_INFOUSR$N}#P đại hiệp quả là lợi hại, quét ngang rừng trúc nhỏ Tô Châu. Một trận đấm đá túi bụi, không có #GHồng Hùng#P nào mà không giải quyết được.",
    "#Y" .. bamboo_forest.g_Name ..
        ": #W#{_INFOUSR$N}#P đại hiệp thật là mạnh, danh tiếng hiệp nghĩa lưu truyền muôn đời. Võ công lại càng không cần bàn, phàm là #GHồng Hùng#P đều bị ngài cho nổ đầu."
}

bamboo_forest.g_TakeTimes = 5
function bamboo_forest:OnDefaultEvent(selfId, targetId, arg, index)
    print("bamboo_forest:OnDefaultEvent =", selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then return end
    local numText = index
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if numText == self.g_NumText_Main then
            if self:CheckAccept(selfId) > 0 then
                self:BeginEvent(self.script_id)
                self:AddText(self.g_MissionName)
                self:AddText(
                    "    Không sai, ta quả thật có thể nói cho ngươi biết lai lịch của Lệnh Bài này, nhưng trước đó, ngươi phải giúp ta một việc.")
                self:AddText(
                    "    Ở ngoài thành Tô Châu trong rừng trúc có một đám gấu hoang, vốn dĩ chúng rất ôn thuận, nhưng từ khi một con Hồng Hùng làm Thủ lĩnh của đám gấu hoang này, chúng liền trở nên tàn bạo, xung quanh đã có không ít thôn xóm bị chúng tấn công, nhưng triều đình vẫn luôn không rảnh phái binh đến đối phó với lũ thú này, để tránh cho hương thân không phải chịu thêm nhiều tổn thương, ta phải nhanh chóng nghĩ cách trừ khử con Hồng Hùng đáng chết này.")
                self:AddText(
                    "    Nếu ngươi có thể giúp ta giết chết con Hồng Hùng này, ta sẽ nói cho ngươi biết lai lịch của Lệnh Bài này.")
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

function bamboo_forest:CheckConflictMission(selfId)
    for missionId = 1260, self.g_MissionId - 1 do
        if self:IsHaveMission(selfId, missionId) then return 1 end
    end
    for missionId = self.g_MissionId + 1, 1269 do
        if self:IsHaveMission(selfId, missionId) then return 1 end
    end
    return 0
end

function bamboo_forest:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name then return end
    if self:CheckConflictMission(selfId) == 1 then return end
    caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, self.g_NumText_Main)
end

function bamboo_forest:CheckAccept(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then return 0 end
    if self:CheckConflictMission(selfId) == 1 then return 0 end
    --[[local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2)
    local CurTime = self:GetQuarterTime()
    if iTime + 1 >= CurTime then
        self:NotifyFailTips(selfId, "放弃任务30分钟后才能再次接取")
        return 0
    end]]
    if self:LuaFnGetAvailableItemCount(selfId, self.g_Token) < 1 then
        self:NotifyFailTips(selfId, "    Yêu cầu #{_ITEM" .. self.g_Token .. "}。")
        return 0
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2_TIMES)
    local oldDate = DayTimes % 100000
    local takenTimes = math.floor(DayTimes / 100000)
    local nowDate = self:GetDayTime()
    if nowDate ~= oldDate then takenTimes = 0 end
    if takenTimes >= self.g_TakeTimes then
        self:NotifyFailTips(selfId, "Hôm nay ngài đã vượt quá số lần lĩnh nhiệm vụ rồi." .. self.g_TakeTimes .. "Xin hãy quay lại lĩnh vào ngày mai.")
        return 0
    else
        DayTimes = nowDate + takenTimes * 100000
        self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2_TIMES, DayTimes)
    end
    return 1
end

function bamboo_forest:AskEnterCopyScene(selfId, targetId)
    self:AddNumText("Đến #YTrúc Lâm#W", 10, self.g_NumText_EnterCopyScene)
end

function bamboo_forest:OnAccept(selfId, targetId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetMissionCount(selfId) >= 20 then
            self:NotifyFailBox(selfId, targetId, "    Nhật ký nhiệm vụ đã đầy, không thể tiếp nhận thêm nhiệm vụ.")
            return
        end
        if self:GetLevel(selfId) < self.g_LevelLimit then
            self:NotifyFailBox(selfId, targetId, "    Cấp độ của ngài còn chưa đủ cấp 30, nhiệm vụ này quá nguy hiểm, hãy luyện tập thêm rồi quay lại.")
            return
        end
        if self:CheckConflictMission(selfId) == 1 then return end
        if not self:LuaFnDelAvailableItem(selfId, self.g_Token, 1) then
            self:NotifyFailBox(selfId, targetId, "    Yêu cầu #{_ITEM" .. self.g_Token .. "}。")
            return
        end
        self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
        if not self:IsHaveMission(selfId, self.g_MissionId) then return end
        local DayTimes
        DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2_TIMES)
        DayTimes = DayTimes + 100000
        self:DungeonDone(selfId, 2)
        self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2_TIMES, DayTimes)
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

function bamboo_forest:AcceptEnterCopyScene(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        if copysceneid >= 0 then
            if self:IsCanEnterCopyScene(copysceneid, selfId) then
                local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
                self:NewWorld(selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z,self.g_ClientRes)
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
            self:NotifyFailBox(selfId, targetId, "    Ngươi không phải đội trưởng, chỉ đội trưởng mới có thể quyết định có chấp nhận ủy thác của ta hay không.")
            return
        end
        local teamMemberCount = self:GetTeamMemberCount(selfId)
        local nearMemberCount = self:GetNearTeamCount(selfId)
        if not teamMemberCount or not nearMemberCount or teamMemberCount ~= nearMemberCount then
            self:NotifyFailBox(selfId, targetId, "    Đội viên của ngươi vẫn còn người chưa đến gần.")
            return
        end
        if nearMemberCount < self.g_LimitMembers then
            self:NotifyFailBox(selfId, targetId, "    Trong rừng trúc có rất nhiều dã hùng, ít nhất các ngươi phải có 3 vị đồng bạn ta mới yên tâm để các ngươi đi. (Trong đội ít nhất Yêu cầu ba nhân vật cấp 30 trở lên)")
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
                misIndex = self:GetMissionIndexByID(member, self.g_MissionId)
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
            outDoingMissionStr = outDoingMissionStr ..
                                     ") Đã có người đang làm nhiệm vụ này rồi."
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
        -- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
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
        config.params[8] = 0
        config.params[9] = 0
        config.params[10] = 0
        config.params[11] = 0
        config.params[12] = 0
        config.params[13] = iniLevel / 10
        config.params[14] = 0
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

function bamboo_forest:OnCopySceneReady(destsceneId)
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
        self:NotifyFailTips(leaderObjId, "    Trong trúc lâm dã hùng rất nhiều, ít nhất các ngươi phải có 3 vị đồng bạn ta mới yên tâm để các ngươi đi.")
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

function bamboo_forest:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, -1, 0, self.g_Fuben_Relive_X, self.g_Fuben_Relive_Z)
end

function bamboo_forest:OnKillObject(selfId, objdataId, objId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then return end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then return end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then return end
    local GroupID = self:GetMonsterGroupID(objId)
    if GroupID == self.g_BossGroup then
        self:LuaFnSetCopySceneData_Param(12, 1)
        local monstercount = self:GetMonsterCount()
        local bossId
        for i = 1, monstercount do
            bossId = self:GetMonsterObjID(i)
            self:SetNPCAIType(bossId, 1)
            self:SetAIScriptID(bossId, 0)
            self:NpcToIdle(bossId)
        end
        local BroadcastMsg = self.g_BroadcastMsg[math.random(#(self.g_BroadcastMsg))]
        BroadcastMsg = string.gsub(BroadcastMsg, "%$N", self:GetName(selfId))
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
    if killedMonsterIndex == 0 then return end
    local maxKilledCount = self.g_DemandKill[killedMonsterIndex]["num"]
    local num = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    local strText = string.format("Đã giết %s: %d/%d", self:GetName(objId), killedCount, maxKilledCount)
    for i = 1, num do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(mems[i]) then
            self:NotifyFailTips(mems[i], strText)
           local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
            self:SetMissionByIndex(mems[i], misIndex, 3 - killedMonsterIndex, killedCount)
        end
    end
    local leaveFlag = 1
    for i = 1, #(self.g_DemandKillGroup) do
        if self:LuaFnGetCopySceneData_Param(7 + i - 1) <
            self.g_DemandKill[i]["num"] then
            leaveFlag = 0
            break
        end
    end
    if leaveFlag == 1 then
        self:LuaFnSetCopySceneData_Param(4, 1)
        for i = 1, num do
            if self:LuaFnIsObjValid(mems[i]) then
                self:NotifyFailTips(mems[i], "Mục tiêu nhiệm vụ hoàn thành, sắp rời Phó bản....")
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                self:SetMissionByIndex(mems[i], misIndex, self.g_IsMissionOkFail, 1)
                self:LuaFnAddSweepPointByID(mems[i], 2, 6)
            end
        end
    end
end

function bamboo_forest:OnHumanDie(selfId, killerId) end

function bamboo_forest:Exit(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function bamboo_forest:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function bamboo_forest:OnAbandon(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex,
                                           self.g_Param_sceneid)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2, CurTime)
    self:DelMission(selfId, self.g_MissionId)
    local sceneid = self:get_scene_id()
    if sceneid == copyscene then
        self:NotifyFailTips(selfId, "Nhiệm vụ thất bại!")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function bamboo_forest:OnCopySceneTimer(nowTime)
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
            local strText = string.format("Ngươi sẽ rời khỏi Phó bản sau %d giây.", (self.g_CloseTick - leaveTickCount) *self.g_TickTime)
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
                self:NotifyFailTips(mems[i],  "Ngươi không ở trong đội ngũ chính xác, rời khỏi cảnh....")
                self:Exit(mems[i])
            end
        end
        if self.g_TickTime * TickCount % 60 < self.g_TickTime and TickCount <
            self.g_LimitTotalHoldTime then
            local str = "Còn lại " .. (self.g_LimitTotalHoldTime - TickCount) * self.g_TickTime / 60 .. " phút..."
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:NotifyFailTips(mems[i], str)
                end
            end
        end
        local monstercount = self:GetMonsterCount()
        local x, z = self:GetLastPatrolPoint(0)
        for i = 1, monstercount do
            if self:LuaFnGetCopySceneData_Param(14) > 0 then break end
            local bossId = self:GetMonsterObjID(i)
            local GroupID = self:GetMonsterGroupID(bossId)
            if GroupID == self.g_BossGroup then
                local bossX, bossZ = self:GetWorldPos(bossId)
                if (x - bossX) * (x - bossX) + (z - bossZ) * (z - bossZ) < 25 then
                    self:NpcToIdle(bossId)
                    self:RestoreHp(bossId)
                    self:SetNPCAIType(bossId, 0)
                    self:SetAIScriptID(bossId, 129)
                    self:SetPatrolId(bossId, -1)
                    self:LuaFnSetCopySceneData_Param(14, 1)
                end
                break
            end
        end
    end
end

function bamboo_forest:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return 0 end
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

function bamboo_forest:OnSubmit(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then return end
    if self:CheckSubmit(selfId) == 1 then
        self:NotifyFailBox(selfId, targetId, self.g_MissionComplete)
        self:TryRecieveItem(selfId, self.g_Mail, 1)
        self:DelMission(selfId, self.g_MissionId)
        self:LuaFnAuditQuest(selfId, "Trúc Lâm")
        local strText = self.g_MissionName .. "Nhiệm vụ đã hoàn thành."
        self:NotifyFailTips(selfId, strText)
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:LuaFnAddSweepPointByID(selfId, 2, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "PlaySoundEffect", selfId, 66)
    end
end

function bamboo_forest:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function bamboo_forest:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function bamboo_forest:CalSweepData(selfId)
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
            if monster_name == "红熊王" then
                boss_id = monster.type
            end
        end
    end
    if boss_id then
        drop_items = self:CalMonsterDropItems(boss_id)
    end
    local DayTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2_TIMES)
    DayTimes = DayTimes + 100000
    self:SetMissionData(selfId, define.MD_ENUM.MD_ROUNDMISSION2_TIMES, DayTimes)
    return drop_items, award_exp
end

return bamboo_forest
