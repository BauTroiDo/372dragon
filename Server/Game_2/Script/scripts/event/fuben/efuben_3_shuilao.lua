local class = require "class"
local define = require "define"
local script_base = require "script_base"
local efuben_3_shuilao = class("efuben_3_shuilao", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
efuben_3_shuilao.script_id = 401020
efuben_3_shuilao.g_CopySceneName = "水牢"
efuben_3_shuilao.g_MissionId = 1055
efuben_3_shuilao.g_Name = "水牢"
efuben_3_shuilao.g_IfMissionElite = 1
efuben_3_shuilao.g_MissionKind = 1
efuben_3_shuilao.g_MissionRound = 7
efuben_3_shuilao.g_MissionName = "水牢"
efuben_3_shuilao.g_MissionInfo = "Giết hết toàn bộ quái vật, không chừa một con!"
efuben_3_shuilao.g_MissionTarget = "Tiêu diệt toàn bộ quái vật"
efuben_3_shuilao.g_ContinueInfo = "Ngươi hãy tiếp tục nỗ lực a!"
efuben_3_shuilao.g_MissionComplete = "Đa tạ, bọn ta cuối cùng cũng dám ra khỏi nhà rồi!"
efuben_3_shuilao.g_MoneyBonus = 9999
efuben_3_shuilao.g_Param_huan = 0
efuben_3_shuilao.g_Param_ok = 1
efuben_3_shuilao.g_Param_sceneid = 2
efuben_3_shuilao.g_Param_teamid = 3
efuben_3_shuilao.g_Param_killcount = 4
efuben_3_shuilao.g_Param_time = 5
efuben_3_shuilao.g_CopySceneType = ScriptGlobal.FUBEN_EXAMPLE
efuben_3_shuilao.g_LimitMembers = 3
efuben_3_shuilao.g_TickTime = 5
efuben_3_shuilao.g_LimitTotalHoldTime = 360
efuben_3_shuilao.g_LimitTimeSuccess = 500
efuben_3_shuilao.g_CloseTick = 6
efuben_3_shuilao.g_NoUserTime = 300
efuben_3_shuilao.g_DeadTrans = 1
efuben_3_shuilao.g_Fuben_X = 64
efuben_3_shuilao.g_Fuben_Z = 64
efuben_3_shuilao.g_Back_X = 234
efuben_3_shuilao.g_Back_Z = 69
efuben_3_shuilao.g_NeedMonsterGroupID = 1
efuben_3_shuilao.g_TotalNeedKillBoss = 10

function efuben_3_shuilao:OnDefaultEvent(selfId, targetId)
    if (self:IsHaveMission(selfId, self.g_MissionId)) then
        local bDone = self:CheckSubmit(selfId)
        if bDone == 0 then
            self:BeginEvent(self.script_id)
                self:AddText(self.g_MissionName)
                self:AddText("Ngươi đã chuẩn bị xong chưa!")
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, self.g_ScriptId, self.g_MissionId)
        elseif bDone == 1 then
            self:BeginEvent(self.script_id)
                self:AddText(self.g_MissionName)
                self:AddText(self.g_MissionComplete)
                self:AddText("Ngươi sẽ nhận được:")
                self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            self:DispatchMissionDemandInfo(selfId, targetId, self.g_ScriptId, self.g_MissionId, bDone)
        end
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionInfo)
            self:AddText("Mục tiêu nhiệm vụ:")
            self:AddText(self.g_MissionTarget)
            self:AddText("Ngươi sẽ nhận được:")
            self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.g_ScriptId, self.g_MissionId)
    end
end

function efuben_3_shuilao:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        --self:AddNumText(self.g_MissionName, 3, -1)
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 3, -1)
    elseif self:CheckAccept(selfId) > 0 then
        --self:AddNumText(self.g_MissionName, 4, -1)
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, -1)
    end
end

function efuben_3_shuilao:CheckTeamLeader(selfId)
    if not self:GetTeamId(selfId) then
        self:BeginEvent(self.script_id)
            self:AddText("Ngươi Yêu cầu gia nhập một đội ngũ.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local nearteammembercount = self:GetNearTeamCount(selfId)
    if nearteammembercount < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
            self:AddText("Số lượng thành viên trong đội của ngươi không đủ.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải đội trưởng.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    return nearteammembercount
end

function efuben_3_shuilao:CheckAccept(selfId)
    if not self:GetTeamId(selfId) then
        self:BeginEvent(self.script_id)
            self:AddText("Ngươi Yêu cầu gia nhập một đội ngũ.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local nearteammembercount = self:GetNearTeamCount(selfId)
    if nearteammembercount < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
            self:AddText("Số lượng thành viên trong đội của ngươi không đủ.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end

    if not self:LuaFnIsTeamLeader(selfId) then
        self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải đội trưởng.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local mems = {}
    for i = 1, nearteammembercount do
        mems[i] = self:GetNearTeamMember(selfId, i)
        if self:GetMissionCount(mems[i]) >= 20 then
            self:BeginEvent(self.script_id)
                self:AddText("Trong đội có người có nhật ký nhiệm vụ đã đầy.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        elseif self:IsHaveMission(mems[i], self.g_MissionId) then
            self:BeginEvent(self.script_id)
                self:AddText("Trong đội có người đã tiếp nhận nhiệm vụ này.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
    end
    return 1
end

function efuben_3_shuilao:OnAccept(selfId)
    local teamid = self:GetTeamId(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        local saveteamid = self:GetMissionParam(selfId, misIndex, self.g_Param_teamid)
        if copysceneid and teamid == saveteamid then
            self:NewWorld(selfId, copysceneid, self.g_Fuben_X, self.g_Fuben_Z)
        else
            self:BeginEvent(self.script_id)
                self:AddText("Điều kiện không phù hợp!")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    else
        if self:CheckAccept(selfId) <= 0 then
            return 0
        end
        local nearteammembercount = self:GetNearTeamCount(selfId)
        local mems = {}
        for i = 1, nearteammembercount do
            mems[i] = self:GetNearTeamMember(selfId, i)
            self:AddMission(mems[i], self.g_MissionId, self.g_ScriptId, 1, 0, 0)
            local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
            local huan = self:GetMissionData(selfId, self.g_MissionRound)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_huan, huan)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_ok, 0)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_sceneid, -1)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_teamid, teamid)
        end
        self:MakeCopyScene(selfId, nearteammembercount)
    end
end

function efuben_3_shuilao:OnAbandon(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    self:DelMission(selfId, self.g_MissionId)
    if self:GetSceneID() == copyscene then
        self:BeginEvent(self.script_id)
        self:AddText("Nhiệm vụ thất bại!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, self.g_Back_X, self.g_Back_Z)
    end
end

function efuben_3_shuilao:MakeCopyScene(selfId, nearmembercount)
    local mems = {}
    local mylevel = 0
    for i = 1, nearmembercount do
        mems[i] = self:GetNearTeamMember(selfId, i)
        mylevel = mylevel + self:GetLevel(mems[i])
    end
    mylevel = mylevel / nearmembercount
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = "shuilao.nav"
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
    config.params[6] = self:GetTeamId(selfId)
    config.params[7] = 0
    for i = 8,31 do
        config.params[i] = 0
    end
    if mylevel <= 10 then
        config.monsterfile = "shuilao_monster_10.ini"
    elseif mylevel <= 15 then
        config.monsterfile = "shuilao_monster_15.ini"
    elseif mylevel <= 20 then
        config.monsterfile = "shuilao_monster_20.ini"
    elseif mylevel <= 25 then
        config.monsterfile = "shuilao_monster_25.ini"
    elseif mylevel <= 30 then
        config.monsterfile = "shuilao_monster_30.ini"
    elseif mylevel <= 35 then
        config.monsterfile = "shuilao_monster_35.ini"
    elseif mylevel <= 40 then
        config.monsterfile = "shuilao_monster_40.ini"
    elseif mylevel <= 45 then
        config.monsterfile = "shuilao_monster_45.ini"
    elseif mylevel <= 50 then
        config.monsterfile = "shuilao_monster_50.ini"
    end
    config.sn = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        self:DelMission(selfId, self.g_MissionId)
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function efuben_3_shuilao:OnContinue(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid) then
        self:DispatchMissionContinueInfo(selfId, targetId, self.g_ScriptId, self.g_MissionId)
    end
end

function efuben_3_shuilao:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(888888, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Param_ok) then
        return 1
    else
        return 0
    end
end

function efuben_3_shuilao:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) > 0 then
        local strText_M,strText = "",""
        local iHuan = self:GetMissionData(selfId,ScriptGlobal.MD_SHUILAO_HUAN)
        iHuan = iHuan + 1
        local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHUILAO_DAYCOUNT)
        local iTime = (iDayCount % 100000)
        local iDayTime = iTime
        local iDayHuan = math.floor(iDayCount / 100000)
        local CurDaytime = self:GetDayTime()
        if CurDaytime == iDayTime then
            iDayHuan = iDayHuan + 1
        else
            iDayTime = CurDaytime
            iDayHuan = 1
        end
        iDayCount = iDayHuan * 100000 + CurDaytime
        local money = 100 * iDayHuan
        self:AddMoney(selfId, money)
        self:SetMissionData(selfId, ScriptGlobal.MD_SHUILAO_HUAN, iHuan)
        self:SetMissionData(selfId, ScriptGlobal.MD_SHUILAO_DAYCOUNT, iDayCount)
        self:BeginEvent(self.script_id)
        strText_M = self:format("Ngươi nhận được %d kim ngân", money)
        strText = self:format("Nhiệm vụ hoàn thành, hiện tại là Khuyên thứ %d", iDayHuan)
        self:AddText(strText)
        self:AddText(strText_M)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:DelMission(selfId, self.g_MissionId)
    end
end

function efuben_3_shuilao:OnKillObject(selfId, objdataId, objId)
    local sceneType = self:LuaFnGetSceneType()
    local strText = ""
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
    GroupID = self:GetMonsterGroupID(objId)
    if GroupID ~= self.g_NeedMonsterGroupID then
        return
    end
    local killedbossnumber = self:LuaFnGetCopySceneData_Param(7)
    killedbossnumber = killedbossnumber + 1
    self:LuaFnSetCopySceneData_Param(7, killedbossnumber)
    if killedbossnumber < self.g_TotalNeedKillBoss then
        self:BeginEvent(self.script_id)
        strText = self:format("Đã giết Boss %d/%d", killedbossnumber, self.g_TotalNeedKillBoss)
        self:AddText(strText)
        self:EndEvent()
        for i = 0, num - 1 do
            local humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:DispatchMissionTips(humanObjId)
            local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
            local killedcount = self:GetMissionParam(humanObjId, misIndex, self.g_Param_killcount)
            killedcount = killedcount + 1
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_killcount, killedcount)
        end
    elseif killedbossnumber >= self.g_TotalNeedKillBoss then
        self:LuaFnSetCopySceneData_Param(4, 1)
        TickCount = self:LuaFnGetCopySceneData_Param(2)
        for i = 0, num - 1 do
            local humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
            local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
            local killedcount = self:GetMissionParam(humanObjId, misIndex, self.g_Param_killcount)
            killedcount = killedcount + 1
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_killcount, killedcount)
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_ok, 1)
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_time, TickCount * self.g_TickTime)
            self:BeginEvent(self.script_id)
            strText = self:format("Nhiệm vụ hoàn thành, sẽ truyền tống đến vị trí lối vào sau %d giây.", self.g_CloseTick * self.g_TickTime)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(humanObjId)
        end
    end
end

function efuben_3_shuilao:OnEnterZone(selfId, zoneId)

end

function efuben_3_shuilao:OnItemChanged(selfId, itemdataId)

end

function efuben_3_shuilao:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    local nearteammembercount = self:GetNearTeamCount(leaderObjId)
    local mems = {}
    for i = 1, nearteammembercount do
        mems[i]  = self:GetNearTeamMember(leaderObjId, i)
        local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
        self:SetMissionByIndex(mems[i], misIndex, self.g_Param_sceneid, destsceneId)
        self:NewWorld(mems[i], destsceneId, self.g_Fuben_X, self.g_Fuben_Z)
    end
end

function efuben_3_shuilao:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, -1, 0, self.g_Fuben_X, self.g_Fuben_Z)
end

function efuben_3_shuilao:OnHumanDie(selfId, killerId)
    if self.g_DeadTrans == 1 then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_ok, 1)
        local TickCount = self:LuaFnGetCopySceneData_Param(2)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_time, TickCount * self.g_TickTime)
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, self.g_Back_X, self.g_Back_Z)
    end
end

function efuben_3_shuilao:OnCopySceneTimer(nowTime)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    local strText = ""
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount == self.g_CloseTick then
            local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            for i = 0, membercount - 1 do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                self:NewWorld(mems[i], oldsceneId, self.g_Back_X, self.g_Back_Z)
            end
        elseif leaveTickCount < self.g_CloseTick then
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            for i = 0, membercount - 1 do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                self:BeginEvent(self.script_id)
                strText = self:format("Ngươi sẽ rời khỏi cảnh sau %d giây!",(self.g_CloseTick - leaveTickCount) * self.g_TickTime)
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(mems[i])
            end
        end
    elseif TickCount == self.g_LimitTimeSuccess then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 0, membercount - 1 do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:BeginEvent(self.script_id)
                self:AddText("Hết thời gian nhiệm vụ, hoàn thành!")
            self:EndEvent()
            self:DispatchMissionTips(mems[i])
            local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_ok, 1)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_time, TickCount * self.g_TickTime)
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    elseif TickCount == self.g_LimitTotalHoldTime then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 0, membercount - 1 do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:DelMission(mems[i], self.g_MissionId)
            self:BeginEvent(self.script_id)
                self:AddText("Nhiệm vụ thất bại, quá thời gian!")
            self:EndEvent()
            self:DispatchMissionTips(mems[i])
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    else
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 0, membercount - 1 do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:IsHaveMission(mems[i], self.g_MissionId) then
                local oldteamid = self:LuaFnGetCopySceneData_Param(6)
                if oldteamid ~= self:GetTeamId(mems[i]) then
                    self:DelMission(mems[i], self.g_MissionId)
                    self:BeginEvent(self.script_id)
                        self:AddText("Nhiệm vụ thất bại, ngươi không ở trong đội đúng!")
                    self:EndEvent()
                    self:DispatchMissionTips(mems[i])
                    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
                    self:NewWorld(mems[i], oldsceneId, self.g_Back_X, self.g_Back_Z)
                end
            end
        end
    end
end
return efuben_3_shuilao