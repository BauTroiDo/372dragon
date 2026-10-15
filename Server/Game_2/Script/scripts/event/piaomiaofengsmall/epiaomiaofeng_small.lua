--缥缈峰副本....
local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local epiaomiaofeng_small = class("epiaomiaofeng_small", script_base)
--脚本号
epiaomiaofeng_small.g_CopySceneType = ScriptGlobal.FUBEN_PIAOMIAOFENG	--副本类型，定义在ScriptGlobal.lua里面

epiaomiaofeng_small.g_TickTime		= 1000				--回调脚本的时钟时间（单位：秒/次）
epiaomiaofeng_small.g_NoUserTime	= 300			--副本中没有人后可以继续保存的时间（单位：秒）
epiaomiaofeng_small.g_Fuben_X		= 124			--进入副本的位置X
epiaomiaofeng_small.g_Fuben_Z		= 164			--进入副本的位置Z
epiaomiaofeng_small.g_FuBenTime		= 3*60*60		--副本关闭时间....
epiaomiaofeng_small.g_client_res	= 261
--BOSS表....
epiaomiaofeng_small.g_BOSSList =
{
	["HaDaBa_NPC"]				= { DataID=9668, Title="", posX=124, posY=86, Dir=0, BaseAI=3, AIScript=0, ScriptID=402283 },
	["HaDaBa_BOSS"]				= { DataID=9660, Title="", posX=124, posY=86, Dir=0, BaseAI=27, AIScript=0, ScriptID=402277, Param = 22 },

	["SangTuGong_NPC"]		= { DataID=9669, Title="", posX=41, posY=105, Dir=0, BaseAI=3, AIScript=0, ScriptID=402284 },
	["SangTuGong_BOSS"]		= { DataID=9661, Title="", posX=41, posY=105, Dir=0, BaseAI=27, AIScript=0, ScriptID=402278, Param = 23 },
	["JiangShi_BOSS"]			= { DataID=9662, Title="", posX=0, posY=0, Dir=0, BaseAI=28, AIScript=0, ScriptID=-1 },

	["WuLaoDa_NPC"]				= { DataID=9670, Title="Vạn Tiên Chi Thủ", posX=117, posY=49, Dir=11, BaseAI=3, AIScript=0, ScriptID=402285 },
	["WuLaoDaLoss_NPC"]		= { DataID=9671, Title="Vạn Tiên Chi Thủ", posX=0, posY=0, Dir=0, BaseAI=3, AIScript=0, ScriptID=402288 },
	["WuLaoDa_BOSS"]			= { DataID=9663, Title="Vạn Tiên Chi Thủ", posX=117, posY=49, Dir=11, BaseAI=27, AIScript=0, ScriptID=402279, Param = 24 },

	["ZhuoBuFan_BOSS"]		= { DataID=9664, Title="Kiếm Thần", posX=121, posY=31, Dir=0, BaseAI=27, AIScript=0, ScriptID=402280, Param = 25 },
	["BuPingDaoRen_BOSS"]	= { DataID=9665, Title="Giao Vương", posX=129, posY=31, Dir=0, BaseAI=27, AIScript=261, ScriptID=402281, Param = 26 },

	["DuanMuYuan_BOSS"]		= { DataID=9667, Title="", posX=125, posY=36, Dir=0, BaseAI=0, AIScript=0, ScriptID=402287, Param = 28 },

	["FuMinYi_NPC"]				= { DataID=9672, Title="", posX=159, posY=54, Dir=11, BaseAI=3, AIScript=0, ScriptID=402286 },

	["LiQiuShui_BOSS"]		= { DataID=9666, Title="神秘女子", posX=125, posY=36, Dir=11, BaseAI=27, AIScript=0, ScriptID=402282, Param = 27 },
}

epiaomiaofeng_small.g_FightBOSSList =
{
	[1] = epiaomiaofeng_small.g_BOSSList["HaDaBa_BOSS"].DataID,
	[2] = epiaomiaofeng_small.g_BOSSList["SangTuGong_BOSS"].DataID,
	[3] = epiaomiaofeng_small.g_BOSSList["WuLaoDa_BOSS"].DataID,
	[4] = epiaomiaofeng_small.g_BOSSList["ZhuoBuFan_BOSS"].DataID,
	[5] = epiaomiaofeng_small.g_BOSSList["BuPingDaoRen_BOSS"].DataID,
	[6] = epiaomiaofeng_small.g_BOSSList["LiQiuShui_BOSS"].DataID
}

--是否可以挑战某个BOSS的标记列表....
epiaomiaofeng_small.g_BattleFlagTbl =
{
	["HaDaBa"]			= 8,	--是否可以挑战哈大霸...
	["SangTuGong"]		= 9,	--是否可以挑战桑土公....
	["WuLaoDa"]			= 10,	--是否可以挑战乌老大....
	["ShuangZi"]		= 11,	--是否可以挑战双子....
	["LiQiuShui"]		= 12,	--是否可以挑战李秋水....
}

--场景变量索引....是否可以挑战某个BOSS的标记....
-- 0=不能挑战 1=可以挑战 2=已经挑战过了
epiaomiaofeng_small.g_IDX_BattleFlag_Hadaba			= 8
epiaomiaofeng_small.g_IDX_BattleFlag_Sangtugong	= 9
epiaomiaofeng_small.g_IDX_BattleFlag_Wulaoda		= 10
epiaomiaofeng_small.g_IDX_BattleFlag_Shuangzi		= 11
epiaomiaofeng_small.g_IDX_BattleFlag_Liqiushui	= 12

epiaomiaofeng_small.g_IDX_FuBenOpenTime		= 13	--副本建立的时间....
epiaomiaofeng_small.g_IDX_FuBenLifeStep		= 14	--副本生命期的step....(包括建立NPC....关闭倒计时提示....)

--场景变量索引....通用的缥缈峰计时器....主要用于激活BOSS战斗....
epiaomiaofeng_small.g_IDX_PMFTimerStep			= 15
epiaomiaofeng_small.g_IDX_PMFTimerScriptID	= 16

--场景变量索引....乌老大死亡的计时器....用于处理死亡逻辑....
epiaomiaofeng_small.g_IDX_WuLaoDaDieStep				= 17
epiaomiaofeng_small.g_IDX_WuLaoDaDieScriptID		= 18
epiaomiaofeng_small.g_IDX_WuLaoDaDiePosX				=	19
epiaomiaofeng_small.g_IDX_WuLaoDaDiePosY				=	20
epiaomiaofeng_small.join_dungeon_times_count = 3
epiaomiaofeng_small.min_team_size = 3
epiaomiaofeng_small.g_Team_Guid = {201,202,203,204,205,206}


--**********************************
--任务入口函数....
--**********************************
function epiaomiaofeng_small:OnDefaultEvent(selfId, targetId )

	--检测是否可以进入副本....
	local ret, msg = self:CheckCanEnter(selfId)
	if 1 ~= ret then
		self:BeginEvent(self.script_id)
		self:AddText(msg)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end

	--关闭NPC对话窗口....
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
	self:MakeCopyScene(selfId,810842022 )
end

--**********************************
--列举事件
--**********************************
function epiaomiaofeng_small:OnEnumerate(caller)
	caller:AddNumTextWithTarget(self.script_id, "Trận Chiến Đầu Tiên tại Phiêu Miễu Phong", 10, 1 )
end

--**********************************
--检测是否可以进入此副本....
--**********************************
function epiaomiaofeng_small:CheckCanEnter(selfId)
	--是否有队伍....
	if not self:LuaFnHasTeam(selfId) then
		return 0, "#{PMF_20080521_02}"
	end
	--是不是队长....
	if self:GetTeamLeader(selfId) ~= selfId then
		return 0, "#{PMF_20080521_03}"
	end
	--人数是否够....
	if self:GetTeamSize(selfId) < self.min_team_size then
		return 0, "#{PMF_20080521_04}"
	end

	--是否都在附近....
	local NearTeamSize = self:GetNearTeamCount(selfId)
	local team_size = self:GetTeamSize(selfId)
	print("NearTeamSize =", NearTeamSize, ";team_size =", team_size)
	if team_size ~= NearTeamSize then
		return 0, "#{PMF_20080521_05}"
	end

	local Humanlist = {}
	local nHumanNum = 0

	--是否有人不够75级....
	for i=1, NearTeamSize do
		local PlayerId = self:GetNearTeamMember(selfId, i )
		if self:GetLevel(PlayerId) < 75 then
			Humanlist[nHumanNum] = self:GetName(PlayerId )
			nHumanNum = nHumanNum + 1
		end
	end

	if nHumanNum > 0 then
		local msg = "    Trong đội ngũ của"
		for i=1, nHumanNum do
			msg = msg .. Humanlist[i] .. "，"
		end
		msg = msg .. Humanlist[nHumanNum-1] .. "tu vi còn nông, tốt nhất đừng đi."
		return 0, msg
	end

	--是否有人今天做过1次了....
	nHumanNum = 0
	local CurDayTime = self:GetDayTime()
	for i=1, NearTeamSize do
		local PlayerId = self:GetNearTeamMember(selfId, i )
		local lastTime = self:GetMissionData(PlayerId, define.MD_ENUM.MD_PIAOMIAOFENG_SMALL_LASTTIME )
		local lastDayTime = math.floor( lastTime / 100 )
		local lastDayCount = lastTime % 100
		if CurDayTime > lastDayTime then
			lastDayCount = 0
		end

		if lastDayCount >= 2 then
			nHumanNum = nHumanNum + 1
			Humanlist[nHumanNum] = self:GetName(PlayerId )
		end
	end
	if nHumanNum > 0 then
		local msg = "    "
		for i=1, nHumanNum do
			msg = msg .. Humanlist[i] .. "，"
		end
		msg = msg .. "#{XPMCZ_081108_1}"
		return 0, msg
	end
	return 1
end

--**********************************
--创建副本....
--**********************************
function epiaomiaofeng_small:MakeCopyScene(selfId,paramx )
	if paramx ~= 810842022 then return end
	local x,z = self:LuaFnGetWorldPos(selfId)
	local leaderguid = self:LuaFnObjId2Guid(selfId)
	local sceneId = self:get_scene_id()

	local config = {}
	config.navmapname = "piaomiao.nav"							-- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
	config.client_res = self.g_client_res
	config.teamleader = leaderguid
	config.NoUserCloseTime = 0
	config.Timer = self.g_TickTime
	config.params = {}
	config.params[0] = self.g_CopySceneType						-- 设置副本类型
	config.params[1] = self.script_id							-- 将1号数据设置为副本场景事件脚本号
	config.params[2] = 0										-- 设置定时器调用次数
	config.params[3] = sceneId
	config.params[4] = x
	config.params[5] = z
	config.params[6] = self:GetTeamId(selfId)
	config.params[7] = 0
	config.eventfile = "piaomiao_area.ini"
	config.monsterfile = "piaomiao_monster.ini"
	config.patrolpoint = "piaomiao_patrolpoint.ini"
	config.sn 		 = self:LuaFnGenCopySceneSN()

	for i=8, 31 do
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
	config.params[self.g_IDX_BattleFlag_Hadaba] = 1
	config.params[self.g_IDX_BattleFlag_Sangtugong] = 0
	config.params[self.g_IDX_BattleFlag_Wulaoda] = 0
	config.params[self.g_IDX_BattleFlag_Shuangzi] = 0
	config.params[self.g_IDX_BattleFlag_Liqiushui] = 0
	config.params[self.g_IDX_FuBenOpenTime] = self:LuaFnGetCurrentTime()
	config.params[self.g_IDX_FuBenLifeStep] = 0
	config.params[self.g_IDX_PMFTimerStep] = 0
	config.params[self.g_IDX_PMFTimerScriptID] = -1

	config.params[self.g_IDX_WuLaoDaDieStep] = 0
	config.params[self.g_IDX_WuLaoDaDieScriptID] = -1
	config.params[self.g_IDX_WuLaoDaDiePosX] = 0
	config.params[self.g_IDX_WuLaoDaDiePosY] = 0

	local bRetSceneID = self:LuaFnCreateCopyScene(config)
	local text
	if bRetSceneID>0 then
		text = "Tạo phó bản thành công!"
	else
		text = "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!"
	end
	self:notify_tips(selfId, text)
end

--**********************************
--副本事件....
--**********************************
function epiaomiaofeng_small:OnCopySceneReady(destsceneId)
	--进入副本的规则
	-- 1，如果这个玩家没有组队，就传送这个玩家自己进入副本
	-- 2, 如果玩家有队伍，但是玩家不是队长，就传送自己进入副本
	-- 3，如果玩家有队伍，并且这个玩家是队长，就传送自己和附近队友一起进去
	local sceneId = self:get_scene_id()

	self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId) --设置副本入口场景号
	local leaderguid  = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
	local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)

	if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
		return
	end
	--统计创建副本次数....
	--AuditPMFCreateFuben(leaderObjId)
	local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
	if not self:LuaFnHasTeam(leaderObjId ) then
		self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
	else
		if not self:IsCaptain(leaderObjId)  then
			self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
		else
			local nearteammembercount = self:GetNearTeamCount(leaderObjId)
			local mems = {}
			for	i=1,nearteammembercount do
				mems[i] = self:GetNearTeamMember(leaderObjId, i)
				--self:LuaFnAddSalaryPoint(sceneId,mems[i],11,1)
				self:NewWorld(mems[i], destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
			end
		end
	end
end

--**********************************
--副本场景定时器事件....
--**********************************
function epiaomiaofeng_small:OnCopySceneTimer(nowTime )
	self:TickFubenCheck()
	self:TickFubenLife()
	self:TickPMFTimer()
	self:TickWuLaoDaDieTimer()
	self:TickJianWuArea(nowTime )
end

--**********************************
--副本检测....
--**********************************
function epiaomiaofeng_small:TickFubenCheck()
	local scene = self:get_scene()
	local nHumanNum = scene:get_human_count()
	local oldSceneId = scene:get_param(3)
	local oldX = scene:get_param(4)
	local oldZ = scene:get_param(5)
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
				self:NewWorld(PlayerId, oldSceneId, nil, oldX, oldZ )
			end
		end
	end
end

--**********************************
--有玩家进入副本事件....
--**********************************
function epiaomiaofeng_small:OnPlayerEnter(selfId)
	--设置死亡事件....
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, sceneId, epiaomiaofeng_small.g_Fuben_X, epiaomiaofeng_small.g_Fuben_Z )

	local guid = self:LuaFnGetGUID(selfId)
	for i,id in ipairs(self.g_Team_Guid) do
		if scene:get_param(id) == guid then
			if scene:get_param(id + 6) == 0 then
				local lastTime = self:GetMissionData(selfId, define.MD_ENUM.MD_PIAOMIAOFENG_SMALL_LASTTIME )
				local lastDayTime = math.floor( lastTime / 100 )
				local lastDayCount = lastTime % 100
				local CurDayTime = self:GetDayTime()
				if CurDayTime > lastDayTime then
					lastDayTime = CurDayTime
					lastDayCount = 0
				end
				if lastDayCount >= self.join_dungeon_times_count then
					scene:set_param(id,0)
					scene:set_param(id + 6,0)
					return
				end
				lastDayCount = lastDayCount + 1
				lastTime = lastDayTime * 100 + lastDayCount
				self:SetMissionData(selfId, define.MD_ENUM.MD_PIAOMIAOFENG_SMALL_LASTTIME, lastTime )
				self:DungeonDone(selfId, 9)
			end
			scene:set_param(id + 6,selfId)
			break
		end
	end
end

--**********************************
--有玩家在副本中死亡事件....
--**********************************
function epiaomiaofeng_small:OnHumanDie()
end

--**********************************
--提示所有副本内玩家....
--**********************************
function epiaomiaofeng_small:TipAllHuman(Str )
	local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanNum do
		local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(PlayerId ) and self:LuaFnIsCanDoScriptLogic(PlayerId ) then
			self:notify_tips(PlayerId, Str)
		end
	end
end

--**********************************
--Tick副本生命期....
--**********************************
function epiaomiaofeng_small:TickFubenLife()
	local openTime = self:LuaFnGetCopySceneData_Param(self.g_IDX_FuBenOpenTime )
	local leftTime = openTime + self.g_FuBenTime - self:LuaFnGetCurrentTime()
	local lifeStep = self:LuaFnGetCopySceneData_Param(self.g_IDX_FuBenLifeStep )
	if lifeStep == 15 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 16 )

		local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
		local oldSceneId = self:LuaFnGetCopySceneData_Param(3 )
		local oldX = self:LuaFnGetCopySceneData_Param(4 )
		local oldZ = self:LuaFnGetCopySceneData_Param(5 )
		for i=1, nHumanNum do
			local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(PlayerId ) and self:LuaFnIsCanDoScriptLogic(PlayerId ) then
				self:NewWorld(PlayerId, oldSceneId, nil, oldX, oldZ )
			end
		end
		return
	end

	if lifeStep == 14 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 15 )
		self:TipAllHuman("Phó bản sẽ đóng sau 1 giây." )
		return
	end

	if lifeStep == 13 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 14 )
		self:TipAllHuman("Phó bản sẽ đóng sau 2 giây." )
		return
	end

	if lifeStep == 12 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 13 )
		self:TipAllHuman("Phó bản sẽ đóng sau 3 giây." )
		return
	end

	if lifeStep == 11 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 12 )
		self:TipAllHuman("Phó bản sẽ đóng sau 4 giây." )
		return
	end

	if lifeStep == 10 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 11 )
		self:TipAllHuman("Phó bản sẽ đóng sau 5 giây." )
		return
	end

	if leftTime <= 10 and lifeStep == 9 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 10 )
		self:TipAllHuman("Phó bản sẽ đóng sau 10 giây." )
		return
	end

	if leftTime <= 30 and lifeStep == 8 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 9 )
		self:TipAllHuman("Phó bản sẽ đóng sau 30 giây." )
		return
	end

	if leftTime <= 60 and lifeStep == 7 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 8 )
		self:TipAllHuman("Phó bản sẽ đóng sau 1 phút." )
		return
	end

	if leftTime <= 120 and lifeStep == 6 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 7 )
		self:TipAllHuman("Phó bản sẽ đóng sau 2 phút." )
		return
	end

	if leftTime <= 180 and lifeStep == 5 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 6 )
		self:TipAllHuman("Phó bản sẽ đóng sau 3 phút." )
		return
	end

	if leftTime <= 300 and lifeStep == 4 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 5 )
		self:TipAllHuman("Phó bản sẽ đóng sau 5 phút." )
		return
	end

	if leftTime <= 900 and lifeStep == 3 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 4 )
		self:TipAllHuman("Phó bản sẽ đóng sau 15 phút." )
		return
	end

	if leftTime <= 1800 and lifeStep == 2 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 3 )
		self:TipAllHuman("Phó bản sẽ đóng sau 30 phút." )
		return
	end

	if leftTime <= 3600 and lifeStep == 1 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 2 )
		self:TipAllHuman("Phó bản sẽ đóng sau 60 phút." )
		return
	end

	--初始化副本内的NPC....
	if lifeStep == 0 then
		local MstId = self:CreateBOSS("HaDaBa_NPC", -1, -1 )
		self:SetUnitReputationID(MstId, MstId, 0 )
		self:SetUnitCampID(MstId, 8)

		MstId = self:CreateBOSS("SangTuGong_NPC", -1, -1 )
		self:SetUnitReputationID(MstId, MstId, 0 )
		self:SetUnitCampID(MstId, 8)

		MstId = self:CreateBOSS("WuLaoDa_NPC", -1, -1 )
		self:SetUnitReputationID(MstId, MstId, 0 )
		self:SetUnitCampID(MstId, 8)

		MstId = self:CreateBOSS("FuMinYi_NPC", -1, -1 )
		self:SetUnitReputationID(MstId, MstId, 0 )
		self:SetUnitCampID(MstId, 8)
		self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 1 )
		return
	end

end

--**********************************
--Tick缥缈峰计时器....
--**********************************
function epiaomiaofeng_small:TickPMFTimer()
	local step = self:LuaFnGetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerStep )
	if step <= 0 then
		return
	end
	local scriptID = self:LuaFnGetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerScriptID )
	--回调指定脚本的OnTimer....
	self:CallScriptFunction(scriptID, "OnPMFTimer", step )

	--如果已经走完所有step则关闭计时器....
	step = step - 1
	if step <= 0 then
		self:LuaFnSetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerStep, 0 )
		self:LuaFnSetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerScriptID, -1 )
	else
		self:LuaFnSetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerStep, step )
	end
end

--**********************************
--开启缥缈峰计时器....
--**********************************
function epiaomiaofeng_small:OpenPMFTimer(allstep, ScriptID )
	self:LuaFnSetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerStep, allstep )
	self:LuaFnSetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerScriptID, ScriptID )
end

--**********************************
--当前缥缈峰计时器是否激活....
--**********************************
function epiaomiaofeng_small:IsPMFTimerRunning()
	local step = self:LuaFnGetCopySceneData_Param(epiaomiaofeng_small.g_IDX_PMFTimerStep )
	if step > 0 then
		return 1
	else
		return 0
	end
end

--**********************************
--Tick乌老大死亡计时器....
--**********************************
function epiaomiaofeng_small:TickWuLaoDaDieTimer()
	local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_WuLaoDaDieStep )
	if step <= 0 then
		return
	end
	local scriptID = self:LuaFnGetCopySceneData_Param(self.g_IDX_WuLaoDaDieScriptID )
	local posX = self:LuaFnGetCopySceneData_Param(self.g_IDX_WuLaoDaDiePosX )
	local posY = self:LuaFnGetCopySceneData_Param(self.g_IDX_WuLaoDaDiePosY )

	--回调指定脚本的OnTimer....
	self:CallScriptFunction(scriptID, "OnHaDaBaDieTimer", step, posX, posY )

	--如果已经走完所有step则关闭计时器....
	step = step - 1
	if step <= 0 then
		self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDieStep, 0 )
		self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDieScriptID, -1 )
		self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDiePosX, 0 )
		self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDiePosY, 0 )
	else
		self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDieStep, step )
	end
end

--**********************************
--开启乌老大死亡计时器....
--**********************************
function epiaomiaofeng_small:OpenWuLaoDaDieTimer(allstep, ScriptID, posX, posY )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDieStep, allstep )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDieScriptID, ScriptID )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDiePosX, posX )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_WuLaoDaDiePosY, posY )
end

--**********************************
--Tick剑舞区域....
--只要玩家站在场景里的6个光柱内....每秒都能获得一个免疫剑舞的buff....
--**********************************
function epiaomiaofeng_small:TickJianWuArea(nowTime )
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			local x,z = self:GetWorldPos(nHumanId)
			local buff1 = -1
			local buff2 = 10376

			if x>=112 and x<=116 and z>=27 and z<=31 then
				buff1 = 10370
			elseif x>=134 and x<=138 and z>=27 and z<=31 then
				buff1 = 10374
			elseif x>=145 and x<=149 and z>=46 and z<=50 then
				buff1 = 10375
			elseif x>=134 and x<=138 and z>=65 and z<=69 then
				buff1 = 10371
			elseif x>=112 and x<=116 and z>=65 and z<=69 then
				buff1 = 10373
			elseif x>=101 and x<=105 and z>=46 and z<=50 then
				buff1 = 10372
			end
			if buff1 ~= -1 then
				self:LuaFnSendSpecificImpactToUnit(nHumanId, nHumanId, nHumanId, buff1, 0)
				self:LuaFnSendSpecificImpactToUnit(nHumanId, nHumanId, nHumanId, buff2, 0)
			end
		end
	end
end

--**********************************
--BOSS脱战....
--**********************************
function epiaomiaofeng_small:SetBossLeaveCombat(name, x, y )
	if name == "BuPingDaoRen_BOSS" or name == "ZhuoBuFan_BOSS" then
		local idx = self.g_BattleFlagTbl[ "ShuangZi" ]
		local create_flag = self:LuaFnGetCopySceneData_Param(idx)
		if create_flag == 0 or create_flag == 2 then
			return
		end
		local BOSSData = self.g_BOSSList[name]
		if not BOSSData then
			return
		elseif not BOSSData.Param then
			return
		end
		self:LuaFnSetCopySceneData_Param(BOSSData.Param,0 )
	else
		local idx = self.g_BattleFlagTbl[ name ]
		local create_flag = self:LuaFnGetCopySceneData_Param(idx)
		if create_flag == 0 or create_flag == 2 then
			return
		end
		local boss_name = name.."_BOSS"
		local BOSSData = self.g_BOSSList[boss_name]
		if not BOSSData then
			return
		elseif not BOSSData.Param then
			return
		end
		self:LuaFnSetCopySceneData_Param(BOSSData.Param,0 )
	end
end

--**********************************
--创建指定BOSS....
--**********************************
function epiaomiaofeng_small:CreateBOSS(name, x, y )
	local BOSSData = self.g_BOSSList[name]
	if not BOSSData then
		return
	end
	if BOSSData.Param then
		if self:LuaFnGetCopySceneData_Param(BOSSData.Param) ~= 0 then
			return -1
		end
		self:LuaFnSetCopySceneData_Param(BOSSData.Param, 1 )
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

	local MstId = self:LuaFnCreateMonster(BOSSData.DataID, posX, posY, BOSSData.BaseAI, BOSSData.AIScript, BOSSData.ScriptID )
	self:SetObjDir(MstId, BOSSData.Dir )
	self:SetMonsterFightWithNpcFlag(MstId, 0)
	if string.sub(name, -4) == "_NPC" then
		self:SetUnitCampID(MstId, 8)
	end
	if BOSSData.Title ~= "" then
		self:SetCharacterTitle(MstId, BOSSData.Title)
	end
	self:LuaFnSendSpecificImpactToUnit(MstId, MstId, MstId, 152, 0)

	--统计创建BOSS....
	--self:AuditPMFCreateBoss(BOSSData.DataID )
	return MstId
end

--**********************************
--删除指定BOSS....
--**********************************
function epiaomiaofeng_small:DeleteBOSS(name )
	local BOSSData = self.g_BOSSList[name]
	if not BOSSData then
		return
	end
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if BOSSData.DataID == self:GetMonsterDataID(MonsterId ) then
			self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, 152, 0)
			self:SetCharacterDieTime(MonsterId, 1000 )
		end
	end
end

--**********************************
--寻找指定BOSS....
--**********************************
function epiaomiaofeng_small:FindBOSS(name )
	local BOSSData = self.g_BOSSList[name]
	if not BOSSData then
		return -1
	end
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if BOSSData.DataID == self:GetMonsterDataID(MonsterId ) then
			return MonsterId
		end
	end
	return -1
end

--**********************************
--检测当前是否已经存在一个BOSS了....
--**********************************
function epiaomiaofeng_small:CheckHaveBOSS()
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

--**********************************
--获取是否可以挑战某个BOSS的标记....
--**********************************
function epiaomiaofeng_small:GetBossBattleFlag(bossName )
	local idx = self.g_BattleFlagTbl[ bossName ]
	return self:LuaFnGetCopySceneData_Param(idx )
end

--**********************************
--设置是否可以挑战某个BOSS的标记....
--**********************************
function epiaomiaofeng_small:SetBossBattleFlag(bossName, bCan )
	local idx = self.g_BattleFlagTbl[ bossName ]
	self:LuaFnSetCopySceneData_Param(idx, bCan )

    if bossName == "LiQiuShui" and bCan == 2 then
        local num = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, num do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddSweepPointByID(mems[i], 9, 8)
        end
    end
end

function epiaomiaofeng_small:CalSweepData(selfId)
	local lastTime = self:GetMissionData(selfId, define.MD_ENUM.MD_PIAOMIAOFENG_SMALL_LASTTIME)
	local lastDayTime = math.floor( lastTime / 100 )
	local lastDayCount = lastTime % 100
	local CurDayTime = self:GetDayTime()
	if CurDayTime > lastDayTime then
		lastDayTime = CurDayTime
		lastDayCount = 0
	end
	lastDayCount = lastDayCount + 1
	lastTime = lastDayTime * 100 + lastDayCount
	self:SetMissionData(selfId, define.MD_ENUM.MD_PIAOMIAOFENG_SMALL_LASTTIME, lastTime)
end

return epiaomiaofeng_small
