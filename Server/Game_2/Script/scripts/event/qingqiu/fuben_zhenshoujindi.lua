local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local fuben_zhenshoujindi = class("fuben_zhenshoujindi", script_base)
fuben_zhenshoujindi.script_id = 893020
fuben_zhenshoujindi.g_IsOpen = 1
fuben_zhenshoujindi.g_CopySceneName = "青丘"
fuben_zhenshoujindi.g_client_res = 577
fuben_zhenshoujindi.g_TodayMax = {[0] = 2, [1] = 1}
fuben_zhenshoujindi.g_CopySceneType = ScriptGlobal.FUBEN_ZHENGSHOUJINGDI
fuben_zhenshoujindi.g_LimitMembers = 1
fuben_zhenshoujindi.g_LimitLevel = 65
fuben_zhenshoujindi.g_TickTime = 5
fuben_zhenshoujindi.g_LimitTotalHoldTime = 720
fuben_zhenshoujindi.g_LimitTimeSuccess = 500
fuben_zhenshoujindi.g_CloseTick = 12
fuben_zhenshoujindi.g_NoUserTime = 60
fuben_zhenshoujindi.g_DeadTrans = 0
fuben_zhenshoujindi.g_Fuben_X = 178
fuben_zhenshoujindi.g_Fuben_Z = 42
fuben_zhenshoujindi.g_BackSceneID = 1
fuben_zhenshoujindi.g_Back_X = 133
fuben_zhenshoujindi.g_Back_Z = 82
fuben_zhenshoujindi.g_TotalNeedKill = 1
fuben_zhenshoujindi.g_SceneData_Type = 7
fuben_zhenshoujindi.g_SceneData_MainStep = 8
fuben_zhenshoujindi.g_SceneData_SaoDiKillNum = 9
fuben_zhenshoujindi.g_SceneData_CurBOSSID = 10
fuben_zhenshoujindi.g_SceneData_CurQingQiuHuNPCID = 11
fuben_zhenshoujindi.g_PosChuanSong = {228, 70}

fuben_zhenshoujindi.g_ChuanSongScript = 893021
fuben_zhenshoujindi.g_QingQiuHu = 893039
fuben_zhenshoujindi.g_SaoDiFoxPos = {
    {195, 34},
    {200, 34},
    {209, 36},
    {213, 43},
    {214, 47},
    {211, 49},
    {208, 46},
    {202, 41},
    {198, 40},
    {211, 47}
}

fuben_zhenshoujindi.g_SaoDiFoxScriptID = 893115
fuben_zhenshoujindi.g_PosYunJuanShu = {180, 123}

fuben_zhenshoujindi.g_BOSS_1_NPC = 893022
fuben_zhenshoujindi.g_BOSS_1_NPC_BOSSAI = 893023
fuben_zhenshoujindi.g_PosBOSS_2 = {144, 200}

fuben_zhenshoujindi.g_BOSS_2_NPC = 893025
fuben_zhenshoujindi.g_BOSS_2_NPC_BOSSAI = 893026
fuben_zhenshoujindi.g_PosBOSS_3 = {62, 144}

fuben_zhenshoujindi.g_BOSS_3_NPC = 893027
fuben_zhenshoujindi.g_BOSS_3_ExtraNPC = {
    {["id"] = 55207, ["x"] = 78, ["z"] = 161, ["dir"] = 18},
    {["id"] = 55208, ["x"] = 68, ["z"] = 170, ["dir"] = 9},
    {["id"] = 55207, ["x"] = 56, ["z"] = 165, ["dir"] = 23},
    {["id"] = 55208, ["x"] = 47, ["z"] = 159, ["dir"] = 23},
    {["id"] = 55207, ["x"] = 37, ["z"] = 150, ["dir"] = 24},
    {["id"] = 55208, ["x"] = 39, ["z"] = 140, ["dir"] = 5},
    {["id"] = 55207, ["x"] = 48, ["z"] = 129, ["dir"] = 5},
    {["id"] = 55208, ["x"] = 54, ["z"] = 121, ["dir"] = 27},
    {["id"] = 55207, ["x"] = 69, ["z"] = 124, ["dir"] = 32},
    {["id"] = 55208, ["x"] = 79, ["z"] = 133, ["dir"] = 32},
    {["id"] = 55207, ["x"] = 88, ["z"] = 138, ["dir"] = 32},
    {["id"] = 55208, ["x"] = 83, ["z"] = 153, ["dir"] = 14}
}

fuben_zhenshoujindi.g_BOSS_3_NPC_BOSSAI = 893028
fuben_zhenshoujindi.g_PosBOSS_5 = {60, 63}

fuben_zhenshoujindi.g_BOSS_5_NPC = 893031
fuben_zhenshoujindi.g_BOSS_5_NPC_BOSSAI = 893032
fuben_zhenshoujindi.g_PosBOSS_4 = {45, 41}

fuben_zhenshoujindi.g_BOSS_DieScript = {893034, 893035, 893036, 893037}

fuben_zhenshoujindi.g_BOSS_StrengthInDifficult = 1
fuben_zhenshoujindi.g_BOSS_DropItem = {
    [1] = {
        {["item"] = 20800005, ["num"] = 1}
    },
    [2] = {
        {["item"] = 20800005, ["num"] = 1}
    },
    [3] = {
        {["item"] = 20800005, ["num"] = 1}
    },
    [4] = {
        {["item"] = 20800005, ["num"] = 1}
    }
}

fuben_zhenshoujindi.nNeedNum = {10, 30, 90, 180, 300}

fuben_zhenshoujindi.TitleData = {1091, 1092, 1093, 1094, 1095}

fuben_zhenshoujindi.g_Team_Guid = {201,202,203,204,205,206}
-- fuben_zhenshoujindi.g_Team_SetMD = fuben_zhenshoujindi.g_Team_Guid + 6

function fuben_zhenshoujindi:OnEventRequest(selfId, targetId,arg,eventID)
    if self.g_IsOpen == 1 and self:GetLevel(selfId) >= 65 then
        if eventID == 100 then
			local isok,msg = self:CheckAccept(selfId, targetId, 0)
			if isok ~= 1 then
				if msg then
					self:BeginEvent(self.script_id)
					self:AddText(msg)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
				end
				return
			end
            self:MakeCopyScene(selfId, 0,918042021)
            return
        end
        if eventID == 101 then
			local isok,msg = self:CheckAccept(selfId, targetId, 1)
			if isok ~= 1 then
				if msg then
					self:BeginEvent(self.script_id)
					self:AddText(msg)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
				end
				return
			end
            self:MakeCopyScene(selfId, 1,918042021)
            return
        end
    end
    if eventID >= 1001 and eventID <= 1002 then
        local daibi = {101,102}
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt((eventID % 10))
        self:UICommand_AddInt(self:GetMissionDataEx(selfId, daibi[(eventID % 10)]))
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89306001)
    end
    if eventID == 103 then
        self:BeginEvent(self.script_id)
        for i = 1, 5 do
            self:AddNumText(string.format("#{ZSFB_20220105_%s}", i + 125), 6, i + 110)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif eventID >= 111 and eventID <= 115 then
        self:BeginEvent(self.script_id)
        self:AddText(
            string.format(
                "    Đổi danh hiệu:#{ZSFB_20220105_%s}, cần tốn#G%s#Wcái#YThanh Khâu Bội#W. Thiếu hiệp chắc chắn đổi chứ?",
                (eventID % 10) + 125,
                self.nNeedNum[(eventID % 10)]
            )
        )
        self:AddNumText("#{ZSFB_20220105_132}", 6, eventID + 90)
        self:AddNumText("#{ZSFB_20220105_133}", 8, 116)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif eventID == 116 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    elseif eventID >= 201 and eventID <= 205 then
        self:AddTitleNew(selfId, targetId, eventID)
    end
    if eventID == 102 then
        self:BeginEvent(self.script_id)
        self:AddText("#{ZSFB_20220105_06}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if eventID == 104 then
        self:BeginEvent(self.script_id)
        self:AddText("#{QQSD_220801_16}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function fuben_zhenshoujindi:AddTitleNew(selfId, targetId, ID)
    local nIndex = (ID % 10)
    local nLevel = self:GetLevel(selfId)
    if nIndex < 1 or nIndex > 5 or nIndex == nil or nIndex < 0 then
        return
    end
    if nLevel < 65 then
        self:NotifyTips(selfId, "#{ZSFB_20220105_134}")
        return
    end
    if nIndex > 1 then
        if not self:LuaFnHaveAgname(selfId, self.TitleData[nIndex - 1]) then
            self:NotifyTips(selfId, string.format("Bạn chưa kích hoạt danh hiệu#{ZSFB_20220105_%s}, không đổi được.", (nIndex + 125) - 1))
            return
        end
    end
    if self:LuaFnHaveAgname(selfId, self.TitleData[nIndex]) then
        self:NotifyTips(selfId, "#{ZSFB_20220105_145}")
        self:MsgBox(selfId, targetId, "#{ZSFB_20220105_146}")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, 20800020) < self.nNeedNum[nIndex] then
        self:NotifyTips(selfId, string.format("Thanh Khâu Bội của bạn không đủ %s, không đổi được.", self.nNeedNum[nIndex]))
        self:MsgBox(
            selfId,
            targetId,
            string.format("    Đổi danh hiệu này cần#G%s#Wcái#YThanh Khâu Bội#W. Thiếu hiệp chưa đủ. Muốn có#YThanh Khâu Bội#W, có thể qua phụ bản \"Thanh Khâu thí luyện (Khó)\" nhận.", self.nNeedNum[nIndex])
        )
        return
    end
    if not self:LuaFnDelAvailableItem(selfId,20800020,self.nNeedNum[nIndex]) then
        self:NotifyTips(selfId, string.format("Thanh Khâu Bội của bạn không đủ %s, không đổi được.", self.nNeedNum[nIndex]))
        self:MsgBox(
            selfId,
            targetId,
            string.format("    Đổi danh hiệu này cần#G%s#Wcái#YThanh Khâu Bội#W. Thiếu hiệp chưa đủ. Muốn có#YThanh Khâu Bội#W, có thể qua phụ bản \"Thanh Khâu thí luyện (Khó)\" nhận.", self.nNeedNum[nIndex])
        )
        return
    end
    self:LuaFnAddNewAgname(selfId, self.TitleData[nIndex])
    self:NotifyTips(selfId, string.format("Kích hoạt danh hiệu#{ZSFB_20220105_%s} thành công.", nIndex + 125))
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
	self:BeginUICommand()
	self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function fuben_zhenshoujindi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSFB_20220105_03}")
    self:AddNumText("#{ZSFB_20220105_125}", 6, 103)
    self:AddNumText("#{QQSD_220801_1}", 7, 1001)
    self:AddNumText("#{QQSD_220801_2}", 7, 1002)
    if self.g_IsOpen == 1 and self:GetLevel(selfId) >= 65 then
        self:AddNumText("#{ZSFB_20220105_04}", 10, 100)
        self:AddNumText("#{ZSFB_20220105_115}", 10, 101)
    end
    self:AddNumText("#{ZSFB_20220105_05}", 11, 102)
    self:AddNumText("#{QQSD_220801_3}", 11, 104)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function fuben_zhenshoujindi:CheckAccept(selfId, targetId, nType)
    local sceneId = self:get_scene_id()
    if self.g_BackSceneID ~= sceneId then
        self:MsgBox(selfId, targetId, "#{ZSFB_20220105_07}")
        self:NotifyTips(selfId, "#{ZSFB_20220105_08}")
        return 0
    end
    if self:LuaFnHasTeam(selfId) then
        if not self:LuaFnIsTeamLeader(selfId) then
            self:MsgBox(selfId, targetId, "#{ZSFB_20220105_11}")
            self:NotifyTips(selfId, "#{ZSFB_20220105_12}")
            return 0
        end
        if self:GetLevel(selfId) < self.g_LimitLevel then
            self:MsgBox(selfId, targetId, "#{ZSFB_20220105_15}")
            self:NotifyTips(selfId, "#{ZSFB_20220105_16}")
            return 0
        end
        if self:GetTeamSize(selfId) < self.g_LimitMembers then
            self:MsgBox(selfId, targetId, "#{ZSFB_20220105_21}")
            self:NotifyTips(selfId, "#{ZSFB_20220105_22}")
            return 0
        end
        local NearTeamSize = self:GetNearTeamCount(selfId)
        if self:GetTeamSize(selfId) ~= NearTeamSize then
            self:MsgBox(selfId, targetId, "#{ZSFB_20220105_23}")
            self:NotifyTips(selfId, "#{ZSFB_20220105_24}")
            return 0
        end
    else
        self:MsgBox(selfId, targetId, "#{ZSFB_20220105_09}")
        self:NotifyTips(selfId, "#{ZSFB_20220105_10}")
        return 0
    end
    if self:GetTodayEnterTime(selfId, nType) > self.g_TodayMax[nType] then
        self:MsgBox(selfId, targetId, "#{ZSFB_20220105_17}")
        self:NotifyTips(selfId, "#{ZSFB_20220105_18}")
        return 0
    end
    local nCanEnter = 1
    local nMissionTips = ""
    local NearTeamSize = self:GetNearTeamCount(selfId)
    for i = 1, NearTeamSize do
        local nPlayerID = self:GetNearTeamMember(selfId, i)
        if self:GetLevel(nPlayerID) < self.g_LimitLevel then
            nMissionTips = nMissionTips .. self:GetName(nPlayerID) .. "#{ZSFB_20220105_30}#r"
            nCanEnter = 0
        else
            nMissionTips = nMissionTips .. self:GetName(nPlayerID) .. "#{ZSFB_20220105_29}#r"
        end
        if self:GetTodayEnterTime(nPlayerID, nType) >= self.g_TodayMax[nType] then
            nMissionTips = nMissionTips .. "#r#cff0000Điểm Khiêu Chiến ≥" .. self.g_TodayMax[nType] .. "              Không đủ#r"
            nCanEnter = 0
        else
            nMissionTips = nMissionTips .. "#r#GĐiểm Khiêu Chiến ≥" .. self.g_TodayMax[nType] .. "              Đủ#r"
        end
    end
	return nCanEnter,nMissionTips
end

function fuben_zhenshoujindi:GetTodayEnterTime(selfId, nType)
    local NowTime = self:GetMissionDataEx(selfId,160)
    local NewTime = self:GetDayTime()
	--青丘次数清理
	if NowTime ~= tonumber(NewTime) then
		self:SetMissionDataEx(selfId,160,NewTime)
		self:SetMissionDataEx(selfId,102,0)
		self:SetMissionDataEx(selfId,103,0)
	end
    if nType == 0 then
        return self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_QINGQIU_TYPE_0)
    end
    return self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_QINGQIU_TYPE_1)
end

function fuben_zhenshoujindi:AddTodayEnterTime(selfId, nType)
    if nType == 0 then
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_QINGQIU_TYPE_0, self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_QINGQIU_TYPE_0) + 1)
    else
		self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_QINGQIU_TYPE_1, self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_QINGQIU_TYPE_1) + 1)
	end
end

function fuben_zhenshoujindi:MakeCopyScene(selfId, nType,paramx)
	if paramx ~= 918042021 then return end
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = "qingqiu.nav"
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
    config.NoUserCloseTime = self.g_NoUserTime * 1000
    config.Timer = self.g_TickTime * 1000
    config.params = {}
    config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
    config.params[2] = 0
    config.params[3] = self.g_BackSceneID
    config.params[4] = 0
    config.params[5] = 0
    config.params[6] = self:GetTeamId(selfId)
    config.params[self.g_SceneData_Type] = nType
    config.params[8] = 0
    config.params[9] = 0
    config.params[10] = 0
    for i = 12,31 do
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
	
	
    config.patrolpoint = "qingqiu_patrolpoint.ini"
    config.sn = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function fuben_zhenshoujindi:OnKillObject(selfId, objdataId, objId)
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

function fuben_zhenshoujindi:OnEnterZone(selfId, zoneId)
end

function fuben_zhenshoujindi:OnItemChanged(selfId, itemdataId)
end

function fuben_zhenshoujindi:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z,self.g_client_res)
    local nearmembercount = self:GetNearTeamCount(leaderObjId)
    for i = 1, nearmembercount do
        local member = self:GetNearTeamMember(leaderObjId, i)
        if self:LuaFnIsCanDoScriptLogic(member) then
            self:NewWorld(member, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z,self.g_client_res)
        end
    end
end
function fuben_zhenshoujindi:OnPlayerEnter(selfId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, sceneId, self.g_Fuben_X, self.g_Fuben_Z)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
	nFubenType = nFubenType == 0 and nFubenType or 1
	local exid = nFubenType == 0 and ScriptGlobal.MDEX_QINGQIU_TYPE_0 or ScriptGlobal.MDEX_QINGQIU_TYPE_1
	local hyid = nFubenType == 0 and 12 or 13
	local guid = self:LuaFnGetGUID(selfId)
    local NewTime = self:GetDayTime()
	for i,id in ipairs(self.g_Team_Guid) do
		if scene:get_param(id) == guid then
			if scene:get_param(id + 6) == 0 then
				local NowTime = self:GetMissionDataEx(selfId,160)
				if NowTime ~= tonumber(NewTime) then
					self:SetMissionDataEx(selfId,160,NewTime)
					self:SetMissionDataEx(selfId,102,0)
					self:SetMissionDataEx(selfId,103,0)
				end
				local today_count = self:GetMissionDataEx(selfId,exid)
				if today_count >= self.g_TodayMax[nFubenType] then
					scene:set_param(id,0)
					scene:set_param(id + 6,0)
					return
				end
				self:SetMissionDataEx(selfId,exid,today_count + 1)
				self:DungeonDone(selfId, hyid)
			end
			scene:set_param(id + 6,selfId)
			break
		end
	end
    self:SetUnitCampID(selfId, 109)
end

function fuben_zhenshoujindi:OnHumanDie(selfId, killerId)
    if self.g_DeadTrans == 1 then
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function fuben_zhenshoujindi:LeaveScene(selfId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
end

function fuben_zhenshoujindi:UpdateCurMainStep(nStep)
    local nCurStep = self:LuaFnGetCopySceneData_Param(self.g_SceneData_MainStep)
    if nCurStep == 3 and nStep <= 2 then
        return
    end
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, nStep)
end

function fuben_zhenshoujindi:OnCopySceneTimer(nowTime)
	local scene = self:get_scene()
	local membercount = scene:get_human_count()
	local oldsceneId = scene:get_param(3)
	for i=1,membercount do
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
				self:NewWorld(PlayerId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
			end
		end
	end

    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local nCurMainStep = self:LuaFnGetCopySceneData_Param(self.g_SceneData_MainStep)
    if nCurMainStep == 0 then
        self:LuaFnCreateMonster(49568, 181, 45, 3, -1, -1)
        local nNPCID = self:LuaFnCreateMonster(49569, 184, 46, 3, -1, self.g_QingQiuHu)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_CurQingQiuHuNPCID, nNPCID)
        self:LuaFnCreateMonster(
            49794,
            self.g_PosChuanSong[1],
            self.g_PosChuanSong[2],
            3,
            -1,
            self.g_ChuanSongScript
        )
        self:CreateMonster_SaoDi()
        self:BroadCastNpcTalkAllHuman(123)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 1)
    end
    if nCurMainStep == 2 then
        self:BroadCastNpcTalkAllHuman(124)
        local nNPCID = self:LuaFnGetCopySceneData_Param(self.g_SceneData_CurQingQiuHuNPCID)
        self:SetPatrolId(nNPCID, 0)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 3)
    end
    if nCurMainStep == 4 then
        self:CreateMonster_BOSS_1_NPC()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 5)
    end
    if nCurMainStep == 5 then
        if self:CheckAllHumanInPosDistance(self.g_PosYunJuanShu[1], self.g_PosYunJuanShu[2], 16) == 1 then
            self:BroadCastNpcTalkAllHuman(125)
            self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 6)
        end
    end
    if nCurMainStep == 7 then
        self:CreateMonster_BOSS_1_BOSS()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 8)
    end
    if nCurMainStep == 8 then
    end
    if nCurMainStep == 9 then
        self:ClearMonster_BOSS_1()
        self:CreateMonster_BOSS_2_NPC()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 10)
        local nNPCID = self:LuaFnGetCopySceneData_Param(self.g_SceneData_CurQingQiuHuNPCID)
        self:SetPatrolId(nNPCID, 1)
        self:TipAllHumanPaoPao(nNPCID, 529)
    end
    if nCurMainStep == 10 then
        if self:CheckAllHumanInPosDistance(self.g_PosBOSS_2[1], self.g_PosBOSS_2[2], 16) == 1 then
            self:BroadCastNpcTalkAllHuman(126)
            self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 11)
        end
    end
    if nCurMainStep == 11 then
        self:BroadCastNpcTalkAllHuman(127)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 12)
    end
    if nCurMainStep == 13 then
        self:CreateMonster_BOSS_2_BOSS()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 14)
    end
    if nCurMainStep == 14 then
    end
    if nCurMainStep == 15 then
        self:ClearMonster_BOSS_2()
        self:CreateMonster_BOSS_3_NPC()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 16)
        local nNPCID = self:LuaFnGetCopySceneData_Param(self.g_SceneData_CurQingQiuHuNPCID)
        self:SetPatrolId(nNPCID, 2)
        self:TipAllHumanPaoPao(nNPCID, 531)
    end
    if nCurMainStep == 16 then
        if self:CheckAllHumanInPosDistance(self.g_PosBOSS_3[1], self.g_PosBOSS_3[2], 16) == 1 then
            self:BroadCastNpcTalkAllHuman(128)
            self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 17)
        end
    end
    if nCurMainStep == 17 then
        self:BroadCastNpcTalkAllHuman(129)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 18)
    end
    if nCurMainStep == 18 then
    end
    if nCurMainStep == 19 then
        self:CreateMonster_BOSS_3_BOSS()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 20)
    end
    if nCurMainStep == 20 then
    end
    if nCurMainStep == 21 then
        self:ClearMonster_BOSS_3()
        self:EnterFinalBossProcedure()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 22)
        local nNPCID = self:LuaFnGetCopySceneData_Param(self.g_SceneData_CurQingQiuHuNPCID)
        self:SetPatrolId(nNPCID, 3)
        self:TipAllHumanPaoPao(nNPCID, 534)
    end
    if nCurMainStep == 22 then
        if self:CheckAllHumanInPosDistance(self.g_PosBOSS_5[1], self.g_PosBOSS_5[2], 16) == 1 then
            self:BroadCastNpcTalkAllHuman(130)
            self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 23)
        end
    end
    if nCurMainStep == 23 then
        self:BroadCastNpcTalkAllHuman(131)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 24)
    end
    if nCurMainStep == 24 then
    end
    if nCurMainStep == 25 then
        self:ActiveBOSSYunPiaoPiao()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 26)
    end
    if nCurMainStep == 26 then
    end
    if nCurMainStep == 27 then
        self:ClearMonster_BOSS_4()
        self:LuaFnSetCopySceneData_Param(4, 1)
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 28)
    end
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
                self:NewWorld(mems[i], oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
            end
        elseif leaveTickCount < self.g_CloseTick then
            self:LuaFnGetCopySceneData_Param(3)
            self:TipAllHuman(string.format("%d giây nữa phụ bản đóng, mọi người chuẩn bị rời!", (self.g_CloseTick - leaveTickCount) * self.g_TickTime))
        end
    elseif TickCount == self.g_LimitTimeSuccess then
        self:LuaFnSetCopySceneData_Param(4, 1)
    elseif TickCount == self.g_LimitTotalHoldTime then
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
end

function fuben_zhenshoujindi:ClearMonsterByName(szName)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == szName then
            self:SetCharacterDieTime(nMonsterId, 1000)
        end
    end
end

function fuben_zhenshoujindi:StrengthBOSS(monsterId)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    if nFubenType ~= 1 then
        return
    end
    --[[
    self:LuaFnSetLifeTimeAttrRefix_MaxHP(monsterId, self:LuaFnGetMaxBaseHp(monsterId) * self.g_BOSS_StrengthInDifficult)
    self:LuaFnSetLifeTimeAttrRefix_CriticalAttack(
        monsterId,
        self:LuaFnGetBaseCriticalAttack(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_Hit(monsterId, self:LuaFnGetBaseHit(monsterId) * self.g_BOSS_StrengthInDifficult)
    self:LuaFnSetLifeTimeAttrRefix_Miss(monsterId, self:LuaFnGetBaseMiss(monsterId) * self.g_BOSS_StrengthInDifficult)
    self:LuaFnSetLifeTimeAttrRefix_AttackPhysics(
        monsterId,
        self:LuaFnGetBaseAttackPhysics(monsterId) * self.g_BOSS_StrengthInDifficult * 1.2
    )
    self:LuaFnSetLifeTimeAttrRefix_DefencePhysics(
        monsterId,
        self:LuaFnGetBaseDefencePhysics(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_AttackMagic(
        monsterId,
        self:LuaFnGetBaseAttackMagic(monsterId) * self.g_BOSS_StrengthInDifficult * 1.2
    )
    self:LuaFnSetLifeTimeAttrRefix_DefenceMagic(
        monsterId,
        self:LuaFnGetBaseDefenceMagic(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_AttackCold(
        monsterId,
        self:LuaFnGetBaseAttackCold(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_ResistCold(
        monsterId,
        self:LuaFnGetBaseAttackCold(monsterId) * self.g_BOSS_StrengthInDifficult * 1.2
    )
    self:LuaFnSetLifeTimeAttrRefix_AttackFire(
        monsterId,
        self:LuaFnGetBaseAttackFire(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_ResistCold(
        monsterId,
        self:LuaFnGetBaseAttackFire(monsterId) * self.g_BOSS_StrengthInDifficult * 1.2
    )
    self:LuaFnSetLifeTimeAttrRefix_AttackLight(
        monsterId,
        self:LuaFnGetBaseAttackLight(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_ResistLight(
        monsterId,
        self:LuaFnGetBaseAttackLight(monsterId) * self.g_BOSS_StrengthInDifficult * 1.2
    )
    self:LuaFnSetLifeTimeAttrRefix_AttackPoison(
        monsterId,
        self:LuaFnGetBaseAttackPosion(monsterId) * self.g_BOSS_StrengthInDifficult
    )
    self:LuaFnSetLifeTimeAttrRefix_ResistPoison(
        monsterId,
        self:LuaFnGetBaseAttackPosion(monsterId) * self.g_BOSS_StrengthInDifficult * 1.2
    )
    ]]
end

function fuben_zhenshoujindi:ClearMonster_BOSS_4()
		if self:LuaFnGetCopySceneData_Param(23) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(23,1)
    self:ClearMonsterByName("云飘飘")
    local monsterID =
        self:LuaFnCreateMonster(49629, self.g_PosBOSS_5[1], self.g_PosBOSS_5[2], 3, -1, self.g_BOSS_DieScript[4])
    self:SetLevel(monsterID, 88)
    self:SetCharacterTitle(monsterID, "Chưởng môn Vân gia")
    self:SetCharacterDir(monsterID, 5)
    self:SetUnitCampID(monsterID, 109)
    self:TipAllHumanPaoPao(monsterID, 526)
end

function fuben_zhenshoujindi:OnFinalBossDie()
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 27)
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_CurBOSSID, 4)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local activeType = nFubenType == 0 and 30 or 31
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, membercount do
        local memberId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(memberId) and self:LuaFnIsCanDoScriptLogic(memberId) then
            self:LuaFnAddMissionHuoYueZhi(memberId, activeType)
            self:LuaFnAddSweepPointByID(memberId, nFubenType == 0 and 12 or 13, 1)
        end
    end
    if nFubenType == 1 then
        local nBoxId = self:DropBoxEnterScene(self.g_PosBOSS_5[1] + 2, self.g_PosBOSS_5[2] + 2)
        --local nRand = math.random(1, #(self.g_BOSS_DropItem[4]))
        self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 1, self.g_BOSS_DropItem[4][1]["item"])
    end
end

function fuben_zhenshoujindi:ActiveBOSSYunPiaoPiao()
		if self:LuaFnGetCopySceneData_Param(24) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(24,1)
    self:ClearMonsterByName("云飘飘")
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local nFoxMonsterIDTab = {49697, 49708, 49719, 49730, 49741}

    local monsterID
    if nFubenType == 0 then
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(1, #(nFoxMonsterIDTab))],
            self.g_PosBOSS_5[1],
            self.g_PosBOSS_5[2],
            21,
            -1,
            self.g_BOSS_5_NPC_BOSSAI
        )
    else
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(4, #(nFoxMonsterIDTab))],
            self.g_PosBOSS_5[1],
            self.g_PosBOSS_5[2],
            21,
            -1,
            self.g_BOSS_5_NPC_BOSSAI
        )
    end
    self:SetLevel(monsterID, 119)
    self:SetUnitCampID(monsterID, 110)
    self:SetMonsterFightWithNpcFlag(monsterID, 1)
    self:StrengthBOSS(monsterID)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetMonsterDataID(nMonsterId) == 49645 then
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
    monsterID = self:LuaFnCreateMonster(49645, self.g_PosBOSS_4[1], self.g_PosBOSS_4[2], 3, -1, 893038)
    self:SetCharacterDir(monsterID, 32)
end

function fuben_zhenshoujindi:EnterFinalBossProcedure()
		if self:LuaFnGetCopySceneData_Param(25) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(25,1)
    local nFox_1 = self:LuaFnCreateMonster(49573, 52, 80, 3, -1, -1)
    self:SetCharacterDir(nFox_1, 23)
    local monsterID = self:LuaFnCreateMonster(49629, self.g_PosBOSS_5[1], self.g_PosBOSS_5[2], 3, -1, self.g_BOSS_5_NPC)
    self:SetCharacterTitle(monsterID, "Chưởng môn Vân gia")
    self:SetLevel(monsterID, 88)
    self:SetCharacterDir(monsterID, 5)
    self:SetUnitCampID(monsterID, 109)
    monsterID = self:LuaFnCreateMonster(49645, self.g_PosBOSS_4[1], self.g_PosBOSS_4[2], 3, -1, -1)
    self:SetCharacterDir(monsterID, 32)
end

function fuben_zhenshoujindi:ClearMonster_BOSS_3()
		if self:LuaFnGetCopySceneData_Param(26) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(26,1)
    self:ClearMonsterByName("艾虎")
    local monsterID =
        self:LuaFnCreateMonster(49627, self.g_PosBOSS_3[1], self.g_PosBOSS_3[2], 3, -1, self.g_BOSS_DieScript[3])
    self:SetLevel(monsterID, 88)
    self:SetCharacterTitle(monsterID, "Kỳ tài Vân gia")
    self:SetCharacterDir(monsterID, 5)
    self:SetUnitCampID(monsterID, 109)
    self:TipAllHumanPaoPao(monsterID, 524)
end

function fuben_zhenshoujindi:OnBOSS_3Die()
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 21)
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_CurBOSSID, 3)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    if nFubenType == 1 then
        local nBoxId = self:DropBoxEnterScene(self.g_PosBOSS_3[1] + 2, self.g_PosBOSS_3[2] + 2)
        --local nRand = math.random(1, #(self.g_BOSS_DropItem[3]))
        self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 1, self.g_BOSS_DropItem[3][1]["item"])
    end
end

function fuben_zhenshoujindi:CreateMonster_BOSS_3_BOSS()
		if self:LuaFnGetCopySceneData_Param(22) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(22,1)
    self:ClearMonsterByName("艾虎")
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local nFoxMonsterIDTab = {49695, 49706, 49717, 49728, 49739}
    local monsterID
    if nFubenType == 0 then
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(1, #(nFoxMonsterIDTab))],
            self.g_PosBOSS_3[1],
            self.g_PosBOSS_3[2],
            21,
            -1,
            self.g_BOSS_3_NPC_BOSSAI
        )
    else
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(4, #(nFoxMonsterIDTab))],
            self.g_PosBOSS_3[1],
            self.g_PosBOSS_3[2],
            21,
            -1,
            self.g_BOSS_3_NPC_BOSSAI
        )
    end
    self:SetLevel(monsterID, 119)
    self:SetUnitCampID(monsterID, 110)
    self:SetMonsterFightWithNpcFlag(monsterID, 1)
    self:StrengthBOSS(monsterID)
end

function fuben_zhenshoujindi:CreateMonster_BOSS_3_NPC()
    local nFox_1 = self:LuaFnCreateMonster(49571, 56, 122, 3, -1, -1)
    self:SetCharacterDir(nFox_1, 5)
    --[[for i = 1, #(self.g_BOSS_3_ExtraNPC) do
        nFox_1 =
            self:LuaFnCreateMonster(
            self.g_BOSS_3_ExtraNPC[i]["id"],
            self.g_BOSS_3_ExtraNPC[i]["x"],
            self.g_BOSS_3_ExtraNPC[i]["z"],
            3,
            -1,
            -1
        )
        self:SetCharacterDir(nFox_1, self.g_BOSS_3_ExtraNPC[i]["dir"])
    end]]
    local monsterID = self:LuaFnCreateMonster(49627, self.g_PosBOSS_3[1], self.g_PosBOSS_3[2], 3, -1, self.g_BOSS_3_NPC)
    self:SetCharacterTitle(monsterID, "Kỳ tài Vân gia")
    self:SetLevel(monsterID, 88)
    self:SetCharacterDir(monsterID, 5)
    self:SetUnitCampID(monsterID, 109)
end

function fuben_zhenshoujindi:ClearMonster_BOSS_2()
		if self:LuaFnGetCopySceneData_Param(28) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(28,1)
    self:ClearMonsterByName("逸")
    local monsterID = self:LuaFnCreateMonster(49625, self.g_PosBOSS_2[1], self.g_PosBOSS_2[2], 3, -1, self.g_BOSS_DieScript[2])
    self:SetLevel(monsterID, 88)
    self:SetCharacterTitle(monsterID, "Vân gia khách khanh")
    self:SetCharacterDir(monsterID, 5)
    self:SetUnitCampID(monsterID, 109)
    self:TipAllHumanPaoPao(monsterID, 523)
end

function fuben_zhenshoujindi:OnBOSS_2Die()
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 15)
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_CurBOSSID, 2)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            self:LuaFnCancelSpecificImpact(nHumanId,31831)
            self:LuaFnCancelSpecificImpact(nHumanId,31838)
            self:LuaFnCancelSpecificImpact(nHumanId,31829)
            self:LuaFnCancelSpecificImpact(nHumanId,31830)
            self:LuaFnCancelSpecificImpact(nHumanId,34621)
            self:LuaFnCancelSpecificImpact(nHumanId,4806)
            self:LuaFnCancelSpecificImpact(nHumanId,34622)
            self:LuaFnCancelSpecificImpact(nHumanId,34623)
        end
    end
    if nFubenType == 1 then
        local nBoxId = self:DropBoxEnterScene(self.g_PosBOSS_2[1] + 2, self.g_PosBOSS_2[2] + 2)
        --local nRand = math.random(1, #(self.g_BOSS_DropItem[2]))
        self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 1, self.g_BOSS_DropItem[2][1]["item"])
    end
end

function fuben_zhenshoujindi:CreateMonster_BOSS_2_BOSS()
		if self:LuaFnGetCopySceneData_Param(27) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(27,1)
    self:ClearMonsterByName("逸")
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local nFoxMonsterIDTab = {49693, 49704, 49715, 49726, 49737}
    local monsterID
    if nFubenType == 0 then
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(1, #(nFoxMonsterIDTab))],
            self.g_PosBOSS_2[1],
            self.g_PosBOSS_2[2],
            21,
            -1,
            self.g_BOSS_2_NPC_BOSSAI
        )
    else
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(4, #(nFoxMonsterIDTab))],
            self.g_PosBOSS_2[1],
            self.g_PosBOSS_2[2],
            21,
            -1,
            self.g_BOSS_2_NPC_BOSSAI
        )
    end
    self:SetLevel(monsterID, 119)
    self:SetUnitCampID(monsterID, 110)
    self:SetMonsterFightWithNpcFlag(monsterID, 1)
    self:StrengthBOSS(monsterID)
end

function fuben_zhenshoujindi:CreateMonster_BOSS_2_NPC()
    local nFox_1 = self:LuaFnCreateMonster(49572, 154, 186, 3, -1, -1)
    self:SetCharacterDir(nFox_1, 9)
    local monsterID = self:LuaFnCreateMonster(49625, self.g_PosBOSS_2[1], self.g_PosBOSS_2[2], 3, -1, self.g_BOSS_2_NPC)
    self:SetCharacterTitle(monsterID, "Vân gia khách khanh")
    self:SetLevel(monsterID, 88)
    self:SetUnitCampID(monsterID, 109)
end

function fuben_zhenshoujindi:ClearMonster_BOSS_1()
		if self:LuaFnGetCopySceneData_Param(21) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(21,1)
    self:ClearMonsterByName("云卷舒")
    local monsterID =
        self:LuaFnCreateMonster(
        49690,
        self.g_PosYunJuanShu[1],
        self.g_PosYunJuanShu[2],
        3,
        -1,
        self.g_BOSS_DieScript[1]
    )
    self:SetLevel(monsterID, 88)
    self:SetCharacterTitle(monsterID, "Vân Gia Thống Lĩnh Hộ Vệ")
    self:SetUnitCampID(monsterID, 109)
    self:TipAllHumanPaoPao(monsterID, 522)
end

function fuben_zhenshoujindi:OnYunJuanShuDie()
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetMonsterDataID(nMonsterId) == 49576 then
            --清除荼蘼花
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 9)
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_CurBOSSID, 1)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    if nFubenType == 1 then
        local nBoxId = self:DropBoxEnterScene(self.g_PosYunJuanShu[1] + 2, self.g_PosYunJuanShu[2] + 2)
        --local nRand = math.random(1, #(self.g_BOSS_DropItem[1]))
        self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 1, self.g_BOSS_DropItem[1][1]["item"])
    end
end

function fuben_zhenshoujindi:CreateMonster_BOSS_1_BOSS()
		if self:LuaFnGetCopySceneData_Param(20) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(20,1)
    self:ClearMonsterByName("云卷舒")
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local nFoxMonsterIDTab = {49691, 49702, 49713, 49724, 49735}

    local monsterID
    if nFubenType == 0 then
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(1, #(nFoxMonsterIDTab))],
            self.g_PosYunJuanShu[1],
            self.g_PosYunJuanShu[2],
            27,
            0,
            self.g_BOSS_1_NPC_BOSSAI
        )
    else
        monsterID =
            self:LuaFnCreateMonster(
            nFoxMonsterIDTab[math.random(4, #(nFoxMonsterIDTab))],
            self.g_PosYunJuanShu[1],
            self.g_PosYunJuanShu[2],
            27,
            0,
            self.g_BOSS_1_NPC_BOSSAI
        )
    end
    self:SetLevel(monsterID, 119)
    self:SetUnitCampID(monsterID, 110)
    self:SetMonsterFightWithNpcFlag(monsterID, 1)
    self:StrengthBOSS(monsterID)
end

function fuben_zhenshoujindi:CreateMonster_BOSS_1_NPC()
    local nFox_1 = self:LuaFnCreateMonster(49570, 202, 125, 3, -1, -1)
    self:SetCharacterDir(nFox_1, 27)
    local monsterID =
        self:LuaFnCreateMonster(49690, self.g_PosYunJuanShu[1], self.g_PosYunJuanShu[2], 3, -1, self.g_BOSS_1_NPC)
    self:SetCharacterTitle(monsterID, "Vân Gia Thống Lĩnh Hộ Vệ")
    self:SetLevel(monsterID, 88)
    self:SetUnitCampID(monsterID, 109)
end

function fuben_zhenshoujindi:OnSaoDiDie()
    local nCurKill = self:LuaFnGetCopySceneData_Param(self.g_SceneData_SaoDiKillNum)
    self:TipAllHuman(string.format("Đã đuổi Hồ Quét Đất: %d/10", nCurKill + 1))
    if nCurKill + 1 >= 10 then
        self:TipAllHuman("#{ZSFB_20220105_114}")
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_MainStep, 4)
    end
    self:LuaFnSetCopySceneData_Param(self.g_SceneData_SaoDiKillNum, nCurKill + 1)
end

function fuben_zhenshoujindi:CreateMonster_SaoDi()
		if self:LuaFnGetCopySceneData_Param(19) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(19,1)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_SceneData_Type)
    local nFoxMonsterIDTab = {49772, 49773, 49774, 49775, 49776, 49777}

    if nFubenType == 0 then
        for i = 1, #(self.g_SaoDiFoxPos) do
            if self.g_SaoDiFoxPos[i] then
               local monsterID =
                    self:LuaFnCreateMonster(
                    nFoxMonsterIDTab[math.random(1, #(nFoxMonsterIDTab))],
                    self.g_SaoDiFoxPos[i][1],
                    self.g_SaoDiFoxPos[i][2],
                    14,
                    -1,
                    self.g_SaoDiFoxScriptID
                )
                self:SetLevel(monsterID, 88)
                self:SetCharacterName(monsterID, "扫地狐")
                self:SetUnitCampID(monsterID, 110)
                self:SetMonsterFightWithNpcFlag(monsterID, 1)
            end
        end
    else
        for i = 1, #(self.g_SaoDiFoxPos) do
            if self.g_SaoDiFoxPos[i] then
                local monsterID =
                    self:LuaFnCreateMonster(
                    nFoxMonsterIDTab[math.random(6, #(nFoxMonsterIDTab))],
                    self.g_SaoDiFoxPos[i][1],
                    self.g_SaoDiFoxPos[i][2],
                    14,
                    -1,
                    self.g_SaoDiFoxScriptID
                )
                self:SetLevel(monsterID, 88)
                self:SetCharacterName(monsterID, "扫地狐")
                self:SetUnitCampID(monsterID, 110)
                self:SetMonsterFightWithNpcFlag(monsterID, 1)
            end
        end
    end
end

function fuben_zhenshoujindi:CheckAllHumanInPosDistance(nPosX, nPosY, nDistance)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then
        return 0
    end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        local nPlayerPosX, nPlayerPosZ = self:LuaFnGetUnitPosition(PlayerId)
        local nPlayerDistance =
            math.floor(
            math.sqrt((nPosX - nPlayerPosX) * (nPosX - nPlayerPosX) + (nPosY - nPlayerPosZ) * (nPosY - nPlayerPosZ))
        )
        if nPlayerDistance <= nDistance then
            return 1
        end
    end
    return 0
end

function fuben_zhenshoujindi:TipAllHumanPaoPao(targetId, nPaoPaoID)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then
        return
    end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:Msg2Player(PlayerId, "@*;npcpaopao;" .. targetId .. ";" .. nPaoPaoID, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end

function fuben_zhenshoujindi:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then
        return
    end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:BeginEvent(self.script_id)
        self:AddText(Str)
        self:EndEvent()
        self:DispatchMissionTips(PlayerId)
    end
end

function fuben_zhenshoujindi:BroadCastNpcTalkAllHuman(nIndex)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then
        return
    end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:DoNpcTalk(PlayerId, nIndex)
    end
end

function fuben_zhenshoujindi:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function fuben_zhenshoujindi:NotifyTips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function fuben_zhenshoujindi:CalSweepData(selfId, index)
    if index == 12 then
        self:AddTodayEnterTime(selfId, 0)
    else
        self:AddTodayEnterTime(selfId, 1)
    end
end

return fuben_zhenshoujindi
