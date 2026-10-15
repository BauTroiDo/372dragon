-- 各擂台对应的 脚本
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local leitai = class("leitai", script_base)
leitai.g_CopyScene = "leitai_2.nav"
leitai.g_client_res = 92
leitai.event_area = "leitai_2_area.ini"
leitai.g_Pos = { x=31, z=32, offset=3.53 }
leitai.g_CopySceneCloseTime = 3000
leitai.g_TickTime = 5000
leitai.g_BeginTick = 3
leitai.g_CloseTick = 3
leitai.g_PvpRuler = 9
local FUBEN_PVP_LEITAI	= 993
leitai.g_CopySceneType = FUBEN_PVP_LEITAI
-- 挑战双方阵营号
leitai.g_Camp = { self=10, target=11 }
-- 挑战结束以后回到的位置
leitai.g_BackPos = { sceneId=0, x=180, z=328 }
-- 无敌 BUFF ~~~
leitai.g_Buff = 112
leitai.g_BuffID_ClearChgBodyBuff = 84
-- 让 selfId (及队友) 挑战 targetId (及队友)
function leitai:DoChallenge(selfId, targetId)
	-- 先创建一个副本，如果创建成功，则继续，否则返回
	local CreatorGUID = self:LuaFnObjId2Guid(selfId )
	local TargetGUID = self:LuaFnObjId2Guid(targetId )
	local config = {}
	config.navmapname = self.g_CopyScene					-- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
	config.client_res = self.g_client_res
	config.teamleader = CreatorGUID
	config.NoUserCloseTime = self.g_CopySceneCloseTime
	config.PvpRule = self.g_PvpRuler
	config.Timer = self.g_TickTime
	config.params = {}
	config.params[0] = self.g_CopySceneType						-- 设置副本类型
	config.params[1] = self.script_id							-- 将1号数据设置为副本场景事件脚本号
	config.params[2] = 0										-- 设置定时器调用次数
	config.params[3] = TargetGUID								-- 挑战对手的 GUID
	config.params[4] = 0										-- 设置副本关闭标志, 0开放，1关闭
	config.params[5] = 0										-- 设置离开倒计时次数
	config.params[6] = 0										-- 保存 self 队伍号以及阵营的剩余人数 TeamID * 10 + TeamMemberCount
	config.params[7] = 0										-- 保存 target 队伍号以及阵营的剩余人数 TeamID * 10 + TeamMemberCount
	config.eventfile = self.event_area							-- 加载擂台出口
	config.sn 		 = skynet.time()

	local CopySceneID = self:LuaFnCreateCopyScene(config)				-- 初始化完成后调用创建副本函数
	if CopySceneID <= 0 then
		self:notify_tips(selfId, "Lôi đài quá chật chội, không thể chứa thêm người Chiến đấu")
		return
	end
	--记录统计信息
end

function leitai:GetSelfTeamId()
    local value = self:LuaFnGetCopySceneData_Param(6) / 10
    return value < 0 and math.ceil(value) or math.floor(value)
end

function leitai:GetTargetTeamId()
    local value = self:LuaFnGetCopySceneData_Param(7) / 10
    return value < 0 and math.ceil(value) or math.floor(value)
end

function leitai:GetSelfMembersCount()
    return math.abs(self:LuaFnGetCopySceneData_Param(6)) % 10
end

function leitai:ModifySelfMembersCount(count )
	local selfInfo = self:LuaFnGetCopySceneData_Param(6)

	if selfInfo < 0 then
		count = -count
	end
	self:LuaFnSetCopySceneData_Param(6, selfInfo + count )
end

function leitai:GetTargetMembersCount()
    return math.abs(self:LuaFnGetCopySceneData_Param(7)) % 10
end

function leitai:ModifyTargetMembersCount(count)
	local TargetInfo = self:LuaFnGetCopySceneData_Param(7)
	if TargetInfo < 0 then
		count = -count
	end
	self:LuaFnSetCopySceneData_Param(7, TargetInfo + count )
end

function leitai:CalcPosOffset()
	local offset = self.g_Pos.offset * math.random(100) / 100
	if math.random(0, 1) > 0 then
		offset = -offset
	end
	return offset
end

--**********************************
--副本事件
--**********************************
function leitai:OnCopySceneReady( destsceneId )
	-- 获取场景
	local sceneId = self:get_scene_id()
	-- 保存下进入的场景
	self:LuaFnSetCopySceneData_Param(destsceneId, 12, sceneId)
	
	-- 以下获得一个完整的需要进入新区域的人员列表
	local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
	local selfId = self:LuaFnGuid2ObjId(self:LuaFnGetCopySceneData_TeamLeader(destsceneId) )
	local targetId = self:LuaFnGuid2ObjId(self:LuaFnGetCopySceneData_Param( destsceneId, 3 ) )
    -- CYS-PVP allocator yields: revalidate before team lookup or transfer.
    if not require('cy_pvp').ready(self.scene, self.scene:get_obj_by_id(selfId), self.scene:get_obj_by_id(targetId)) then return end
	local members = {}

	-- 将两边的队伍号保存起来
	self:LuaFnSetCopySceneData_Param(destsceneId, 6, 10 * self:GetTeamId(selfId))
	self:LuaFnSetCopySceneData_Param(destsceneId, 7, 10 * self:GetTeamId(targetId))

	-- CYS-PVP: only unique, living teammates on the same challenge platform.
    local seen = {}
    for _, leader in ipairs({selfId,targetId}) do
        local obj = self.scene:get_obj_by_id(leader)
        if not obj then return end
        for _, member in ipairs(self.scene:get_team_challenge_members(obj)) do
            local id=member:get_obj_id()
            if not seen[id] then seen[id]=true;members[#members+1]=id end
        end
    end
	for _, member in ipairs(members) do
		-- TODO: 目前是有标记就传送过去，将要判断是否处于一些特定状态，比如交易、摆摊等等状态是不能传送的
		if self:LuaFnIsCanDoScriptLogic(member) then
			self:NewWorld(member, destsceneId, sn, self.g_Pos.x + self:CalcPosOffset(), self.g_Pos.z + self:CalcPosOffset(), self.g_client_res)
		end
	end
end

-- 获得自己站在哪方的信息，1: 挑战方，2: 被挑战方
function leitai:GetMySide(selfId )
	local MyGUID = self:LuaFnObjId2Guid(selfId )
	local ChallengerGUID = self:LuaFnGetCopySceneData_TeamLeader()
	local targetGUID = self:LuaFnGetCopySceneData_Param(3)
	local MySide
	if MyGUID == ChallengerGUID then
		MySide = 1
	elseif MyGUID == targetGUID then
		MySide = 2
	else
		local MyTeamId = self:GetTeamId(selfId)
		local selfTeamId = self:GetSelfTeamId()
		local MyName = self:GetName(selfId)
		if MyTeamId == selfTeamId then
			MySide = 1
		else	-- 出了问题就便宜被挑战者了，呵呵
			MySide = 2
		end
		print("GetMySide selfId =", selfId, ";MyName =", MyName, ";MyTeamId =", MyTeamId, ";selfTeamId =", selfTeamId, ";MySide =", MySide)
	end
	return MySide
end

--**********************************
--有玩家进入副本事件
--**********************************
function leitai:OnPlayerEnter(selfId )
	-- 设置玩家阵营号，如果玩家的 GUID 等于挑战方或被挑战方 GUID，则直接设置相应阵营号
	-- 否则玩家应该属于某一方的队伍，如果队伍号相等，则赋予该队伍号对应的阵营号
	--self:SetMissionData(selfId, define.MD_ENUM.MD_PREV_CAMP, self:GetCurCamp(selfId) )

	local MySide = self:GetMySide(selfId )
	if MySide == 1 then
		self:SetUnitCampID(selfId, self.g_Camp.self)
		--self:SetPvpAuthorizationFlagByID(selfId, 3, 1) --2是竞技授权标记
	else
		self:SetUnitCampID(selfId, self.g_Camp.target)
		--self:SetPvpAuthorizationFlagByID(selfId, 3, 1) --2是竞技授权标记
	end

	-- 加上 15 秒的 buff，也许应该放在 NewWorld 以前，主要害怕如果 NewWorld 失败可能会有一些副作用
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Buff, 0)
	
	-- 设置默认还魂点为进入场景的擂台
	local oldsceneId = self:LuaFnGetCopySceneData_Param(12)
	-- 在天外就给他还送到天外
	if oldsceneId == 1298 then
		self:SetPlayerDefaultReliveInfo(selfId, 0.1, nil, 0, 1298, 95, 99 )
	else
		self:SetPlayerDefaultReliveInfo(selfId, 0.1, nil, 0, self.g_BackPos.sceneId, self.g_BackPos.x, self.g_BackPos.z )
	end
	
	-- 进入校场副本的玩家要清除变身buff，防止不能操作被打死
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_BuffID_ClearChgBodyBuff, 0)
	self:LuaFnAddMissionHuoYueZhi(selfId,23)
	self:LuaFnChallengeRefreshSkillCoolDown(selfId)
end

-- 副本出口离开调用这个函数
function leitai:LeaveScene(selfId )
	self:SetUnitCampID(selfId, -1)
	--self:SetPvpAuthorizationFlagByID(selfId, 2, 0) --2是竞技授权标记
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 83 , 0);
	
	local oldsceneId = self:LuaFnGetCopySceneData_Param(12)
	if oldsceneId == 1298 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 1298, 95, 99)
	else
		self:CallScriptFunction((400900), "TransferFunc", selfId, self.g_BackPos.sceneId, self.g_BackPos.x, self.g_BackPos.z)
	end	
end

function leitai:OnPlayerLeave(selfId)
    -- CYS-PVP leave: clear arena camp even on death/teleport/logout exits.
    self:SetUnitCampID(selfId, -1)
	self:LuaFnChallengeRestoreSkillCoolDown(selfId)
end

--**********************************
--有玩家在副本中死亡事件
--**********************************
function leitai:OnHumanDie(selfId, killerId )
end

--**********************************
--副本场景定时器事件
--**********************************
function leitai:OnCopySceneTimer(nowTime)
	-- 副本时钟设置
	local tick = self:LuaFnGetCopySceneData_Param(2)
	tick = tick + 1
	self:LuaFnSetCopySceneData_Param(2, tick + 1)		-- 设置新的定时器调用次数

	-- 副本关闭标志
	local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
	if leaveFlag == 1 then																			-- 需要离开
		-- 离开倒计时间的读取和设置
		local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
		leaveTickCount = leaveTickCount + 1
		self:LuaFnSetCopySceneData_Param(5, leaveTickCount + 1 )

		if self.g_CloseTick <= leaveTickCount then
			-- 将当前副本场景里的所有人传送回原来进入时候的场景
			local membercount = self:LuaFnGetCopyScene_HumanCount()
			for	i=1, membercount do
				local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
				if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
					self:LeaveScene(playerId)
				end
			end
		else
			-- 通知剩余玩家副本即将关闭
			local membercount = self:LuaFnGetCopyScene_HumanCount()
			local strText = string.format( "Lôi đài sẽ đóng sau %d giây nữa", (self.g_CloseTick-leaveTickCount)*self.g_TickTime/1000)
			for	i=1, membercount do
				local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
				if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
					self:notify_tips(playerId, strText)
				end
			end
		end
	elseif tick > self.g_BeginTick then
		-- 统计双方人员数量，当一方无人时，则关闭副本，不考虑断线
		local membercount = self:LuaFnGetCopyScene_HumanCount()
		local selfCount = 0
		local targetCount = 0

		for	i=1, membercount do
			local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
				if self:GetMySide(playerId ) == 1 then
					selfCount = selfCount + 1
				else
					targetCount = targetCount + 1
				end
			end
		end

		if selfCount < 1 or targetCount < 1 then
			self:LuaFnSetCopySceneData_Param(4, 1)
		else
			return
		end

		local strText = "so tài kết thúc, lôi đài sắp đóng"
		for	i=1, membercount do
			local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
				self:notify_tips(playerId, strText)
			end
		end
	else
		local membercount = self:LuaFnGetCopyScene_HumanCount()
		local strText
		if tick < self.g_BeginTick then
			strText = string.format( "so tài sẽ bắt đầu sau %d giây nữa", (self.g_BeginTick-tick)*self.g_TickTime/1000 )
		else
			strText = "so tài chính thức bắt đầu"
		end

		for	i=1, membercount do
			local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(playerId) and self:LuaFnIsCanDoScriptLogic(playerId) then
				self:notify_tips(playerId, strText)
			end
		end
	end
end

return leitai