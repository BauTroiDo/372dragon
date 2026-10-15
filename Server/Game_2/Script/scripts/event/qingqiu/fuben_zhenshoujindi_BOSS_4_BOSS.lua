local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_4_BOSS = class("fuben_zhenshoujindi_BOSS_4_BOSS", script_base)
fuben_zhenshoujindi_BOSS_4_BOSS.script_id = 893038
fuben_zhenshoujindi_BOSS_4_BOSS.g_FuBenScriptId = 893020
fuben_zhenshoujindi_BOSS_4_BOSS.IDX_StopWatch = 1
fuben_zhenshoujindi_BOSS_4_BOSS.IDX_SkillA_CD = 2
fuben_zhenshoujindi_BOSS_4_BOSS.IDX_SkillB_CD = 3
fuben_zhenshoujindi_BOSS_4_BOSS.SkillA_CD = 5000
fuben_zhenshoujindi_BOSS_4_BOSS.SkillB_CD = 5000
fuben_zhenshoujindi_BOSS_4_BOSS.SkillA_SkillID = 3369
fuben_zhenshoujindi_BOSS_4_BOSS.SkillB_SkillID = 3369
function fuben_zhenshoujindi_BOSS_4_BOSS:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch,0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD,0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD,0)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    self:TickStopWatch(selfId, nTick)
	--技能A心跳
	if 1 == self:TickSkillA( selfId, nTick ) then
		return
	end
end
function fuben_zhenshoujindi_BOSS_4_BOSS:TickSkillA(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillA_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, self.SkillA_CD - (nTick - cd))
        self:UseSkillA(selfId)
        return 1
    end
end

function fuben_zhenshoujindi_BOSS_4_BOSS:UseSkillA(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillA_SkillID, selfId, x, z, 0, 1)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:EnumAllPlayerDistance(selfId, enmeyId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:OnEnterCombat(selfId, enmeyId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    --self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_BOSS_4_BOSS:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_4_BOSS:OnDie(selfId, killerId)
    self:CallScriptFunction(self.g_FuBenScriptId, "OnFinalBossDie")
end
function fuben_zhenshoujindi_BOSS_4_BOSS:TickStopWatch(selfId, nTick)
    local time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_StopWatch)
    if (time + nTick) > 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick - 1000)
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick)
        return
    end
end
function fuben_zhenshoujindi_BOSS_4_BOSS:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_BOSS_4_BOSS
