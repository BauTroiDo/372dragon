local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yunzhonghe = class("yunzhonghe", script_base)
yunzhonghe.TBL =
{
IDX_TimerPrepare = 1,
IDX_TimerInterval = 2,
IDX_FlagCombat = 1,
BossSkill = 1002,
PrepareTime = 60000,
SkillInterval = 60000,
BossBuff = 9999
}

function yunzhonghe:OnDie(selfId, killerId )
	self:LuaFnNpcChat(selfId, 0, "Lão đại! Hộ vệ của tên cẩu quan này lợi hại, ta cũng lui đây.")
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerPrepare, 0)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerInterval, 0)
	self:MonsterAI_SetBoolParamByIndex(selfId, yunzhonghe.TBL.IDX_FlagCombat, 0)
	-- 检测目前的副本进度
	if self:LuaFnGetCopySceneData_Param(8) == 5  then
		self:LuaFnSetCopySceneData_Param(8, 6)
	end
end

function yunzhonghe:OnHeartBeat(selfId, nTick)
end

function yunzhonghe:OnInit(selfId)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerPrepare, 0)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerInterval, 0)
	self:MonsterAI_SetBoolParamByIndex(selfId, yunzhonghe.TBL.IDX_FlagCombat, 0)
end

function yunzhonghe:OnKillCharacter(selfId, targetId)
end

function yunzhonghe:OnEnterCombat(selfId, enmeyId)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerPrepare, yunzhonghe.TBL.PrepareTime)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerInterval, 0)
	self:MonsterAI_SetBoolParamByIndex(selfId, yunzhonghe.TBL.IDX_FlagCombat, 1)
end

function yunzhonghe:OnLeaveCombat(selfId)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerPrepare, 0)
	self:MonsterAI_SetIntParamByIndex(selfId, yunzhonghe.TBL.IDX_TimerInterval, 0)
	self:MonsterAI_SetBoolParamByIndex(selfId, yunzhonghe.TBL.IDX_FlagCombat, 0)
end

return yunzhonghe
