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
local ai_liqiushui = class("ai_liqiushui", script_base)

--副本逻辑脚本号....
ai_liqiushui.g_FuBenScriptId = 402263


--免疫特定技能buff....
ai_liqiushui.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_liqiushui.Buff_MianYi2	= 10471	--免疫普通隐身....

--A小无相功....
ai_liqiushui.SkillA_ID			= 1042
ai_liqiushui.SkillA_Buff		=	10271
ai_liqiushui.SkillA_CD			= 20000

--B剑舞....
ai_liqiushui.SkillB_SkillIDTbl = { 1043, 1044, 1045, 1046, 1047, 1048 }
ai_liqiushui.SkillB_WeatherTbl = { 11, 12, 13, 14, 15, 16 }
ai_liqiushui.SkillB_TalkTbl =
{
	"#{PMF_20080530_10}",
	"#{PMF_20080530_11}",
	"#{PMF_20080530_12}",
	"#{PMF_20080530_13}",
	"#{PMF_20080530_14}",
	"#{PMF_20080530_15}"
}

ai_liqiushui.SkillB_Text =
{
	"#{PMFTS_80917_5}",
	"#{PMFTS_80917_3}",
	"#{PMFTS_80917_6}",
	"#{PMFTS_80917_1}",
	"#{PMFTS_80917_2}",
	"#{PMFTS_80917_4}"
}

ai_liqiushui.SkillB_BuffIDTbl =	--简单版缥缈峰使用伤害降低了的版本....
{
	[1] = {10280,10281,10282,10283,10284,10285,10286,10287,10288,10289,10290,10291,10292,10293,10294},
	[2] = {10295,10296,10297,10298,10299,10300,10301,10302,10303,10304,10305,10306,10307,10308,10309},
	[3] = {10310,10311,10312,10313,10314,10315,10316,10317,10318,10319,10320,10321,10322,10323,10324},
	[4] = {10325,10326,10327,10328,10329,10330,10331,10332,10333,10334,10335,10336,10337,10338,10339},
	[5] = {10340,10341,10342,10343,10344,10345,10346,10347,10348,10349,10350,10351,10352,10353,10354},
	[6] = {10355,10356,10357,10358,10359,10360,10361,10362,10363,10364,10365,10366,10367,10368,10369}
}

--C洒脱....
ai_liqiushui.SkillC_ID		= 1049
ai_liqiushui.SkillC_CD		= 20000

--D冰爆....
ai_liqiushui.SkillD_ID		= 1050
ai_liqiushui.SkillD_CD		= 20000
ai_liqiushui.SkillD_SpecObj = 59	--简单版缥缈峰使用伤害降低了的版本....

--E狂暴....
ai_liqiushui.SkillE_Buff1	= 10234
ai_liqiushui.SkillE_Buff2	= 10235
--开始进入狂暴状态的时间....
ai_liqiushui.EnterKuangBaoTime	= 10*60*1000


--AI Index....
ai_liqiushui.IDX_StopWatch						= 1	--秒表....
ai_liqiushui.IDX_SkillA_CD						= 2	--A技能的CD时间....
ai_liqiushui.IDX_SkillB_HPStep				= 3	--血量级别....
ai_liqiushui.IDX_SkillB_Step					= 4	--B技能的Step....0=未发动 15=buff1 14=buff2 …… 1=buff15
ai_liqiushui.IDX_SkillB_Type					= 5	--当前正在使用哪种类型的剑舞....
ai_liqiushui.IDX_SkillC_CD						= 6	--C技能的CD时间....
ai_liqiushui.IDX_SkillD_CD						= 7	--C技能的CD时间....
ai_liqiushui.IDX_KuangBaoTimer				= 8	--狂暴的计时器....


ai_liqiushui.IDX_CombatFlag 			= 1	--是否处于战斗状态的标志....
ai_liqiushui.IDX_IsKuangBaoMode	= 2	--是否处于狂暴模式的标志....


--**********************************
--初始化....
--**********************************
function ai_liqiushui:OnInit(selfId)
	--重置AI....
	self:ResetMyAI(selfId )
end


--**********************************
--心跳....
--**********************************
function ai_liqiushui:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end
	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_liqiushui.IDX_CombatFlag ) then
		return
	end
	--狂暴状态不需要走逻辑....
	if 1 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_liqiushui.IDX_IsKuangBaoMode ) then
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
function ai_liqiushui:OnEnterCombat(selfId, enmeyId)
	--加初始buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui.Buff_MianYi1, 0 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui.Buff_MianYi2, 0 )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui.IDX_CombatFlag, 1 )
end


--**********************************
--离开战斗....
--**********************************
function ai_liqiushui:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI(selfId )

	--删除自己....
	--self:LuaFnDeleteMonster(selfId )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "LiQiuShui" )
end


--**********************************
--杀死敌人....
--**********************************
function ai_liqiushui:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_liqiushui:OnDie(selfId, killerId )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置已经挑战过李秋水....
	self:CallScriptFunction( ai_liqiushui.g_FuBenScriptId, "SetBossBattleFlag", "LiQiuShui", 2 )
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
		self:LuaFnAddMissionHuoYueZhi(nPlayerId,14)
		self:LuaFnAddSweepPointByID(nPlayerId,9,1)
	end
end


--**********************************
--重置AI....
--**********************************
function ai_liqiushui:ResetMyAI(selfId )
	--重置参数....
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_StopWatch, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillA_CD, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_HPStep, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Type, 1 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillC_CD, ai_liqiushui.SkillC_CD )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillD_CD, ai_liqiushui.SkillD_CD )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_KuangBaoTimer, 0 )

	self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui.IDX_CombatFlag, 0 )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui.IDX_IsKuangBaoMode, 0 )

end

--**********************************
--A技能心跳....
--**********************************
function ai_liqiushui:TickSkillA(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillA_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillA_CD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillA_CD, ai_liqiushui.SkillA_CD-(nTick-cd) )
		return self:UseSkillA(selfId )
	end
end

--**********************************
--B技能心跳....
--**********************************
function ai_liqiushui:TickSkillB(selfId, nTick )
	local CurPercent = self:GetHp(selfId ) / self:GetMaxHp(selfId )
	local LastStep = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_HPStep )
	local CurStep = 0
	if CurPercent <= 0.3333 then
		CurStep = 2
	elseif CurPercent <= 0.6666 then
		CurStep = 1
	end
	if CurStep > LastStep then
		--设置参数....
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_HPStep, CurStep )
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step, 15 )
		local JianWuType = math.random( #(ai_liqiushui.SkillB_SkillIDTbl) )
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Type, JianWuType )
		--喊话....
		self:MonsterTalk(-1, "", ai_liqiushui.SkillB_TalkTbl[JianWuType] )

		self:MonsterTalk(-1, "", ai_liqiushui.SkillB_Text[JianWuType] )

		--放全场景烟花....
		self:LuaFnSetSceneWeather(ai_liqiushui.SkillB_WeatherTbl[JianWuType], 15000 )

		--对自己使用空技能....
		local x,z = self:GetWorldPos(selfId )
		self:LuaFnUnitUseSkill(selfId, ai_liqiushui.SkillB_SkillIDTbl[JianWuType], selfId, x, z, 0, 1 )
		return 1
	end
	return 0
end

--**********************************
--C技能心跳....
--**********************************
function ai_liqiushui:TickSkillC(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillC_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillC_CD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillC_CD, ai_liqiushui.SkillC_CD-(nTick-cd) )
		return self:UseSkillC(selfId )
	end
end

--**********************************
--D技能心跳....
--**********************************
function ai_liqiushui:TickSkillD(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillD_CD )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillD_CD, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillD_CD, ai_liqiushui.SkillD_CD-(nTick-cd) )
		return self:UseSkillD(selfId )
	end
end

--**********************************
--E技能心跳....
--**********************************
function ai_liqiushui:TickSkillE(selfId, nTick )
	--如果正在用B技能则先等待....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step ) > 0 then
		return 0
	end
	--检测是否到了狂暴的时候....
	local kbTime = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_KuangBaoTimer )
	if kbTime < ai_liqiushui.EnterKuangBaoTime then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_KuangBaoTimer, kbTime+nTick )
		return 0
	else
		self:MonsterAI_SetBoolParamByIndex(selfId, ai_liqiushui.IDX_IsKuangBaoMode, 1 )
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui.SkillE_Buff1, 0 )
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_liqiushui.SkillE_Buff2, 0 )
		return 1
	end
end

--**********************************
--秒表心跳....
--**********************************
function ai_liqiushui:TickStopWatch(selfId, nTick )
	--限制每秒才会执行一次....
	local time = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_StopWatch )
	if (time + nTick) > 1000 then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_StopWatch, time+nTick-1000 )
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_StopWatch, time+nTick )
		return
	end
	-------------------------
	--剑舞技能逻辑....
	-------------------------
	local buffStep = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step )
	local skillType = self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Type )
	if buffStep >= 1 and buffStep <= 15 then
		--寻找符敏仪....
		local bossId = self:CallScriptFunction( ai_liqiushui.g_FuBenScriptId, "FindBOSS", "FuMinYi_NPC" )
		if bossId <= 0 then
			return 0
		end
		--让符敏仪给玩家加buff....
		local buffTbl = ai_liqiushui.SkillB_BuffIDTbl[skillType]
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
		self:MonsterAI_SetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step, buffStep-1 )
	end
end

--**********************************
--使用A技能....
--**********************************
function ai_liqiushui:UseSkillA(selfId )
	--如果正在用B技能则跳过....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step ) > 0 then
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
function ai_liqiushui:UseSkillC(selfId )
	--如果正在用B技能则跳过....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step ) > 0 then
		return 0
	end
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_liqiushui.SkillC_ID, selfId, x, z, 0, 1 )
	return 1
end

--**********************************
--使用D技能....
--**********************************
function ai_liqiushui:UseSkillD(selfId )
	--如果正在用B技能则跳过....
	if self:MonsterAI_GetIntParamByIndex(selfId, ai_liqiushui.IDX_SkillB_Step ) > 0 then
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
	self:LuaFnUnitUseSkill(selfId, ai_liqiushui.SkillD_ID, selfId, x, z, 0, 1 )

	--在该玩家脚底下放陷阱....
	x,z = self:GetWorldPos(PlayerId )
	self:CreateSpecialObjByDataIndex(selfId, ai_liqiushui.SkillD_SpecObj, x, z, 0)
	return 1
end

return ai_liqiushui