local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_2_BOSS = class("fuben_zhenshoujindi_BOSS_2_BOSS", script_base)
fuben_zhenshoujindi_BOSS_2_BOSS.script_id = 893026
fuben_zhenshoujindi_BOSS_2_BOSS.g_FuBenScriptId = 893020
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_StopWatch = 1
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_SkillA_CD = 2
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_SkillA_Step = 3
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_SkillC_CD = 4
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_SkillD_CD = 5
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_Skill_Line_CD = 6
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_CombatFlag = 1
fuben_zhenshoujindi_BOSS_2_BOSS.IDX_IsKuangBaoMode = 2
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_SkillID = 3352
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_CD = 30000
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_PlayerIMPACT_A = 31829
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_PlayerIMPACT_B = 31830
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_PlayerIMPACT_Line = 31831
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_PlayerIMPACT_LineSame = 31838
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_PlayerIMPACT_BOSS_A = 31832
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_PlayerIMPACT_BOSS_B = 31833
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_DecHP = 31834
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_LineCD = 500
fuben_zhenshoujindi_BOSS_2_BOSS.SkillA_SkillID_YYYS = 3357
fuben_zhenshoujindi_BOSS_2_BOSS.SkillC_CD = 30000
fuben_zhenshoujindi_BOSS_2_BOSS.SkillD_CD = 40000
function fuben_zhenshoujindi_BOSS_2_BOSS:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_2_BOSS:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_Step, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, self.SkillC_CD)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, self.SkillD_CD)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_Skill_Line_CD, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnInit(selfId)
    self:ResetMyAI(selfId)
    local nFubenType = self:LuaFnGetCopySceneData_Param(7)
    if nFubenType == 1 then
        self.SkillC_CD = 20000
        self.SkillD_CD = 30000
    end
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
	--A技能心跳....
    --local nStep = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillA_Step)
    --if nStep > 0 then
        --self:TickSkillA_Impact(selfId, 110)
    --end
	--if 1 == self:TickSkillA( selfId, nTick ) then
		--return
	--end

	--B技能心跳....
	--if 1 == self:TickSkillB( selfId, nTick ) then
		--return
	--end

	--C技能心跳....
	--if 1 == self:TickSkillC(selfId, nTick ) then
		--return
	--end
	
	--D技能心跳....
	--if 1 == self:TickSkillD( selfId, nTick ) then
		--return
	--end
    self:TickStopWatch(selfId, nTick)
end

function fuben_zhenshoujindi_BOSS_2_BOSS:TickSkillA(selfId, nTick)
    local nStep = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillA_Step)
    if nStep > 0 then
        return 0
    end
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

function fuben_zhenshoujindi_BOSS_2_BOSS:TickSkillA_Impact(selfId, nTick)
    local nStep = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillA_Step)
    if nStep ~= 1 then
        return
    end
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillA_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, cd - nTick)
        local cdLine = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_Skill_Line_CD)
        if cdLine > nTick then
            self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_Skill_Line_CD, cdLine - nTick)
        else
            self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_Skill_Line_CD, self.SkillA_LineCD - (nTick - cdLine))
            local tPlayerID_D = {}

            local tPlayerID_S = {}

            local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, nHumanCount do
                local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
                if
                    self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                        self:LuaFnIsCharacterLiving(nHumanId)
                 then
                    if self:LuaFnHaveImpactOfSpecificDataIndex(nHumanId, self.SkillA_PlayerIMPACT_Line) then
                        table.insert(tPlayerID_D, nHumanId)
                    end
                    if self:LuaFnHaveImpactOfSpecificDataIndex(nHumanId, self.SkillA_PlayerIMPACT_LineSame) then
                        table.insert(tPlayerID_S, nHumanId)
                    end
                end
            end
            if #(tPlayerID_D) >= 2 then
                for i = 1, #(tPlayerID_D) do
                    for j = 1, #(tPlayerID_D) do
                        if tPlayerID_D[i] ~= tPlayerID_D[j] then
                            if self:IsInDist(tPlayerID_D[i], tPlayerID_D[j], 6) then
                                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, tPlayerID_D[i], self.SkillA_DecHP, 0)
                                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, tPlayerID_D[j], self.SkillA_DecHP, 0)
                            end
                        end
                    end
                end
            end
            if #(tPlayerID_S) >= 2 then
                for i = 1, #(tPlayerID_S) do
                    for j = 1, #(tPlayerID_S) do
                        if tPlayerID_S[i] ~= tPlayerID_S[j] then
                            if not self:IsInDist(tPlayerID_S[i], tPlayerID_S[j], 6) then
                                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, tPlayerID_S[i], self.SkillA_DecHP, 0)
                                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, tPlayerID_S[j], self.SkillA_DecHP, 0)
                            end
                        end
                    end
                end
            end
        end
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, self.SkillA_CD - (nTick - cd))
        local tPlayerImpactA = {}
        local tPlayerImpactB = {}
        local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanCount do
            local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
                self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_Line)
                self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_LineSame)
                self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_A)
                self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_B)
                if math.random(1, 2) == 1 then
                    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillA_PlayerIMPACT_A, 0)
                    table.insert(tPlayerImpactA, nHumanId)
                else
                    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillA_PlayerIMPACT_B, 0)
                    table.insert(tPlayerImpactB, nHumanId)
                end
            end
        end
        if #(tPlayerImpactA) >= 2 then
            self:LuaFnSendSpecificImpactToUnit(
                selfId,
                tPlayerImpactA[1],
                tPlayerImpactA[1],
                self.SkillA_PlayerIMPACT_Line,
                0
            )
            for i = 2, #(tPlayerImpactA) do
                self:LuaFnSendSpecificImpactToUnit(
                    selfId,
                    tPlayerImpactA[1],
                    tPlayerImpactA[i],
                    self.SkillA_PlayerIMPACT_Line,
                    0
                )
            end
        end
        if #(tPlayerImpactB) >= 2 then
            self:LuaFnSendSpecificImpactToUnit(
                selfId,
                tPlayerImpactA[1],
                tPlayerImpactA[1],
                self.SkillA_PlayerIMPACT_Line,
                0
            )
            for i = 2, #(tPlayerImpactB) do
                self:LuaFnSendSpecificImpactToUnit(
                    selfId,
                    tPlayerImpactB[1],
                    tPlayerImpactB[i],
                    self.SkillA_PlayerIMPACT_Line,
                    0
                )
            end
        end
        if #(tPlayerImpactA) >= 2 and #(tPlayerImpactB) >= 2 then
            self:LuaFnSendSpecificImpactToUnit(
                selfId,
                tPlayerImpactA[1],
                tPlayerImpactB[1],
                self.SkillA_PlayerIMPACT_LineSame,
                0
            )
            self:LuaFnSendSpecificImpactToUnit(
                selfId,
                tPlayerImpactB[1],
                tPlayerImpactA[1],
                self.SkillA_PlayerIMPACT_LineSame,
                0
            )
        end
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, self.SkillA_SkillID_YYYS, selfId, x, z, 0, 1)
        self:CallScriptFunction((893020), "TipAllHuman", "#{ZSFB_20220105_70}")
        self:LuaFnCancelSpecificImpact(selfId, self.SkillA_PlayerIMPACT_BOSS_A)
        self:LuaFnCancelSpecificImpact(selfId, self.SkillA_PlayerIMPACT_BOSS_B)
        if math.random(1, 2) == 1 then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillA_PlayerIMPACT_BOSS_A, 0)
        else
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillA_PlayerIMPACT_BOSS_B, 0)
        end
    end
end

function fuben_zhenshoujindi_BOSS_2_BOSS:UseSkillA(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 505)
    self:CallScriptFunction((893020), "TipAllHuman", "#{ZSFB_20220105_69}")
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillA_SkillID, selfId, x, z, 0, 1)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if
            self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and
                self:LuaFnIsCharacterLiving(nHumanId)
         then
            self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_A)
            self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_B)
            if math.random(1, 2) == 1 then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillA_PlayerIMPACT_A, 0)
            else
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, self.SkillA_PlayerIMPACT_B, 0)
            end
        end
    end
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_Step, 1)
end

function fuben_zhenshoujindi_BOSS_2_BOSS:TickSkillB(selfId, nTick)
    return 1
end

function fuben_zhenshoujindi_BOSS_2_BOSS:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillC_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, self.SkillC_CD - (nTick - cd))
    end
end

function fuben_zhenshoujindi_BOSS_2_BOSS:TickSkillD(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillD_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, self.SkillD_CD - (nTick - cd))
    end
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnEnterCombat(selfId, enmeyId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 528)
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    --self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_BOSS_2_BOSS:TickStopWatch(selfId, nTick)
    local time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_StopWatch)
    if (time + nTick) > 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick - 1000)
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick)
        return
    end
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnDie(selfId, killerId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_Line)
            self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_LineSame)
            self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_A)
            self:LuaFnCancelSpecificImpact(nHumanId, self.SkillA_PlayerIMPACT_B)
        end
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "OnBOSS_2Die")
end

function fuben_zhenshoujindi_BOSS_2_BOSS:OnImpactFadeOut(selfId, impactId)
    if impactId == 31835 then
        if not self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.SkillA_PlayerIMPACT_A) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillA_DecHP, 0)
        end
    end
    if impactId == 31836 then
        if not self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.SkillA_PlayerIMPACT_B) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.SkillA_DecHP, 0)
        end
    end
end

function fuben_zhenshoujindi_BOSS_2_BOSS:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_BOSS_2_BOSS
