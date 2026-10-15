local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_1_BOSS = class("fuben_zhenshoujindi_BOSS_1_BOSS", script_base)
fuben_zhenshoujindi_BOSS_1_BOSS.script_id = 893023
fuben_zhenshoujindi_BOSS_1_BOSS.g_FuBenScriptId = 893020
fuben_zhenshoujindi_BOSS_1_BOSS.Buff_MianYi1 = 31811
fuben_zhenshoujindi_BOSS_1_BOSS.Buff_MianYi2 = 31810
fuben_zhenshoujindi_BOSS_1_BOSS.Buff_WuDi1 = 31816
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_StopWatch = 1
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_SkillA_CD = 2
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_SkillB_CD = 3
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_SkillC_CD = 6
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_SkillD_CD = 7
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_KuangBaoTimer = 8
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_CombatFlag = 1
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_IsKuangBaoMode = 2
fuben_zhenshoujindi_BOSS_1_BOSS.IDX_CombatFlag = 1
fuben_zhenshoujindi_BOSS_1_BOSS.SkillA_CD = 16000
fuben_zhenshoujindi_BOSS_1_BOSS.SkillA_SpecObj = 1338
fuben_zhenshoujindi_BOSS_1_BOSS.SkillB_ID = 3354
fuben_zhenshoujindi_BOSS_1_BOSS.SkillB_CD = 48000
fuben_zhenshoujindi_BOSS_1_BOSS.SkillB_ImpactIDA = 31824
fuben_zhenshoujindi_BOSS_1_BOSS.SkillB_ImpactIDB = 31825
fuben_zhenshoujindi_BOSS_1_BOSS.SkillB_ImpactIDB_DI = 31827
fuben_zhenshoujindi_BOSS_1_BOSS.SkillC_ID = 3353
fuben_zhenshoujindi_BOSS_1_BOSS.SkillC_CD = 16000
fuben_zhenshoujindi_BOSS_1_BOSS.SkillD_ID = 3355
fuben_zhenshoujindi_BOSS_1_BOSS.SkillD_CD = 40000
fuben_zhenshoujindi_BOSS_1_BOSS.PosYunJuanShu = {180, 123}

fuben_zhenshoujindi_BOSS_1_BOSS.g_DamageImpact = {31818, 31819, 31820, 31821, 31822}

function fuben_zhenshoujindi_BOSS_1_BOSS:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_1_BOSS:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillA_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, self.SkillC_CD)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, self.SkillD_CD)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_KuangBaoTimer, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
end

function fuben_zhenshoujindi_BOSS_1_BOSS:OnInit(selfId)
    self:ResetMyAI(selfId)
    local nFubenType = self:LuaFnGetCopySceneData_Param(7)
    if nFubenType == 1 then
        self.SkillA_CD = 8000
        self.SkillB_CD = 24000
        self.SkillC_CD = 8000
        self.SkillD_CD = 30000
    end
end

function fuben_zhenshoujindi_BOSS_1_BOSS:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
    if 1 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode) then
        return
    end
    --荼蘼花事了
    if 1 == self:TickSkillC(selfId, nTick) then
        return
    end
    --一叶摄心
    if 1 == self:TickSkillB(selfId, nTick) then
        return
    end
    --流芳谢春风
    if 1 == self:TickSkillD(selfId, nTick) then
        return
    end
    self:TickStopWatch(selfId, nTick)
end

function fuben_zhenshoujindi_BOSS_1_BOSS:TickSkillB(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillB_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillB_CD, self.SkillB_CD - (nTick - cd))
        return self:UseSkillB(selfId)
    end
end

function fuben_zhenshoujindi_BOSS_1_BOSS:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillC_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillC_CD, self.SkillC_CD - (nTick - cd))
        return self:UseSkillC(selfId)
    end
end

function fuben_zhenshoujindi_BOSS_1_BOSS:TickSkillD(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SkillD_CD)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SkillD_CD, self.SkillD_CD - (nTick - cd))
        return self:UseSkillD(selfId)
    end
end

function fuben_zhenshoujindi_BOSS_1_BOSS:TickStopWatch(selfId, nTick)
    local time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_StopWatch)
    if (time + nTick) > 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick - 1000)
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick)
        return
    end
end

function fuben_zhenshoujindi_BOSS_1_BOSS:UseSkillB(selfId)
    local tPlayerID = {}
    local nCount = 1
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            self:NotifyTip(nHumanId,"#{ZSFB_20220105_59}")
            table.insert(tPlayerID, nHumanId)
        end
    end
    local x,z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillB_ID, selfId, x, z, 0, 1)
    if #tPlayerID then
        if #tPlayerID >= 2 then
            nCount = 2
        end
        for i = 1,nCount do
            local nRandom = math.random(1, #(tPlayerID))
            local nRandomPlayerID = tPlayerID[nRandom]
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nRandomPlayerID, self.SkillB_ImpactIDA, 0)
            local nFubenType = self:LuaFnGetCopySceneData_Param(7)
            if nFubenType == 1 then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nRandomPlayerID, self.SkillB_ImpactIDB_DI, 0)
            else
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nRandomPlayerID, self.SkillB_ImpactIDB, 0)
            end
        end
    end
    return 1
end

function fuben_zhenshoujindi_BOSS_1_BOSS:UseSkillC(selfId)
    local x, z = self:GetWorldPos(selfId)
    local tPlayerID = {}
    local nCount = 1
    self:LuaFnUnitUseSkill(selfId, self.SkillC_ID, selfId, x, z, 0, 1)
    --荼蘼花事了
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            self:NotifyTip(nHumanId,"#{ZSFB_20220105_58}")
            self:NotifyTip(nHumanId,"#{ZSFB_20220105_154}")
            table.insert(tPlayerID, nHumanId)
        end
    end
    if #tPlayerID then
        if #tPlayerID > 2 then
            nCount = 2
        end
        for i = 1,nCount do
            local RanDomID = tPlayerID[math.random(1,#tPlayerID)]
            local PlayerX,PlayerZ = self:GetWorldPos(RanDomID)
            self:CreateSpecialObjByDataIndex(selfId, self.SkillA_SpecObj,PlayerX,PlayerZ,4000)
            self:LuaFnCreateMonster(49576, PlayerX,PlayerZ,33,-1,893114)
            --self:DelayCallFunction(3000,"DelayCreateTuMiHua",PlayerX,PlayerZ)
        end
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHumanPaoPao", selfId, 527)
    return 1
end

--//无法实现连续释放三次以及AOE技能伤害
function fuben_zhenshoujindi_BOSS_1_BOSS:UseSkillD(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHumanPaoPao", selfId, 504)
    self:CallScriptFunction(self.g_FuBenScriptId, "BroadCastNpcTalkAllHuman", 119)
    self:PutTuMiFlower(selfId, 172, 128)
    self:PutTuMiFlower(selfId, 174, 113)
    self:PutTuMiFlower(selfId, 192, 122)
    self:PutTuMiFlower(selfId, 183, 136)
    self:SetPos(selfId, self.PosYunJuanShu[1], self.PosYunJuanShu[2])
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, self.SkillD_ID, selfId, x, z, 0, 1)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetMonsterDataID(nMonsterId) == 49576 then
            self:DelaySkillDImpact(nMonsterId)
            --荼蘼花爆炸
            --self:DelayCallFunction(5000,"DelaySkillDImpact",nMonsterId)
        end
    end
    return 1
end
function fuben_zhenshoujindi_BOSS_1_BOSS:DelaySkillDImpact(selfId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            if self:IsInDist(nHumanId,selfId,3) then
                for j = 1,#self.g_DamageImpact do
                    self:LuaFnSendSpecificImpactToUnit(selfId,selfId,nHumanId,self.g_DamageImpact[j],0)
                end
            end
        end
    end
    self:LuaFnDeleteMonster(selfId)
end
function fuben_zhenshoujindi_BOSS_1_BOSS:PutTuMiFlower(selfId, posX, posZ)
    self:CreateSpecialObjByDataIndex(selfId, self.SkillA_SpecObj, posX, posZ, 4000)
    local nTuMiHuaObjID = self:LuaFnCreateMonster(49576, posX, posZ, 33, -1, 893114)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nTuMiHuaObjID, self.Buff_WuDi1, 0)
    self:SetUnitCampID(nTuMiHuaObjID, 110)
end

function fuben_zhenshoujindi_BOSS_1_BOSS:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHumanPaoPao", selfId, 527)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function fuben_zhenshoujindi_BOSS_1_BOSS:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    --self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_BOSS_1_BOSS:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_1_BOSS:OnDie(selfId, killerId)
    self:CallScriptFunction(self.g_FuBenScriptId, "OnYunJuanShuDie")
end

function fuben_zhenshoujindi_BOSS_1_BOSS:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_BOSS_1_BOSS
