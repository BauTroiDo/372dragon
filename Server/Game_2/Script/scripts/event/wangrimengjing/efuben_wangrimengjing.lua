local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local efuben_wangrimengjing = class("efuben_wangrimengjing", script_base)
efuben_wangrimengjing.script_id = 801801
efuben_wangrimengjing.g_TodayMax = 1
efuben_wangrimengjing.g_client_res = 649
efuben_wangrimengjing.g_NoUserTime = 0
efuben_wangrimengjing.g_TickTime = 5
efuben_wangrimengjing.g_LimitLevel = 65
efuben_wangrimengjing.g_LimitMembers = 1
efuben_wangrimengjing.g_BackSceneID = 2
efuben_wangrimengjing.g_Back_X = 239
efuben_wangrimengjing.g_Back_Z = 60
efuben_wangrimengjing.g_Fuben_X = 33
efuben_wangrimengjing.g_Fuben_Z = 199
efuben_wangrimengjing.g_BossData = 8
efuben_wangrimengjing.g_CopySceneType = ScriptGlobal.FUBEN_WANGRIMENGJING
efuben_wangrimengjing.g_TitleTextInfo = { "Kẻ Vào Mộng Tìm Vi Diệu", "Người Độc Hành Thám Mộng", "Khách Dắt Mộng Tỏ Tình", "Quân Nhặt Mộng Phù Sinh", "Tiên Giải Mộng Nhân Duyên" }
efuben_wangrimengjing.nNeedNum = { 10, 30, 90, 180, 300 }
efuben_wangrimengjing.TitleData = { 1299, 1300, 1301, 1302, 1303 }
efuben_wangrimengjing.BossIDTblTYPE_0 = 
{
    {51209,51210,51211,51212,51213,51214},
    {51215,51216,51217,51218,51219,51220},
    {51221,51222,51223,51224,51225,51226},
    {51227,51228,51229,51230,51231,51232},
}

efuben_wangrimengjing.BossIDTblTYPE_1 = 
{
    {51239,51240,51241,51242,51243,51244},
    {51245,51246,51247,51248,51249,51250},
    {51251,51252,51253,51254,51255,51256},
    {51257,51258,51259,51260,51261,51262},
}
efuben_wangrimengjing.SmallMonsterTblTYPE_0 = 
{
    51233,51234,51235,51236,51237,51238
}
efuben_wangrimengjing.SmallMonsterTblTYPE_1 = 
{
    51263,51264,51265,51266,51267,51268
}
efuben_wangrimengjing.SmallMonsterPos = 
{
    {65,67},{65,70},{65,73},{65,76},{65,79},
    {75,67},{75,70},{75,73},{75,76},{75,79},
}
efuben_wangrimengjing.g_DynamicRegionPos = {} --动态阻挡
efuben_wangrimengjing.g_Team_Guid = {201,202,203,204,205,206}
-- efuben_wangrimengjing.g_Team_SetMD = efuben_wangrimengjing.g_Team_Guid + 6

function efuben_wangrimengjing:OnEventRequest(selfId, targetId, arg, index)
    if self:GetLevel(selfId) >= 65 then
        if index == 100 then
            if self:CheckAccept(selfId, targetId, 0) ~= 1 then
                return
            end
            self:MakeCopyScene(selfId, 0)
            return
        end
        if index == 101 then
            if self:CheckAccept(selfId, targetId, 1) ~= 1 then
                return
            end
            self:MakeCopyScene(selfId, 1)
            return
        end
        if index == 103 then
            self:BeginEvent(self.script_id)
            for i = 1, 5 do
                self:AddNumText(string.format("#{SBRC_20230627_%s}", i + 135), 6, i + 110)
            end
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index >= 111 and index <= 115 then
            self:BeginEvent(self.script_id)
            self:AddText(
                string.format(
                    "#W    Đổi danh hiệu:#G%s#W, cần tốn#G%s#Wcái#Ytín vật mộng cũ#W. Thiếu hiệp chắc chắn đổi chứ?",
                    self.g_TitleTextInfo[(index % 10)],
                    self.nNeedNum[(index % 10)]
                )
            )
            self:AddNumText("#{SBRC_20230627_143}", 6, index + 90)
            self:AddNumText("#{SBRC_20230627_144}", 8, 116)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index == 116 then
            self:BeginUICommand()
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        elseif index >= 201 and index <= 205 then
            self:AddTitleNew(selfId, targetId, index)
        end
    end
    --副本介绍
    if index == 102 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_6}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function efuben_wangrimengjing:AddTitleNew(selfId,targetId,ID)
    local nIndex = (ID % 10)
    local nLevel = self:GetLevel(selfId)
    if nIndex < 1 or nIndex > 5 or nIndex == nil or nIndex < 0 then
        return
    end
    if nLevel < 65 then
        self:NotifyTips(selfId, "#{SBRC_20230627_145}")
        return
    end
    if nIndex > 1 then
        if not self:LuaFnHaveAgname(selfId, self.TitleData[nIndex - 1]) then
            self:NotifyTips(selfId, string.format("Bạn chưa kích hoạt danh hiệu#{SBRC_20230627_%s}, không đổi được.", (nIndex + 135) - 1))
            return
        end
    end
    if self:LuaFnHaveAgname(selfId, self.TitleData[nIndex]) then
        self:NotifyTips(selfId, "#{SBRC_20230627_148}")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, 20800020) < self.nNeedNum[nIndex] then
        self:NotifyTips(selfId, string.format("Tín vật mộng cũ không đủ %s cái, không đổi được.", self.nNeedNum[nIndex]))
        self:MsgBox(
            selfId,
            targetId,
            string.format("#W    Đổi danh hiệu này cần#G%s#Wcái#Ytín vật mộng cũ#W. Thiếu hiệp chưa đủ. Muốn có#Ytín vật mộng cũ#W, có thể qua phụ bản \"Mộng cảnh xưa (Khó)\" nhận.",
                self.nNeedNum[nIndex])
        )
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, 20800020, self.nNeedNum[nIndex]) then
        self:NotifyTips(selfId, string.format("Tín vật mộng cũ không đủ %s cái, không đổi được.", self.nNeedNum[nIndex]))
        self:MsgBox(
            selfId,
            targetId,
            string.format("#W    Đổi danh hiệu này cần#G%s#Wcái#Ytín vật mộng cũ#W. Thiếu hiệp chưa đủ. Muốn có#Ytín vật mộng cũ#W, có thể qua phụ bản \"Mộng cảnh xưa (Khó)\" nhận.",
                self.nNeedNum[nIndex])
        )
        return
    end
    self:LuaFnAddNewAgname(selfId, self.TitleData[nIndex])
    self:NotifyTips(selfId, string.format("Kích hoạt danh hiệu#{SBRC_20230627_%s} thành công.", nIndex + 135))
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function efuben_wangrimengjing:MakeCopyScene(selfId, nType)
    local param0 = 4
    local param1 = 3
    local mylevel = 0
    local memId
    local tempMemlevel = 0
    local level0 = 0
    local level1 = 0
    local nearmembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearmembercount  do
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
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = "milimengjing.nav"
    config.client_res = self.g_client_res
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
    config.params[7] = nType
    config.params[8] = 0
    config.params[9] = 0
    config.params[10] = 0
    for i = 11, 30 do
        config.params[i] = 0
    end
	local NearTeamSize = self:GetNearTeamCount(selfId)
	for i,id in ipairs(self.g_Team_Guid) do
		if i <= NearTeamSize then
			local PlayerId = self:GetNearTeamMember(selfId, i )
			config.params[id] = self:LuaFnGetGUID(PlayerId)
			config.params[id + 6] = 0
		else
			config.params[id] = 0
			config.params[id + 6] = 0
		end
	end
    config.params[31] = mylevel
    config.monsterfile = "milimengjing_monster.ini"
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

function efuben_wangrimengjing:OnPlayerEnter(selfId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, sceneId, self.g_Fuben_X, self.g_Fuben_Z)
    local NewTime = self:GetDayTime()
	local guid = self:LuaFnGetGUID(selfId)
	for i,id in ipairs(self.g_Team_Guid) do
		if scene:get_param(id) == guid then
			if scene:get_param(id + 6) == 0 then
				local NowTime = self:GetMissionDataEx(selfId, 170)
				if NowTime ~= tonumber(NewTime) then
					self:SetMissionDataEx(selfId, 171, 0)
					self:SetMissionDataEx(selfId, 172, 0)
					self:SetMissionDataEx(selfId, 170, tonumber(NewTime))
				end
				local exid = scene:get_param(7) == 0 and 171 or 172
				local today_count = self:GetMissionDataEx(selfId, exid)
				if today_count >= self.g_TodayMax then
					scene:set_param(id,0)
					scene:set_param(id + 6,0)
					return
				end
				self:SetMissionDataEx(selfId, exid, today_count + 1)
			end
			scene:set_param(id + 6,selfId)
			break
		end
	end
end

function efuben_wangrimengjing:BroadCastNpcTalkAllHuman(idx)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(PlayerId) and self:LuaFnIsCanDoScriptLogic(PlayerId) and self:LuaFnIsCharacterLiving(PlayerId) then
            self:DoNpcTalk(PlayerId,idx)
        end
    end
end
function efuben_wangrimengjing:OnCopySceneTimer()
	local scene = self:get_scene()
	local nHumanNum = scene:get_human_count()
	for i=1,nHumanNum do
		local PlayerId = scene:get_human_obj_id(i)
		if self:LuaFnIsObjValid(PlayerId) then
			local istrue = false
			for j,id in ipairs(self.g_Team_Guid) do
				if scene:get_param(id + 6) == PlayerId then
					istrue = true
					break
				elseif scene:get_param(id) == self:LuaFnGetGUID(PlayerId) then
					istrue = true
					break
				end
			end
			if not istrue then
				self:notify_tips(PlayerId,"Không phải thành viên hợp lệ của phụ bản, mời ngươi rời.")
				self:LeaveScene(PlayerId )
			end
		end
	end
    local ShenBingType = self:LuaFnGetWorldGlobalData(100)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    local MonsterLevel = self:LuaFnGetCopySceneData_Param(31)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2,TickCount)
    local nCurMainStep = self:LuaFnGetCopySceneData_Param(self.g_BossData)
    if nCurMainStep == 0 then
        nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanNum do
            local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(PlayerId) and self:LuaFnIsCanDoScriptLogic(PlayerId) and self:LuaFnIsCharacterLiving(PlayerId) then
                self:BeginUICommand()
                self:UICommand_AddInt(ShenBingType)
                self:EndUICommand()
                self:DispatchUICommand(PlayerId,99848001)
            end
        end
        local NpcID = self:LuaFnCreateMonster(51204, 71, 195, 3, -1, 801804)
        self:SetLevel(NpcID,MonsterLevel)
        self:SetUnitCampID(NpcID, 8)
        self:BroadCastNpcTalkAllHuman(257)
        self:LuaFnSetCopySceneData_Param(self.g_BossData, 1)
    end
    if nCurMainStep == 1 then
        if TickCount == 2 then
            self:BroadCastNpcTalkAllHuman(258)
        end
    end
    if nCurMainStep == 2 then
        local NpcID = self:LuaFnCreateMonster(51205, 70, 63, 3, -1, 801805)
        self:SetLevel(NpcID,MonsterLevel)
        self:SetUnitCampID(NpcID, 8)
        self:LuaFnSetCopySceneData_Param(self.g_BossData, 3)
    end
    if nCurMainStep == 4 then
        local NpcID = self:LuaFnCreateMonster(51206, 198, 198, 3, -1, 801806)
        self:SetLevel(NpcID,MonsterLevel)
        self:SetUnitCampID(NpcID, 8)
        self:LuaFnSetCopySceneData_Param(self.g_BossData, 5)
    end
    if nCurMainStep == 6 then
        local NpcID = self:LuaFnCreateMonster(51207, 203, 55, 3, -1, 801807)
        self:SetLevel(NpcID,MonsterLevel)
        self:SetUnitCampID(NpcID, 8)
        self:LuaFnSetCopySceneData_Param(self.g_BossData, 7)
    end
    if nCurMainStep == 8 then
        local NpcID = self:LuaFnCreateMonster(51294, 203, 42, 3, -1, 801802)
        self:SetUnitCampID(NpcID, 8)
        self:LuaFnSetCopySceneData_Param(self.g_BossData, 9)
    end
end

function efuben_wangrimengjing:CreateBoss(nType,nPosX,nPosZ)
    local BossIdx,MonsterLevel = self:BossIdxData()
    local nFubenType = self:LuaFnGetCopySceneData_Param(7)
    local nBossId
    if nFubenType == 0 then
        nBossId = self.BossIDTblTYPE_0[nType][BossIdx]
    else
        nBossId = self.BossIDTblTYPE_1[nType][BossIdx]
    end
    local NewBossId = self:LuaFnCreateMonster(nBossId, nPosX, nPosZ, 21, -1, self.script_id)
    self:SetLevel(NewBossId,MonsterLevel)
end

function efuben_wangrimengjing:CreateSmallMonster()
    local Isok = self:LuaFnGetCopySceneData_Param(10)
    if Isok == 1 then
        return
    end
    local BossIdx,MonsterLevel = self:BossIdxData()
    local nFubenType = self:LuaFnGetCopySceneData_Param(7)
    local nSmallMonsterID
    if nFubenType == 0 then
        nSmallMonsterID = self.SmallMonsterTblTYPE_0[BossIdx]
    else
        nSmallMonsterID = self.SmallMonsterTblTYPE_1[BossIdx]
    end
    for i = 1,10 do
        local NewBossId = self:LuaFnCreateMonster(nSmallMonsterID,self.SmallMonsterPos[i][1],self.SmallMonsterPos[i][2], 21, -1, self.script_id)
        self:SetLevel(NewBossId,MonsterLevel)
    end
    self:LuaFnSetCopySceneData_Param(10,1)
end

function efuben_wangrimengjing:BossIdxData()
    local MonsterLevel = self:LuaFnGetCopySceneData_Param(31)
    local BossIdx = 1 --默认得
    if MonsterLevel >= 70  and MonsterLevel < 80 then
        BossIdx = 2
    elseif MonsterLevel >= 80  and MonsterLevel < 90 then
        BossIdx = 3
    elseif MonsterLevel >= 90  and MonsterLevel < 100 then
        BossIdx = 4
    elseif MonsterLevel >= 100  and MonsterLevel < 110 then
        BossIdx = 5
    elseif MonsterLevel >= 110 then
        BossIdx = 6
    end
    return BossIdx,MonsterLevel
end

function efuben_wangrimengjing:CheckAccept(selfId, targetId, nType)
    local sceneId = self:GetSceneID()
    if self.g_BackSceneID ~= sceneId then
        self:MsgBox(selfId, targetId, "#{SBRC_20230627_7}")
        self:NotifyTips(selfId, "#{SBRC_20230627_8}")
        return 0
    end
    if self:LuaFnHasTeam(selfId) then
        if not self:LuaFnIsTeamLeader(selfId) then
            self:MsgBox(selfId, targetId, "#{SBRC_20230627_11}")
            self:NotifyTips(selfId, "#{SBRC_20230627_12}")
            return 0
        end
        if self:GetLevel(selfId) < self.g_LimitLevel then
            self:MsgBox(selfId, targetId, "#{SBRC_20230627_15}")
            self:NotifyTips(selfId, "#{SBRC_20230627_16}")
            return 0
        end
        if self:GetTeamSize(selfId) < self.g_LimitMembers then
            self:MsgBox(selfId, targetId, "#{SBRC_20230627_21}")
            self:NotifyTips(selfId, "#{SBRC_20230627_22}")
            return 0
        end
        local NearTeamSize = self:GetNearTeamCount(selfId)
        if self:GetTeamSize(selfId) ~= NearTeamSize then
            self:MsgBox(selfId, targetId, "#{SBRC_20230627_23}")
            self:NotifyTips(selfId, "#{SBRC_20230627_24}")
            return 0
        end
    else
        self:MsgBox(selfId, targetId, "#{SBRC_20230627_9}")
        self:NotifyTips(selfId, "#{SBRC_20230627_10}")
        return 0
    end
    if self:GetTodayEnterTime(selfId) >= self.g_TodayMax then
        self:MsgBox(selfId, targetId, "#{SBRC_20230627_17}")
        self:NotifyTips(selfId, "#{SBRC_20230627_18}")
        return 0
    end
    local nCanEnter = 1
    local nMissionTips = "#cfff263Đội viên#G"
    local NearTeamSize = self:GetNearTeamCount(selfId)
    for i = 1, NearTeamSize do
        local nPlayerID = self:GetNearTeamMember(selfId, i)
        if self:GetLevel(nPlayerID) < self.g_LimitLevel then
            nMissionTips = nMissionTips .. self:GetName(nPlayerID) .. "#{SBRC_20230627_31}#r"
            nCanEnter = 0
        else
            nMissionTips = nMissionTips .. self:GetName(nPlayerID) .. "#{SBRC_20230627_30}#r"
        end
        if self:GetTodayEnterTime(nPlayerID,nType) >= self.g_TodayMax then
            nMissionTips = nMissionTips .. "#r#cff0000Điểm Khiêu Chiến ≥" .. self.g_TodayMax .. "              Không đủ#r"
            nCanEnter = 0
        else
            nMissionTips = nMissionTips .. "#r#GĐiểm Khiêu Chiến ≥" .. self.g_TodayMax .. "              Đủ#r"
        end
    end
    if nCanEnter == 0 then
        self:MsgBox(selfId, targetId, nMissionTips)
        return 0
    end
    return 1
end

function efuben_wangrimengjing:GetTodayEnterTime(selfId,nType)
    local NowTime = self:GetMissionDataEx(selfId, 170)
    local NewTime = self:GetDayTime()
    if NowTime ~= tonumber(NewTime) then
        self:SetMissionDataEx(selfId, 171, 0)
        self:SetMissionDataEx(selfId, 172, 0)
        self:SetMissionDataEx(selfId, 170, tonumber(NewTime))
    end
	local exid = nType == 0 and 171 or 172
    return self:GetMissionDataEx(selfId, exid)
end

function efuben_wangrimengjing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SBRC_20230627_2}")
    self:AddNumText("#{SBRC_20230627_167}", 6, 103)
    if self:GetLevel(selfId) >= 65 then
        self:AddNumText("#{SBRC_20230627_3}", 10, 100)
        self:AddNumText("#{SBRC_20230627_4}", 10, 101)
    end
    self:AddNumText("#{SBRC_20230627_5}", 11, 102)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function efuben_wangrimengjing:OnDie(objId, selfId)
    local BossName = self:GetName(objId)
    local SmallNum = self:LuaFnGetCopySceneData_Param(9)
    local nCurMainStep = self:LuaFnGetCopySceneData_Param(self.g_BossData)
    if BossName == "白世镜" and nCurMainStep == 1 then
        self:LuaFnSetCopySceneData_Param(self.g_BossData,2)
    elseif BossName == "单家军" then
        SmallNum = SmallNum + 1
        local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanNum do
            local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(PlayerId) and self:LuaFnIsCanDoScriptLogic(PlayerId) and self:LuaFnIsCharacterLiving(PlayerId) then
                self:notify_tips(PlayerId,string.format("Đã đánh bại Đan Gia Quân (%s/10).",SmallNum))
            end
        end
        self:LuaFnSetCopySceneData_Param(9,SmallNum)
    elseif BossName == "单正" and nCurMainStep == 3 then
        self:LuaFnSetCopySceneData_Param(self.g_BossData,4)
    elseif BossName == "谭婆" and nCurMainStep == 5 then
        self:LuaFnSetCopySceneData_Param(self.g_BossData,6)
    elseif BossName == "玄苦" and nCurMainStep == 7 then
        self:LuaFnSetCopySceneData_Param(self.g_BossData,8)
        local nFubenType = self:LuaFnGetCopySceneData_Param(7)
        local activeType = nFubenType == 0 and 39 or 40
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, membercount do
            local memberId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(memberId) and self:LuaFnIsCanDoScriptLogic(memberId) then
                self:LuaFnAddMissionHuoYueZhi(memberId, activeType)
                self:LuaFnAddSweepPointByID(memberId, nFubenType == 0 and 14 or 15, 1)
            end
        end
    end
end

function efuben_wangrimengjing:OnKillObject(selfId, objdataId, objId)
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
    if objdataId then
    end
end

function efuben_wangrimengjing:OnEnterZone(selfId, zoneId)
end

function efuben_wangrimengjing:LeaveScene(selfId)
    self:CallScriptFunction((400900), "TransferFunc", selfId, 2, self.g_Back_X, self.g_Back_Z)
end

function efuben_wangrimengjing:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
    local nearmembercount = self:GetNearTeamCount(leaderObjId)
    for i = 1, nearmembercount do
        local member = self:GetNearTeamMember(leaderObjId, i)
        if self:LuaFnIsCanDoScriptLogic(member) then
            self:NewWorld(member, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
        end
    end
end

function efuben_wangrimengjing:NotifyTips(selfId, msg)
    self:notify_tips(selfId, msg)
end

function efuben_wangrimengjing:CalSweepData(selfId, index)
    local today = tonumber(self:GetDayTime())
    if self:GetMissionDataEx(selfId, 170) ~= today then
        self:SetMissionDataEx(selfId, 170, today)
        self:SetMissionDataEx(selfId, 171, 0)
        self:SetMissionDataEx(selfId, 172, 0)
    end
    local exid = index == 14 and 171 or 172
    local count = self:GetMissionDataEx(selfId, exid)
    self:SetMissionDataEx(selfId, exid, count + 1)
end

return efuben_wangrimengjing
