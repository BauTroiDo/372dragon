--飘渺峰 李秋水AI

--A 【小无相功】给自己用个空技能....再给随机给一个玩家失明....
--B 【剑舞】给自己用一个空技能....接下来15s内依次给全副本玩家加伤害值逐渐加大的伤害buff....
--C 【洒脱】给自己用一个清buff的技能....
--D 【冰爆】给自己用个空技能....再给随机给玩家脚下放个陷阱....
--E 【狂暴】给自己加疯狂的buff....不再使用其他技能....

--全程都带有免疫制定技能的buff....
--战斗开始同时每隔10秒用A技能....
--当HP降为66%和33%时分别使用B技能....B技能的持续时间内....其它技能CD到了不使用....
--每隔20秒用C技能....
--每隔20秒用D技能....
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_liqiushui_small = class("ai_liqiushui_small", script_base)

--副本逻辑脚本号....
ai_liqiushui_small.g_FuBenScriptId = 402276


--免疫特定技能buff....
ai_liqiushui_small.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_liqiushui_small.Buff_MianYi2	= 10471	--免疫普通隐身....

--A小无相功....
ai_liqiushui_small.SkillA_ID			= 1042
ai_liqiushui_small.SkillA_Buff		=	10271
ai_liqiushui_small.SkillA_CD			= 20000

--B剑舞....
ai_liqiushui_small.SkillB_SkillIDTbl = { 1043, 1044, 1045, 1046, 1047, 1048 }
ai_liqiushui_small.SkillB_WeatherTbl = { 11, 12, 13, 14, 15, 16 }
ai_liqiushui_small.SkillB_TalkTbl =
{
	"#{PMF_20080530_10}",
	"#{PMF_20080530_11}",
	"#{PMF_20080530_12}",
	"#{PMF_20080530_13}",
	"#{PMF_20080530_14}",
	"#{PMF_20080530_15}"
}

ai_liqiushui_small.SkillB_Text =
{
	"#{PMFTS_80917_5}",
	"#{PMFTS_80917_3}",
	"#{PMFTS_80917_6}",
	"#{PMFTS_80917_1}",
	"#{PMFTS_80917_2}",
	"#{PMFTS_80917_4}"
}

ai_liqiushui_small.SkillB_BuffIDTbl =	--简单版缥缈峰使用伤害降低了的版本....
{
	[1] = {19808,19809,19810,19811,19812,19813,19814,19815,19816,19817,19818,19819,19820,19821,19822},
	[2] = {19823,19824,19825,19826,19827,19828,19829,19830,19831,19832,19833,19834,19835,19836,19837},
	[3] = {19838,19839,19840,19841,19842,19843,19844,19845,19846,19847,19848,19849,19850,19851,19852},
	[4] = {19853,19854,19855,19856,19857,19858,19859,19860,19861,19862,19863,19864,19865,19866,19867},
	[5] = {19868,19869,19870,19871,19872,19873,19874,19875,19876,19877,19878,19879,19880,19881,19882},
	[6] = {19883,19884,19885,19886,19887,19888,19889,19890,19891,19892,19893,19894,19895,19896,19897}
}

--C洒脱....
ai_liqiushui_small.SkillC_ID		= 1049
ai_liqiushui_small.SkillC_CD		= 20000

--D冰爆....
ai_liqiushui_small.SkillD_ID		= 1050
ai_liqiushui_small.SkillD_CD		= 20000
ai_liqiushui_small.SkillD_SpecObj = 73	--简单版缥缈峰使用伤害降低了的版本....

--E狂暴....
ai_liqiushui_small.SkillE_Buff1	= 10234
ai_liqiushui_small.SkillE_Buff2	= 10235
--开始进入狂暴状态的时间....
ai_liqiushui_small.EnterKuangBaoTime	= 10*60*1000


--AI Index....
ai_liqiushui_small.IDX_StopWatch						= 1	--秒表....
ai_liqiushui_small.IDX_SkillA_CD						= 2	--A技能的CD时间....
ai_liqiushui_small.IDX_SkillB_HPStep				= 3	--血量级别....
ai_liqiushui_small.IDX_SkillB_Step					= 4	--B技能的Step....0=未发动 15=buff1 14=buff2 …… 1=buff15
ai_liqiushui_small.IDX_SkillB_Type					= 5	--当前正在使用哪种类型的剑舞....
ai_liqiushui_small.IDX_SkillC_CD						= 6	--C技能的CD时间....
ai_liqiushui_small.IDX_SkillD_CD						= 7	--C技能的CD时间....
ai_liqiushui_small.IDX_KuangBaoTimer				= 8	--狂暴的计时器....


ai_liqiushui_small.IDX_CombatFlag 			= 1	--是否处于战斗状态的标志....
ai_liqiushui_small.IDX_IsKuangBaoMode	= 2	--是否处于狂暴模式的标志....


--**********************************
--初始化....
--**********************************
function ai_liqiushui_small:OnInit(selfId)
	--重置AI....
	self:ResetMyAI(selfId )
end


--**********************************
--心跳....
--**********************************
function ai_liqiushui_small:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end
	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_liqiushui_small.IDX_CombatFlag ) then
		return
	end
	--狂暴状态不需要走逻辑....
	if 1 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_liqiushui_small.IDX_IsKuangBaoMode ) then
		return
	end
	--A技能心跳....
	if 1 == self:TickSkillA(selfId, nTick ) then
		return
	end

	--B技能心跳....
	if 1 == self:TickSkillB(selfId, nTick ) then
		return
	end

	--C技能心跳....
	if 1 == self:TickSkillC(selfId, nTick ) then
		return
	end

	--D技能心跳....
	if 1 == self:TickSkillD(selfId, nTick ) then
		return
	end

	--E技能心跳....
	if 1 == self:TickSkillE(selfId, nTick ) then
		return
	end

	--秒表心跳....
	self:TickStopWatch(selfId, nTick )
end


--**********************************
--进入战斗....
--**********************************
function ai_liqiushui_small:OnEnterCombat(selfId, enmeyId)
	--加初始buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui_small.Buff_MianYi1, 0 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui_small.Buff_MianYi2, 0 )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui_small.IDX_CombatFlag, 1 )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "LiQiuShui" )
end


--**********************************
--离开战斗....
--**********************************
function ai_liqiushui_small:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI(selfId )

	--删除自己....
	self:LuaFnDeleteMonster(selfId )
end


--**********************************
--杀死敌人....
--**********************************
function ai_liqiushui_small:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_liqiushui_small:OnDie(selfId, killerId )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置已经挑战过李秋水....
	self:CallScriptFunction( ai_liqiushui_small.g_FuBenScriptId, "SetBossBattleFlag", "LiQiuShui", 2 )
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
		local str = string.format("#{XPM_8724_7}#{_INFOUSR%s}#{XPM_8724_8}", playerName);   --李秋水
		self:AddGlobalCountNews(str )
	end
	local nPlayerNum = self:GetNearTeamCount(killerId)
	for i=1, nPlayerNum  do
		local nPlayerId = self:GetNearTeamMember(killerId, i)
		self:LuaFnAddMissionHuoYueZhi(nPlayerId,13)
		self:LuaFnAddSweepPointByID(nPlayerId,9,1)
	end
end


--**********************************
--重置AI....
--**********************************
function ai_liqiushui_small:ResetMyAI(selfId )
	--重置参数....
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_StopWatch, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillA_CD, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_HPStep, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Type, 1 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillC_CD, ai_liqiushui_small.SkillC_CD )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillD_CD, ai_liqiushui_small.SkillD_CD )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_KuangBaoTimer, 0 )

	self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui_small.IDX_CombatFlag, 0 )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui_small.IDX_IsKuangBaoMode, 0 )

end

--**********************************
--A技能心跳....
--**********************************
function ai_liqiushui_small:TickSkillA(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillA_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillA_CD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillA_CD, ai_liqiushui_small.SkillA_CD-(nTick-cd) )
		return self:UseSkillA(selfId )
	end
end

--**********************************
--B技能心跳....
--**********************************
function ai_liqiushui_small:TickSkillB(selfId, nTick )
	local CurPercent = self:GetHp(selfId ) / self:GetMaxHp(selfId )
	local LastStep = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_HPStep )
	local CurStep = 0
	if CurPercent <= 0.3333 then
		CurStep = 2
	elseif CurPercent <= 0.6666 then
		CurStep = 1
	end
	if CurStep > LastStep then
		--设置参数....
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_HPStep, CurStep )
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step, 15 )
		local JianWuType = math.random( #(ai_liqiushui_small.SkillB_SkillIDTbl) )
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Type, JianWuType )
		--喊话....
		self:MonsterTalk(-1, "", ai_liqiushui_small.SkillB_TalkTbl[JianWuType] )

		self:MonsterTalk(-1, "", ai_liqiushui_small.SkillB_Text[JianWuType] )

		--放全场景烟花....
		self:LuaFnSetSceneWeather(ai_liqiushui_small.SkillB_WeatherTbl[JianWuType], 15000 )

		--对自己使用空技能....
		local x,z = self:GetWorldPos(selfId )
		self:LuaFnUnitUseSkill(selfId, ai_liqiushui_small.SkillB_SkillIDTbl[JianWuType], selfId, x, z, 0, 1 )
		return 1
	end
	return 0
end

--**********************************
--C技能心跳....
--**********************************
function ai_liqiushui_small:TickSkillC(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillC_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillC_CD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillC_CD, ai_liqiushui_small.SkillC_CD-(nTick-cd) )
		return self:UseSkillC(selfId )
	end
end

--**********************************
--D技能心跳....
--**********************************
function ai_liqiushui_small:TickSkillD(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillD_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillD_CD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillD_CD, ai_liqiushui_small.SkillD_CD-(nTick-cd) )
		return self:UseSkillD(selfId )
	end
end

--**********************************
--E技能心跳....
--**********************************
function ai_liqiushui_small:TickSkillE(selfId, nTick )
	--如果正在用B技能则先等待....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step ) > 0 then
		return 0
	end
	--检测是否到了狂暴的时候....
	local kbTime = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_KuangBaoTimer )
	if kbTime < ai_liqiushui_small.EnterKuangBaoTime then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_KuangBaoTimer, kbTime+nTick )
		return 0
	else
		self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui_small.IDX_IsKuangBaoMode, 1 )
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui_small.SkillE_Buff1, 0 )
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui_small.SkillE_Buff2, 0 )
		return 1
	end
end

--**********************************
--秒表心跳....
--**********************************
function ai_liqiushui_small:TickStopWatch(selfId, nTick )
	--限制每秒才会执行一次....
	local time = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_StopWatch )
	if (time + nTick) > 1000 then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_StopWatch, time+nTick-1000 )
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_StopWatch, time+nTick )
		return
	end
	-------------------------
	--剑舞技能逻辑....
	-------------------------
	local buffStep = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step )
	local skillType = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Type )
	if buffStep >= 1 and buffStep <= 15 then
		--寻找符敏仪....
		local bossId = self:CallScriptFunction( ai_liqiushui_small.g_FuBenScriptId, "FindBOSS", "FuMinYi_NPC" )
		if bossId <= 0 then
			return 0
		end
		--让符敏仪给玩家加buff....
		local buffTbl = ai_liqiushui_small.SkillB_BuffIDTbl[skillType]
		local buffId = buffTbl[16-buffStep]
		local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
		for i=1, nHumanCount do
			local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
				--计算NPC和玩家距离，在距离范围内得给技能
				if self:IsInDist(nHumanId,selfId,5) then
					self:LuaFnSendSpecificImpactToUnit(bossId, bossId, nHumanId, buffId, 0 )
				end
			end
		end
	end
	if buffStep > 0 then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step, buffStep-1 )
	end
end

--**********************************
--使用A技能....
--**********************************
function ai_liqiushui_small:UseSkillA(selfId )
	--如果正在用B技能则跳过....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step ) > 0 then
		return 0
	end
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

	--对自己使用一个空技能....
	local x,z = self:GetWorldPos( selfId )
	self:LuaFnUnitUseSkill(selfId, self.SkillA_ID, selfId, x, z, 0, 1 )
	--给玩家加失明buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, PlayerId, self.SkillA_Buff, 0 )
	return 1
end

--**********************************
--使用C技能....
--**********************************
function ai_liqiushui_small:UseSkillC(selfId )
	--如果正在用B技能则跳过....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step ) > 0 then
		return 0
	end
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_liqiushui_small.SkillC_ID, selfId, x, z, 0, 1 )
	return 1
end

--**********************************
--使用D技能....
--**********************************
function ai_liqiushui_small:UseSkillD(selfId )
	--如果正在用B技能则跳过....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui_small.IDX_SkillB_Step ) > 0 then
		return 0
	end

	--副本中有效的玩家的列表....
	local PlayerList = {}

	--将有效的人加入列表....
	local numPlayer = 0
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId)  and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			PlayerList[numPlayer+1] = nHumanId
			numPlayer = numPlayer + 1
		end
	end

	--随机挑选一个玩家....
	if numPlayer <= 0 then
		return 0
	end
	local PlayerId = PlayerList[ math.random(numPlayer) ]

	--使用空技能....
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_liqiushui_small.SkillD_ID, selfId, x, z, 0, 1 )

	--在该玩家脚底下放陷阱....
	x,z = self:GetWorldPos(PlayerId )
	self:CreateSpecialObjByDataIndex(selfId, ai_liqiushui_small.SkillD_SpecObj, x, z, 0)
	return 1
end

return ai_liqiushui_small