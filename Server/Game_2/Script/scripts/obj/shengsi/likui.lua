local class = require "class"
local define = require "define"
local script_base = require "script_base"
local likui = class("likui", script_base)
likui.script_id = 892012
likui.g_FuBenScriptId = 892009
likui.Buff_MianYi1 = 10472
likui.Buff_MianYi2 = 10471
likui.Buff_E1 = 10234
likui.Buff_E2 = 10235
likui.UseSkillList = {
    {6, "A"},
    {7, "A1"},
    {18, "B"},
    {26, "A"},
    {27, "A1"},
    {38, "B"},
    {46, "A"},
    {47, "A1"},
    {58, "B"},
    {66, "A"},
    {67, "A1"},
    {78, "B"},
    {86, "A"},
    {87, "A1"},
    {98, "B"},
    {106, "A"},
    {107, "A1"},
    {118, "B"},
    {126, "A"},
    {127, "A1"},
    {138, "B"},
    {146, "A"},
    {147, "A1"},
    {158, "B"},
    {166, "A"},
    {167, "A1"},
    {178, "B"},
    {186, "A"},
    {187, "A1"},
    {198, "B"},
    {206, "A"},
    {207, "A1"},
    {218, "B"},
    {226, "A"},
    {227, "A1"},
    {238, "B"},
    {246, "A"},
    {247, "A1"},
    {258, "B"},
    {300, "E"}
}

likui.IDX_CombatTime = 1
likui.IDX_UseSkillIndex = 2
likui.IDX_CombatFlag = 1
likui.IDX_IsKuangBaoMode = 2
function likui:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function likui:OnHeartBeat(selfId, nTick)
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

function likui:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function likui:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
    local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "likui_NPC", -1, -1)
    self:SetUnitReputationID(MstId, MstId, 0)
end

function likui:OnKillCharacter(selfId, targetId)
end

function likui:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "likui", 2)
    if 2 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "huarong") then
        self:CallScriptFunction(self.g_FuBenScriptId, "SetBossBattleFlag", "huarong", 1)
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đã đánh bại Lý Khôi")
end

function likui:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, 1)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E1)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_E2)
end

function likui:UseMySkill(selfId, skill)
    if skill == "A" then
        local num = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, num do
            local ServerID = self:LuaFnGetCopyScene_HumanObjId(i)
            local KillStr = string.format("#{SXRW_090119_156}")
            self:NotifyTip(ServerID, KillStr)
        end
    elseif skill == "A1" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090119_144}")
        local x, z = self:GetWorldPos(selfId)
        self:LuaFnUnitUseSkill(selfId, 757, selfId, x, z, 0, 1)
        local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanCount do
            local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
            local PlayerX, PlayerZ = self:GetWorldPos(nHumanId)
            local Distance = math.floor(math.sqrt((x - PlayerX) * (x - PlayerX) + (z - PlayerZ) * (z - PlayerZ)))
            if Distance < 5 then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, 8885, 0)
                self:LuaFnNpcChat(selfId, 0, self:GetName(nHumanId) .. "#{SXRW_090630_116}")
            end
        end
    elseif skill == "B" then
        self:LuaFnNpcChat(selfId, 0, "#{SXRW_090630_117}")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8886, 0)
    elseif skill == "E" then
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_IsKuangBaoMode, 1)
        self:SkillE_KuangBao(selfId)
    end
end

function likui:SkillE_KuangBao(selfId)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_B)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_C)
    self:LuaFnCancelSpecificImpact(selfId, self.Buff_D)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_E2, 0)
end

function likui:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return likui
