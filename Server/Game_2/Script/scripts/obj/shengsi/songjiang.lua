local class = require "class"
local define = require "define"
local script_base = require "script_base"
local songjiang = class("songjiang", script_base)
songjiang.script_id = 892016
songjiang.g_FuBenScriptId = 892009
songjiang.Buff_MianYi1 = 10472
songjiang.Buff_MianYi2 = 10471
songjiang.Buff_E1 = 10234
songjiang.Buff_E2 = 10235
songjiang.UseSkillList = {
    {3, "A"},
    {4, "B1"},
    {7, "B2"},
    {17, "A"},
    {18, "B1"},
    {21, "B2"},
    {31, "A"},
    {32, "B1"},
    {35, "B2"},
    {45, "A"},
    {46, "B1"},
    {49, "B2"},
    {59, "A"},
    {60, "B1"},
    {63, "B2"},
    {73, "A"},
    {74, "B1"},
    {77, "B2"},
    {87, "A"},
    {88, "B1"},
    {91, "B2"},
    {101, "A"},
    {102, "B1"},
    {105, "B2"},
    {115, "A"},
    {116, "B1"},
    {119, "B2"},
    {129, "A"},
    {130, "B1"},
    {133, "B2"},
    {143, "A"},
    {144, "B1"},
    {147, "B2"},
    {157, "A"},
    {158, "B1"},
    {161, "B2"},
    {171, "A"},
    {172, "B1"},
    {175, "B2"},
    {185, "A"},
    {186, "B1"},
    {189, "B2"},
    {199, "A"},
    {200, "B1"},
    {203, "B2"},
    {213, "A"},
    {214, "B1"},
    {217, "B2"},
    {227, "A"},
    {228, "B1"},
    {231, "B2"},
    {241, "A"},
    {242, "B1"},
    {245, "B2"},
    {255, "A"},
    {256, "B1"},
    {259, "B2"},
    {300, "E"}
}

songjiang.IDX_CombatTime = 1
songjiang.IDX_UseSkillIndex = 2
songjiang.IDX_CombatFlag = 1
songjiang.IDX_IsKuangBaoMode = 2
function songjiang:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function songjiang:OnHeartBeat(selfId, nTick)
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

function songjiang:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function songjiang:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
    local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "songjiang_NPC", -1, -1)
    self:SetUnitReputationID(MstId, MstId, 0)
end

function songjiang:OnKillCharacter(selfId, targetId)
end

function songjiang:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "songjiang", 2)
    if 2 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "guansheng") then
        self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "guansheng", 1)
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đã đánh bại Tống Khương")
end

function songjiang:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, 1)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E1)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E2)
end

function songjiang:UseMySkill(selfId, skill)
    if skill == "A" then
        local num = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, num do
            local ServerID = self:LuaFnGetCopyScene_HumanObjId(i)
            local KillStr = string.format("#{SXRW_090119_154}")
            self:NotifyTip(ServerID, KillStr)
        end
    elseif skill == "B2" then
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 756, selfId, x, z, 0, 1)
    elseif skill == "B1" then
        self:LuaFnNpcChat(selfId, 0, "Các ngươi đã chọc giận ta, chịu chết đi! Yêu Tinh Tụ Nghĩa!!")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8891, 0)
    elseif skill == "E" then
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1)
        self:SkillE_KuangBao(selfId)
    end
end

function songjiang:SkillE_KuangBao(selfId)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_B)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_C)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_D)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E2, 0)
end

function songjiang:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return songjiang
