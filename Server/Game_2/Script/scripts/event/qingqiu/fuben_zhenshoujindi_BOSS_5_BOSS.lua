local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_5_BOSS = class("fuben_zhenshoujindi_BOSS_5_BOSS", script_base)
fuben_zhenshoujindi_BOSS_5_BOSS.script_id = 893032
fuben_zhenshoujindi_BOSS_5_BOSS.g_FuBenScriptId = 893020
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_StopWatch = 1
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillA_CD = 2
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillB_CD = 3
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillC_CD = 4
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillD_CD = 5
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillA_Monster1 = 6
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillA_Monster2 = 7
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_SkillB_Time = 8
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_CombatFlag = 1
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_IsKuangBaoMode = 2
fuben_zhenshoujindi_BOSS_5_BOSS.IDX_IsSkillBActive = 3
fuben_zhenshoujindi_BOSS_5_BOSS.SkillA_CD = 15000
fuben_zhenshoujindi_BOSS_5_BOSS.SkillA_SkillID = 3365
fuben_zhenshoujindi_BOSS_5_BOSS.Buff_WuDi1 = 31816
fuben_zhenshoujindi_BOSS_5_BOSS.SkillB_CD = 20000
fuben_zhenshoujindi_BOSS_5_BOSS.SkillB_SkillID = 3364
fuben_zhenshoujindi_BOSS_5_BOSS.SkillB_ImpactID = 31840
fuben_zhenshoujindi_BOSS_5_BOSS.SkillB_DamageID = 31840
fuben_zhenshoujindi_BOSS_5_BOSS.SkillC_CD = 12000
fuben_zhenshoujindi_BOSS_5_BOSS.SkillC_SkillID = 3363
fuben_zhenshoujindi_BOSS_5_BOSS.SkillD_CD = 15000
fuben_zhenshoujindi_BOSS_5_BOSS.SkillD_SkillID = 3366
function fuben_zhenshoujindi_BOSS_5_BOSS:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_Monster1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_Monster2, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_Time, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsSkillBActive, 0)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    self:TickStopWatch(selfId, nTick)
	--技能A心跳
	if 1 == self:TickSkillA( selfId, nTick ) then
		return
	end
	
	--技能B心跳
	if 1 == self:TickSkillB( selfId, nTick ) then
		return
	end
	
	--技能B心跳
	if 1 == self:TickSkillC( selfId, nTick ) then
		return
	end
	
	--技能D心跳
	if 1 == self:TickSkillD( selfId, nTick ) then
		return
	end
end

function fuben_zhenshoujindi_BOSS_5_BOSS:TickSkillD(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillD_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, self.SkillD_CD - (nTick - cd))
        self:UseSkillD(selfId)
        return 1
    end
end

function fuben_zhenshoujindi_BOSS_5_BOSS:UseSkillD(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillD_SkillID, selfId, x, z, 0, 1)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillC_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, self.SkillC_CD - (nTick - cd))
        self:UseSkillC(selfId)
        return 1
    end
end

function fuben_zhenshoujindi_BOSS_5_BOSS:UseSkillC(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillC_SkillID, selfId, x, z, 0, 1)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:TickSkillB(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillB_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, self.SkillB_CD - (nTick - cd))
        self:UseSkillB(selfId)
        return 1
    end
end

function fuben_zhenshoujindi_BOSS_5_BOSS:UseSkillB(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillB_SkillID, selfId, x, z, 0, 1)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if
            self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                self:LuaFnIsCharacterLiving(nHumanId)
         then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillB_ImpactID, 0)
        end
    end
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsSkillBActive, 1)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:TickSkillA(selfId, nTick)
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

function fuben_zhenshoujindi_BOSS_5_BOSS:UseSkillA(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 513)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillA_SkillID, selfId, x, z, 0, 1)
    local nTuMiHuaObjNum = 0
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetMonsterDataID(nMonsterId) == 49604 then
            nTuMiHuaObjNum = nTuMiHuaObjNum + 1
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
    local nDataIdx = {self.IDX_SkillA_Monster1, self.IDX_SkillA_Monster2}
    for i = 1, 2 do
        local nYunYanDuan = self:LuaFnCreateMonster(49604, math.random(47, 73), math.random(61, 65), 3, -1, -1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nYunYanDuan, self.Buff_WuDi1, 0)
        self:SetUnitCampID(nYunYanDuan, 110)
        self:MonsterAI_SetIntParamByIndex(selfId, nDataIdx[i], nYunYanDuan)
    end
end

function fuben_zhenshoujindi_BOSS_5_BOSS:TickStopWatch(selfId, nTick)
    local time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_StopWatch)
    if (time + nTick) > 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick - 1000)
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick)
        return
    end
    for i = 1, 2 do
        local nDataIdx = {self.IDX_SkillA_Monster1, self.IDX_SkillA_Monster2}
        local nMonsterId = self:MonsterAI_GetIntParamByIndex(selfId, nDataIdx[i])
        if nMonsterId > 0 then
            local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
            for j = 1, nHumanCount do
                local nHumanId = self:LuaFnGetCopyScene_HumanObjId(j)
                if
                    self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                        self:LuaFnIsCharacterLiving(nHumanId)
                 then
                    if self:IsInDist(nMonsterId, nHumanId, 2) then
                        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, 31839, 0)
                    end
                end
            end
        end
    end
    local bSkillBOpen = self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_IsSkillBActive)
    if bSkillBOpen > 0 then
        local nSkillBTime = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillB_Time)
        if nSkillBTime >= 6 then
            self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsSkillBActive, 0)
            self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_Time, 0)
            local nNotIn3MDisitNum = 1
            local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, nHumanCount do
                local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
                if
                    self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                        self:LuaFnIsCharacterLiving(nHumanId)
                 then
                    nHumanCount = self:LuaFnGetCopyScene_HumanCount()
                    for j = 1, nHumanCount do
                        local nHumanId2 = self:LuaFnGetCopyScene_HumanObjId(j)
                        if nHumanId2 ~= nHumanId then
                            --///在范围内人数+1。
                            if self:IsInDist(nHumanId2, nHumanId,3) then
                                nNotIn3MDisitNum = nNotIn3MDisitNum + 1
                            end
                        end
                    end
                end
            end
            nHumanCount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, nHumanCount do
                local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
                if
                    self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                        self:LuaFnIsCharacterLiving(nHumanId)
                 then
                    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillB_DamageID + nNotIn3MDisitNum, 0)
                end
            end
        else
            self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_Time, nSkillBTime + 1)
        end
    end
end

function fuben_zhenshoujindi_BOSS_5_BOSS:EnumAllPlayerDistance(selfId, enmeyId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "BroadCastNpcTalkAllHuman", 132)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:OnEnterCombat(selfId, enmeyId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "BroadCastNpcTalkAllHuman", 132)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    --self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_BOSS_5_BOSS:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_5_BOSS:OnDie(selfId, killerId)
    self:CallScriptFunction(self.g_FuBenScriptId, "OnFinalBossDie")
end

function fuben_zhenshoujindi_BOSS_5_BOSS:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_BOSS_5_BOSS
