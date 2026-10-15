local class = require "class"
local define = require "define"
local script_base = require "script_base"
local lujunyi = class("lujunyi", script_base)
lujunyi.script_id = 892011
lujunyi.g_FuBenScriptId = 892009
lujunyi.Buff_MianYi1 = 10472
lujunyi.Buff_MianYi2 = 10471
lujunyi.Buff_E1 = 10234
lujunyi.Buff_E2 = 10235
lujunyi.UseSkillList = {
    {6, "A0"},
    {120, "A"},
    {37, "B"},
    {48, "A0"},
    {68, "A"},
    {79, "B"},
    {90, "A0"},
    {110, "A"},
    {121, "B"},
    {132, "A0"},
    {152, "A"},
    {163, "B"},
    {174, "A0"},
    {194, "A"},
    {205, "B"},
    {216, "A0"},
    {236, "A"},
    {247, "B"},
    {258, "A0"},
    {278, "A"},
    {289, "B"},
    {300, "E"}
}

lujunyi.IDX_CombatTime = 1
lujunyi.IDX_UseSkillIndex = 2
lujunyi.IDX_CombatFlag = 1
lujunyi.IDX_IsKuangBaoMode = 2
function lujunyi:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function lujunyi:OnHeartBeat(selfId, nTick)
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

function lujunyi:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function lujunyi:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
    local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "lujunyi_NPC", -1, -1)
    self:SetUnitReputationID(MstId, MstId, 0)
end

function lujunyi:OnKillCharacter(selfId, targetId)
end

function lujunyi:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "lujunyi", 2)
    if 2 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "luzhishen") then
        self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "luzhishen", 1)
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đã đánh bại Lư Quân Dật")
end

function lujunyi:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, 1)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E1)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E2)
end

function lujunyi:UseMySkill(selfId, skill)
    if skill == "A0" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnNpcChat(selfId, 0, "Xem Thiên Cương Hoàng Khí của ta! Đòn của các ngươi chỉ như gãi ngứa, ha ha!")
        self:LuaFnUnitUseSkill(selfId, 769, selfId, x, z, 0, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8887, 0)
    elseif skill == "A" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnNpcChat(selfId, 0, "Thiên Cương Bá Khí hộ thể! Dám đánh ta, các ngươi đây là tự tìm đường chết.")
        self:LuaFnUnitUseSkill(selfId, 770, selfId, x, z, 0, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8877, 0)
    elseif skill == "B" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090630_115}")
        self:LuaFnUnitUseSkill(selfId, 771, selfId, x, z, 0, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8878, 0)
    elseif skill == "E" then
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1)
        self:SkillE_KuangBao(selfId)
    end
end

function lujunyi:SkillE_KuangBao(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E2, 0)
end

function lujunyi:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return lujunyi
