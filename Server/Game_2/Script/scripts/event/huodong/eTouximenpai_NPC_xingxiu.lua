--偷袭门派 星宿
--

--************************************************************************
--MisDescBegin
--脚本号
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local eTouximenpai_NPC_xingxiu = class("eTouximenpai_NPC_xingxiu", script_base)
--副本名称
eTouximenpai_NPC_xingxiu.g_CopySceneName	= "星宿海"

eTouximenpai_NPC_xingxiu.g_ClientRes = 3180
--任务号
eTouximenpai_NPC_xingxiu.g_MissionId = 1250
--上一个任务的ID
eTouximenpai_NPC_xingxiu.g_MissionIdPre	= 0
--目标NPC
eTouximenpai_NPC_xingxiu.g_Name					= "偷袭门派"
--是否是精英任务
eTouximenpai_NPC_xingxiu.g_IfMissionElite= 1
--任务等级
eTouximenpai_NPC_xingxiu.g_MissionLevel	= 10000
--任务归类
eTouximenpai_NPC_xingxiu.g_MissionKind		= 1
--任务文本描述
eTouximenpai_NPC_xingxiu.g_MissionName			= "偷袭门派"
--任务描述
eTouximenpai_NPC_xingxiu.g_MissionInfo			= "  "
--任务目标
eTouximenpai_NPC_xingxiu.g_MissionTarget		= "  Giết tất cả quái vật là có thể hoàn thành nhiệm vụ."
--未完成任务的npc对话
eTouximenpai_NPC_xingxiu.g_ContinueInfo		= "  "
--完成任务npc说话的话
eTouximenpai_NPC_xingxiu.g_MissionComplete	= "  "

--********下面几项是动态显示的内容，用于在任务列表中动态显示任务情况******
--循环任务的数据索引，里面存着已做的环数 MD_SHUILAO_HUAN
--任务是否已经完成
--**********************************以上是动态****************************
--角色Mission变量说明
eTouximenpai_NPC_xingxiu.g_Param_IsMissionOkFail	= 0						--0号：当前任务是否完成(0未完成；1完成)
eTouximenpai_NPC_xingxiu.g_Param_killmonstercount	= 1					--1号：杀死任务小怪的数量
eTouximenpai_NPC_xingxiu.g_Param_killbosscount	= 2							--2号：杀死任务boss怪的数量
eTouximenpai_NPC_xingxiu.g_Param_sceneid		= 3									--3号：当前副本任务的场景号
eTouximenpai_NPC_xingxiu.g_Param_teamid		= 4									--4号：接副本任务时候的队伍号
eTouximenpai_NPC_xingxiu.g_Param_time			= 5									--5号：完成副本所用时间(单位：秒)
																							--6号：具体副本事件脚本占用
																							--7号：具体副本事件脚本占用
--MisDescEnd
--************************************************************************

eTouximenpai_NPC_xingxiu.g_CopySceneType			= ScriptGlobal.FUBEN_XINGXIU1	--副本类型，定义在ScriptGlobal.lua里面
eTouximenpai_NPC_xingxiu.g_LimitMembers			= 3		--可以进副本的最小队伍人数
eTouximenpai_NPC_xingxiu.g_TickTime					= 5		--回调脚本的时钟时间（单位：秒/次）
eTouximenpai_NPC_xingxiu.g_LimitTotalHoldTime= 360	--副本可以存活的时间（单位：次数）,如果此时间到了，则任务将会失败
eTouximenpai_NPC_xingxiu.g_LimitTimeSuccess	= 500	--副本时间限制（单位：次数），如果此时间到了，任务完成
eTouximenpai_NPC_xingxiu.g_CloseTick					= 6		--副本关闭前倒计时（单位：次数）
eTouximenpai_NPC_xingxiu.g_NoUserTime				= 300	--副本中没有人后可以继续保存的时间（单位：秒）
eTouximenpai_NPC_xingxiu.g_Fuben_X						= 96	--进入副本的位置X
eTouximenpai_NPC_xingxiu.g_Fuben_Z						= 52	--进入副本的位置Z
eTouximenpai_NPC_xingxiu.g_Back_X						= 96	--源场景位置X
eTouximenpai_NPC_xingxiu.g_Back_Z						= 52	--源场景位置Z
eTouximenpai_NPC_xingxiu.g_Totalkillmonstercount	= 30	--需要杀死monster数量
eTouximenpai_NPC_xingxiu.g_Totalkillbosscount	= 1	--需要杀死Boss数量

--副本数据索引对照
eTouximenpai_NPC_xingxiu.g_keySD					= {}
eTouximenpai_NPC_xingxiu.g_keySD["typ"]	= 0		--设置副本类型
eTouximenpai_NPC_xingxiu.g_keySD["spt"]	= 1		--设置副本场景事件脚本号
eTouximenpai_NPC_xingxiu.g_keySD["tim"]	= 2		--设置定时器调用次数
eTouximenpai_NPC_xingxiu.g_keySD["scn"]	= 3		--设置副本入口场景号, 初始化
eTouximenpai_NPC_xingxiu.g_keySD["cls"]	= 4		--设置副本关闭标志, 0开放，1关闭
eTouximenpai_NPC_xingxiu.g_keySD["dwn"]	= 5		--设置离开倒计时次数
eTouximenpai_NPC_xingxiu.g_keySD["tem"]	= 6		--保存队伍号
eTouximenpai_NPC_xingxiu.g_keySD["x"]	= 7			--人物在入口场景中的x位置
eTouximenpai_NPC_xingxiu.g_keySD["z"]	= 8			--人物在入口场景中的z位置
eTouximenpai_NPC_xingxiu.g_keySD["killedmonsternum"]	= 9		--杀死喽啰的数量
eTouximenpai_NPC_xingxiu.g_keySD["killedbossnum"]	= 10		--杀死Boss的数量
eTouximenpai_NPC_xingxiu.g_keySD["mp"]	= 11		--记录当前副本的 门派

--接取任务的最低等级
eTouximenpai_NPC_xingxiu.g_minLevel			= 20
--需要配置小怪物
eTouximenpai_NPC_xingxiu.g_typMonster		= 749	--水鬼探子
--门派id
eTouximenpai_NPC_xingxiu.g_MenPaiID		= ScriptGlobal.MP_XINGSU

eTouximenpai_NPC_xingxiu.g_NianNum = 5
eTouximenpai_NPC_xingxiu.g_NianPos = {
	{x=86  ,y=113},
	{x=105 ,y=113},
	{x=71  ,y=66 },
	{x=114  ,y=55},
	{x=120  ,y=73},
}
--**********************************
--任务入口函数
--**********************************
function eTouximenpai_NPC_xingxiu:OnDefaultEvent( selfId, targetId )
	self:OnAccept(selfId, targetId)
end

--**********************************
--列举事件
--**********************************
function eTouximenpai_NPC_xingxiu:OnEnumerate(_, selfId, targetId )
	local	MenPaiID = self:GetMenPai(selfId)
	-- if MenPaiID ~= self.g_MenPaiID then
		-- self:NotifyTip(selfId,"你不是星宿派弟子，叫星宿派弟子来。")
		-- return
	-- end
	local	lev	= self:GetLevel( selfId )
	if lev < self.g_minLevel then
	  self:NotifyTip( selfId, "Cấp độ của ngươi quá thấp, căn bản không đủ để ta xem, vẫn là sau khi đạt cấp 20 rồi hãy đến tìm ta." )
		return
	end

	if not self:LuaFnHasTeam( selfId ) then
		self:NotifyTip( selfId, "Một Cá nhân nhỏ bé cũng dám đến thách đấu ta, ta căn bản không thèm chấp ngươi động thủ." )
		return
	end
	if self:GetTeamSize( selfId ) < self.g_LimitMembers then
		self:NotifyTip( selfId, "Muốn khiêu chiến ta thì ít nhất cũng phải ba người trở lên chứ, chỉ có chút người này thôi sao? Cũng quá xem thường ta rồi." )
		return
	end
	if not self:LuaFnIsTeamLeader( selfId ) then
		self:NotifyTip( selfId, "Muốn khiêu chiến ta? Gọi đội trưởng của các ngươi đến đây đi." )
		return
	end
	-- 取得玩家附近的队友数量（包括自己）
	local nearteammembercount = self:GetNearTeamCount( selfId )
	if nearteammembercount ~= self:LuaFnGetTeamSize( selfId ) then
		self:NotifyTip( selfId, "Đội của ngài có thành viên không ở gần, xin tập hợp lại rồi hãy tìm ta đưa ngài vào hoạt động." )
		return
	end

	local namenum = 0
	local notifyString = "Đội của ngài có thành viên("
	print("nearteammembercount =", nearteammembercount)
	for i=1, nearteammembercount  do
		local nPlayerId = self:GetNearTeamMember(selfId, i)
		local	lev	= self:GetLevel( nPlayerId )
		local	nam	= self:GetName( nPlayerId )
		if(lev<self.g_minLevel) then
			notifyString = notifyString..nam.." "
			namenum = 1
		end
	end
	notifyString = notifyString.."Cấp độ chưa đủ."
	if(namenum>0) then
		self:NotifyTip( selfId, notifyString )
		return
	end

	self:BeginEvent(self.script_id)
	self:AddText("Đã bằng hữu không sợ chết, ta cũng không cần lưu tình, tiểu nhân kia, tiến lên cho chúng nếm mùi lợi hại!" )
	self:AddNumText("Lẽ nào ta lại sợ ngươi không thành..." ,10 ,0)
	self:EndEvent()
	self:DispatchEventList( selfId, targetId )
end

--**********************************
--检测接受条件
--**********************************
function eTouximenpai_NPC_xingxiu:CheckAccept( selfId )
	local	lev	= self:GetLevel( selfId )
	if lev < self.g_minLevel then
		self:NotifyTip( selfId, "Cấp độ của ngươi quá thấp, căn bản không đủ để ta xem, vẫn là sau khi đạt cấp 20 rồi hãy đến tìm ta." )
		return 0
	end

	if not self:LuaFnHasTeam( selfId ) then
		self:NotifyTip( selfId, "Một Cá nhân nhỏ bé cũng dám đến thách đấu ta, ta căn bản không thèm chấp ngươi động thủ." )
		return 0
	end

	if self:GetTeamSize( selfId ) < self.g_LimitMembers then
		self:NotifyTip( selfId, "Muốn khiêu chiến ta thì ít nhất cũng phải ba người trở lên chứ, chỉ có chút người này thôi sao? Cũng quá xem thường ta rồi." )
		return 0
	end
	if not self:LuaFnIsTeamLeader( selfId ) then
		self:NotifyTip( selfId, "Muốn khiêu chiến ta? Gọi đội trưởng của các ngươi đến đây đi." )
		return 0
	end
	local MenPaiID = self:GetMenPai(selfId)
	-- if MenPaiID ~= self.g_MenPaiID then
		-- self:NotifyTip(selfId,"你不是星宿派弟子，叫星宿派弟子来。")
		-- return 0
	-- end
	-- 取得玩家附近的队友数量（包括自己）
	local nearteammembercount = self:GetNearTeamCount( selfId )
	if nearteammembercount ~= self:LuaFnGetTeamSize( selfId ) then
		self:NotifyTip( selfId, "Đội của ngài có thành viên không ở gần, xin tập hợp lại rồi hãy tìm ta đưa ngài vào hoạt động." )
		return 0
	end

	local namenum = 0
	local notifyString = "Đội của ngài có thành viên(";
	for i=1, nearteammembercount  do
		local nPlayerId = self:GetNearTeamMember(selfId, i)
		local	lev	= self:GetLevel( nPlayerId )
		local	nam	= self:GetName( nPlayerId )
		if(lev<self.g_minLevel) then
			notifyString = notifyString..nam.." "
			namenum = 1;
		end
	end
	notifyString = notifyString.."Cấp độ chưa đủ."
	if(namenum>0) then
		self:NotifyTip( selfId, notifyString )
		return 0
	end
	return 1
end

--**********************************
--接受
--**********************************
function eTouximenpai_NPC_xingxiu:OnAccept( selfId, targetId )
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
	if self:GetMenPai(selfId) ~= self.g_MenPaiID then
		self:NotifyTip(selfId, "Chỉ đệ tử môn phái đang bị tập kích mới dẫn đội vào được")
		return
	end
	if self:CheckAccept( selfId ) == 0 then
		return
	end
	local teamid = self:GetTeamId( selfId )

	--如果有任务，直接传入副本
	if self:IsHaveMission( selfId, self.g_MissionId) then

		local misIndex = self:GetMissionIndexByID( selfId, self.g_MissionId )
		local copysceneid = self:GetMissionParam( selfId, misIndex, self.g_Param_sceneid )
		local saveteamid = self:GetMissionParam( selfId, misIndex, self.g_Param_teamid )
		local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
		--进过副本
		if copysceneid >= 0 and teamid == saveteamid then
			--将自己传送到副本场景
			if self:IsCanEnterCopyScene( copysceneid, selfId ) then
				self:NewWorld( selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes )
			else
				self:NotifyTip( selfId, "Nhiệm vụ thất bại, xin hãy từ bỏ và nhận lại." )
				self:SetMissionByIndex( selfId, misIndex, self.g_Param_IsMissionOkFail, 2 )
				self:DelMission(selfId, self.g_MissionId);
			end
			return
		end
	end

	--加入任务到玩家列表
	--取得玩家附近的队友数量（包括自己）
	local numMem	= self:GetNearTeamCount( selfId )
	local member
	local i
	local misIndex
	for i=1, numMem do
		member = self:GetNearTeamMember( selfId, i );
		if self:IsMissionFull(member) then
			self:BeginEvent(self.script_id)
			self:AddText("Trong đội ngũ có người nhiệm vụ đã đầy!");
			self:EndEvent()
			self:DispatchMissionTips(selfId);
			return
		end
	end
	for	i=1, numMem do
		member = self:GetNearTeamMember( selfId, i )
		if self:IsHaveMission( member, self.g_MissionId ) then
			--删掉先
			self:DelMission( member, self.g_MissionId)
		end

		--给每个队伍成员加入任务
		if not self:AddMission( member, self.g_MissionId, self.script_id, 1, 0, 0 ) then
			return
		end

		misIndex = self:GetMissionIndexByID( member, self.g_MissionId )
		--将任务的第0号数据设置为0,表示未完成的任务
		self:SetMissionByIndex( member, misIndex, self.g_Param_IsMissionOkFail, 0 )
		--将任务的第2号数据设置为-1, 用于保存副本的场景号
		self:SetMissionByIndex( member, misIndex, self.g_Param_sceneid, -1 )
		--将任务的第3号数据队伍号
		self:SetMissionByIndex( member, misIndex, self.g_Param_teamid, teamid )
	end
	self:MakeCopyScene( selfId, numMem,targetId )
	self:LuaFnDeleteMonster( targetId)
end

--**********************************
--放弃
--**********************************
function eTouximenpai_NPC_xingxiu:OnAbandon( selfId )
	--不在场景的不做此操作
	if not self:LuaFnIsObjValid( selfId ) then
		return
	end

	--处于无法执行逻辑的状态
	if not self:LuaFnIsCanDoScriptLogic( selfId ) then
		return
	end

	--不是在副本中直接删除任务
	local misIndex = self:GetMissionIndexByID( selfId, self.g_MissionId )
	local copysceneid = self:GetMissionParam( selfId, misIndex, self.g_Param_sceneid )

	if(copysceneid ~= self:get_scene_id()) then
		self:DelMission( selfId, self.g_MissionId )
		return
	end

	local leaderguid = self:LuaFnGetCopySceneData_TeamLeader()
	local leaderObjId = self:LuaFnGuid2ObjId( leaderguid )

	--找不到该玩家
	if leaderObjId == -1 then
		self:DelMission( selfId, self.g_MissionId )
		return
	end

	--此时一定在副本中，可以获得入口场景号
	local oldsceneId = self:LuaFnGetCopySceneData_Param( self.g_keySD["scn"] )	--取得副本入口场景号
	if(selfId == leaderObjId) then
		--队长放弃，全部传出副本
		self:LuaFnSetCopySceneData_Param( self.g_keySD["cls"], 1 )
		local membercount = self:LuaFnGetCopyScene_HumanCount()
		local mems = {}
		local i
		for	i=0, membercount-1 do
			mems[i] = self:LuaFnGetCopyScene_HumanObjId( i )
		end
		--将当前副本场景里的所有人传送回原来进入时候的场景
		for	i=1, membercount do
			if self:LuaFnIsObjValid( mems[i] ) then
				self:DelMission( mems[i], self.g_MissionId )
				local x = self:LuaFnGetCopySceneData_Param( self.g_keySD["x"] )
				local z = self:LuaFnGetCopySceneData_Param( self.g_keySD["z"] )
				self:get_scene():notify_change_scene(mems[i], oldsceneId, x, z)
			end
		end
	else
		--自己不是队长只是自己放弃，只把自己传出副本
		self:DelMission( selfId, self.g_MissionId )
		local x = self:LuaFnGetCopySceneData_Param( self.g_keySD["x"] )
		local z = self:LuaFnGetCopySceneData_Param( self.g_keySD["z"] )
		self:CallScriptFunction((400900), "TransferFunc", selfId, oldsceneId, x, z)
	end
end

--**********************************
--创建副本
--**********************************
function eTouximenpai_NPC_xingxiu:MakeCopyScene( selfId, nearmembercount,targetId )
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
	local mems = {}
	local mylevel = 0
	local i

-- 	PrintStr("sdlf")

	local member, mylevel, numerator, denominator = 0, 0, 0, 0

	for	i = 1, nearmembercount do
		member = self:GetNearTeamMember( selfId, i )
		numerator = numerator + self:GetLevel( member ) ^ 4
		denominator = denominator + self:GetLevel( member ) ^ 3
		mems[i] = member
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
		iniLevel = math.floor( mylevel/10 ) * 10
	else
		iniLevel = PlayerMaxLevel
	end
	iniLevel = iniLevel > 100 and 100 or iniLevel

	local leaderguid = self:LuaFnObjId2Guid( selfId )
	--地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
	local config = {}
	config.navmapname = "xingxiu_1.path"					-- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
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
	config.params[self.g_keySD["killedmonsternum"]] = 0
	config.params[self.g_keySD["killedbossnum"]] = 0
	config.params[self.g_keySD["mp"]] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU
	config.params[self.g_keySD["x"]] = self.g_Back_X
	config.params[self.g_keySD["z"]] = self.g_Back_Z
	config.params[13] = mylevel
	config.eventfile = "xingxiu_1_area.ini"
	config.monsterfile = "xingxiu_1_monster_" .. iniLevel .. ".ini"
	config.sn 		 = self:LuaFnGenCopySceneSN()
	local x,z = self:GetWorldPos( selfId )

	local bRetSceneID = self:LuaFnCreateCopyScene(config)						--初始化完成后调用创建副本函数
	if bRetSceneID > 0 then
		self:NotifyTip( selfId, "Tạo phó bản thành công!" )
	else
		self:NotifyTip( selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!" )

		--删除玩家任务列表中对应的任务
		for	i=1, nearmembercount do
			self:DelMission( mems[i], self.g_MissionId )
		end
	end

end

--**********************************
--继续
--**********************************
function eTouximenpai_NPC_xingxiu:OnContinue( selfId, targetId )

end

--**********************************
--检测是否可以提交
--**********************************
function eTouximenpai_NPC_xingxiu:CheckSubmit( selfId, selectRadioId )


end

--**********************************
--提交
--**********************************
function eTouximenpai_NPC_xingxiu:OnSubmit( selfId, targetId, selectRadioId )

end

--**********************************
--杀死怪物或玩家
--**********************************
function eTouximenpai_NPC_xingxiu:OnKillObject( selfId, objdataId, objId )
	print("eTouximenpai_NPC_xingxiu:OnKillObject", selfId, objdataId, objId)
	--是否是副本
	local sceneType = self:LuaFnGetSceneType()
	if sceneType ~= 1 then
		return
	end

	--是否是所需要的副本
	local fubentype = self:LuaFnGetCopySceneData_Param( 0 )
	if fubentype ~= self.g_CopySceneType then
		return
	end

	--副本关闭标志
	local leaveFlag = self:LuaFnGetCopySceneData_Param( 4 )
	--如果副本已经被置成关闭状态，则杀怪无效
	if leaveFlag == 1 then
		return
	end

	--取得当前场景里的人数
	local num = self:LuaFnGetCopyScene_HumanCount(  )

	local killedmonsternumber = self:LuaFnGetCopySceneData_Param( self.g_keySD["killedmonsternum"] )			--杀死monster的数量
	local killedbossnumber = self:LuaFnGetCopySceneData_Param( self.g_keySD["killedbossnum"] )			--杀死boss的数量

	local MonsterName = self:GetName(objId)
	local	isBoss

	if(MonsterName == "喽啰")then
		killedmonsternumber = killedmonsternumber + 1
		self:LuaFnSetCopySceneData_Param( self.g_keySD["killedmonsternum"], killedmonsternumber )					--设置杀死monster的数量
		isBoss = 0
		if killedmonsternumber ==  self.g_Totalkillmonstercount then
			local	Selflev	= self:GetLevel( selfId )
			local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
			local monsterLevel=0
			if Selflev < 10 then
				monsterLevel = 0
			elseif Selflev < 110 then
				monsterLevel = math.floor( Selflev/10 ) + 3670 - 1
			elseif Selflev < PlayerMaxLevel then
				monsterLevel = math.floor( Selflev/10 ) + 33670 - 11
			else
				monsterLevel = 9
			end
			local tmpMonsterId = self:LuaFnCreateMonster( monsterLevel, 96, 44, 14, 138, -1)
			local tmpsMessage = string.format("Đáng ghét, thấy chúng ta sắp tập kích thành công rồi, nếu đã vậy, thì đừng trách ta vô lễ!")
			self:MonsterTalk(tmpMonsterId, self.g_CopySceneName, tmpsMessage)
			local szName = self:GetName(tmpMonsterId)
			if szName == "恶霸"   then
				self:SetCharacterTitle(tmpMonsterId, "\"Thư Sơn Hữu Lộ\"")
			end
		end
	elseif ( MonsterName == "恶霸" ) then
		killedbossnumber = killedbossnumber + 1
		self:LuaFnSetCopySceneData_Param( self.g_keySD["killedbossnum"], killedbossnumber )					--设置杀死boss的数量
		isBoss = 1
	end
	-------------------------------------------------------------------------------
	local membercount = self:LuaFnGetCopyScene_HumanCount()
	local memId
	local teamLeaderName;
	local firstMemName;
	local firstMemId;
	teamLeaderName = ""
	for	i = 1, membercount do
		memId = self:LuaFnGetCopyScene_HumanObjId(i);
		if self:LuaFnIsObjValid( memId ) and self:LuaFnIsCanDoScriptLogic( memId ) then
			local teamLeaderFlag = self:LuaFnIsTeamLeader(memId);
			if teamLeaderFlag and teamLeaderFlag == 1 then
				teamLeaderName = self:LuaFnGetName(memId);
				break;
			end
		end
	end

	if isBoss==1 and teamLeaderName ~= "" then
		local nPlayerNum = self:LuaFnGetCopyScene_HumanCount()
		for i=1, nPlayerNum  do
			local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
			self:LuaFnAddMissionHuoYueZhi(nPlayerId,17)
		end
	local message;
	local randMessage = math.random(3);
	if teamLeaderName then
		teamLeaderName = gbk.fromutf8(teamLeaderName)
	end
	if randMessage == 1 then
		message = string.format("#B#{_INFOUSR%s}#{TouXi_00}#G#{MP_emei}#{TouXi_01}", teamLeaderName );
	elseif randMessage == 2 then
		message = string.format("#G#{MP_emei}#{TouXi_02}#{_INFOUSR%s}#{TouXi_03}#B#{_INFOUSR%s}#{TouXi_04}", teamLeaderName, teamLeaderName );
	else
		message = string.format("#{TouXi_05}#G#{MP_emei}#{TouXi_06}#{_INFOUSR%s}#{TouXi_07}", teamLeaderName );
	end
		self:BroadMsgByChatPipe(selfId, message, 4);
	end
	-------------------------------------------------------------------------------
	local i
	local misIndex
	local humanObjId
	local	mppoint

	if (killedmonsternumber < self.g_Totalkillmonstercount ) or (killedbossnumber < self.g_Totalkillbosscount )then
		local strText = string.format( "Đã tiêu diệt lâu la: %d/%d Đã tiêu diệt ác bá: %d/%d" , killedmonsternumber, self.g_Totalkillmonstercount, killedbossnumber, self.g_Totalkillbosscount )
		for i=1, num do
			humanObjId = self:LuaFnGetCopyScene_HumanObjId( i )				--取得当前场景里人的objId
			if self:LuaFnIsObjValid( humanObjId ) and self:LuaFnIsCanDoScriptLogic( humanObjId ) then						--不在场景的不做此操作
				self:NotifyTip( humanObjId, strText )

				local	MenPaiID	=	self:GetMenPai(humanObjId)
				if(MenPaiID == self.g_MenPaiID) then
					if isBoss == 0 then
						mppoint = self:GetHumanMenpaiPoint(humanObjId)
						mppoint = mppoint+1
						self:SetHumanMenpaiPoint(humanObjId, mppoint)
					else
						mppoint = self:GetHumanMenpaiPoint(humanObjId)
						mppoint = mppoint+5
						self:SetHumanMenpaiPoint(humanObjId, mppoint)
					end
				end
				misIndex = self:GetMissionIndexByID( humanObjId, self.g_MissionId )					--取得任务数据索引值
				self:SetMissionByIndex( humanObjId, misIndex, self.g_Param_killmonstercount, killedmonsternumber )	--设置任务数据
				self:SetMissionByIndex( humanObjId, misIndex, self.g_Param_killbosscount, killedbossnumber )	--设置任务数据
			end
		end
	else

		--设置任务完成标志
		self:LuaFnSetCopySceneData_Param( self.g_keySD["cls"], 1 )

		--取得已经执行的定时次数
		local TickCount = self:LuaFnGetCopySceneData_Param( 2 )
		local strText = string.format( "Đã tiêu diệt lâu la: %d/%d Đã tiêu diệt ác bá: %d/%d", self.g_Totalkillmonstercount, self.g_Totalkillmonstercount, self.g_Totalkillbosscount, self.g_Totalkillbosscount)
		local strText2 = string.format( "Nhiệm vụ hoàn thành, sẽ truyền tống đến vị trí lối vào sau %d giây.", self.g_CloseTick * self.g_TickTime )

		for i=1, num do
			humanObjId = self:LuaFnGetCopyScene_HumanObjId( i )									--取得当前场景里人的objId

			if self:LuaFnIsObjValid( humanObjId ) and self:LuaFnIsCanDoScriptLogic( humanObjId ) then										--不在场景的不做此操作
				misIndex = self:GetMissionIndexByID( humanObjId, self.g_MissionId)					--取得任务数据索引值
				self:SetMissionByIndex( humanObjId, misIndex, self.g_Param_killmonstercount, killedmonsternumber )	--设置任务数据
				self:SetMissionByIndex( humanObjId, misIndex, self.g_Param_killbosscount, killedbossnumber )	--设置任务数据

				--将任务的第1号数据设置为1,表示完成的任务
				self:SetMissionByIndex( humanObjId, misIndex, self.g_Param_IsMissionOkFail, 1 )					--设置任务数据
				--完成副本所用时间
				self:SetMissionByIndex( humanObjId, misIndex, self.g_Param_time, TickCount * self.g_TickTime )	--设置任务数据

				self:NotifyTip( humanObjId, strText )
				self:NotifyTip( humanObjId, strText2 )

				local	MenPaiID	=	self:GetMenPai(humanObjId)
				if(MenPaiID == self.g_MenPaiID) then
					if isBoss == 0 then
						mppoint = self:GetHumanMenpaiPoint(humanObjId)
						mppoint = mppoint+1
						self:SetHumanMenpaiPoint(humanObjId, mppoint)
					else
						mppoint = self:GetHumanMenpaiPoint(humanObjId)
						mppoint = mppoint+5
						self:SetHumanMenpaiPoint(humanObjId, mppoint)
					end
				end
			end
		end
	end
end

--**********************************
--进入区域事件
--**********************************
function eTouximenpai_NPC_xingxiu:OnEnterZone( selfId, zoneId )
end

--**********************************
--道具改变
--**********************************
function eTouximenpai_NPC_xingxiu:OnItemChanged( selfId, itemdataId )
end

--**********************************
--副本事件
--**********************************
function eTouximenpai_NPC_xingxiu:OnCopySceneReady( destsceneId )
	--设置副本入口场景号
	print("destsceneId =", destsceneId)
	self:LuaFnSetCopySceneData_Param( destsceneId, self.g_keySD["scn"], self:get_scene_id())
	local leaderguid = self:LuaFnGetCopySceneData_TeamLeader( destsceneId )
	local leaderObjId = self:LuaFnGuid2ObjId( leaderguid )

	--找不到该玩家
	if leaderObjId == -1 then
		return
	end

	--处于无法执行逻辑的状态
	if not self:LuaFnIsCanDoScriptLogic( leaderObjId ) then
		return
	end
	if not self:IsCopySceneOwnerTeamMember(leaderObjId, destsceneId, self.g_keySD["tem"]) or
		not self:IsHaveMission(leaderObjId, self.g_MissionId) then
		return
	end

	--取得玩家附近的队友数量（包括自己）
	local numMem	= self:GetNearTeamCount( leaderObjId )
	local member
	local misIndex

	misIndex = self:GetMissionIndexByID( leaderObjId, self.g_MissionId )
	print("OnCopySceneReady destsceneId =", destsceneId)
	self:SetMissionByIndex( leaderObjId, misIndex, self.g_Param_sceneid, destsceneId )
	local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
	self:NewWorld( leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes )
	
	--活动统计
	--self:LuaFnAuditQuest(leaderObjId, self.g_MissionName.."-"..self.g_CopySceneName)

	for	i=2, numMem do
		member = self:GetNearTeamMember( leaderObjId, i )
		if self:LuaFnIsCanDoScriptLogic( member ) and
			self:IsCopySceneOwnerTeamMember(member, destsceneId, self.g_keySD["tem"]) then
			if self:IsHaveMission( member, self.g_MissionId ) then
				misIndex = self:GetMissionIndexByID( member, self.g_MissionId )
				--将任务的第2号数据设置为副本的场景号
				self:SetMissionByIndex( member, misIndex, self.g_Param_sceneid, destsceneId )
				self:NewWorld( member, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_ClientRes )
				--活动统计
				--self:LuaFnAuditQuest(member, self.g_MissionName.."-"..self.g_CopySceneName)
			else
				self:NotifyTip( member, "Ngươi hiện tại chưa tiếp nhiệm vụ này" )
			end
		end
	end
end

--**********************************
--有玩家进入副本事件
--**********************************
function eTouximenpai_NPC_xingxiu:OnPlayerEnter( selfId )
	if not self:IsAuthorizedCopyScenePlayer(selfId, self.g_keySD["tem"], self.g_MissionId, self.g_Param_sceneid) then
		self:NotifyTip( selfId, "Ngươi không thuộc đội tạo phụ bản này" )
		if self:IsHaveMission(selfId, self.g_MissionId) then
			self:DelMission(selfId, self.g_MissionId)
		end
		local oldsceneId = self:LuaFnGetCopySceneData_Param( self.g_keySD["scn"] )		--取得副本入口场景号
		local x = self:LuaFnGetCopySceneData_Param( self.g_keySD["x"] )
		local z = self:LuaFnGetCopySceneData_Param( self.g_keySD["z"] )
		self:NewWorld( selfId, oldsceneId, nil, x, z)
		return
	end

	--设置死亡后复活点位置
	self:SetPlayerDefaultReliveInfo( selfId, 0.1, -1, 0, self.g_Fuben_X, self.g_Fuben_Z )
end

--**********************************
--有玩家在副本中死亡事件
--**********************************
function eTouximenpai_NPC_xingxiu:OnHumanDie( selfId, killerId )
end

--**********************************
--副本场景定时器事件
--**********************************
function eTouximenpai_NPC_xingxiu:OnCopySceneTimer( nowTime )
	print("eTouximenpai_NPC_xingxiu:OnCopySceneTimer")
	--副本时钟读取及设置
	--取得已经执行的定时次数
	local TickCount = self:LuaFnGetCopySceneData_Param( self.g_keySD["tim"] )
	TickCount = TickCount + 1
	--设置新的定时器调用次数
	self:LuaFnSetCopySceneData_Param( self.g_keySD["tim"], TickCount )

	--副本关闭标志
	local leaveFlag = self:LuaFnGetCopySceneData_Param( self.g_keySD["cls"] )

	local membercount = self:LuaFnGetCopyScene_HumanCount()
	local mems = {}
	local i

	if membercount==0 and leaveFlag~=1 then
		self:LuaFnSetCopySceneData_Param( self.g_keySD["cls"], 1 )
		return
	end

	for	i=1, membercount do
		mems[i] = self:LuaFnGetCopyScene_HumanObjId( i )
	end

	--需要离开
	if leaveFlag == 1 then
		--离开倒计时间的读取和设置
		local leaveTickCount = self:LuaFnGetCopySceneData_Param( self.g_keySD["dwn"] )
		leaveTickCount = leaveTickCount + 1
		self:LuaFnSetCopySceneData_Param( self.g_keySD["dwn"], leaveTickCount )

		if leaveTickCount == self.g_CloseTick then										--倒计时间到，大家都出去吧
			local oldsceneId = self:LuaFnGetCopySceneData_Param( self.g_keySD["scn"] )	--取得副本入口场景号

			--将当前副本场景里的所有人传送回原来进入时候的场景
			for	i=1, membercount do
				if self:LuaFnIsObjValid( mems[i] ) then
					self:DelMission( mems[i], self.g_MissionId )
					local x = self:LuaFnGetCopySceneData_Param( self.g_keySD["x"] )
					local z = self:LuaFnGetCopySceneData_Param( self.g_keySD["z"] )
					self:get_scene():notify_change_scene(mems[i], oldsceneId, x, z)
				end
			end
		elseif leaveTickCount < self.g_CloseTick then
			--通知当前副本场景里的所有人，场景关闭倒计时间
			local strText = string.format( "Ngươi sẽ rời khỏi cảnh sau %d giây!", (self.g_CloseTick-leaveTickCount) * self.g_TickTime )

			for	i=1, membercount do
				if self:LuaFnIsObjValid( mems[i] ) then
					self:NotifyTip( mems[i], strText )
				end
			end
		end
	elseif TickCount == self.g_LimitTimeSuccess then
		--此处设置有时间限制的任务完成处理
		local misIndex
		for	i=1, membercount do
			if self:LuaFnIsObjValid( mems[i] ) then
				self:DelMission( mems[i], self.g_MissionId )
				self:NotifyTip( mems[i], "Hết thời gian nhiệm vụ, hoàn thành!" )
				--取得任务数据索引值
				misIndex = self:GetMissionIndexByID( mems[i], self.g_MissionId )
				--将任务的第1号数据设置为1,表示完成的任务
				--设置任务数据
				self:SetMissionByIndex( mems[i], misIndex, self.g_Param_IsMissionOkFail, 1 )
				--完成副本所用时间
				self:SetMissionByIndex( mems[i], misIndex, self.g_Param_time, TickCount * self.g_TickTime )	--设置任务数据
			end
		end
		--设置副本关闭标志
		self:LuaFnSetCopySceneData_Param( self.g_keySD["cls"], 1 )
	elseif TickCount == self.g_LimitTotalHoldTime then						--副本总时间限制到了
		--此处设置副本任务有时间限制的情况，当时间到后处理...
		for	i=0, membercount-1 do
			if self:LuaFnIsObjValid( mems[i] ) then
				self:DelMission( mems[i], self.g_MissionId )				--任务失败,删除之
				self:NotifyTip( mems[i], "Nhiệm vụ thất bại, quá thời gian!" )
			end
		end

		--设置副本关闭标志
		self:LuaFnSetCopySceneData_Param( self.g_keySD["cls"], 1 )
	else
		--定时检查队伍成员的队伍号，如果不符合，则踢出副本
		local oldteamid = self:LuaFnGetCopySceneData_Param( self.g_keySD["tem"] )		--取得保存的队伍号
		local oldsceneId = self:LuaFnGetCopySceneData_Param( self.g_keySD["scn"] )	--取得副本入口场景号

		for	i=1, membercount do
			if self:LuaFnIsObjValid( mems[i] ) and self:IsHaveMission( mems[i], self.g_MissionId ) then
				if oldteamid ~= self:GetTeamId( mems[i] ) then
					self:DelMission( mems[i], self.g_MissionId )			--任务失败,删除之
					self:NotifyTip( mems[i], "Nhiệm vụ thất bại, ngươi không ở trong đội đúng!" )

					local x = self:LuaFnGetCopySceneData_Param( self.g_keySD["x"] )
					local z = self:LuaFnGetCopySceneData_Param( self.g_keySD["z"] )
					self:get_scene():notify_change_scene(mems[i], oldsceneId, x, z)
				end
			end
		end
	end
end

--**********************************
--醒目提示
--**********************************
function eTouximenpai_NPC_xingxiu:NotifyTip( selfId, msg )
	self:notify_tips(selfId, msg)
end

--**********************************
--对话窗口信息提示
--**********************************
function eTouximenpai_NPC_xingxiu:MsgBox( selfId, targetId, msg )
	self:BeginEvent(self.script_id)
	self:AddText( msg )
	self:EndEvent()
	self:DispatchEventList( selfId, targetId )
end

return eTouximenpai_NPC_xingxiu
