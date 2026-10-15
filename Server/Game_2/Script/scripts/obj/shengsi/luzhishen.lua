local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luzhishen = class("luzhishen", script_base)
luzhishen.script_id = 892017
luzhishen.g_FuBenScriptId = 892009
luzhishen.Buff_MianYi1 = 10472
luzhishen.Buff_MianYi2 = 10471
luzhishen.Buff_E1 = 10234
luzhishen.Buff_E2 = 10235
luzhishen.UseSkillList = {
    {4, "A"},
    {4, "B"},
    {28, "A"},
    {28, "B"},
    {52, "A"},
    {52, "B"},
    {76, "A"},
    {76, "B"},
    {100, "A"},
    {100, "B"},
    {124, "A"},
    {124, "B"},
    {148, "A"},
    {148, "B"},
    {172, "A"},
    {172, "B"},
    {196, "A"},
    {196, "B"},
    {220, "A"},
    {220, "B"},
    {244, "A"},
    {244, "B"},
    {268, "A"},
    {268, "B"},
    {300, "E"}
}

luzhishen.IDX_CombatTime = 1
luzhishen.IDX_UseSkillIndex = 2
luzhishen.IDX_CombatFlag = 1
luzhishen.IDX_IsKuangBaoMode = 2
function luzhishen:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function luzhishen:OnHeartBeat(selfId, nTick)
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

function luzhishen:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function luzhishen:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
    local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "luzhishen_NPC", -1, -1)
    self:SetUnitReputationID(MstId, MstId, 0)
end

function luzhishen:OnKillCharacter(selfId, targetId)
    local objType = self:GetCharacterType(targetId)
    if objType == 3 then
        local Hp, MaxHp = self:GetHp(selfId), self:GetMaxHp(selfId)
        if Hp <= MaxHp * 0.9 then
            self:SetHp(selfId, (Hp + MaxHp * 0.1))
        end
    end
end

function luzhishen:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "luzhishen", 2)
    if 2 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "likui") then
        self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "likui", 1)
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đã đánh bại Lỗ Chí Sinh")
end

function luzhishen:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, 1)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E1)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E2)
end

function luzhishen:UseMySkill(selfId, skill)
    if skill == "A" then
        self:LuaFnNpcChat(selfId, 0, "Chân khí hộ thể của lão gia, há bọn ngươi phá nổi!")
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 758, selfId, x, z, 0, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8879, 0)
    elseif skill == "B" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 759, selfId, x, z, 0, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8880, 0)
    elseif skill == "E" then
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1)
        self:SkillE_KuangBao(selfId)
    end
end

function luzhishen:SkillE_KuangBao(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E2, 0)
end

function luzhishen:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return luzhishen
