--飘渺峰 卓不凡AI

--A	【剑芒】使用一个空技能....再按门派setdamage....
--B 【金甲】给自己用一个加buff的技能....
--C 【明镜】给自己用一个加buff的技能....
--D	【朋友】不平道人死时给自己用一个加buff的技能....


--全程都带有免疫制定技能的buff....
--每隔40秒对当前敌人使用A....
--每隔30秒轮流使用BC....
--死亡时寻找不平道人....设置其需要使用狂暴技能....
--死亡时发现不平道人已经死了....则创建另一个BOSS....
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_zhuobufan_small = class("ai_zhuobufan_small", script_base)

--副本逻辑脚本号....
ai_zhuobufan_small.g_FuBenScriptId = 402276

--免疫Buff....
ai_zhuobufan_small.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_zhuobufan_small.Buff_MianYi2	= 10471	--免疫普通隐身....

--技能....
ai_zhuobufan_small.SkillID_A		= 1033
ai_zhuobufan_small.SkillID_B		= 1034
ai_zhuobufan_small.SkillID_C		= 1035
ai_zhuobufan_small.SkillID_D		= 1036

ai_zhuobufan_small.BuffID_D1		= 10253
ai_zhuobufan_small.BuffID_D2		= 10254

ai_zhuobufan_small.SkillCD_A		=	40000
ai_zhuobufan_small.SkillCD_BC	=	30000

ai_zhuobufan_small.SkillA_Damage =	--简单版缥缈峰使用伤害降低了的版本....
{
	[0] = 23815/4,
	[1] = 16570/4,
	[2] = 18820/4,
	[3] = 11978/4,
	[4] = 13170/4,
	[5] = 15610/4,
	[6] = 14496/4,
	[7] = 15240/4,
	[8] = 14070/4,
	[9] = 99999
}

ai_zhuobufan_small.BrotherName = "不平道人"	--兄弟的名字....


--AI Index....
ai_zhuobufan_small.IDX_KuangBaoMode	= 1	--狂暴模式....0未狂暴 1需要进入狂暴 2已经进入狂暴
ai_zhuobufan_small.IDX_CurSkillIndex	= 2	--接下来该使用BC中的哪个技能....
ai_zhuobufan_small.IDX_CD_SkillA			= 3	--A技能的CD....
ai_zhuobufan_small.IDX_CD_SkillBC		= 4	--BC技能的CD....

ai_zhuobufan_small.IDX_CombatFlag 		= 1	--是否处于战斗状态的标志....


--**********************************
--初始化....
--**********************************
function ai_zhuobufan_small:OnInit(selfId)
	--重置AI....
	self:ResetMyAI(selfId )
end


--**********************************
--心跳....
--**********************************
function ai_zhuobufan_small:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId)  then
		return
	end

	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_zhuobufan_small.IDX_CombatFlag ) then
		return
	end

	--A技能心跳....
	if 1 == self:TickSkillA(selfId, nTick ) then
		return
	end

	--BC技能心跳....
	if 1 == self:TickSkillBC(selfId, nTick ) then
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
function ai_zhuobufan_small:OnEnterCombat(selfId)
	--加初始buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_zhuobufan_small.Buff_MianYi1, 0 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_zhuobufan_small.Buff_MianYi2, 0 )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_zhuobufan_small.IDX_CombatFlag, 1 )
end


--**********************************
--离开战斗....
--**********************************
function ai_zhuobufan_small:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI(selfId )

	--遍历场景里所有的怪....寻找兄弟并将其删除....
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if ai_zhuobufan_small.BrotherName == self:GetName(MonsterId ) then
			self:LuaFnDeleteMonster(MonsterId )
		end
	end
	--删除自己....
	self:LuaFnDeleteMonster(selfId )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "ZhuoBuFan_BOSS" )
end


--**********************************
--杀死敌人....
--**********************************
function ai_zhuobufan_small:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_zhuobufan_small:OnDie(selfId, killerId )
	--重置AI....
	self:ResetMyAI(selfId )

	local bFind = 0

	--遍历场景里所有的怪....寻找兄弟....给其设置需要使用狂暴技能....
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if ai_zhuobufan_small.BrotherName == self:GetName(MonsterId ) and self:LuaFnIsCharacterLiving(MonsterId) then
			bFind = 1
			self:MonsterAI_SetIntParamByIndex(MonsterId, ai_zhuobufan_small.IDX_KuangBaoMode, 1 )
		end
	end

	--如果没找到兄弟则说明就剩自己一个了....
	if 0 == bFind then
		--创建端木元....
		local MstId = self:CallScriptFunction( ai_zhuobufan_small.g_FuBenScriptId, "CreateBOSS", "DuanMuYuan_BOSS", -1, -1 )
		self:LuaFnNpcChat(MstId, 0, "#{PMF_20080521_18}")
		--设置已经挑战过双子....
		self:CallScriptFunction( ai_zhuobufan_small.g_FuBenScriptId, "SetBossBattleFlag", "ShuangZi", 2 )
	end
end


--**********************************
--重置AI....
--**********************************
function ai_zhuobufan_small:ResetMyAI(selfId )
	--重置参数....
	self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_KuangBaoMode, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CurSkillIndex, 1 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillA, ai_zhuobufan_small.SkillCD_A )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillBC, ai_zhuobufan_small.SkillCD_BC )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_zhuobufan_small.IDX_CombatFlag, 0 )
end


--**********************************
--A技能心跳....
--**********************************
function ai_zhuobufan_small:TickSkillA(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillA )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillA, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillA, ai_zhuobufan_small.SkillCD_A-(nTick-cd) )
		return self:UseSkillA(selfId )
	end
end


--**********************************
--BC技能心跳....
--**********************************
function ai_zhuobufan_small:TickSkillBC(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillBC )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillBC, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CD_SkillBC, ai_zhuobufan_small.SkillCD_BC-(nTick-cd) )
		local CurSkill = self:MonsterAI_GetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CurSkillIndex )
		if CurSkill == 1 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CurSkillIndex, 2 )
			return self:UseSkillB(selfId )
		elseif CurSkill == 2 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_CurSkillIndex, 1 )
			return self:UseSkillC(selfId )
		end
	end
end


--**********************************
--D技能心跳....
--**********************************
function ai_zhuobufan_small:TickSkillD(selfId, nTick )
	--获得当前狂暴mode....
	local CurMode = self:MonsterAI_GetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_KuangBaoMode )
	if CurMode == 0 or CurMode == 2 then
		--如果不需要狂暴或者已经狂暴了则返回....
		return 0
	elseif CurMode == 1 then
		--如果需要狂暴则使用狂暴技能....
		local ret =  self:UseSkillD(selfId )
		if ret == 1 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_zhuobufan_small.IDX_KuangBaoMode, 2 )
			return 1
		else
			return 0
		end
	end
end


--**********************************
--使用A技能....
--**********************************
function ai_zhuobufan_small:UseSkillA(selfId )

	--获得当前敌人....
	local enemyId = self:GetMonsterCurEnemy(selfId )
	if enemyId <= 0 then
		return 0
	end
	if self:GetCharacterType(enemyId ) == "pet" then
		enemyId = self:GetPetCreator(enemyId )
	end

	--使用一个空技能....
	local x,z = self:GetWorldPos(enemyId )
	self:LuaFnUnitUseSkill(selfId, ai_zhuobufan_small.SkillID_A, enemyId, x, z, 0, 1 )

	--按门派扣血....
	local MenPai = self:GetMenPai(enemyId )
	local Damage = ai_zhuobufan_small.SkillA_Damage[ MenPai ]
	self:IncreaseHp(enemyId, -Damage )

	--喊话....
	self:MonsterTalk(-1, "", "#{PMF_20080530_18}"..self:GetName(enemyId).."#{PMF_20080530_19}" )
	return 1
end


--**********************************
--使用B技能....
--**********************************
function ai_zhuobufan_small:UseSkillB(selfId )

	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_zhuobufan_small.SkillID_B, selfId, x, z, 0, 1 )
	self:MonsterTalk(-1, "", "#{PMF_20080530_20}" )
	return 1

end


--**********************************
--使用C技能....
--**********************************
function ai_zhuobufan_small:UseSkillC(selfId )
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_zhuobufan_small.SkillID_C, selfId, x, z, 0, 1 )
	self:MonsterTalk(-1, "", "#{PMF_20080530_21}" )
	return 1
end


--**********************************
--使用D技能....
--**********************************
function ai_zhuobufan_small:UseSkillD(selfId )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_zhuobufan_small.BuffID_D1, 5000 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_zhuobufan_small.BuffID_D2, 5000 )

	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_zhuobufan_small.SkillID_D, selfId, x, z, 0, 1 )

	self:MonsterTalk(-1, "", "#{PMF_20080530_22}" )
	return 1
end

return ai_zhuobufan_small