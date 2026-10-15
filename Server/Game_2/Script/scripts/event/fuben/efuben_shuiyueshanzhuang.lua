local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local efuben_shuiyueshanzhuang = class("efuben_shuiyueshanzhuang", script_base)
efuben_shuiyueshanzhuang.script_id = 892328
efuben_shuiyueshanzhuang.g_client_res = 549
-- efuben_shuiyueshanzhuang.g_LimitMembers = 1
efuben_shuiyueshanzhuang.g_LimitMembers = 1
efuben_shuiyueshanzhuang.g_minLevel = 80
efuben_shuiyueshanzhuang.g_CopySceneType = ScriptGlobal.FUBEN_SHUIYUESHANZHUANG
efuben_shuiyueshanzhuang.g_NoUserTime = 300
efuben_shuiyueshanzhuang.g_TickTime = 1
efuben_shuiyueshanzhuang.g_Fuben_X = 110
efuben_shuiyueshanzhuang.g_Fuben_Z = 216
efuben_shuiyueshanzhuang.g_Back_X = 129
efuben_shuiyueshanzhuang.g_Back_Z = 108
efuben_shuiyueshanzhuang.g_Back_SceneId = 1
efuben_shuiyueshanzhuang.g_CloseTick = 6
efuben_shuiyueshanzhuang.g_IDX_FuBenOpenTime	= 13
efuben_shuiyueshanzhuang.g_IDX_FuBenLifeStep    = 14
efuben_shuiyueshanzhuang.g_IDX_SYSZTimerStep	= 15
efuben_shuiyueshanzhuang.g_IDX_SYSZTimerScriptID= 16
efuben_shuiyueshanzhuang.g_FuBenTime		= 3*60*60
efuben_shuiyueshanzhuang.g_Name = "沈夜雨"
efuben_shuiyueshanzhuang.g_CopySceneType = ScriptGlobal.FUBEN_SHUIYUESHANZHUANG
efuben_shuiyueshanzhuang.g_BOSSList =
{
	["ShiSan_NPC"]				= { DataID=48503, Title="", posX=125, posY=168, Dir=0, BaseAI=3, AIScript=0, ScriptID=892335,MsgData = ""},
	["ShiSan_BOSS"]				= {Param = 22, DataID=48504, Title="", posX=125, posY=168, Dir=0, BaseAI=27, AIScript=0, ScriptID=892330,MsgData = "#{SYSZ_20210203_74}"},

	["FanWuJiu_NPC"]			= { DataID=48509, Title="", posX=125, posY=125, Dir=0, BaseAI=3, AIScript=0, ScriptID=892336,MsgData = ""},
	["FanWuJiu_BOSS"]			= {Param = 23, DataID=48510, Title="", posX=125, posY=125, Dir=0, BaseAI=27, AIScript=0, ScriptID=892331,MsgData = "#{SYSZ_20210203_77}"},

	["Aying_NPC"]				= { DataID=48516, Title="", posX=142, posY=65, Dir=0, BaseAI=3, AIScript=0, ScriptID=892337,MsgData = ""},
	["Aying_BOSS"]				= {Param = 24, DataID=48517, Title="", posX=142, posY=65, Dir=0, BaseAI=27, AIScript=0, ScriptID=892332,MsgData = "#{SYSZ_20210203_81}"},

	["YeLvHongYou_NPC"]				= { DataID=48520, Title="", posX=71, posY=65, Dir=0, BaseAI=3, AIScript=0, ScriptID=892338,MsgData = ""},
	["YeLvHongYou_BOSS"]			= {Param = 25, DataID=48521, Title="", posX=71, posY=65, Dir=0, BaseAI=27, AIScript=0, ScriptID=892334,MsgData = "#{SYSZ_20210203_84}"},
}
efuben_shuiyueshanzhuang.g_SmallMonsterAPos = {
    {113,	180},{113,	182},{116,	182},{116,	180},{113,	177},
    {126,	181},{123,	183},{124,	180},{122,	182},{122,	178},
}
efuben_shuiyueshanzhuang.g_SmallMonsterBPos = 
{
	{183,91},{182,91},{195,100},{202,97},{202,90},
}
efuben_shuiyueshanzhuang.g_LaoLongPos = 
{
	{181,95},{181,88},
}
efuben_shuiyueshanzhuang.g_DynamicRegionPos = {
	ShiSan_BOSS = {
		{ id = 2, data_index = 5, dir = 2.6, x = 115, y = 197, DataID = 49016 },
		{ id = 3, data_index = 6, dir = 0, x = 125, y = 148, DataID = 49016 },
	},
	FanWuJiu_BOSS = {
		{ id = 2, data_index = 5, dir = 2.6, x = 115, y = 197, DataID = 49016 },
		{ id = 3, data_index = 6, dir = 0, x = 125, y = 148, DataID = 49016 },
	},
	Aying_BOSS = {
		{ id = 2, data_index = 5, dir = 2.6, x = 115, y = 197, DataID = 49016 },
		{ id = 3, data_index = 6, dir = 0, x = 125, y = 148, DataID = 49016 },
	},
	YeLvHongYou_BOSS = {
		{ id = 2, data_index = 5, dir = 2.6, x = 115, y = 197, DataID = 49016 },
		{ id = 3, data_index = 6, dir = 0, x = 125, y = 148, DataID = 49016 },
	},
}

efuben_shuiyueshanzhuang.g_FightBOSSList =
{
	[1] = efuben_shuiyueshanzhuang.g_BOSSList["ShiSan_BOSS"].DataID,
	[2] = efuben_shuiyueshanzhuang.g_BOSSList["FanWuJiu_BOSS"].DataID,
	[3] = efuben_shuiyueshanzhuang.g_BOSSList["Aying_BOSS"].DataID,
	[4] = efuben_shuiyueshanzhuang.g_BOSSList["YeLvHongYou_BOSS"].DataID,
}
efuben_shuiyueshanzhuang.join_dungeon_times_count = 3

efuben_shuiyueshanzhuang.g_Team_Guid = {201,202,203,204,205,206}
-- efuben_shuiyueshanzhuang.g_Team_SetMD = efuben_shuiyueshanzhuang.g_Team_Guid + 6

function efuben_shuiyueshanzhuang:OnDefaultEvent(selfId, targetId, arg, index)
	local isok,msg = self:CheckAccept(selfId,targetId)
	if isok ~= 1 then
		if msg then
			self:BeginEvent(self.script_id)
			self:AddText(msg)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		end
		return
	end
    self:MakeCopyScene(selfId,81804202)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function efuben_shuiyueshanzhuang:CheckAccept(selfId,targetId)
    local lev = self:GetLevel(selfId)
    if lev < self.g_minLevel then
        self:BeginEvent(self.script_id)
        self:AddText("#{SYSZ_20210203_08}")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
		self:notify_tips(selfId,"#{SYSZ_20210203_09}")
        return 0
    end
    if not self:LuaFnHasTeam(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#{SYSZ_20210203_04}")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
		self:notify_tips(selfId,"#{SYSZ_20210203_05}")
        return 0
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("#{SYSZ_20210203_12}")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
		self:notify_tips(selfId,"#{SYSZ_20210203_13}")
        return 0
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#{SYSZ_20210203_06}")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
		self:notify_tips(selfId,"#{SYSZ_20210203_07}")
        return 0
    end
	local NearTeamSize = self:GetNearTeamCount(selfId)
	if self:GetTeamSize(selfId) ~= NearTeamSize then
		return 0, "#{SYSZ_20210203_15}"
	end
    local leaderObjId = selfId
    local NearCount = self:GetNearTeamCount(leaderObjId)
    local namenum = 0
    local notifyString = "Đội của ngài có thành viên("
    for i = 1, NearCount do
        local nPlayerId = self:GetNearTeamMember(selfId, i)
        local lev = self:GetLevel(nPlayerId)
        local nam = self:GetName(nPlayerId)
        if (lev < self.g_minLevel) then
            notifyString = notifyString .. nam .. " "
            namenum = 1
        end
    end
    notifyString = notifyString .. "Cấp độ chưa đủ."
    if (namenum > 0) then
        self:BeginEvent(self.script_id)
        self:AddText(notifyString)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return 0
    end
    for i = 1, NearCount do
        local TeammateID = self:GetNearTeamMember(leaderObjId, i)
        if (-1 == TeammateID) then return end
        local Level = self:GetLevel(TeammateID)
        if (Level < self.g_minLevel) then
            self:BeginEvent(self.script_id)
            self:AddText("Đội ngươi có thành viên chưa đủ cấp 80!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return 0
        end
    end
	local NearTeamSize = self:GetNearTeamCount(selfId)
	--是否有人今天做过3次了....
	local nHumanNum = 0
	local Humanlist = {}
	local CurDayTime = self:GetDayTime()
	for i=1, NearTeamSize do
		local PlayerId = self:GetNearTeamMember(selfId,i)
		local takenTimes = self:GetPlayerActiveTimes(PlayerId)
		if takenTimes >= self.join_dungeon_times_count then
			Humanlist[nHumanNum] = self:GetName(PlayerId)
			nHumanNum = nHumanNum + 1
		end

	end
	if nHumanNum > 0 then
		local msg = "    "
		for i=0, nHumanNum-2 do
			msg = msg .. Humanlist[i] .. "，"
		end
		msg = msg..Humanlist[nHumanNum-1] .. "Lượt khiêu chiến hôm nay đã hết."
		return 0,msg

	end
	return 1
end

function efuben_shuiyueshanzhuang:MakeCopyScene(selfId,paramx)
	if paramx ~= 81804202 then return end
    local param0 = 4
    local param1 = 3
    local mylevel
    local level0 = 0
    local level1 = 0
    local nearmembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearmembercount do
        local memId = self:GetNearTeamMember(selfId, i)
        local tempMemlevel = self:GetLevel(memId)
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
    config.navmapname = "shuiyueshanzhuang.nav"
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
    for i = 8, 31 do
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
	
	config.params[self.g_IDX_FuBenOpenTime] = self:LuaFnGetCurrentTime()
    config.params[define.CopyScene_LevelGap] = mylevel
    config.eventfile = "shuiyue_area.ini"
	config.monsterfile = "shuiyue_monster.ini"
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
function efuben_shuiyueshanzhuang:OnPlayerEnter(selfId )
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, sceneId, self.g_Fuben_X, self.g_Fuben_Z)
	self:DoNpcTalk(selfId, 105)
	--记录副本次数以及时间
	local guid = self:LuaFnGetGUID(selfId)
	local nowDate = self:GetDayTime()
	for i,id in ipairs(self.g_Team_Guid) do
		if scene:get_param(id) == guid then
			if scene:get_param(id + 6) == 0 then
				local DayTimes = self:GetMissionDataEx(selfId,142)
				local oldDate = (DayTimes % 100000 )
				local takenTimes = math.floor( DayTimes/100000 )
				if nowDate ~= oldDate then
					takenTimes = 0
				end
				if takenTimes >= self.join_dungeon_times_count then
					scene:set_param(id,0)
					scene:set_param(id + 6,0)
					return
				end
				DayTimes = (takenTimes + 1) * 100000 + nowDate
				self:SetMissionDataEx(selfId,142,DayTimes)
				self:DungeonDone(selfId, 11)
			end
			scene:set_param(id + 6,selfId)
			break
		end
	end
end

function efuben_shuiyueshanzhuang:OnCopySceneReady(destsceneId)
	local sceneId = self:get_scene_id()
	self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
	if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
		return
	end

    local nearteammembercount = self:GetNearTeamCount(leaderObjId)
    local mems = {}
    for i = 1, nearteammembercount do
        mems[i] = self:GetNearTeamMember(leaderObjId, i)
        self:GotoScene(mems[i], destsceneId)
    end
end

function efuben_shuiyueshanzhuang:GotoScene(ObjId, destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:NewWorld(ObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
end


function efuben_shuiyueshanzhuang:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) == self.g_Name then
        caller:AddNumTextWithTarget(self.script_id, "#{SYSZ_20210203_03}", 10, 1)
        caller:AddNumTextWithTarget(self.script_id, "#{SYSZ_20210308_01}", 11, 1)
    end
end

function efuben_shuiyueshanzhuang:OnDie(objId, selfId )
	local objType = self:GetCharacterType(selfId )
	if objType == "pet" then --如果是宠物的话，把这个ID设置成主人ID
		selfId = self:GetPetCreator(selfId )
	end
	if selfId == -1 then
		return
	end
	--是否是副本
	local sceneType = self:LuaFnGetSceneType()
	if sceneType ~= 1 then
		return
	end

	--副本关闭标志
	local leaveFlag = self:LuaFnGetCopySceneData_Param(4 )
	if leaveFlag == 1 then														-- 如果副本已经被置成关闭状态，则杀怪无效
		return
	end
	--取得当前场景里的人数
	local num = self:LuaFnGetCopyScene_HumanCount()
	local mems = {}
	for i = 1, num do
		mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
	end

	--取得杀死怪物的name
	local szName = self:GetName(objId )
	if szName == "伪装的家丁" then--小怪Group
		local KilledMonsterNum = self:LuaFnGetCopySceneData_Param(7)
		KilledMonsterNum = KilledMonsterNum + 1
		self:NotifyFailTips("Đã giết"..szName.."： "..KilledMonsterNum.."/10" )
		self:LuaFnSetCopySceneData_Param(7, KilledMonsterNum ) --设置杀小怪数量
		--刷新十三
		if KilledMonsterNum >= 10 then
			local MstId = self:CreateBOSS("ShiSan_NPC", -1, -1 )
			self:SetUnitReputationID(MstId, MstId, 0 )
			self:NotifyFailTips("#{SYSZ_20210203_73}")
		end
	elseif szName == "十三" then
		self:DisableDynamicRegions("ShiSan_BOSS")
		self:LuaFnSetCopySceneData_Param(8, 1 )
		self:NotifyFailTips("Đã giết"..szName.."： 1/1" )
		self:NotifyFailTips("#{SYSZ_20210203_75}")
		for i = 1,#mems do
			if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and self:LuaFnIsCharacterLiving(mems[i]) then
				self:DoNpcTalk(mems[i],107)
			end
		end
		local MstId = self:CreateBOSS("FanWuJiu_NPC", -1, -1 )
		self:SetUnitReputationID(MstId, MstId, 0 )
	elseif szName == "梵无救" then
		self:LuaFnSetCopySceneData_Param(9, 1 )
		self:NotifyFailTips("Đã giết"..szName.."： 1/1" )
		self:NotifyFailTips("#{SYSZ_20210203_78}")
		--清空梵体梵修
		local nMonsterNum = self:GetMonsterCount()
		for i=1,nMonsterNum do
			local MonsterId = self:GetMonsterObjID(i)
			if 48511 == self:GetMonsterDataID(MonsterId) or 48512 == self:GetMonsterDataID(MonsterId) then
				self:SetCharacterDieTime(MonsterId, 1000 )
			end
		end
		for i = 1,#mems do
			if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and self:LuaFnIsCharacterLiving(mems[i]) then
				self:DoNpcTalk(mems[i],109)
			end
		end
		self:CreateLaoLong()
	elseif szName == "护卫" or szName == "护卫长" then
		local KilledMonsterNum = self:LuaFnGetCopySceneData_Param(29)
		KilledMonsterNum = KilledMonsterNum + 1
		self:LuaFnSetCopySceneData_Param(29,KilledMonsterNum) --设置杀小怪数量
		self:NotifyFailTips("Đã xử vệ binh: "..KilledMonsterNum.."/6" )
		if KilledMonsterNum >= 6 then
			self:LuaFnSetCopySceneData_Param(9, 1 )
			self:NotifyFailTips("#{SYSZ_20210203_79}" )
			for i = 1,#mems do
				if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and self:LuaFnIsCharacterLiving(mems[i]) then
					self:DoNpcTalk(mems[i],110)
				end
			end
			local MstId = self:CreateBOSS("Aying_NPC", -1, -1 )
			self:SetUnitReputationID(MstId, MstId, 0 )
		end
	elseif szName == "阿莺" then
		self:LuaFnSetCopySceneData_Param(10, 1 )
		self:NotifyFailTips("Đã giết"..szName.."： 1/1" )
		self:NotifyFailTips("#{SYSZ_20210203_82}")
		for i = 1,#mems do
			if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and self:LuaFnIsCharacterLiving(mems[i]) then
				self:DoNpcTalk(mems[i],112)
			end
		end
		local MstId = self:CreateBOSS("YeLvHongYou_NPC", -1, -1 )
		self:SetUnitReputationID(MstId, MstId, 0 )
	elseif szName == "耶律泓佑" then-- boss王阎
		self:LuaFnSetCopySceneData_Param(11, 1 )
		self:NotifyFailTips("Đã giết"..szName.."： 1/1" )
		self:NotifyFailTips("Đã đánh bại Gia Luật Hoằng Hựu, phó bản sẽ đóng sau 5 phút." )
		for i = 1,#mems do
			if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) and self:LuaFnIsCharacterLiving(mems[i]) then
				self:LuaFnAddMissionHuoYueZhi(mems[i],16)
				self:LuaFnAddSweepPointByID(mems[i],11,1)
				self:DoNpcTalk(mems[i],114)
			end
		end
		local exitNpcId = self:LuaFnCreateMonster(48500, 74, 65, 3, -1, 892340)
		self:SetCharacterName(exitNpcId, "沈夜雨")
		self:SetCharacterTitle(exitNpcId, "水月山庄接引人")
		self:SetUnitCampID(exitNpcId, 8)
		self:SetUnitReputationID(exitNpcId, exitNpcId, 0)
		self:LuaFnSetCopySceneData_Param(4, 1 )--设置离开场景
	end
end

function efuben_shuiyueshanzhuang:DisableDynamicRegions(name)
	local dynamic_region = self.g_DynamicRegionPos[name]
	if dynamic_region then
		for _, region in ipairs(dynamic_region) do
			local monster_count = self:GetMonsterCount()
			for i = 1, monster_count do
				local MonsterId = self:GetMonsterObjID(i)
				local data_id = self:GetMonsterDataID(MonsterId)
				if data_id == region.DataID then
					self:SetCharacterDieTime(MonsterId, 1000 )
				end
			end
			self:DisableDynamicRegion(region.id, region.data_index)
		end
	end
end

function efuben_shuiyueshanzhuang:CreateBOSS(name, x, y )
	local BOSSData = self.g_BOSSList[name]
	if not BOSSData then
		return
	end
	if BOSSData.Param then
		if self:LuaFnGetCopySceneData_Param(BOSSData.Param) ~= 0 then
			return
		end
		self:LuaFnSetCopySceneData_Param(BOSSData.Param,1)
	end
	local posX
	local posY
	if x ~= -1 and y ~= -1 then
		posX = x
		posY = y
	else
		posX = BOSSData.posX
		posY = BOSSData.posY
	end

	local MstId = self:LuaFnCreateMonster(BOSSData.DataID, posX, posY, BOSSData.BaseAI, BOSSData.AIScript, BOSSData.ScriptID)
	self:SetObjDir(MstId, BOSSData.Dir )
	self:SetMonsterFightWithNpcFlag(MstId,0)
	if BOSSData.MsgData ~= "" then
		self:MonsterTalk(MstId,"Thủy Nguyệt Sơn Trang",BOSSData.MsgData)
	end
	if BOSSData.Title ~= "" then
		self:SetCharacterTitle(MstId, BOSSData.Title)
	end
	self:LuaFnSendSpecificImpactToUnit(MstId, MstId, MstId, 152, 0)

	local dynamic_region = self.g_DynamicRegionPos[name]
	if dynamic_region then
		for _, region in ipairs(dynamic_region) do
			self:EnableDynamicRegion(region.id, region.data_index, region.x, region.y, region.dir)
			local mst_id = self:LuaFnCreateMonster(region.DataID, region.x, region.y, 3, -1, -1)
			self:SetCharacterDir(mst_id, region.dir)
		end
	end
	self:LOGI("efuben_shuiyueshanzhuang CreateBOSS name =", name, ";x =", x, ";y =", y, ";stack =", debug.traceback())
	--统计创建BOSS....
	--self:AuditPMFCreateBoss(BOSSData.DataID )
	return MstId
end

--**********************************
--删除指定BOSS....
--**********************************
function efuben_shuiyueshanzhuang:DeleteBOSS(name )
	local BOSSData = self.g_BOSSList[name]
	if not BOSSData then
		return
	end
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if BOSSData.DataID == self:GetMonsterDataID(MonsterId ) then
			self:SetCharacterDieTime(MonsterId, 1000 )
		end
	end
end

function efuben_shuiyueshanzhuang:CheckHaveBOSS()
	local BossList = {}
	local nBossNum = 0
	local nMonsterNum = self:GetMonsterCount()

	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if self:LuaFnIsCharacterLiving(MonsterId) then
			local DataID = self:GetMonsterDataID(MonsterId )
			for _, dataId in ipairs(self.g_FightBOSSList) do
				if DataID == dataId then
					BossList[nBossNum] = self:GetName(MonsterId )
					nBossNum = nBossNum + 1
				end
			end
		end
	end
	if nBossNum > 0 then
		local msg = "Đang cùng"
		for i=0, nBossNum-2 do
			msg = msg .. BossList[i] .. "，"
		end
		msg = msg .. BossList[nBossNum-1] .. "Trong Chiến đấu"
		return 1, msg
	end
	return 0, ""
end

function efuben_shuiyueshanzhuang:Exit(selfId )
	self:CallScriptFunction((400900), "TransferFunc", selfId,1, self.g_Back_X, self.g_Back_Z)
end

function efuben_shuiyueshanzhuang:OnCopySceneTimer(nowTime)
	self:TickFubenCheck()
	self:TickFubenLife()
	self:TickSYSZTimer()
end
--**********************************
--副本检测....
--**********************************
function efuben_shuiyueshanzhuang:TickFubenCheck()
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
				self:Exit(PlayerId )
			end
		end
	end
end

function efuben_shuiyueshanzhuang:TickFubenLife()
	--初始化副本内的NPC....
	local TickCount = self:LuaFnGetCopySceneData_Param(2)						-- 取得已经执行的定时次数
	TickCount = TickCount + 1
	self:LuaFnSetCopySceneData_Param(2,TickCount)							-- 设置新的定时器调用次数
	-- local membercount = self:LuaFnGetCopyScene_HumanCount()
	-- local mems = {}
	-- for	i = 1, membercount do
		-- mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
		-- 检查参与次数
		-- local takenTimes = self:GetPlayerActiveTimes(mems[i] )
		-- if takenTimes >= 3 then
			-- self:NotifyFailTips("今天已经参加过3次水月山庄。请离副本" )
			-- self:Exit(mems[i])
		-- end
	-- end
	if TickCount == 1 then
		for i = 1, #(self.g_SmallMonsterAPos) do
			if self.g_SmallMonsterAPos[i] then
				local monsterID = self:LuaFnCreateMonster(48506, self.g_SmallMonsterAPos[i][1], self.g_SmallMonsterAPos[i][2], 14, -1, 892328)
				self:SetLevel(monsterID, 80 )
				self:SetCharacterName(monsterID, "伪装的家丁")
			end
		end
		return
	end
end

function efuben_shuiyueshanzhuang:CreateLaoLong()
	for i = 1, #(self.g_SmallMonsterBPos) do
		if self.g_SmallMonsterBPos[i] then
			local monsterID = self:LuaFnCreateMonster(49500, self.g_SmallMonsterBPos[i][1], self.g_SmallMonsterBPos[i][2], 14, -1, 892328)
			self:SetLevel(monsterID, 80 )
			self:SetCharacterName(monsterID, "护卫")
		end
	end
	self:LuaFnCreateMonster(49499,180,91, 14, -1, 892328)
	--创建牢笼
	local MsId_1 = self:LuaFnCreateMonster(48524, self.g_LaoLongPos[1][1], self.g_LaoLongPos[1][2], 3, -1, -1)
	local MsId_2 = self:LuaFnCreateMonster(48525, self.g_LaoLongPos[2][1], self.g_LaoLongPos[2][2], 3, -1, -1)
	self:SetCharacterDir(MsId_1,0)
	self:SetCharacterDir(MsId_2,0)
	--创建被关起来的NPC
	self:LuaFnCreateMonster(48534, 180,94, 3, -1, -1)
	self:LuaFnCreateMonster(48535, 179,96, 3, -1, -1)
	self:LuaFnCreateMonster(48531, 182,95, 3, -1, -1)
	self:LuaFnCreateMonster(48532, 182,96, 3, -1, -1)
	self:LuaFnCreateMonster(48533, 180,96, 3, -1, -1)
	self:LuaFnCreateMonster(48526, 182,88, 3, -1, -1)
	self:LuaFnCreateMonster(48527, 182,89, 3, -1, -1)
	self:LuaFnCreateMonster(48528, 181,86, 3, -1, -1)
	self:LuaFnCreateMonster(48529, 181,88, 3, -1, -1)
	self:LuaFnCreateMonster(48530, 181,87, 3, -1, -1)
end

function efuben_shuiyueshanzhuang:TickSYSZTimer()
	local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_SYSZTimerStep )
	if step <= 0 then
		return
	end
	local scriptID = self:LuaFnGetCopySceneData_Param(self.g_IDX_SYSZTimerScriptID )
	--回调指定脚本的OnTimer....
	self:CallScriptFunction(scriptID, "OnSYSZTimer", step )

	--如果已经走完所有step则关闭计时器....
	step = step - 1
	if step <= 0 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerStep, 0 )
		self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerScriptID, -1 )
	else
		self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerStep, step )
	end
end

function efuben_shuiyueshanzhuang:NotifyFailBox(selfId, targetId, msg )
	self:BeginEvent()
	self:AddText(msg)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId )
end

function efuben_shuiyueshanzhuang:NotifyFailTips(Tip)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			self:BeginEvent()
			self:AddText(Tip )
			self:EndEvent()
			self:DispatchMissionTips(nHumanId)
        end
    end
end

function efuben_shuiyueshanzhuang:IsSYSZTimerRunning()
	local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_SYSZTimerStep)
	if step > 0 then
		return 1
	else
		return 0
	end
end

function efuben_shuiyueshanzhuang:OpenSYSZTimer(allstep, ScriptID )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerStep, allstep )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerScriptID, ScriptID )
end

function efuben_shuiyueshanzhuang:GetPlayerActiveTimes(selfId)
	local nowDate = self:GetDayTime()
	local DayTimes = self:GetMissionDataEx(selfId,142)
	local oldDate = (DayTimes % 100000 )
	local takenTimes = math.floor( DayTimes/100000 )
	if nowDate ~= oldDate then
		takenTimes = 0
	end	
	return takenTimes
end
function efuben_shuiyueshanzhuang:CalSweepData(selfId)
	local nowDate = self:GetDayTime()
	local DayTimes = self:GetMissionDataEx(selfId,142)
	local oldDate = (DayTimes % 100000 )
	local takenTimes = math.floor( DayTimes/100000 )
	if nowDate ~= oldDate then
		takenTimes = 0
	end
	DayTimes = (takenTimes+1)*100000 + nowDate
	self:SetMissionDataEx(selfId,142,DayTimes)
end
return efuben_shuiyueshanzhuang