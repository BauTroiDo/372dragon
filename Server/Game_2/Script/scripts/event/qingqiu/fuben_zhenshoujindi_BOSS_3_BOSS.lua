local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_3_BOSS = class("fuben_zhenshoujindi_BOSS_3_BOSS", script_base)
fuben_zhenshoujindi_BOSS_3_BOSS.script_id = 893028
fuben_zhenshoujindi_BOSS_3_BOSS.g_FuBenScriptId = 893020
fuben_zhenshoujindi_BOSS_3_BOSS.IDX_StopWatch = 1
fuben_zhenshoujindi_BOSS_3_BOSS.IDX_SkillA_CD = 2
fuben_zhenshoujindi_BOSS_3_BOSS.IDX_SkillB_CD = 3
fuben_zhenshoujindi_BOSS_3_BOSS.IDX_SkillC_CD = 4
fuben_zhenshoujindi_BOSS_3_BOSS.IDX_CombatFlag = 1
fuben_zhenshoujindi_BOSS_3_BOSS.IDX_IsKuangBaoMode = 2
fuben_zhenshoujindi_BOSS_3_BOSS.SkillA_CD = 15000
fuben_zhenshoujindi_BOSS_3_BOSS.SkillA_SkillID = 3360
fuben_zhenshoujindi_BOSS_3_BOSS.SkillA_DecHP = 31839
fuben_zhenshoujindi_BOSS_3_BOSS.SkillB_CD = 10000
fuben_zhenshoujindi_BOSS_3_BOSS.SkillB_SkillID = 3359
fuben_zhenshoujindi_BOSS_3_BOSS.SkillC_CD = 12000
fuben_zhenshoujindi_BOSS_3_BOSS.SkillC_SkillID = 3361
function fuben_zhenshoujindi_BOSS_3_BOSS:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:OnHeartBeat(selfId, nTick)
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
end

function fuben_zhenshoujindi_BOSS_3_BOSS:TickSkillC(selfId, nTick)
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

function fuben_zhenshoujindi_BOSS_3_BOSS:UseSkillC(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 510)
    self:CallScriptFunction((893020), "TipAllHuman", "#{ZSFB_20220105_81}")
    self:CallScriptFunction(self.g_FuBenScriptId, "BroadCastNpcTalkAllHuman", 121)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillC_SkillID, selfId, x, z, 0, 1)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:TickSkillB(selfId, nTick)
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

function fuben_zhenshoujindi_BOSS_3_BOSS:UseSkillB(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 508)
    self:CallScriptFunction((893020), "TipAllHuman", "#{ZSFB_20220105_79}")
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillB_SkillID, selfId, x, z, 0, 1)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:TickSkillA(selfId, nTick)
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

function fuben_zhenshoujindi_BOSS_3_BOSS:UseSkillA(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 509)
    self:CallScriptFunction((893020), "TipAllHuman", "#{ZSFB_20220105_80}")
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillA_SkillID, selfId, x, z, 0, 1)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if
            self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                self:LuaFnIsCharacterLiving(nHumanId)
         then
            if self:IsInDist(selfId, nHumanId, 6) then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillA_DecHP, 0)
            end
        end
    end
end

function fuben_zhenshoujindi_BOSS_3_BOSS:TickStopWatch(selfId, nTick)
    local time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_StopWatch)
    if (time + nTick) > 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick - 1000)
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick)
        return
    end
end

function fuben_zhenshoujindi_BOSS_3_BOSS:OnEnterCombat(selfId, enmeyId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 530)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    --self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_BOSS_3_BOSS:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_3_BOSS:OnDie(selfId, killerId)
    self:CallScriptFunction(self.g_FuBenScriptId, "OnBOSS_3Die")
end

function fuben_zhenshoujindi_BOSS_3_BOSS:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_BOSS_3_BOSS
