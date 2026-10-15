local class                        = require "class"
local define                       = require "define"
local script_base                  = require "script_base"
local seek_treasure                = class("seek_treasure", script_base)
local ScriptGlobal                 = require "scripts.ScriptGlobal"
seek_treasure.script_id            = 808039
seek_treasure.g_CopySceneName      = "楼兰寻宝"
seek_treasure.g_activity_time      = {
    [1] = { ["startTime"] = 1930, ["endTime"] = 2200 }
    ,
    [2] = { ["startTime"] = 1130, ["endTime"] = 1430 }
}
seek_treasure.g_impact_Id          = 73
seek_treasure.g_TotalNeedKill      = 200
seek_treasure.g_MonsterChangeTime  = 90 * 1000
seek_treasure.g_CopySceneType      = ScriptGlobal.FUBEN_SEEK_TREASURE
seek_treasure.g_LimitMembers       = 3
seek_treasure.g_TickTime           = 5
seek_treasure.g_LimitTotalHoldTime = 720
seek_treasure.g_StartTickCount     = 7
seek_treasure.g_CloseTick          = 6
seek_treasure.g_NoUserTime         = 36
seek_treasure.g_Fuben_X            = 65
seek_treasure.g_Fuben_Z            = 94
seek_treasure.g_Back_X             = 163
seek_treasure.g_Back_Z             = 77
seek_treasure.g_Back_SceneId       = 186
seek_treasure.g_FuBen_Data         = {
    ["MapFile"] = "loulanxunbao.nav",
    ["AreaFile"] = "loulanxunbao_area.ini",
    ["MonsterFile"] = "loulanxunbao_monster.ini"
}
seek_treasure.g_MonsterFlushSpeed  = { { ["from"] = 1, ["to"] = 10, ["speed"] = 8 }
, { ["from"] = 11, ["to"] = 20, ["speed"] = 7 }
, { ["from"] = 21, ["to"] = 30, ["speed"] = 6 }
, { ["from"] = 31, ["to"] = 40, ["speed"] = 5 }
, { ["from"] = 41, ["to"] = 50, ["speed"] = 4 }
}
seek_treasure.g_MonsterFlushPos    = { { { 63, 81 }
, { 66, 83 }
, { 63, 85 }
, { 66, 87 }
}
, { { 65, 81 }
, { 63, 83 }
, { 66, 85 }
, { 63, 87 }
}
, { { 68, 81 }
, { 71, 82 }
, { 69, 85 }
, { 72, 87 }
}
, { { 71, 80 }
, { 68, 83 }
, { 72, 85 }
, { 69, 87 }
}
, { { 73, 79 }
, { 77, 80 }
, { 75, 84 }
, { 81, 85 }
}
, { { 75, 78 }
, { 74, 81 }
, { 79, 83 }
, { 77, 87 }
}
, { { 77, 77 }
, { 82, 76 }
, { 83, 81 }
, { 89, 80 }
}
, { { 79, 75 }
, { 80, 79 }
, { 85, 78 }
, { 86, 84 }
}
, { { 80, 73 }
, { 84, 72 }
, { 87, 75 }
, { 93, 74 }
}
, { { 80, 71 }
, { 83, 74 }
, { 89, 73 }
, { 91, 77 }
}
, { { 80, 69 }
, { 85, 67 }
, { 90, 70 }
, { 94, 67 }
}
, { { 81, 67 }
, { 85, 69 }
, { 90, 67 }
, { 94, 70 }
}
, { { 81, 65 }
, { 85, 62 }
, { 89, 64 }
, { 93, 62 }
}
, { { 81, 63 }
, { 85, 64 }
, { 89, 62 }
, { 94, 65 }
}
, { { 80, 61 }
, { 84, 57 }
, { 88, 59 }
, { 91, 55 }
}
, { { 80, 59 }
, { 84, 60 }
, { 88, 56 }
, { 92, 58 }
}
, { { 79, 57 }
, { 81, 53 }
, { 86, 53 }
, { 88, 49 }
}
, { { 78, 55 }
, { 82, 55 }
, { 85, 51 }
, { 89, 52 }
}
, { { 77, 53 }
, { 78, 48 }
, { 83, 48 }
, { 82, 43 }
}
, { { 76, 51 }
, { 79, 51 }
, { 80, 45 }
, { 86, 46 }
}
, { { 74, 50 }
, { 72, 45 }
, { 77, 43 }
, { 76, 39 }
}
, { { 71, 48 }
, { 75, 46 }
, { 74, 42 }
, { 79, 40 }
}
, { { 69, 48 }
, { 68, 44 }
, { 71, 41 }
, { 68, 36 }
}
, { { 67, 47 }
, { 70, 45 }
, { 68, 40 }
, { 72, 37 }
}
, { { 65, 47 }
, { 62, 44 }
, { 65, 40 }
, { 61, 36 }
}
, { { 63, 47 }
, { 65, 43 }
, { 62, 40 }
, { 65, 36 }
}
, { { 61, 47 }
, { 58, 45 }
, { 58, 41 }
, { 54, 39 }
}
, { { 59, 48 }
, { 60, 44 }
, { 56, 42 }
, { 57, 38 }
}
, { { 57, 48 }
, { 53, 47 }
, { 53, 43 }
, { 48, 42 }
}
, { { 55, 49 }
, { 56, 46 }
, { 51, 45 }
, { 51, 41 }
}
, { { 53, 51 }
, { 49, 51 }
, { 48, 47 }
, { 43, 47 }
}
, { { 52, 53 }
, { 51, 49 }
, { 46, 49 }
, { 46, 44 }
}
, { { 51, 54 }
, { 46, 55 }
, { 44, 52 }
, { 39, 54 }
}
, { { 50, 56 }
, { 47, 53 }
, { 43, 54 }
, { 41, 50 }
}
, { { 49, 58 }
, { 45, 59 }
, { 42, 57 }
, { 37, 59 }
}
, { { 49, 60 }
, { 46, 57 }
, { 41, 59 }
, { 38, 57 }
}
, { { 48, 62 }
, { 44, 64 }
, { 41, 61 }
, { 37, 64 }
}
, { { 48, 64 }
, { 44, 62 }
, { 40, 64 }
, { 37, 62 }
}
, { { 48, 66 }
, { 45, 68 }
, { 41, 66 }
, { 38, 69 }
}
, { { 48, 67 }
, { 44, 66 }
, { 41, 69 }
, { 37, 67 }
}
, { { 48, 69 }
, { 46, 72 }
, { 42, 71 }
, { 40, 74 }
}
, { { 49, 71 }
, { 45, 70 }
, { 43, 73 }
, { 39, 72 }
}
, { { 49, 72 }
, { 48, 76 }
, { 44, 75 }
, { 42, 79 }
}
, { { 50, 74 }
, { 47, 74 }
, { 44, 77 }
, { 41, 76 }
}
, { { 51, 76 }
, { 51, 80 }
, { 46, 80 }
, { 46, 84 }
}
, { { 53, 78 }
, { 49, 78 }
, { 48, 82 }
, { 43, 82 }
}
, { { 55, 78 }
, { 56, 82 }
, { 51, 84 }
, { 54, 87 }
}
, { { 57, 79 }
, { 53, 81 }
, { 55, 85 }
, { 50, 86 }
}
, { { 59, 80 }
, { 60, 83 }
, { 58, 85 }
, { 60, 87 }
}
, { { 61, 81 }
, { 58, 83 }
, { 60, 85 }
, { 57, 87 }
}
}
seek_treasure.g_NianShouCreatePos  = { { 34, 65 }
, { 38, 49 }
, { 43, 42 }
, { 73, 35 }
, { 91, 48 }
, { 95, 60 }
, { 92, 78 }
, { 80, 91 }
, { 48, 91 }
, { 97, 66 }
}
seek_treasure.g_NianShouId         = { 12206, 12207, 12208, 12209, 12210, 12210 }
seek_treasure.g_BossPos            = { ["x"] = 64, ["z"] = 64 }
seek_treasure.g_SmallMonsterId     = {}
seek_treasure.g_SmallMonsterId[1]  = { 12102, 12103, 12104, 12105, 12106, 12107, 12108, 12109, 12110 }
seek_treasure.g_SmallMonsterId[2]  = { 12111, 12112, 12113, 12114, 12115, 12116, 12117, 12118, 12119 }
seek_treasure.g_MiddleMonsterId    = {}
seek_treasure.g_MiddleMonsterId[1] = { 12120, 12121, 12122, 12123, 12124, 12125, 12126, 12127, 12128 }
seek_treasure.g_MiddleMonsterId[2] = { 12129, 12130, 12131, 12132, 12133, 12134, 12135, 12136, 12137 }
seek_treasure.g_BossMonsterId      = { 12138, 12139, 12140, 12141, 12142, 12143, 12144, 12145, 12146 }
function seek_treasure:OnDefaultEvent(selfId, targetId, index, arg)
    local id = index
    if id == 1 then
        if self:IsOpenNow() == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("    #{LLXB_8815_09}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local ret, msg = self:CheckEnterCondition(selfId)
        if ret == 0 then
            self:RetDlg(selfId, targetId, msg)
            return
        end
        if self:CheckMemberInfo(selfId, targetId) ~= 1 then
            return
        end
        self:MakeCopyScene(selfId)
    elseif id == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{LLXB_8815_08}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function seek_treasure:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "楼兰寻宝", 6, 1)
    caller:AddNumTextWithTarget(self.script_id, "Lâu Lan Tầm Bảo hoạt động trợ giúp", 11, 2)
end

function seek_treasure:OnDie(objId, killerId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then
        return
    end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(12)
    if leaveFlag == 1 then
        return
    end
    local num = self:LuaFnGetCopyScene_HumanCount()
    local killednumber = self:LuaFnGetCopySceneData_Param(7)
    killednumber = killednumber + 1
    local humanObjId
    local strText
    self:LuaFnSetCopySceneData_Param(7, killednumber)
    if killednumber <= self.g_TotalNeedKill then
        for i = 1, num do
            humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(humanObjId) and self:LuaFnIsCanDoScriptLogic(humanObjId) then
                self:BeginEvent(self.script_id)
                strText = string.format("Đã tiêu diệt quái vật %d/%d", killednumber, self.g_TotalNeedKill)
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(humanObjId)
            end
        end
        if killednumber == self.g_TotalNeedKill then
            self:LuaFnSetCopySceneData_Param(15, 1)
            for i = 1, num do
                humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(humanObjId) and self:LuaFnIsCanDoScriptLogic(humanObjId) then
                    self:LuaFnSendSpecificImpactToUnit(objId, objId, humanObjId, self.g_impact_Id, 0)
                end
            end
        end
    elseif killednumber > self.g_TotalNeedKill then
        self:LuaFnSetCopySceneData_Param(12, 1)
        for i = 1, num do
            humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(humanObjId) and self:LuaFnIsCanDoScriptLogic(humanObjId) then
                self:LuaFnAddMissionHuoYueZhi(humanObjId,21)
                self:BeginEvent(self.script_id)
                strText = string.format("Nhiệm vụ hoàn thành, sẽ truyền tống đến vị trí lối vào sau %d giây.",
                    self.g_CloseTick * self.g_TickTime)
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(humanObjId)
            end
        end
        self:playNotify(killerId)
    end
end

function seek_treasure:playNotify(killerId)
    local playerName = self:GetName(killerId)
    local msg = {}
    local playerID = killerId
    local objType = self:GetCharacterType(killerId)
    if objType == 3 then
        playerID = self:GetPetCreator(killerId)
        playerName = self:GetName(playerID)
    end
    local leaderID = self:GetTeamLeader(playerID)
    if leaderID ~= -1 then
        playerName = self:GetName(leaderID)
    end
    local str  = string.format("#{_INFOUSR%s}#{LLXB_8815_15}#{_BOSS94}#{LLXB_8815_16}", playerName)
    msg[1]     = str
    str        = string.format("#{_BOSS94}#{LLXB_8815_17}#{_INFOUSR%s}#{LLXB_8815_18}", playerName)
    msg[2]     = str
    str        = string.format("#{_INFOUSR%s}#{LLXB_8815_19}#{_BOSS94}#{LLXB_8815_20}", playerName)
    msg[3]     = str
    str        = string.format("#{LLXB_8815_21}#{_INFOUSR%s}#{LLXB_8815_22}#{_BOSS94}#{LLXB_8815_23}", playerName)
    msg[4]     = str
    local rand = math.random(4)
    --self:LuaFnAddSalaryPoint(killerId, 9, 1)
    if playerName ~= nil then
        self:AddGlobalCountNews(msg[rand])
    end
end

function seek_treasure:OnHumanDie(selfId, killerId)
end

function seek_treasure:OnCopySceneTimer(nowTime)
    local msg, strText = "", ""
    local leaveTickCount = ""
    local tickCount = self:LuaFnGetCopySceneData_Param(2)
    tickCount = tickCount + 1
    self:LuaFnSetCopySceneData_Param(2, tickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(12)
    local oldsceneId
    if leaveFlag == 1 then
        leaveTickCount = self:LuaFnGetCopySceneData_Param(16)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(16, leaveTickCount)
        oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        if leaveTickCount >= self.g_CloseTick then
            oldsceneId = self:LuaFnGetCopySceneData_Param(3)
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            for i = 1, membercount do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:CallScriptFunction((400900), "TransferFunc", mems[i], 186, self.g_Back_X, self.g_Back_Z)
                end
            end
        elseif leaveTickCount < self.g_CloseTick then
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            for i = 1, membercount do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                    self:BeginEvent(self.script_id)
                    strText = string.format("Ngươi sẽ rời khỏi cảnh sau %d giây!",
                        (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(mems[i])
                end
            end
        end
    elseif tickCount >= self.g_LimitTotalHoldTime then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, membercount do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:BeginEvent(self.script_id)
                self:AddText("Nhiệm vụ thất bại, quá thời gian!")
                self:EndEvent()
                self:DispatchMissionTips(mems[i])
            end
        end
        self:LuaFnSetCopySceneData_Param(12, 1)
    elseif tickCount < self.g_StartTickCount then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, membercount do
            local objId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(objId) and self:LuaFnIsCanDoScriptLogic(objId) then
                local tm = (self.g_StartTickCount - tickCount) * self.g_TickTime
                self:BeginEvent(self.script_id)
                local msg = string.format("Sau %d giây sẽ bắt đầu Chiến đấu!", tm)
                self:AddText(msg)
                self:EndEvent()
                self:DispatchMissionTips(objId)
            end
        end
    elseif tickCount == self.g_StartTickCount then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, membercount do
            local objId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(objId) and self:LuaFnIsCanDoScriptLogic(objId) then
                self:BeginEvent(self.script_id)
                self:AddText("Chiến đấu đã bắt đầu")
                self:EndEvent()
                self:DispatchMissionTips(objId)
            end
        end
        local grade = self:LuaFnGetCopySceneData_Param(10)
        local mstColor = self:LuaFnGetCopySceneData_Param(11)
        local mstLvl = self:LuaFnGetCopySceneData_Param(13)
        local mstId = self.g_SmallMonsterId[1][grade]
        for i, pos in pairs(self.g_MonsterFlushPos[1]) do
            local objId = self:LuaFnCreateMonster(mstId, pos[1], pos[2], 7, -1, 808039)
            self:SetLevel(objId, mstLvl)
        end
        self:LuaFnSetCopySceneData_Param(11, 2)
        self:LuaFnSetCopySceneData_Param(9, tickCount)
        self:LuaFnSetCopySceneData_Param(8, 2)
    else
        local bActive = self:IsOpenNow()
        if bActive and bActive == 1 then
        else
            self:LuaFnSetCopySceneData_Param(12, 1)
            return
        end
        local monsterCount = self:GetMonsterCount() 
        if monsterCount > 0 then
            for i = 1, monsterCount do
                local monsterObjId = self:GetMonsterObjID(i)
                if self:LuaFnIsCharacterLiving(monsterObjId) then
                    local monstertype = self:GetMonsterDataID(monsterObjId)
                    local monsterLevel = self:GetLevel(monsterObjId)
                    local mcreatetime = self:GetObjCreateTime(monsterObjId)
                    local PosX, PosZ = self:LuaFnGetWorldPos(monsterObjId)
                    PosX = math.floor(PosX)
                    PosZ = math.floor(PosZ)
                    for j = 1, 2 do
                        for i, record in pairs(self.g_SmallMonsterId[j]) do
                            if monstertype == record then
                                if nowTime >= mcreatetime + self.g_MonsterChangeTime then
                                    self:LuaFnDeleteMonster(monsterObjId)
                                    monsterObjId = self:LuaFnCreateMonster(self.g_MiddleMonsterId[j][i], PosX, PosZ, 0, 19,
                                        808039)
                                    if monsterObjId and monsterObjId > -1 then
                                        self:SetLevel(monsterObjId, monsterLevel)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        local grade = self:LuaFnGetCopySceneData_Param(10)
        local mstColor = self:LuaFnGetCopySceneData_Param(11)
        local mstLvl = self:LuaFnGetCopySceneData_Param(13)
        local oldFlushMonsterTime = self:LuaFnGetCopySceneData_Param(9)
        local monsterBatch = self:LuaFnGetCopySceneData_Param(8)
        local ret = nil
        for i, record in pairs(self.g_MonsterFlushSpeed) do
            if monsterBatch >= record["from"] and monsterBatch <= record["to"] then
                ret = i
                break
            end
        end
        if ret ~= nil then
            if oldFlushMonsterTime + self.g_MonsterFlushSpeed[ret]["speed"] <= tickCount then
                self:LuaFnSetCopySceneData_Param(14, 0)
                if mstColor == 1 then
                    self:LuaFnSetCopySceneData_Param(11, 2)
                elseif mstColor == 2 then
                    self:LuaFnSetCopySceneData_Param(11, 1)
                end
                local mstId = self.g_SmallMonsterId[mstColor][grade]
                if monsterBatch <= 50 and monsterBatch >= 1 then
                    for i, pos in pairs(self.g_MonsterFlushPos[monsterBatch]) do
                        local objId = self:LuaFnCreateMonster(mstId, pos[1], pos[2], 7, -1, 808039)
                        self:SetLevel(objId, mstLvl)
                    end
                    monsterBatch = monsterBatch + 1
                    self:LuaFnSetCopySceneData_Param(8, monsterBatch)
                end
                self:LuaFnSetCopySceneData_Param(9, tickCount)
                if monsterBatch == 31 then
                    self:LuaFnSetCopySceneData_Param(9, tickCount + 18 - 5)
                    self:LuaFnSetCopySceneData_Param(14, 1)
                    local membercount = self:LuaFnGetCopyScene_HumanCount()
                    for i = 1, membercount do
                        local objId = self:LuaFnGetCopyScene_HumanObjId(i)
                        if self:LuaFnIsObjValid(objId) and self:LuaFnIsCanDoScriptLogic(objId) then
                            self:ShowMsg(objId, "#{LLXB_8815_14}")
                        end
                    end
                end
            end
        end
        oldFlushMonsterTime = self:LuaFnGetCopySceneData_Param(9)
        if self:LuaFnGetCopySceneData_Param(14) == 1 then
            local diffCount = oldFlushMonsterTime + 5 - tickCount
            if diffCount <= 6 and diffCount >= 1 then
                local membercount = self:LuaFnGetCopyScene_HumanCount()
                for i = 1, membercount do
                    local objId = self:LuaFnGetCopyScene_HumanObjId(i)
                    if self:LuaFnIsObjValid(objId) and self:LuaFnIsCanDoScriptLogic(objId) then
                        local tm = diffCount * self.g_TickTime
                        msg = string.format("%d giây sau sẽ bắt đầu lại Chiến đấu!", tm)
                        self:ShowMsg(objId, msg)
                    end
                end
            end
        end
        local num = self:LuaFnGetCopySceneData_Param(15)
        if num > 0 then
            if num == 4 then
                local grade = self:LuaFnGetCopySceneData_Param(10)
                local mstLvl = self:LuaFnGetCopySceneData_Param(13)
                local objId = self:LuaFnCreateMonster(self.g_BossMonsterId[grade], self.g_BossPos["x"],
                    self.g_BossPos["z"], 0, 19, 808039)
                self:SetLevel(objId, mstLvl)
                self:CallScriptFunction((200060), "Paopao", "镇宝龙王", "Lâu Lan Tàng Bảo Động",
                    "Thế nhân tấp nập, đều vì lợi mà đến; thế nhân rộn ràng, đều vì lợi mà đi. Có bản lĩnh thì lên đây mà lấy!")
                self:LuaFnSetCopySceneData_Param(15, 0)
            else
                self:LuaFnSetCopySceneData_Param(15, num + 1)
            end
        end
    end
end

function seek_treasure:OnPlayerEnter(selfId)
    local tmDay = self:GetTime2Day()
    self:SetMissionDataEx(selfId, 150, tmDay)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, nil, 0, self.g_Fuben_X, self.g_Fuben_Z)
end

function seek_treasure:OnCopySceneReady(destsceneId)
    local sceneId = self:GetSceneID()
    self:LuaFnSetCopySceneData_Param(destsceneId, 3,sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
        return
    end
    if not self:LuaFnHasTeam(leaderObjId) then
        self:NewWorld(leaderObjId, destsceneId,sn, self.g_Fuben_X, self.g_Fuben_Z, 269)
    else
        if not self:IsCaptain(leaderObjId) then
            self:NewWorld(leaderObjId, destsceneId,sn, self.g_Fuben_X, self.g_Fuben_Z, 269)
        else
            local nearteammembercount = self:GetNearTeamCount(leaderObjId)
            local mems = {}
            for i = 1, nearteammembercount do
                mems[i] = self:GetNearTeamMember(leaderObjId, i)
                self:NewWorld(mems[i], destsceneId,sn, self.g_Fuben_X, self.g_Fuben_Z, 269)
            end
        end
    end
end

function seek_treasure:MakeCopyScene(selfId)
    local param0 = 4
    local param1 = 3
    local mylevel = 0
    local memId
    local tempMemlevel = 0
    local level0 = 0
    local level1 = 0
    local nearmembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearmembercount do
        memId = self:GetNearTeamMember(selfId, i)
        tempMemlevel = self:GetLevel(memId)
        level0 = level0 + (tempMemlevel ^ param0)
        level1 = level1 + (tempMemlevel ^ param1)
    end
    if level1 == 0 then
        mylevel = 0
    else
        mylevel = level0 / level1
    end
    if nearmembercount == -1 then
        mylevel = self:GetLevel(selfId)
    end
    local x
    local z
    x,z = self:LuaFnGetWorldPos(selfId)
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = self.g_FuBen_Data["MapFile"]
    config.client_res = 269
    config.teamleader = leaderguid
    config.NoUserCloseTime = 0
	config.Timer = self.g_TickTime * 1000
    config.params = {}
	config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
	config.params[2] = 0
    config.params[3] = -1
    config.params[4] = x
    config.params[5] = z
	config.params[6] = self:GetTeamId(selfId)
	config.params[7] = 0
    config.params[8] = 1
    config.params[9] = 0
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    if mylevel < 60 then
        iniLevel = 1
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor(mylevel / 10) - 5
    else
        iniLevel = PlayerMaxLevel / 10
    end
    config.params[10] = iniLevel
    config.params[11] = 1
    config.params[12] = mylevel
    for i = 13, 31 do
        config.params[i] = 0
    end
    config.params[define.CopyScene_LevelGap] = mylevel
    config.eventfile = self.g_FuBen_Data["AreaFile"]
	config.monsterfile = self.g_FuBen_Data["MonsterFile"]
    config.sn = self:LuaFnGenCopySceneSN()
	local bRetSceneID = self:LuaFnCreateCopyScene(config)
	local text
	if bRetSceneID > 0 then
		text = "Tạo phó bản thành công!"
	else
		text = "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!"
	end
	self:notify_tips(selfId, text)
end

function seek_treasure:ShowMsg(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function seek_treasure:RetDlg(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function seek_treasure:IsOpenNow()
    local hour = self:GetHour()
    local minute = self:GetMinute()
    local time = hour * 100 + minute
    if (time > self.g_activity_time[1]["startTime"] and time < self.g_activity_time[1]["endTime"]) or (time > self.g_activity_time[2]["startTime"] and time < self.g_activity_time[2]["endTime"]) then
        return 1
    end
    return 0
end

function seek_treasure:CheckEnterCondition(selfId)
    local msg = ""
    if not self:LuaFnHasTeam(selfId) then
        msg = "Xin lập đội rồi thử lại."
        return 0,msg
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        msg = "Bảo đội trưởng các ngươi tới."
        return 0,msg
    end
    local teamSize = self:GetTeamSize(selfId)
    if teamSize < self.g_LimitMembers then
        msg = "Hoạt động tìm bảo Lâu Lan cần đội ít nhất ba người."
        return 0,msg
    end
    if self:GetNearTeamCount(selfId) < teamSize then
        msg = "Có thành viên đội không ở gần."
        return 0,msg
    end
    for i = 1, teamSize do
        local objId = self:GetNearTeamMember(selfId, i)
        if self:LuaFnGetHumanPKValue(objId) > 0 then
            local name = self:GetName(objId)
            msg = string.format("Thành viên %s sát khí quá nặng, không thể vào Tàng Bảo Động!", name)
            return 0,msg
        end
    end
    return 1
end

function seek_treasure:CheckMemberInfo(selfId, targetId)
    local bSucc = 1
    local teamSize = self:GetTeamSize(selfId)
    local msg = ""
    local member_info = {
        { ["name"] = "", ["levelReq"] = "#GĐạt", ["xinfaReq"] = "#GĐạt", ["taskCount"] = "#GĐạt" }
        , { ["name"] = "", ["levelReq"] = "#GĐạt", ["xinfaReq"] = "#GĐạt", ["taskCount"] = "#GĐạt" }
    , { ["name"] = "", ["levelReq"] = "#GĐạt", ["xinfaReq"] = "#GĐạt", ["taskCount"] = "#GĐạt" }
    , { ["name"] = "", ["levelReq"] = "#GĐạt", ["xinfaReq"] = "#GĐạt", ["taskCount"] = "#GĐạt" }
    , { ["name"] = "", ["levelReq"] = "#GĐạt", ["xinfaReq"] = "#GĐạt", ["taskCount"] = "#GĐạt" }
    , { ["name"] = "", ["levelReq"] = "#GĐạt", ["xinfaReq"] = "#GĐạt", ["taskCount"] = "#GĐạt" }
    }
    for i = 1, teamSize do
        local objId                     = self:GetNearTeamMember(selfId, i)
        local level                     = self:LuaFnGetLevel(objId)
        local bXinfaOK                  = self:CheckXinfaLevel(selfId,40)
        local joinDate                  = self:GetMissionDataEx(objId, 150)
        member_info[i]["name"] = self:GetName(objId)
        if self:GetTime2Day() == joinDate then
            member_info[i]["taskCount"] = "#cff0000不满足"
            bSucc                                = 0
        end
        if level < 75 then
            member_info[i]["levelReq"] = "#cff0000不满足"
            bSucc                               = 0
        end
        if bXinfaOK == 0 then
            member_info[i]["xinfaReq"] = "#cff0000不满足"
            bSucc                               = 0
        end
    end
    if bSucc == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("  Thông tin thành viên đội:")
        for i, mem in pairs(member_info) do
            if i > teamSize then
                break
            end
            msg = string.format("  #BĐội viên %s:", mem["name"])
            if member_info[i]["levelReq"] == "#cff0000不满足" then
                msg = msg .. "#r  #cff0000Cấp nhiệm vụ 65             chưa đạt"
            else
                msg = msg .. "#r #GNhiệm vụ Cấp độ 75 Đáp ứng"
            end
            if member_info[i]["xinfaReq"] == "#cff0000不满足" then
                msg = msg .. "#r #cff0000Tâm pháp Cấp độ 40 Không đáp ứng"
            else
                msg = msg .. "#r #GTâm pháp Cấp độ 40 Đáp ứng"
            end
            if member_info[i]["taskCount"] == "#cff0000不满足" then
                msg = msg .. "#r #cff0000Số lần nhiệm vụ Không đáp ứng"
            else
                msg = msg .. "#r #GSố lần nhiệm vụ Đáp ứng"
            end
            self:AddText(msg)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    return 1
end

function seek_treasure:CheckXinfaLevel(selfId, level)
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
    return 1
end

return seek_treasure
