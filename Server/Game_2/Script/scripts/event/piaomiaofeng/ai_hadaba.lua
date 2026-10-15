--飘渺峰 哈大霸AI

--A 【哪里走】给自己用一个空技能....所有非少林玩家加定身buff....
--B 【悬枢之痛】给自己加不能移动双倍攻击buff....
--C 【气海之痛】给自己加受到伤害加倍buff....
--D 【丝竹空之痛】给自己加被玩家挑衅的buff....
--E 【疯狂】给自己加一击致命buff....

--全程都带有免疫制定技能的buff....
--20秒后开始使用A技能....冷却20秒....
--25秒后开始循环释放BCD技能....冷却分别是20..20..30....
--5分钟后进入狂暴模式....停止使用ABCD....清除ABCD的buff....使用E技能....
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_hadaba = class("ai_hadaba", script_base)
--脚本号

--副本逻辑脚本号....
ai_hadaba.g_FuBenScriptId = 402263

--buff....
ai_hadaba.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_hadaba.Buff_MianYi2	= 10471	--免疫普通隐身....
ai_hadaba.Skill_A			=	1024
ai_hadaba.Buff_A			= 10230
ai_hadaba.Skill_B			=	1025
ai_hadaba.Buff_B			= 10231
ai_hadaba.Skill_C			=	1026
ai_hadaba.Buff_C			= 10232
ai_hadaba.Skill_D			=	1027
ai_hadaba.Buff_D			= 10233
ai_hadaba.Buff_E1			= 10234
ai_hadaba.Buff_E2			= 10235

--技能释放时间表....
ai_hadaba.UseSkillList =
{
	{ 20,  "A" },
	{ 25,  "B" },
	{ 40,  "A" },
	{ 45,  "C" },
	{ 60,  "A" },
	{ 65,  "D" },
	{ 80,  "A" },
	{ 95,  "B" },
	{ 100, "A" },
	{ 115, "C" },
	{ 120, "A" },
	{ 135, "D" },
	{ 140, "A" },
	{ 160, "A" },
	{ 165, "B" },
	{ 180, "A" },
	{ 185, "C" },
	{ 200, "A" },
	{ 205, "D" },
	{ 220, "A" },
	{ 235, "B" },
	{ 240, "A" },
	{ 255, "C" },
	{ 260, "A" },
	{ 275, "D" },
	{ 280, "A" },
	{ 300, "E" }
}


--AI Index....
ai_hadaba.IDX_CombatTime		= 1	--进入战斗的计时器....用于记录已经进入战斗多长时间了....
ai_hadaba.IDX_UseSkillIndex	= 2	--接下来该使用技能表中的第几个技能....

ai_hadaba.IDX_CombatFlag 			= 1	--是否处于战斗状态的标志....
ai_hadaba.IDX_IsKuangBaoMode	= 2	--是否处于狂暴模式的标志....


--**********************************
--初始化....
--**********************************
function ai_hadaba:OnInit(selfId)
	print("ai_hadaba:OnInit")
	--重置AI....
	self:ResetMyAI( selfId )
end


--**********************************
--心跳....
--**********************************
function ai_hadaba:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end

	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex( selfId, self.IDX_CombatFlag ) then
		return
	end

	--狂暴状态不需要走逻辑....
	if 1 == self:MonsterAI_GetBoolParamByIndex( selfId, self.IDX_IsKuangBaoMode ) then
		return
	end

	--==================================
	--根据节目单释放技能....
	--==================================

	--获得战斗时间和已经执行到技能表中的第几项....
	local CombatTime = self:MonsterAI_GetIntParamByIndex( selfId, self.IDX_CombatTime )
	local NextSkillIndex = self:MonsterAI_GetIntParamByIndex( selfId, self.IDX_UseSkillIndex )
	--累加进入战斗的时间....
	self:MonsterAI_SetIntParamByIndex( selfId, self.IDX_CombatTime, CombatTime + nTick )

	--如果已经执行完整张技能表则不使用技能....
	if NextSkillIndex < 1 or NextSkillIndex > #(self.UseSkillList) then
		return
	end

	--如果已经到了用这个技能的时间则使用技能....
	local SkillData = self.UseSkillList[NextSkillIndex]
	if ( CombatTime + nTick ) >= SkillData[1]*1000 then
		self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, NextSkillIndex+1 )
		self:UseMySkill( selfId, SkillData[2] )
	end
end


--**********************************
--进入战斗....
--**********************************
function ai_hadaba:OnEnterCombat(selfId)
	print("ai_hadaba:OnEnterCombat")
	--简单版缥缈峰不需要加初始buff....
	--LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, ai_hadaba.Buff_MianYi1, 0 )
	--LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, ai_hadaba.Buff_MianYi2, 0 )
	--重置AI....
	self:ResetMyAI( selfId )
	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1 )
end


--**********************************
--离开战斗....
--**********************************
function ai_hadaba:OnLeaveCombat(selfId)
	print("ai_hadaba:OnLeaveCombat")
	--重置AI....
	self:ResetMyAI( selfId )

	--删除自己....
	self:LuaFnDeleteMonster( selfId )

	--创建对话NPC....
	local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "HaDaBa_NPC", -1, -1 )
	self:SetUnitReputationID( MstId, MstId, 0 )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "HaDaBa" )
end


--**********************************
--杀死敌人....
--**********************************
function ai_hadaba:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_hadaba:OnDie( selfId, killerId )
	print("ai_hadaba:OnDie selfId =", selfId, ";killerId =", killerId)
	--设置已经挑战过哈大霸....
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossBattleFlag", "HaDaBa", 2 )

	--如果还没有挑战过桑土公则可以挑战桑土公....
	if 2 ~= self:CallScriptFunction( self.g_FuBenScriptId, "GetBossBattleFlag", "SangTuGong" ) then
		self:CallScriptFunction( self.g_FuBenScriptId, "SetBossBattleFlag", "SangTuGong", 1 )
	end
	-- zchw 全球公告
	local	playerName	= self:GetName( killerId )

	--杀死怪物的是宠物则获取其主人的名字....
	local playerID = killerId
	local objType = self:GetCharacterType( killerId )
	if objType == "pet" then
		playerID = self:GetPetCreator( killerId )
		playerName = self:GetName( playerID )
	end

	--如果玩家组队了则获取队长的名字....
	local leaderID = self:GetTeamLeader( playerID )
	if leaderID ~= -1 then
		playerName = self:GetName( leaderID )
	end

	if playerName ~= nil then
		local str = string.format("#{XPM_8724_1}#{_INFOUSR%s}#{XPM_8724_2}", playerName); --哈大霸
		self:AddGlobalCountNews( str )
	end
end


--**********************************
--重置AI....
--**********************************
function ai_hadaba:ResetMyAI( selfId )
	--重置参数....
	self:MonsterAI_SetIntParamByIndex( selfId, self.IDX_CombatTime, 0 )
	self:MonsterAI_SetIntParamByIndex( selfId, self.IDX_UseSkillIndex, 1 )

	self:MonsterAI_SetBoolParamByIndex( selfId, self.IDX_IsKuangBaoMode, 0 )
	self:MonsterAI_SetBoolParamByIndex( selfId, self.IDX_CombatFlag, 0 )

	--清除buff....
	self:LuaFnCancelSpecificImpact( selfId, self.Buff_B )
	self:LuaFnCancelSpecificImpact( selfId, self.Buff_C )
	self:LuaFnCancelSpecificImpact( selfId, self.Buff_D )
	self:LuaFnCancelSpecificImpact( selfId, self.Buff_E1 )
	self:LuaFnCancelSpecificImpact( selfId, self.Buff_E2 )
end


--**********************************
--BOSS使用技能....
--**********************************
function ai_hadaba:UseMySkill( selfId, skill )
	if skill == "A" then
		self:SkillA_NaLiZou( selfId )
	elseif skill == "B" then
		self:MonsterTalk(-1, "", "#{PMF_20080530_06}" )
		local x,z = self:GetWorldPos( selfId )
		self:LuaFnUnitUseSkill( selfId, self.Skill_B, selfId, x, z, 0, 0 )
		self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, self.Buff_B, 2000 )
	elseif skill == "C" then
		self:MonsterTalk(-1, "", "#{PMF_20080530_07}" )
		local x,z = self:GetWorldPos( selfId )
		self:LuaFnUnitUseSkill( selfId, self.Skill_C, selfId, x, z, 0, 0 )
		self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, self.Buff_C, 0 )
	elseif skill == "D" then
		local enemyId = self:GetMonsterCurEnemy( selfId )
		if enemyId > 0 then
			if self:GetCharacterType( enemyId ) == "pet" then
				enemyId = self:GetPetCreator( enemyId )
			end
			self:MonsterTalk(-1, "", "#{PMF_20080530_08}" )
			local x,z = self:GetWorldPos( selfId )
			self:LuaFnUnitUseSkill( selfId, self.Skill_D, selfId, x, z, 0, 0 )
			self:LuaFnSendSpecificImpactToUnit( selfId, enemyId, selfId, self.Buff_D, 0 )
		end
	elseif skill == "E" then
		self:MonsterAI_SetBoolParamByIndex( selfId, self.IDX_IsKuangBaoMode, 1 )
		self:SkillE_KuangBao( selfId )
	end
end


--**********************************
--哪里走技能....对非少林玩家加buff....
--**********************************
function ai_hadaba:SkillA_NaLiZou( selfId )
	self:MonsterTalk(-1, "", "#{PMF_20080530_09}" )
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			if self:GetMenPai(nHumanId) ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
				self:LuaFnSendSpecificImpactToUnit( selfId, selfId, nHumanId, self.Buff_A, 0 )
				local x,z = self:GetWorldPos( selfId )
				self:LuaFnUnitUseSkill(selfId, self.Skill_A, selfId, x, z, 0, 0 )
			end
		end
	end
end


--**********************************
--狂暴技能....
--**********************************
function ai_hadaba:SkillE_KuangBao( selfId )
	--取消BCD的buff....
	self:LuaFnCancelSpecificImpact( selfId, ai_hadaba.Buff_B )
	self:LuaFnCancelSpecificImpact( selfId, ai_hadaba.Buff_C )
	self:LuaFnCancelSpecificImpact( selfId, ai_hadaba.Buff_D )

	--加狂暴buff....
	self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, ai_hadaba.Buff_E1, 0 )
	self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, ai_hadaba.Buff_E2, 0 )
end

return ai_hadaba