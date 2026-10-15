--飘渺峰 乌老大AI

--A	【金灯万盏】毒属性群攻....
--B 【麻痹毒药】普通技能....全副本随机挑一个人对其释放空技能....再给其加个buff....
--C 【绿波香露】对自己使用一个空技能....同时在当前敌人脚下放个陷阱....
--D 【毒性变换】每隔5秒给全副本所有人加一个buff....

--全程都带有免疫制定技能的buff....
--20秒后开始循环释放ABC技能....冷却20秒....
--每5秒使用一次D....
--BOSS死亡或脱离战斗会给所有人清除D的buff....
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_wulaoda_small = class("ai_wulaoda_small", script_base)


--副本逻辑脚本号....
ai_wulaoda_small.g_FuBenScriptId = 402276

--免疫Buff....
ai_wulaoda_small.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_wulaoda_small.Buff_MianYi2	= 10471	--免疫普通隐身....

--ABC技能....
ai_wulaoda_small.SkillA			= 1111	--简单版缥缈峰使用伤害降低了的版本....
ai_wulaoda_small.SkillB			= 1112	--简单版缥缈峰使用伤害降低了的版本....
ai_wulaoda_small.BuffB				= 19803	--简单版缥缈峰使用伤害降低了的版本....
ai_wulaoda_small.SkillC			= 1113	--简单版缥缈峰使用伤害降低了的版本....
ai_wulaoda_small.SpeObjC			= 72	--简单版缥缈峰使用伤害降低了的版本....
ai_wulaoda_small.SkillABC_CD	=	60000

--D技能....
ai_wulaoda_small.BuffD				= 19801	--简单版缥缈峰使用伤害降低了的版本....
ai_wulaoda_small.SkillD_CD		= 5000


--AI Index....
ai_wulaoda_small.IDX_CD_SkillABC		= 1	--ABC技能的CD....
ai_wulaoda_small.IDX_CurSkillIndex	= 2	--接下来该使用ABC中的哪个技能....
ai_wulaoda_small.IDX_CD_SkillD			= 3	--D技能的CD....

ai_wulaoda_small.IDX_CombatFlag 		= 1	--是否处于战斗状态的标志....


--**********************************
--初始化....
--**********************************
function ai_wulaoda_small:OnInit(selfId)
	--重置AI....
	self:ResetMyAI(selfId )
end


--**********************************
--心跳....
--**********************************
function ai_wulaoda_small:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end

	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_wulaoda_small.IDX_CombatFlag ) then
		return
	end

	--ABC技能心跳....
	if 1 == self:TickSkillABC(selfId, nTick ) then
		return
	end

	--D技能心跳....
	if 1 == self:TickSkillD(selfId, nTick ) then
		return
	end
end


--**********************************
--进入战斗....
--**********************************
function ai_wulaoda_small:OnEnterCombat(selfId)

	--加初始buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_wulaoda_small.Buff_MianYi1, 0 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_wulaoda_small.Buff_MianYi2, 0 )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_wulaoda_small.IDX_CombatFlag, 1 )
end


--**********************************
--离开战斗....
--**********************************
function ai_wulaoda_small:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI(selfId )

	--删除自己....
	self:LuaFnDeleteMonster(selfId )

	--创建对话NPC....
	local MstId = self:CallScriptFunction( ai_wulaoda_small.g_FuBenScriptId, "CreateBOSS", "WuLaoDa_NPC", -1, -1 )
	self:SetUnitReputationID(MstId, MstId, 0 )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "WuLaoDa" )
end


--**********************************
--杀死敌人....
--**********************************
function ai_wulaoda_small:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_wulaoda_small:OnDie(selfId, killerId )

	--重置AI....
	self:ResetMyAI(selfId )

	--删除自己....
	self:SetCharacterDieTime(selfId, 3000 )

	--开启乌老大死亡的计时器....
	local x,z = self:GetWorldPos(selfId )
	self:CallScriptFunction( ai_wulaoda_small.g_FuBenScriptId, "OpenWuLaoDaDieTimer", 4, self.script_id, x, z )

	--设置已经挑战过乌老大....
	self:CallScriptFunction( ai_wulaoda_small.g_FuBenScriptId, "SetBossBattleFlag", "WuLaoDa", 2 )

	--如果还没有挑战过双子则可以挑战双子....
	if 2 ~= self:CallScriptFunction( ai_wulaoda_small.g_FuBenScriptId, "GetBossBattleFlag", "ShuangZi" )	then
		self:CallScriptFunction( ai_wulaoda_small.g_FuBenScriptId, "SetBossBattleFlag", "ShuangZi", 1 )
	end
	-- zchw 全球公告
	local	playerName	= self:GetName(killerId )

	--杀死怪物的是宠物则获取其主人的名字....
	local playerID = killerId
	local objType = self:GetCharacterType(killerId )
	if objType == "pet" then
		playerID = self:GetPetCreator(killerId )
		playerName = self:GetName(playerID )
	end

	--如果玩家组队了则获取队长的名字....
	local leaderID = self:GetTeamLeader(playerID )
	if leaderID ~= -1 then
		playerName = self:GetName(leaderID )
	end

	if playerName ~= nil then
		local str = string.format("#{_INFOUSR%s}#{XPM_8724_4}", playerName);      --乌老大
		self:AddGlobalCountNews(str )
	end
	self:CancelImpacts()
end

function ai_wulaoda_small:CancelImpacts()
	local count = self:LuaFnGetCopyScene_HumanCount()
	for i = 1, count do
		local objId = self:LuaFnGetCopyScene_HumanObjId(i)
		if objId then
			self:LuaFnCancelSpecificImpact(objId, self.BuffD)
		end
	end
end

--**********************************
--重置AI....
--**********************************
function ai_wulaoda_small:ResetMyAI(selfId )
	--重置参数....
	self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillABC, ai_wulaoda_small.SkillABC_CD )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CurSkillIndex, 1 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillD, ai_wulaoda_small.SkillD_CD )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_wulaoda_small.IDX_CombatFlag, 0 )

	--给所有人清除D的buff....
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId =self: LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) then
			self:LuaFnCancelSpecificImpact(nHumanId, ai_wulaoda_small.BuffD )
			self:LuaFnCancelSpecificImpact(nHumanId,891)
		end
	end

end


--**********************************
--ABC技能心跳....
--**********************************
function ai_wulaoda_small:TickSkillABC(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillABC )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillABC, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillABC, ai_wulaoda_small.SkillABC_CD-(nTick-cd) )
		local CurSkill = self:MonsterAI_GetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CurSkillIndex )
		if CurSkill == 1 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CurSkillIndex, 2 )
			return self:UseSkillA(selfId )
		elseif CurSkill == 2 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CurSkillIndex, 3 )
			return self:UseSkillB(selfId )
		elseif CurSkill == 3 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CurSkillIndex, 1 )
			return self:UseSkillC(selfId )
		end
	end
end


--**********************************
--D技能心跳....
--**********************************
function ai_wulaoda_small:TickSkillD(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_wulaoda_small.IDX_CD_SkillD, ai_wulaoda_small.SkillD_CD-(nTick-cd) )
		return self:UseSkillD(selfId )
	end
end


--**********************************
--使用A技能....
--**********************************
function ai_wulaoda_small:UseSkillA(selfId )
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_wulaoda_small.SkillA, selfId, x, z, 0, 1 )
	return 1
end


--**********************************
--使用B技能....
--**********************************
function ai_wulaoda_small:UseSkillB(selfId )
	--副本中有效的玩家的列表....
	local PlayerList = {}

	--将有效的人加入列表....
	local numPlayer = 0
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			PlayerList[numPlayer+1] = nHumanId
			numPlayer = numPlayer + 1
		end
	end

	--随机挑选一个玩家....
	if numPlayer <= 0 then
		return 0
	end
	local PlayerId = PlayerList[ math.random(numPlayer) ]

	--对其使用技能....
	local x,z = self:GetWorldPos(PlayerId )
	self:LuaFnUnitUseSkill(selfId, ai_wulaoda_small.SkillB, PlayerId, x, z, 0, 1 )

	--给其加buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, PlayerId, ai_wulaoda_small.BuffB, 0 )
	return 1
end


--**********************************
--使用C技能....
--**********************************
function ai_wulaoda_small:UseSkillC(selfId )
	--获得当前敌人....
	local enemyId = self:GetMonsterCurEnemy(selfId )
	if enemyId <= 0 then
		return 0
	end
	if self:GetCharacterType(enemyId ) == 3 then
		enemyId = self:GetPetCreator(enemyId )
	end

	--在该敌人脚下放个陷阱....
	local x,z = self:GetWorldPos(enemyId )
	self:CreateSpecialObjByDataIndex(selfId, ai_wulaoda_small.SpeObjC, x, z, 0 )

	--喊话....
	self:MonsterTalk(-1, "", "#{PMF_20080530_17}" )

	--对自己使用一个只有特效的空技能....
	x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_wulaoda_small.SkillC, selfId, x, z, 0, 1 )
	return 1
end


--**********************************
--使用D技能....
--**********************************
function ai_wulaoda_small:UseSkillD(selfId )
	--给副本里所有人加buff....
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, ai_wulaoda_small.BuffD, 0 )
		end
	end
end


--**********************************
--乌老大死亡计时器OnTimer....
--用于控制死亡后延迟刷出战败乌老大....
--**********************************
function ai_wulaoda_small:OnHaDaBaDieTimer(step, posX, posY )
	if 1 == step then
		--创建战败的乌老大NPC....
		local MstId = self:CallScriptFunction( ai_wulaoda_small.g_FuBenScriptId, "CreateBOSS", "WuLaoDaLoss_NPC", posX, posY )
		self:SetUnitReputationID(MstId, MstId, 0 )
		self:SetPatrolId(MstId, 0)
	end
end

return ai_wulaoda_small