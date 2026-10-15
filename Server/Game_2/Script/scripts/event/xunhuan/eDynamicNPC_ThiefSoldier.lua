local gbk = require "wire_charset"
local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local eDynamicNPC_ThiefSoldier = class("eDynamicNPC_ThiefSoldier", script_base)
eDynamicNPC_ThiefSoldier.script_id = 050013
eDynamicNPC_ThiefSoldier.g_ClientRes = 3170
eDynamicNPC_ThiefSoldier.g_CopySceneType = ScriptGlobal.FUBEN_ZEIBINGRUQIN
eDynamicNPC_ThiefSoldier.g_LimitMembers = 3
eDynamicNPC_ThiefSoldier.g_TickTime = 5
eDynamicNPC_ThiefSoldier.g_LimitTotalHoldTime = 360
eDynamicNPC_ThiefSoldier.g_LimitTimeSuccess = 500
eDynamicNPC_ThiefSoldier.g_CloseTick = 6
eDynamicNPC_ThiefSoldier.g_NoUserTime = 300
eDynamicNPC_ThiefSoldier.g_Fuben_X = 76
eDynamicNPC_ThiefSoldier.g_Fuben_Z = 110
eDynamicNPC_ThiefSoldier.g_BossGroupID = 1
eDynamicNPC_ThiefSoldier.g_TotalNeedKillBoss = 31
eDynamicNPC_ThiefSoldier.g_keySD = {}

eDynamicNPC_ThiefSoldier.g_keySD["typ"] = 0
eDynamicNPC_ThiefSoldier.g_keySD["spt"] = 1
eDynamicNPC_ThiefSoldier.g_keySD["tim"] = 2
eDynamicNPC_ThiefSoldier.g_keySD["scn"] = 3
eDynamicNPC_ThiefSoldier.g_keySD["cls"] = 4
eDynamicNPC_ThiefSoldier.g_keySD["dwn"] = 5
eDynamicNPC_ThiefSoldier.g_keySD["tem"] = 6
eDynamicNPC_ThiefSoldier.g_keySD["x"] = 7
eDynamicNPC_ThiefSoldier.g_keySD["z"] = 8
eDynamicNPC_ThiefSoldier.g_keySD["ObjKilled"] = 9
eDynamicNPC_ThiefSoldier.g_keySD["MyLevel"] = 10
eDynamicNPC_ThiefSoldier.g_keySD["FlagThielf"] = 11
eDynamicNPC_ThiefSoldier.paramonce = 28
eDynamicNPC_ThiefSoldier.g_minLevel = 20
eDynamicNPC_ThiefSoldier.g_typMonster0 = 3650
eDynamicNPC_ThiefSoldier.g_typMonster1 = 3659
eDynamicNPC_ThiefSoldier.Monster_Boss = {
    3650, 3651, 3652, 3653, 3654, 3655, 3656, 3657, 3658, 3659
}

eDynamicNPC_ThiefSoldier.NianShou_Boss = {
    12200, 12201, 12202, 12203, 12204, 12205, 12206, 12207, 12208, 12209, 12210,
    12211
}

eDynamicNPC_ThiefSoldier.NianShou_Pos = {
    {["x"] = 83, ["z"] = 45}, {["x"] = 93, ["z"] = 34},
    {["x"] = 53, ["z"] = 30}, {["x"] = 27, ["z"] = 24}, {["x"] = 34, ["z"] = 41}
}

function eDynamicNPC_ThiefSoldier:OnDefaultEvent(selfId, targetId)
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
    local CanAccept = self:OnAccept(selfId,targetId)
    if (1 == CanAccept) then self:LuaFnDeleteMonster(targetId) end
end

function eDynamicNPC_ThiefSoldier:OnEnumerate(caller, selfId, targetId, arg,index)
	-- if not self:LuaFnIsActivityMonster(selfId,targetId,true)
		-- return
	-- end

    local lev = self:GetLevel(selfId)
    if lev < self.g_minLevel then
        caller:BeginEvent(self.script_id)
        caller:AddText("Cấp độ của ngươi quá thấp, căn bản không đủ để ta xem, vẫn là sau khi đạt cấp 20 rồi hãy đến tìm ta.")
        caller:EndEvent()
        caller:DispatchEventList(selfId, targetId)
        return
    end
    if not self:LuaFnHasTeam(selfId) then
        caller:BeginEvent(self.script_id)
        caller:AddText("Một Cá nhân nhỏ bé cũng dám đến thách đấu ta, ta căn bản không thèm chấp ngươi động thủ.")
        caller:EndEvent()
        caller:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        caller:BeginEvent(self.script_id)
        caller:AddText("Muốn khiêu chiến ta thì ít nhất cũng phải ba người trở lên chứ, chỉ có chút người này thôi sao? Cũng quá xem thường ta rồi.")
        caller:EndEvent()
        caller:DispatchEventList(selfId, targetId)
        return
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        caller:BeginEvent(self.script_id)
        caller:AddText("Muốn khiêu chiến ta? Gọi đội trưởng của các ngươi đến đây đi.")
        caller:EndEvent()
        caller:DispatchEventList(selfId, targetId)
        return
    end
    local leaderObjId = selfId
    local NearCount = self:GetNearTeamCount(leaderObjId)
    local namenum = 0
    local notifyString = "Đội của ngài có thành viên("
    for i = 1, NearCount do
        local nPlayerId = self:GetNearTeamMember(selfId, i)
        local lev = self:GetLevel(nPlayerId)
        local nam = self:GetName(nPlayerId)
        if (lev < 20) then
            notifyString = notifyString .. nam .. " "
            namenum = 1
        end
    end
    notifyString = notifyString .. "Cấp độ chưa đủ."
    if (namenum > 0) then
        caller:BeginEvent(self.script_id)
        caller:AddText(notifyString)
        caller:EndEvent()
        caller:DispatchEventList(selfId, targetId)
        return
    end
    for i = 1, NearCount do
        local TeammateID = self:GetNearTeamMember(leaderObjId, i)
        if (-1 == TeammateID) then return end
        local Level = self:GetLevel(TeammateID)
        if (Level < 20) then
            caller:BeginEvent(self.script_id)
            caller:AddText("Trong đội ngũ của ngươi có thành viên Cấp độ chưa đạt 20!")
            caller:EndEvent()
            caller:DispatchEventList(selfId, targetId)
            return
        end
    end
    caller:BeginEvent(self.script_id)
    caller:AddText("Đã bằng hữu không sợ chết, ta cũng không cần lưu tình, tiểu nhân kia, tiến lên cho chúng nếm mùi lợi hại!")
    caller:AddNumTextWithTarget(self.script_id, "Lẽ nào ta lại sợ ngươi không thành...", 10, -1)
    caller:EndEvent()
    caller:DispatchEventList(selfId, targetId)
end

function eDynamicNPC_ThiefSoldier:CheckAccept(selfId) return 1 end

function eDynamicNPC_ThiefSoldier:OnAccept(selfId, targetId)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return -1 end
    local lev = self:GetLevel(selfId)
    if lev < self.g_minLevel then
        self:NotifyTip(selfId, "Cấp độ của ngươi quá thấp.")
        return -1
    end
    if not self:LuaFnHasTeam(selfId) then
        self:NotifyTip(selfId, "Ngươi chưa có đội.")
        return -1
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:NotifyTip(selfId, "Đội ngũ không đủ." .. (self.g_LimitMembers) .. "người")
        return -1
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        self:NotifyTip(selfId, "Ngươi không phải đội trưởng.")
        return -1
    end
    local NearCount = self:GetNearTeamCount(selfId)
    local TeammateCount = self:GetTeamMemberCount(selfId)
    if (NearCount < TeammateCount) then
        self:BeginEvent(self.script_id)
        local strText = "Ngài có đồng đội không ở gần."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return -1
    end
    for i = 1, TeammateCount do
        local TeammateID = self:GetNearTeamMember(selfId, i)
        if (-1 == TeammateID) then return -1 end
        local Level = self:GetLevel(TeammateID)
        if (Level < 20) then
            self:BeginEvent(self.script_id)
            self:AddText("Trong đội ngũ của ngài có thành viên Cấp độ chưa đạt 20!")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return -1
        end
    end
    local numMem = self:GetNearTeamCount(selfId)
    self:MakeCopyScene(selfId, numMem,targetId)
    return 1
end

function eDynamicNPC_ThiefSoldier:OnAbandon(selfId) end

function eDynamicNPC_ThiefSoldier:CreateBoss(iniLevel)
    if (iniLevel < self.g_minLevel) then iniLevel = self.g_minLevel end
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    if (iniLevel > PlayerMaxLevel) then iniLevel = PlayerMaxLevel end
    local ini = math.floor(iniLevel / 10)
    if ini <= 0 then
        ini = 1
    elseif ini > 10 then
        ini = 10
    end
    local typ = self.Monster_Boss[ini]
    local objId = self:LuaFnCreateMonster(typ, 19.4121, 102.2840, 14, 76, 50013)
    self:SetMonsterGroupID(objId, self.g_BossGroupID)
    self:SetLevel(objId, iniLevel)
    local szName = self:LuaFnGetName(objId)
    if szName == "贼兵头目" then
        self:SetCharacterTitle(objId, "\"Vây Mà Không Chết\"")
    end
    local DataID = self:GetMonsterDataID(objId)
    local strMonsterName = self:GetMonsterNamebyDataId(DataID)
    self:CallScriptFunction((200060), "Paopao", strMonsterName, "Doanh địa Tặc Khấu",
                            "Thiên đường có lối ngươi không đi, địa ngục không cửa ngươi xông vào! Đã đến đây, đừng hòng bước ra, ngày này năm sau là ngày giỗ của ngươi.")
end

function eDynamicNPC_ThiefSoldier:MakeCopyScene(selfId, nearmembercount,targetId)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
    local param0 = 4
    local param1 = 3
    local mems = {}

    local level0 = 0
    local level1 = 0
    for i = 1, nearmembercount do
        mems[i] = self:GetNearTeamMember(selfId, i)
        local tempMemlevel = self:GetLevel(mems[i])
        level0 = level0 + (tempMemlevel ^ param0)
        level1 = level1 + (tempMemlevel ^ param1)
    end
    local mylevel
    if level1 == 0 then
        mylevel = self.g_minLevel
    else
        mylevel = level0 / level1
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
	config.navmapname = "zeiying.path"					-- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
	config.client_res = self.g_ClientRes
	config.teamleader = leaderguid
	config.NoUserCloseTime = 0
	config.Timer = self.g_TickTime * 1000
	config.params = {}
	config.params[self.g_keySD["typ"]] = self.g_CopySceneType
	config.params[self.g_keySD["spt"]] = self.script_id
	config.params[self.g_keySD["tim"]] = 0
	config.params[self.g_keySD["scn"]] = -1
	config.params[self.g_keySD["cls"]] = 0
	config.params[self.g_keySD["dwn"]] = 0
	config.params[self.g_keySD["tem"]] = self:GetTeamId( selfId )
	config.params[self.g_keySD["FlagThielf"]] = 800
    local x, z = self:GetWorldPos(selfId)
	config.params[self.g_keySD["x"]] = x
	config.params[self.g_keySD["z"]] = z
    config.params[self.g_keySD["ObjKilled"]] = 0
	config.params[self.g_keySD["MyLevel"]] = mylevel
    local CopyScene_LevelGap = 31
    config.params[CopyScene_LevelGap] = mylevel - iniLevel
    config.params[self.paramonce] = 0
	config.eventfile = "zeiying_area.ini"
	config.monsterfile = "zeiying_monster_" .. iniLevel .. ".ini"
	config.sn 		 = self:LuaFnGenCopySceneSN()

    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    if bRetSceneID > 0 then
        self:NotifyTip(selfId, "Tạo phó bản thành công!")
    else
        self:NotifyTip(selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
end

function eDynamicNPC_ThiefSoldier:OnContinue(selfId, targetId) end

function eDynamicNPC_ThiefSoldier:CheckSubmit(selfId, selectRadioId) end

function eDynamicNPC_ThiefSoldier:OnSubmit(selfId, targetId, selectRadioId) end

function eDynamicNPC_ThiefSoldier:OnDie(objId, killerId)
    print("eDynamicNPC_ThiefSoldier:OnDie", objId, killerId)
    local DataID = self:GetMonsterDataID(objId)
    self:OnKillObject(killerId, DataID, objId)
end

function eDynamicNPC_ThiefSoldier:OnKillObject(selfId, objdataId, objId)
    for i = 1, 10 do if (objdataId == self.NianShou_Boss[i]) then return end end
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then return end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then return end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then return end
    local num = self:LuaFnGetCopyScene_HumanCount()
    local bIsBoss = 0
    local GroupID = self:GetMonsterGroupID(objId)
    if GroupID == self.g_BossGroupID then bIsBoss = 1 end
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local memId
    local teamLeaderName
    for i = 1, membercount do
        memId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(memId) and self:LuaFnIsCanDoScriptLogic(memId) then
            local teamLeaderFlag = self:LuaFnIsTeamLeader(memId)
            if teamLeaderFlag and teamLeaderFlag then
                teamLeaderName = self:LuaFnGetName(memId)
                break
            end
        end
    end
    if bIsBoss == 1 then
        local message
        local nPlayerNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nPlayerNum do
            local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddMissionHuoYueZhi(nPlayerId, 18)
        end
        local randMessage = math.random(3)
        if teamLeaderName ~= nil then
            teamLeaderName = gbk.fromutf8(teamLeaderName)
            if randMessage == 1 then
                message = string.format(
                              "#{ItemMsg_08}#B#{_INFOUSR%s}#{ItemMsg_09}",
                              teamLeaderName)
            elseif randMessage == 2 then
                message = string.format("#B#{_INFOUSR%s}#cff0000#{ItemMsg_11}",
                                        teamLeaderName)
            else
                message = string.format(
                              "#{ItemMsg_12}#B#{_INFOUSR%s}#cff0000#{ItemMsg_13}",
                              teamLeaderName)
            end
            self:BroadMsgByChatPipe(selfId, message, 4)
        end
    end
    local killedbossnumber = self:LuaFnGetCopySceneData_Param(self.g_keySD["ObjKilled"])
    killedbossnumber = killedbossnumber + 1
    print("killedbossnumber =", killedbossnumber)
    self:LuaFnSetCopySceneData_Param(self.g_keySD["ObjKilled"], killedbossnumber)
    for i = 1, num do
        local ServerID = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(ServerID) and
            self:LuaFnIsCanDoScriptLogic(ServerID) then
            local score = self:GetMissionData(ServerID, define.MD_ENUM.MD_ThiefSoldierInvade)
            if score < 65000 then
                if bIsBoss == 1 then
                    score = score + 5
                else
                    score = score + 1
                end
                if score > 65000 then score = 65000 end
                self:SetMissionData(ServerID, define.MD_ENUM.MD_ThiefSoldierInvade, score)
            end
            local ScoreStr = string.format("Tích Phân Hiện Tại %d", score)
            self:NotifyTip(ServerID, ScoreStr)
            self:LuaFnAddSalaryPoint(ServerID, 7, 1)
            local KillStr = string.format("Đã tiêu diệt xong bọn ác tặc tạo phản: %d/%d",
                                        killedbossnumber,
                                        self.g_TotalNeedKillBoss)
            self:NotifyTip(ServerID, KillStr)
        end
    end
    if killedbossnumber >= self.g_TotalNeedKillBoss then
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
    if killedbossnumber == (self.g_TotalNeedKillBoss - 1) then
        local CurLevel = self:LuaFnGetCopySceneData_Param(
                             self.g_keySD["MyLevel"])
        self:CreateBoss(CurLevel)
    end
end

function eDynamicNPC_ThiefSoldier:OnEnterZone(selfId, zoneId) end

function eDynamicNPC_ThiefSoldier:OnItemChanged(selfId, itemdataId) end

function eDynamicNPC_ThiefSoldier:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if leaderObjId == -1 then return end
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then return end
    if not self:IsCopySceneOwnerTeamMember(leaderObjId, destsceneId, self.g_keySD["tem"]) then
        return
    end
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    local numMem = self:GetNearTeamCount(leaderObjId)
    local member
    self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes)
    self:LuaFnAuditQuest(leaderObjId, "Giặc tràn vào")
    for i = 2, numMem do
        member = self:GetNearTeamMember(leaderObjId, i)
        if self:LuaFnIsCanDoScriptLogic(member) and
            self:IsCopySceneOwnerTeamMember(member, destsceneId, self.g_keySD["tem"]) then
            self:NewWorld(member, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes)
            self:LuaFnAuditQuest(member, "Giặc tràn vào")
        end
    end
end

function eDynamicNPC_ThiefSoldier:OnPlayerEnter(selfId)
	if not self:IsAuthorizedCopyScenePlayer(selfId, self.g_keySD["tem"]) then
		self:NotifyTip(selfId, "Ngươi không thuộc đội tạo phụ bản này")
		self:KickOut(selfId)
		return
	end
	self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, self.g_Fuben_X, self.g_Fuben_Z )
end

function eDynamicNPC_ThiefSoldier:OnHumanDie(selfId, killerId) end

function eDynamicNPC_ThiefSoldier:KickOut(objId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    local x = self:LuaFnGetCopySceneData_Param(self.g_keySD["x"])
    local z = self:LuaFnGetCopySceneData_Param(self.g_keySD["z"])
    if self:LuaFnIsObjValid(objId) then
        self:NewWorld(objId, oldsceneId, nil, x, z)
    end
end

function eDynamicNPC_ThiefSoldier:OnCopySceneTimer()
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    print("eDynamicNPC_ThiefSoldier:OnCopySceneTimer", os.time(), "TickCount =", TickCount)
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}

    for i = 1, membercount do mems[i] = self:LuaFnGetCopyScene_HumanObjId(i) end
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount == self.g_CloseTick then
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:KickOut(mems[i])
                end
            end
        elseif leaveTickCount < self.g_CloseTick then
            local strText = string.format("Ngươi sẽ rời khỏi cảnh sau %d giây!",
                                          (self.g_CloseTick - leaveTickCount) *
                                              self.g_TickTime)
            for i = 1, membercount do
                if self:LuaFnIsObjValid(mems[i]) then
                    self:NotifyTip(mems[i], strText)
                end
            end
        end
    elseif TickCount == self.g_LimitTimeSuccess then
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) then
                self:NotifyTip(mems[i], "Hết thời gian nhiệm vụ, hoàn thành!")
            end
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    elseif TickCount == self.g_LimitTotalHoldTime then
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) then
                self:NotifyTip(mems[i], "Nhiệm vụ thất bại, quá thời gian!")
            end
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    else
        local oldteamid = self:LuaFnGetCopySceneData_Param(6)
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) then
                if oldteamid ~= self:GetTeamId(mems[i]) then
                    self:NotifyTip(mems[i], "Ngươi không ở trong đội ngũ đúng!")
                    self:KickOut(mems[i])
                end
            end
        end
    end
end

function eDynamicNPC_ThiefSoldier:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function eDynamicNPC_ThiefSoldier:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return eDynamicNPC_ThiefSoldier
