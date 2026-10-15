--飘渺峰 桑土公AI

--A 【土遁】BOSS的HP每损失20%则会消失20秒....同时创建小怪依次为1122只..死亡or脱离战斗消失....
--B 【牛毛毒针】非土遁状态时每隔20一次大范围攻击....土遁状态下CD正常走只是不使用....土遁结束时清CD....
--C 【出土文物】进入土遁时随机获得2个buff....同时清除上次的2个buff....
--D 【疯狂】战斗5分钟后给自己和所有僵尸加一击致命buff....不再使用AB(C)....

--全程都带有免疫制定技能的buff....
--脱离战斗或死亡时删除僵尸....
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_sangtugong_small = class("ai_sangtugong_small", script_base)

--副本逻辑脚本号....
ai_sangtugong_small.g_FuBenScriptId = 402276


--免疫特定技能buff....
ai_sangtugong_small.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_sangtugong_small.Buff_MianYi2	= 10471	--免疫普通隐身....

--A土遁....
ai_sangtugong_small.SkillA_TuDun				= 1028
ai_sangtugong_small.SkillA_ChildName		= "Bích Lân Cương Thi"
ai_sangtugong_small.SkillA_ChildBuff		= 10246
ai_sangtugong_small.SkillA_ChildTime		= 5000		--土遁多长时间后开始刷小怪....
ai_sangtugong_small.SkillA_Time					= 20000		--土遁持续的时间....


--B牛毛毒针....
ai_sangtugong_small.SkillB_NiuMaoDuZhen = 1110	--简单版缥缈峰使用伤害降低了的版本....
--冷却时间....
ai_sangtugong_small.SkillB_CD						= 20000


--C出土文物技能的buff列表....
ai_sangtugong_small.SkillC_ChutuBuff1 = { 10237, 10238 }
ai_sangtugong_small.SkillC_ChutuBuff2 = { 10239, 10240, 10241, 10242 }


--D疯狂....
ai_sangtugong_small.SkillD_Buff1	= 10234
ai_sangtugong_small.SkillD_Buff2	= 10235
--开始进入狂暴状态的时间....
ai_sangtugong_small.EnterKuangBaoTime	= 5*60*1000


--AI Index....
ai_sangtugong_small.IDX_HPStep							= 1	--血量级别....
ai_sangtugong_small.IDX_SkillB_CD						= 2	--B技能的CD时间....
ai_sangtugong_small.IDX_KuangBaoTimer				= 3	--狂暴的计时器....
ai_sangtugong_small.IDX_TuDunTimer					= 4	--土遁的计时器....用于计算何时土遁结束....
ai_sangtugong_small.IDX_NeedCreateChildNum	= 5	--需要创建的小怪的数量....

ai_sangtugong_small.IDX_CombatFlag 			= 1	--是否处于战斗状态的标志....
ai_sangtugong_small.IDX_IsTudunMode			= 2	--是否处于土遁模式的标志....
ai_sangtugong_small.IDX_IsKuangBaoMode	= 3	--是否处于狂暴模式的标志....


--**********************************
--初始化....
--**********************************
function ai_sangtugong_small:OnInit(selfId)
	--重置AI....
	self:ResetMyAI(selfId )
end


--**********************************
--心跳....
--**********************************
function ai_sangtugong_small:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end

	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_CombatFlag ) then
		return
	end

	--狂暴状态不需要走逻辑....
	if 1 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_IsKuangBaoMode ) then
		return
	end

	--执行狂暴逻辑....
	if 1 == self:DoSkillD_KuangBao(selfId, nTick ) then
		return
	end

	--执行土遁逻辑....
	if 1 == self:SkillLogicA_TunDun(selfId, nTick ) then
		return
	end

	--执行牛毛毒针逻辑....
	if 1 == self:SkillLogicB_NiuMaoDuZhen(selfId, nTick ) then
		return
	end
end


--**********************************
--进入战斗....
--**********************************
function ai_sangtugong_small:OnEnterCombat(selfId, enmeyId)
	--加初始buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_sangtugong_small.Buff_MianYi1, 0 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_sangtugong_small.Buff_MianYi2, 0 )
	--重置AI....
	self:ResetMyAI(selfId )

	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_CombatFlag, 1 )
end


--**********************************
--离开战斗....
--**********************************
function ai_sangtugong_small:OnLeaveCombat(selfId)
	print("ai_sangtugong_small:OnLeaveCombat", debug.traceback())
	--删除自己....
	self:ResetMyAI(selfId)
	self:LuaFnDeleteMonster(selfId )

	--创建对话NPC....
	local MstId = self:CallScriptFunction( ai_sangtugong_small.g_FuBenScriptId, "CreateBOSS", "SangTuGong_NPC", -1, -1 )
	self:SetUnitReputationID(MstId, MstId, 0 )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "SangTuGong" )
end


--**********************************
--杀死敌人....
--**********************************
function ai_sangtugong_small:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_sangtugong_small:OnDie(selfId, killerId )

	self:ResetMyAI(selfId)
	--设置已经挑战过桑土公....
	self:CallScriptFunction( ai_sangtugong_small.g_FuBenScriptId, "SetBossBattleFlag", "SangTuGong", 2 )

	--如果还没有挑战过乌老大则可以挑战乌老大....
	if 2 ~= self:CallScriptFunction( ai_sangtugong_small.g_FuBenScriptId, "GetBossBattleFlag", "WuLaoDa" )	then
		self:CallScriptFunction( ai_sangtugong_small.g_FuBenScriptId, "SetBossBattleFlag", "WuLaoDa", 1 )
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
		local str = string.format("#{_INFOUSR%s}#{XPM_8724_3}", playerName);             --桑土公
		self:AddGlobalCountNews(str )
	end
end


--**********************************
--重置AI....
--**********************************
function ai_sangtugong_small:ResetMyAI(selfId )

	--重置参数....
	self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_HPStep, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_SkillB_CD, ai_sangtugong_small.SkillB_CD )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_KuangBaoTimer, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_TuDunTimer, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_NeedCreateChildNum, 0 )

	self:MonsterAI_SetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_CombatFlag, 0 )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_IsTudunMode, 0 )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_IsKuangBaoMode, 0 )

	--清除buff....
	for _, buffId in ipairs(self.SkillC_ChutuBuff1) do
		self:LuaFnCancelSpecificImpact(selfId, buffId )
	end

	for _, buffId in ipairs(self.SkillC_ChutuBuff2)  do
		self:LuaFnCancelSpecificImpact(selfId, buffId )
	end

	self:LuaFnCancelSpecificImpact(selfId, self.SkillD_Buff1 )
	self:LuaFnCancelSpecificImpact(selfId, self.SkillD_Buff2 )

	--清除小怪....
	local childIds = {}
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if self:GetName(MonsterId) == self.SkillA_ChildName then
			childIds[#childIds + 1] = MonsterId
		end
	end
	for _, MonsterId in ipairs(childIds) do
		self:LuaFnDeleteMonster(MonsterId)
	end
end

--**********************************
--土遁逻辑....
--**********************************
function ai_sangtugong_small:SkillLogicA_TunDun(selfId, nTick )
	--土遁模式则更新土遁的计时器....
	if 1 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_IsTudunMode ) then
		local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_TuDunTimer )
		if cd > nTick then
			self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_TuDunTimer, cd-nTick )
			--如果到了刷小怪的时间并且本次土遁还没刷过小怪....
			if cd < (self.SkillA_Time-self.SkillA_ChildTime) then
				local needCreateNum = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_NeedCreateChildNum )
				if needCreateNum > 0 then
					--创建小怪....
					self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_NeedCreateChildNum, 0 )
					local x,z = self:GetWorldPos(selfId )
					for i=1, needCreateNum do
						local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "JiangShi_BOSS", x, z )
						self:LuaFnSendSpecificImpactToUnit(MstId, MstId, MstId, self.SkillA_ChildBuff, 0 )
						self:SetCharacterName(MstId, self.SkillA_ChildName )
					end
				end
			end
		else
			--土遁结束....设置离开土遁状态....
			self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_TuDunTimer, 0 )
			self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsTudunMode, 0 )
			--重置牛毛毒针CD....
			self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, self.SkillB_CD )

		end
	--非土遁模式则检测是否可以进入土遁模式....
	else
		--每减少20%血时进入土遁模式....
		local CurPercent = self:GetHp(selfId ) / self:GetMaxHp(selfId )
		local LastStep = self:MonsterAI_GetIntParamByIndex(selfId, ai_sangtugong_small.IDX_HPStep )
		local CurStep = -1
		if CurPercent <= 0.2 then
			CurStep = 4
		elseif CurPercent <= 0.4 then
			CurStep = 3
		elseif CurPercent <= 0.6 then
			CurStep = 2
		elseif CurPercent <= 0.8 then
			CurStep = 1
		end

		--进行土遁....
		if CurStep > LastStep then
			--给自己设置隐身and不能攻击....
			local x,z = self:GetWorldPos(selfId )
			self:LuaFnUnitUseSkill(selfId, self.SkillA_TuDun, selfId, x, z, 0, 1 )

			--随机获得2个buff(出土文物)....
			local idx1 = math.random( #(self.SkillC_ChutuBuff1) )
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillC_ChutuBuff1[idx1], 0 )
			local idx2 = math.random( #(self.SkillC_ChutuBuff2) )
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillC_ChutuBuff2[idx2], 0 )

			local NeedCreateNum = 1
			if CurStep == 3 or CurStep == 4 then
				NeedCreateNum = 2
			end

			self:MonsterAI_SetBoolParamByIndex(selfId, ai_sangtugong_small.IDX_IsTudunMode, 1 )
			self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_NeedCreateChildNum, NeedCreateNum )
			self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_HPStep, CurStep )
			self:MonsterAI_SetIntParamByIndex(selfId, ai_sangtugong_small.IDX_TuDunTimer, ai_sangtugong_small.SkillA_Time )
			return 1
		end
	end
	return 0
end


--**********************************
--牛毛毒针逻辑....
--**********************************
function ai_sangtugong_small:SkillLogicB_NiuMaoDuZhen(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillB_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, cd-nTick )
	else
		self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, self.SkillB_CD-(nTick-cd) )
		--非土遁状态才可以用....
		if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_IsTudunMode ) then
			local x,z = self:GetWorldPos(selfId )
			self:MonsterTalk(-1, "", "#{PMF_20080530_16}" )
			self:LuaFnUnitUseSkill(selfId, self.SkillB_NiuMaoDuZhen, selfId, x, z, 0, 0 )
			return 1
		end
	end
	return 0
end


--**********************************
--狂暴逻辑....
--**********************************
function ai_sangtugong_small:DoSkillD_KuangBao(selfId, nTick )
	--检测是否到了狂暴的时候....
	local kbTime = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_KuangBaoTimer )
	if kbTime < self.EnterKuangBaoTime then
		self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_KuangBaoTimer, kbTime+nTick )
	else
		self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1 )
		--加狂暴buff....
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillD_Buff1, 0 )
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillD_Buff2, 0 )
		--给所有小怪加狂暴buff....
		local nMonsterNum = self:GetMonsterCount()
		for i=1, nMonsterNum do
			local MonsterId = self:GetMonsterObjID(i)
			if self:GetName(MonsterId) == self.SkillA_ChildName then
				self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, self.SkillD_Buff1, 0 )
				self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, self.SkillD_Buff2, 0 )
			end
		end
		return 1
	end
	return 0
end

return ai_sangtugong_small
