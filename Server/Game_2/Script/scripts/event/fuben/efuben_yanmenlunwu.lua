local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local efuben_yanmenlunwu = class("efuben_yanmenlunwu", script_base)
efuben_yanmenlunwu.scirpt_id = 893131
efuben_yanmenlunwu.g_client_res = 583
efuben_yanmenlunwu.g_NoUserTime = 300
efuben_yanmenlunwu.g_TickTime = 1
efuben_yanmenlunwu.g_Fuben_X = 177
efuben_yanmenlunwu.g_Fuben_Z = 356
efuben_yanmenlunwu.g_CloseTick = 6
efuben_yanmenlunwu.g_IDX_SYSZTimerStep	= 8
efuben_yanmenlunwu.g_IDX_SYSZTimerScriptID = 9
efuben_yanmenlunwu.g_IDX_CreaPosX = 10
efuben_yanmenlunwu.g_IDX_CreaPosZ = 11
efuben_yanmenlunwu.g_FuBenTime		= 3*60*60
efuben_yanmenlunwu.g_Name = "孟闯"
efuben_yanmenlunwu.g_CopySceneType = ScriptGlobal.FUBEN_YANMENLUNWU
--此副本为随机怪物副本，创建的时候随机取四个怪物进行创建
efuben_yanmenlunwu.g_NPCList ={49886,49893,49900,49907,49914,49921,49928,49935,49942}
efuben_yanmenlunwu.g_NPCScriptID = {893132,893133,893134,893135,893136,893137,893138,893139,893140}
efuben_yanmenlunwu.g_CharTile = {"Thanh Nguyệt Chi Liên","Thao Thiên Thánh Hỏa","Ưng kích trường không","Thâm Xuân Hồng Vũ","Càn Khôn Diệu Pháp","Cuồng Long Tửu Ca","Cưu Độc Chi Mạn","Phục Ma Kim Cang","Thiên Thánh Chi Chỉ"}
efuben_yanmenlunwu.g_NPCPosData =
{
	{282,406},{358,226},{400,75},{185,155}
}
--动态阻挡数据预留
efuben_yanmenlunwu.g_DynamicRegionPos = {}

function efuben_yanmenlunwu:OnDefaultEvent(selfId, targetId, arg, index)
	local numText = index
	if numText == 300 then
		self:BeginEvent(self.script_id)
        self:AddNumText("#{SBRC_20230627_48}", 6, 301)
		self:AddNumText("#{SBRC_20230627_49}", 6, 302)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if numText == 301 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 153, 238)
		return
	end
	if numText == 302 then
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId,1000)
		return
	end
	if numText < 4 then
		local ret, msg = self:CheckCanEnter(selfId)
		if 1 ~= ret then
			self:BeginEvent(self.script_id)
			self:AddText(msg)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
			return
		end
		self:MakeCopyScene(selfId,numText)
	end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId,1000)
end

function efuben_yanmenlunwu:CheckCanEnter(selfId)
	--是否有队伍....
	if not self:LuaFnHasTeam(selfId) then
		return 0, "#{PMF_20080521_02}"
	end
	--是不是队长....
	if self:GetTeamLeader(selfId) ~= selfId then
		return 0, "#{PMF_20080521_03}"
	end
	--人数是否够....
	if self:GetTeamSize(selfId) < 1 then
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
		local lastTime = self:GetMissionDataEx(PlayerId, ScriptGlobal.MDEX_YANMENLUNWU_LASTTIME )
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

function efuben_yanmenlunwu:MakeCopyScene(selfId,nType)
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
    for i = 8,31 do
        config.params[i] = 0
    end
    config.sn = self:LuaFnGenCopySceneSN()
	local bRetSceneID = self:LuaFnCreateCopyScene(config)
	local text
	if bRetSceneID > 0 then
		text = "Tạo phó bản thành công!"
	else
		text = "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!"
	end
	self:notify_tips(selfId,text)
end

function efuben_yanmenlunwu:OnPlayerEnter(selfId)
	self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, self:get_scene_id(), self.g_Fuben_X, self.g_Fuben_Z)
	self:DoNpcTalk(selfId,134)
end

function efuben_yanmenlunwu:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId,3)
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

function efuben_yanmenlunwu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) == self.g_Name then
		if self:LuaFnGetSceneType() == 1 then
			caller:AddNumTextWithTarget(self.scirpt_id, "#{SBRC_20230627_42}", 9, 300)
		else
			caller:AddNumTextWithTarget(self.script_id, "#{MPCG_191029_307}", 6, 100)
			caller:AddNumTextWithTarget(self.script_id, "#{MPCG_191029_310}", 6, 200)
			caller:AddNumTextWithTarget(self.script_id, "#{MPCG_191029_308}", 10, 3)
			caller:AddNumTextWithTarget(self.script_id, "#{MPCG_191029_309}", 10, 2)
			caller:AddNumTextWithTarget(self.script_id, "#{MPCG_191029_06}", 10, 1)
			caller:AddNumTextWithTarget(self.script_id, "#{MPCG_191029_305}", 11, 4)
		end
    end
end

function efuben_yanmenlunwu:OnDie(objId,selfId)
	local objType = self:GetCharacterType(selfId)
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
	local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
	if leaveFlag == 1 then														-- 如果副本已经被置成关闭状态，则杀怪无效
		return
	end
	--取得当前场景里的人数
	local num = self:LuaFnGetCopyScene_HumanCount()
	local mems = {}
	for i = 1, num do
		mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
	end

	--self:LuaFnSetCopySceneData_Param(4,1)--设置离开场景
end

--[[function efuben_yanmenlunwu:DisableDynamicRegions(name)
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
end]]

function efuben_yanmenlunwu:CreateBOSS(nMonsterID,posX,posY,BaseAI,AIScript,ScriptID,Title,Level)
	local MstId = self:LuaFnCreateMonster(nMonsterID,posX,posY,BaseAI,AIScript,ScriptID)
	self:SetMonsterFightWithNpcFlag(MstId,0)
	if Title > 0 and Title <= 9 then
		self:SetCharacterTitle(MstId,self.g_CharTile[Title])
	end
	self:SetLevel(MstId,Level) --设置怪物等级
	self:StrengthBOSS(MstId)--加强怪物
	self:LuaFnSendSpecificImpactToUnit(MstId,MstId,MstId,152,0)
	-- if BOSSData.MsgData ~= "" then
		-- self:MonsterTalk(MstId,"水月山庄",BOSSData.MsgData)
	-- end
	--//动态阻挡数据预留
	--[[local dynamic_region = self.g_DynamicRegionPos[name]
	if dynamic_region then
		for _, region in ipairs(dynamic_region) do
			self:EnableDynamicRegion(region.id, region.data_index, region.x, region.y, region.dir)
			local mst_id = self:LuaFnCreateMonster(region.DataID, region.x, region.y, 3, -1, -1)
			self:SetCharacterDir(mst_id, region.dir)
		end
	end]]

	--统计创建BOSS....
	--self:AuditPMFCreateBoss(BOSSData.DataID)
	return MstId
end

--**********************************
--删除指定BOSS....
--**********************************
function efuben_yanmenlunwu:DeleteBOSS(selfId)
	self:SetCharacterDieTime(selfId,1000)
end

--[[function efuben_yanmenlunwu:Exit(selfId )
	local oldsceneId = self:LuaFnGetCopySceneData_Param(3)				-- 取得副本入口场景号
	--self:NewWorld(selfId, oldsceneId, nil ,self.g_Back_X, self.g_Back_Z )
end]]

function efuben_yanmenlunwu:OnCopySceneTimer()
	self:TickFubenLife()
	--self:TickSYSZTimer()
end

function efuben_yanmenlunwu:TickFubenLife()
	--初始化副本内的NPC....
	local TickCount = self:LuaFnGetCopySceneData_Param(2)
	TickCount = TickCount + 1
	self:LuaFnSetCopySceneData_Param(2,TickCount)
	if TickCount == 1 then
		self:LuaFnCreateMonster(49885,175,351,3,-1, 893130) --创建孟闯
		self:LuaFnCreateMonster(49885,192,140,3,-1, 893130)
		--创建飞天坐骑
		--创建此次副本所随机的四个门派弟子
		for i = 1,4 do
			local RandomNpc = math.random(1,#self.g_NPCList)
			local nMonsterID = self:LuaFnCreateMonster(self.g_NPCList[RandomNpc],self.g_NPCPosData[i][1],self.g_NPCPosData[i][2],3,-1,self.g_NPCScriptID[RandomNpc])
			self:SetCharacterTitle(nMonsterID,self.g_CharTile[RandomNpc]) --设置怪物称号
		end
		return
	end
end

function efuben_yanmenlunwu:TickSYSZTimer()
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

function efuben_yanmenlunwu:NotifyFailBox(selfId, targetId, msg )
	self:BeginEvent()
	self:AddText(msg)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId )
end

function efuben_yanmenlunwu:NotifyFailTips(Tip)
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

function efuben_yanmenlunwu:IsSYSZTimerRunning()
	local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_SYSZTimerStep)
	if step > 0 then
		return 1
	else
		return 0
	end
end

function efuben_yanmenlunwu:OpenSYSZTimer(allstep, ScriptID )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerStep, allstep )
	self:LuaFnSetCopySceneData_Param(self.g_IDX_SYSZTimerScriptID, ScriptID )
end
--////用于加强副本难度伤害
function efuben_yanmenlunwu:StrengthBOSS(monsterId)
    local nFubenType = self:LuaFnGetCopySceneData_Param(self.g_IDX_CopyDiff)
    self:LuaFnSetLifeTimeAttrRefix_MaxHP(monsterId, self:LuaFnGetMaxBaseHp(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_CriticalAttack(monsterId,self:LuaFnGetBaseCriticalAttack(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_Hit(monsterId, self:LuaFnGetBaseHit(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_Miss(monsterId, self:LuaFnGetBaseMiss(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_AttackPhysics(monsterId,self:LuaFnGetBaseAttackPhysics(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_DefencePhysics(monsterId,self:LuaFnGetBaseDefencePhysics(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_AttackMagic(monsterId,self:LuaFnGetBaseAttackMagic(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_DefenceMagic(monsterId,self:LuaFnGetBaseDefenceMagic(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_AttackCold(monsterId,self:LuaFnGetBaseAttackCold(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_ResistCold(monsterId,self:LuaFnGetBaseAttackCold(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_AttackFire(monsterId,self:LuaFnGetBaseAttackFire(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_ResistCold(monsterId,self:LuaFnGetBaseAttackFire(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_AttackLight(monsterId,self:LuaFnGetBaseAttackLight(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_ResistLight(monsterId,self:LuaFnGetBaseAttackLight(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_AttackPoison(monsterId,self:LuaFnGetBaseAttackPosion(monsterId) * nFubenType)
    self:LuaFnSetLifeTimeAttrRefix_ResistPoison(monsterId,self:LuaFnGetBaseAttackPosion(monsterId) * nFubenType)
end

return efuben_yanmenlunwu