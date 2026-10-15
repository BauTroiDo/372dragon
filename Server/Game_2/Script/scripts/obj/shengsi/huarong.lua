local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huarong = class("huarong", script_base)
huarong.script_id = 892013
huarong.g_FuBenScriptId = 892009
huarong.Buff_MianYi1 = 10472
huarong.Buff_MianYi2 = 10471
huarong.Skill_A = 763
huarong.SkillA_SpecObj = 128
huarong.Skill_B = 764
huarong.SkillB_SpecObj = 129
huarong.Skill_C = 765
huarong.SkillC_SpecObj = 130
huarong.Skill_D = 766
huarong.SkillD_SpecObj = 131
huarong.Buff_E1 = 10234
huarong.Buff_E2 = 10235
huarong.UseSkillList = {
    {10, "A"},
    {15, "B"},
    {30, "A"},
    {35, "C"},
    {50, "A"},
    {55, "D"},
    {51, "D1"},
    {70, "A"},
    {85, "B"},
    {90, "A"},
    {100, "C"},
    {110, "A"},
    {125, "D"},
    {126, "D1"},
    {130, "A"},
    {150, "A"},
    {155, "B"},
    {170, "A"},
    {175, "C"},
    {190, "A"},
    {195, "D"},
    {196, "D1"},
    {210, "A"},
    {225, "B"},
    {230, "A"},
    {245, "C"},
    {250, "A"},
    {265, "D"},
    {266, "D1"},
    {270, "A"},
    {300, "E"}
}

huarong.IDX_CombatTime = 1
huarong.IDX_UseSkillIndex = 2
huarong.IDX_CombatFlag = 1
huarong.IDX_IsKuangBaoMode = 2
function huarong:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function huarong:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
    if 1 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode) then
        return
    end
    local CombatTime = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_CombatTime)
    local NextSkillIndex = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_UseSkillIndex)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, CombatTime + nTick)
    if NextSkillIndex < 1 or NextSkillIndex > #(self.UseSkillList) then
        return
    end
    local SkillData = self.UseSkillList[NextSkillIndex]
    if (CombatTime + nTick) >= SkillData[1] * 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, NextSkillIndex + 1)
        self:UseMySkill(selfId, SkillData[2])
    end
end

function huarong:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function huarong:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
    local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "huarong_NPC", -1, -1)
    self:SetUnitReputationID(MstId, MstId, 0)
end

function huarong:OnKillCharacter(selfId, targetId)
end

function huarong:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "huarong", 2)
    if 2 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "songjiang") then
        self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "songjiang", 1)
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đã đánh bại Hoa Vinh")
end

function huarong:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, 1)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E1)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E2)
end

function huarong:UseMySkill(selfId, skill)
    if skill == "A" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090630_123}")
        local x, z = self:GetWorldPos(selfId)
        local a, b = math.random(3) - math.random(3), math.random(3) - math.random(3)
        self:LuaFnUnitUseSkill(selfId, self.Skill_A, selfId, x, z, 0, 1)
        self:CreateSpecialObjByDataIndex(selfId, self.SkillA_SpecObj, x + a, z + b, 0)
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "#{SXRW_090119_164}")
    elseif skill == "B" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090630_124}")
        local x, z = self:GetWorldPos(selfId)
        local a, b = math.random(3) - math.random(3), math.random(3) - math.random(3)
        self:LuaFnUnitUseSkill(selfId, self.Skill_B, selfId, x, z, 0, 1)
        self:CreateSpecialObjByDataIndex(selfId, self.SkillB_SpecObj, x + a, z + b, 0)
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "#{SXRW_090119_164}")
    elseif skill == "C" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090630_125}")
        local x, z = self:GetWorldPos(selfId)
        local a, b = math.random(3) - math.random(3), math.random(3) - math.random(3)
        self:LuaFnUnitUseSkill(selfId, self.Skill_C, selfId, x, z, 0, 1)
        self:CreateSpecialObjByDataIndex(selfId, self.SkillC_SpecObj, x + a, z + b, 0)
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "#{SXRW_090119_164}")
    elseif skill == "D" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090630_126}")
        local x, z = self:GetWorldPos(selfId)
        local a, b = math.random(3) - math.random(3), math.random(3) - math.random(3)
        self:LuaFnUnitUseSkill(selfId, self.Skill_D, selfId, x, z, 0, 1)
        self:CreateSpecialObjByDataIndex(selfId, self.SkillD_SpecObj, x + a, z + b, 0)
    elseif skill == "D1" then
    elseif skill == "E" then
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1)
        self:SkillE_KuangBao(selfId)
    end
end

function huarong:SkillE_KuangBao(selfId)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_B)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_C)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_D)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E2, 0)
end

function huarong:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return huarong
