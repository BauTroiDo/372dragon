--飘渺峰 不平道人AI

--F	【暗雷】对自己用一个空技能....再给玩家加个结束后会回调脚本的buff....回调时让BOSS给其周围人加伤寒buff并喊话....
--G 【精算】给自己用一个加buff的技能....
--H 【烟花】对自己用一个空技能....再给玩家加个结束后会回调脚本的buff....回调时喊话....
--I	【朋友】卓不凡死时给自己用一个加buff的技能....


--全程都带有免疫制定技能的buff....
--每隔30秒对随机玩家随机使用FH....
--每隔45秒对自己使用G....
--死亡或脱离战斗时给所有玩家清除FH的buff....
--死亡时寻找不平道人....设置其需要使用狂暴技能....
--死亡时发现不平道人已经死了....则创建另一个BOSS....
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_bupingdaoren_small = class("ai_bupingdaoren_small", script_base)

--副本逻辑脚本号....
ai_bupingdaoren_small.g_FuBenScriptId = 402276

--免疫Buff....
ai_bupingdaoren_small.Buff_MianYi1	= 10472	--免疫一些负面效果....
ai_bupingdaoren_small.Buff_MianYi2	= 10471	--免疫普通隐身....

--技能....
ai_bupingdaoren_small.SkillID_F		= 1037
ai_bupingdaoren_small.BuffID_F1		= 19806	--回调简单版缥缈峰的脚本....
ai_bupingdaoren_small.BuffID_F2		= 19807	--简单版缥缈峰使用伤害降低了的版本....
ai_bupingdaoren_small.SkillID_G		= 1038
ai_bupingdaoren_small.SkillID_H		= 1037
ai_bupingdaoren_small.BuffID_H		= 19899	--回调简单版缥缈峰的脚本....
ai_bupingdaoren_small.SkillID_I		= 1036
ai_bupingdaoren_small.BuffID_I1		= 10253
ai_bupingdaoren_small.BuffID_I2		= 10254

ai_bupingdaoren_small.SkillCD_FH	=	30000
ai_bupingdaoren_small.SkillCD_G		=	45000


ai_bupingdaoren_small.MyName			= "不平道人"	--自己的名字....
ai_bupingdaoren_small.BrotherName = "卓不凡"		--兄弟的名字....


--AI Index....
ai_bupingdaoren_small.IDX_KuangBaoMode	= 1	--狂暴模式....0未狂暴 1需要进入狂暴 2已经进入狂暴
ai_bupingdaoren_small.IDX_CD_SkillFH		= 2	--FH技能的CD....
ai_bupingdaoren_small.IDX_CD_SkillG			= 3	--G技能的CD....
ai_bupingdaoren_small.IDX_CD_Talk				= 4	--FH技能喊话的CD....

ai_bupingdaoren_small.IDX_CombatFlag 		= 1	--是否处于战斗状态的标志....


--**********************************
--初始化....
--**********************************
function ai_bupingdaoren_small:OnInit(selfId)
	--重置AI....
	self:ResetMyAI(selfId )
end


--**********************************
--心跳....
--**********************************
function ai_bupingdaoren_small:OnHeartBeat(selfId, nTick)

	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end

	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, ai_bupingdaoren_small.IDX_CombatFlag ) then
		return
	end

	--FH技能心跳....
	if 1 == self:TickSkillFH(selfId, nTick ) then
		return
	end

	--G技能心跳....
	if 1 == self:TickSkillG(selfId, nTick ) then
		return
	end

	--I技能心跳....
	if 1 == self:TickSkillI(selfId, nTick ) then
		return
	end
end


--**********************************
--进入战斗....
--**********************************
function ai_bupingdaoren_small:OnEnterCombat(selfId)
	--加初始buff....
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_bupingdaoren_small.Buff_MianYi1, 0 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_bupingdaoren_small.Buff_MianYi2, 0 )

	--重置AI....
	self:ResetMyAI(selfId )

	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_bupingdaoren_small.IDX_CombatFlag, 1 )
end


--**********************************
--离开战斗....
--**********************************
function ai_bupingdaoren_small:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI(selfId )

	--遍历场景里所有的怪....寻找兄弟并将其删除....
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if ai_bupingdaoren_small.BrotherName == self:GetName(MonsterId ) then
			self:LuaFnDeleteMonster(MonsterId )
		end
	end
	--删除自己....
	self:LuaFnDeleteMonster(selfId )
	self:CallScriptFunction( self.g_FuBenScriptId, "SetBossLeaveCombat", "BuPingDaoRen_BOSS" )
end


--**********************************
--杀死敌人....
--**********************************
function ai_bupingdaoren_small:OnKillCharacter(selfId, targetId)

end


--**********************************
--死亡....
--**********************************
function ai_bupingdaoren_small:OnDie(selfId, killerId )
	--重置AI....
	self:ResetMyAI(selfId )
	local bFind = 0
	--遍历场景里所有的怪....寻找兄弟....给其设置需要使用狂暴技能....
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		local brother_name = ai_bupingdaoren_small.BrotherName
		local monster_name = self:GetName(MonsterId )
		local living = self:LuaFnIsCharacterLiving(MonsterId)
		print("MonsterId =", MonsterId, ";brother_name =", brother_name, ";monster_name =", monster_name, ";living =", living)
		if brother_name == monster_name and living then
			bFind = 1
			self:MonsterAI_SetIntParamByIndex(MonsterId, ai_bupingdaoren_small.IDX_KuangBaoMode, 1 )
		end
	end
	--如果没找到兄弟则说明就剩自己一个了....
	if 0 == bFind then
		--创建端木元....
		local MstId = self:CallScriptFunction( ai_bupingdaoren_small.g_FuBenScriptId, "CreateBOSS", "DuanMuYuan_BOSS", -1, -1 )
		self:LuaFnNpcChat(MstId, 0, "#{PMF_20080521_18}")
		--设置已经挑战过双子....
		self:CallScriptFunction( ai_bupingdaoren_small.g_FuBenScriptId, "SetBossBattleFlag", "ShuangZi", 2 )
	end
end


--**********************************
--重置AI....
--**********************************
function ai_bupingdaoren_small:ResetMyAI(selfId )

	--重置参数....
	self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_KuangBaoMode, 0 )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillFH, ai_bupingdaoren_small.SkillCD_FH )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillG, ai_bupingdaoren_small.SkillCD_G )
	self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_Talk, 0 )
	self:MonsterAI_SetBoolParamByIndex(selfId, ai_bupingdaoren_small.IDX_CombatFlag, 0 )

	--给所有玩家清除FH的buff....
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) then
			self:LuaFnCancelSpecificImpact(nHumanId, ai_bupingdaoren_small.BuffID_F1 )
			self:LuaFnCancelSpecificImpact(nHumanId, ai_bupingdaoren_small.BuffID_H )
		end
	end

end


--**********************************
--FH技能心跳....
--**********************************
function ai_bupingdaoren_small:TickSkillFH(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillFH )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillFH, cd-nTick )
		return 0

	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillFH, ai_bupingdaoren_small.SkillCD_FH-(nTick-cd) )
		--随机使用FH....
		if math.random(100) < 50 then
			return self:UseSkillF(selfId )
		else
			return self:UseSkillH(selfId )
		end
	end
end


--**********************************
--G技能心跳....
--**********************************
function ai_bupingdaoren_small:TickSkillG(selfId, nTick )
	--更新技能CD....
	local cd = self:MonsterAI_GetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillG )
	if cd > nTick then
		self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillG, cd-nTick )
		return 0
	else
		self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_CD_SkillG, ai_bupingdaoren_small.SkillCD_G-(nTick-cd) )
		return self:UseSkillG(selfId )
	end
end


--**********************************
--I技能心跳....
--**********************************
function ai_bupingdaoren_small:TickSkillI(selfId, nTick )
	--获得当前狂暴mode....
	local CurMode = self:MonsterAI_GetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_KuangBaoMode )
	if CurMode == 0 or CurMode == 2 then
		--如果不需要狂暴或者已经狂暴了则返回....
		return 0
	elseif CurMode == 1 then
		--如果需要狂暴则使用狂暴技能....
		local ret =  self:UseSkillI(selfId )
		if ret == 1 then
			self:MonsterAI_SetIntParamByIndex(selfId, ai_bupingdaoren_small.IDX_KuangBaoMode, 2 )
			return 1
		else
			return 0
		end
	end
end


--**********************************
--使用F技能....
--**********************************
function ai_bupingdaoren_small:UseSkillF(selfId )
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

	--对自己使用空技能....
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_bupingdaoren_small.SkillID_F, selfId, x, z, 0, 1 )
	--给玩家加结束后回调脚本的buff....
	self:LuaFnSendSpecificImpactToUnit(PlayerId, PlayerId, PlayerId, ai_bupingdaoren_small.BuffID_F1, 0 )
	return 1
end


--**********************************
--使用G技能....
--**********************************
function ai_bupingdaoren_small:UseSkillG(selfId )
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_bupingdaoren_small.SkillID_G, selfId, x, z, 0, 1 )
	self:MonsterTalk(-1, "", "#{PMF_20080530_01}" )
	return 1
end


--**********************************
--使用H技能....
--**********************************
function ai_bupingdaoren_small:UseSkillH(selfId )
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

	--对自己使用空技能....
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_bupingdaoren_small.SkillID_H, selfId, x, z, 0, 1 )

	--给玩家加结束后回调脚本的buff....
	self:LuaFnSendSpecificImpactToUnit(PlayerId, PlayerId, PlayerId, ai_bupingdaoren_small.BuffID_H, 0 )

	return 1

end


--**********************************
--使用I技能....
--**********************************
function ai_bupingdaoren_small:UseSkillI(selfId )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_bupingdaoren_small.BuffID_I1, 5000 )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, ai_bupingdaoren_small.BuffID_I2, 5000 )
	local x,z = self:GetWorldPos(selfId )
	self:LuaFnUnitUseSkill(selfId, ai_bupingdaoren_small.SkillID_I, selfId, x, z, 0, 1 )
	self:MonsterTalk(-1, "", "#{PMF_20080530_02}" )
	return 1
end


--**********************************
--暗雷和烟花的buff结束的时候回调本接口....
--**********************************
function ai_bupingdaoren_small:OnImpactFadeOut(selfId, impactId )
	--寻找BOSS....
	local bossId = -1
	local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		if ai_bupingdaoren_small.MyName == self:GetName(MonsterId ) then
			bossId = MonsterId
		end
	end

	--没找到则返回....
	if bossId == -1 then
		return
	end

	--如果是烟花的buff则让BOSS喊话....
	if impactId == ai_bupingdaoren_small.BuffID_H then
		self:MonsterTalk(-1, "", "#{PMF_20080530_03}"..self:GetName(selfId ).."#{PMF_20080530_04}" )
		return
	end

	--如果是暗雷的buff....则让BOSS给附近的玩家加一个伤害的buff并喊话....
	if impactId == ai_bupingdaoren_small.BuffID_F1 then
		self:MonsterTalk(-1, "", "#{PMF_20080530_03}"..self:GetName(selfId ).."#{PMF_20080530_05}" )
		local x = 0
		local z = 0
		local xx = 0
		local zz = 0
		x,z = self:GetWorldPos(selfId )
		local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
		for i=1, nHumanNum  do
			local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(PlayerId) == 1 and self:LuaFnIsCanDoScriptLogic(PlayerId) == 1 and self:LuaFnIsCharacterLiving(PlayerId) == 1 and PlayerId ~= selfId then
				xx,zz = self:GetWorldPos(PlayerId)
				if (x-xx)*(x-xx) + (z-zz)*(z-zz) < 8*8 then
					self:LuaFnSendSpecificImpactToUnit(bossId, bossId, PlayerId, ai_bupingdaoren_small.BuffID_F2, 0 )
				end
			end
		end
		return
	end
end

return ai_bupingdaoren_small