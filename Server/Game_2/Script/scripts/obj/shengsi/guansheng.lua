local class = require "class"
local define = require "define"
local script_base = require "script_base"
local guansheng = class("guansheng", script_base)
guansheng.script_id = 892010
guansheng.g_FuBenScriptId = 892009
guansheng.Buff_MianYi1 = 10472
guansheng.Buff_MianYi2 = 10471
guansheng.Buff_E1 = 10234
guansheng.Buff_E2 = 10235
guansheng.UseSkillList = {
    {13, "B1"},
    {16, "A2"},
    {17, "C"},
    {33, "B1"},
    {36, "A2"},
    {37, "C"},
    {53, "B1"},
    {56, "A2"},
    {57, "C"},
    {68, "B"},
    {73, "B1"},
    {76, "A2"},
    {77, "C"},
    {88, "B"},
    {93, "B1"},
    {96, "A2"},
    {97, "C"},
    {108, "B"},
    {113, "B1"},
    {116, "A2"},
    {117, "C"},
    {128, "B"},
    {133, "B1"},
    {136, "A2"},
    {137, "C"},
    {148, "B"},
    {153, "B1"},
    {156, "A2"},
    {157, "C"},
    {168, "B"},
    {173, "B1"},
    {176, "A2"},
    {177, "C"},
    {188, "B"},
    {193, "B1"},
    {196, "A2"},
    {197, "C"},
    {208, "B"},
    {213, "B1"},
    {216, "A2"},
    {217, "C"},
    {228, "B"},
    {233, "B1"},
    {236, "A2"},
    {237, "C"},
    {248, "B"},
    {253, "B1"},
    {256, "A2"},
    {257, "C"},
    {268, "B"},
    {273, "B1"},
    {276, "A2"},
    {277, "C"},
    {300, "E"}
}

guansheng.IDX_CombatTime = 1
guansheng.IDX_UseSkillIndex = 2
guansheng.IDX_CombatFlag = 1
guansheng.IDX_IsKuangBaoMode = 2
function guansheng:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function guansheng:OnHeartBeat(selfId, nTick)
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

function guansheng:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function guansheng:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
    local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "guansheng_NPC", -1, -1)
    self:SetUnitReputationID(MstId, MstId, 0)
end

function guansheng:OnKillCharacter(selfId, targetId)
end

function guansheng:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "guansheng", 2)
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đã đánh bại Quan Thịnh")
end

function guansheng:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, 1)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E1)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E2)
end

function guansheng:UseMySkill(selfId, skill)
    if skill == "A" then
    elseif skill == "A1" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 760, selfId, x, z, 0, 1)
    elseif skill == "A2" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 760, selfId, x, z, 0, 1)
    elseif skill == "B" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090119_146}")
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 772, selfId, x, z, 0, 1)
    elseif skill == "C" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 761, selfId, x, z, 0, 1)
    elseif skill == "B1" then
        self:LuaFnNpcChat(selfId, 0, "Diệt Thế Chi Trận, cửu tử nhất sinh. Các ngươi chịu chết đi!")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8891, 0)
    elseif skill == "E" then
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1)
        self:SkillE_KuangBao(selfId)
    end
end

function guansheng:SkillE_KuangBao(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E2, 0)
end

function guansheng:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return guansheng
