local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_fanwu = class("ai_fanwu", script_base)
ai_fanwu.script_id = 892331
ai_fanwu.g_FuBenScriptId = 892328
ai_fanwu.Buff_MianYi1 = 10472
ai_fanwu.Buff_MianYi2 = 10471
ai_fanwu.Skill_A = 1409
ai_fanwu.Buff_A = 10230
ai_fanwu.IDX_CombatFlag = 1
function ai_fanwu:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function ai_fanwu:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
    --[[if self:LuaFnGetCopySceneData_Param(20) == 2 then
        self:LuaFnCancelSpecificImpact(selfId, 50006)
        self:LuaFnSetCopySceneData_Param(20, 0)
    end]]
    local Per = math.floor(self:GetHp(selfId) / self:GetMaxHp(selfId))
    if Per <= 0.9 then
        if 1 == self:TickSkillA(selfId, nTick) then
            return
        end
    end
    if Per <= 0.8 then
        if 1 == self:TickSkillB(selfId, nTick) then
            return
        end
    end
    if Per <= 0.6 then
        if 1 == self:TickSkillC(selfId, nTick) then
            return
        end
    end
end

function ai_fanwu:TickSkillA(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 1)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 1, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 1, 75000 - (nTick - cd))
        return self:UseSkillA(selfId)
    end
end

function ai_fanwu:UseSkillA(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, 3230, selfId, x, z, 0, 0)
    self:NotifyFailTips("#{SYSZ_20210203_44}")
    self:NotifyFailTips("#{SYSZ_20210203_45}")
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "#{SYSZ_20210203_43}")
    local nNpcId = self:LuaFnCreateMonster(48511, x + 1, z + 1, 27, -1, -1)
    self:SetCharacterTitle(nNpcId,"E rằng ngoại công")
    self:SetUnitReputationID(nNpcId, nNpcId, 18)
    self:LuaFnSendSpecificImpactToUnit(nNpcId, nNpcId, nNpcId, 50007, 0)
    nNpcId = self:LuaFnCreateMonster(48512, x - 1, z - 1, 27, -1, -1)
    self:SetCharacterTitle(nNpcId,"E rằng nội công")
    self:SetUnitReputationID(nNpcId, nNpcId, 18)
    self:LuaFnSendSpecificImpactToUnit(nNpcId, nNpcId, nNpcId, 50008, 0)
    return 1
end

function ai_fanwu:TickSkillB(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 2)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 2, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 2, 105000 - (nTick - cd))
        return self:UseSkillB(selfId)
    end
end

function ai_fanwu:UseSkillB(selfId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local nCount = 1
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "#{SYSZ_20210203_48}")
    self:NotifyFailTips("#{SYSZ_20210203_49}")
    self:LuaFnUnitUseSkill(selfId, 3231, selfId, x, z, 0, 0)
    local mensi = {}
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(mensi, nHumanId)
        end
    end
    if #mensi then
        if #mensi >= 2 then
            nCount = 2
        end
        for i = 1,nCount do
            local randomID = mensi[math.random(1,#(mensi))]
            self:LuaFnSendSpecificImpactToUnit(randomID, randomID, randomID, 50005, 0)
            x, z = self:GetWorldPos(randomID)
            local nNpcId = self:LuaFnCreateMonster(48513, x, z, 7, -1, 892339)
            self:SetUnitReputationID(nNpcId, nNpcId, 18)
        end
    end
    return 1
end

function ai_fanwu:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 3)
    if cd > nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 3, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 3, 125000 - (nTick - cd))
        return self:UseSkillC(selfId)
    end
end

function ai_fanwu:UseSkillC(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Độc chướng sát hồn, sát khí đoạt phách! Không nhanh chóng lựa chọn thì sẽ mệnh tang hoàng tuyền đấy!")
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            self:DoNpcTalk(nHumanId,102)
        end
    end
    self:SetPos(selfId,125,125) --将BOSS转移回中间位置
    self:LuaFnUnitUseSkill(selfId, 3232, selfId, x, z, 0, 0)
    local nPos = 
    {
        {117, 125},
        {135, 125}
    }

    local nType = math.random(1,2)
    local MonsterId = -1
    local nType_1 = self:LuaFnCreateMonster(48514, nPos[1][1], nPos[1][2], 3, -1, -1)
    local nType_2 = self:LuaFnCreateMonster(48515, nPos[2][1], nPos[2][2], 3, -1, -1)
    if nType == 1 then
        MonsterId = nType_1
    else
        MonsterId = nType_2
    end
    self:SetCharacterDieTime(nType_1, 13000)
    self:SetCharacterDieTime(nType_2, 13000)
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            if self:IsInDist(nHumanId,MonsterId,10) then
            else
                self:DelaySkillAImpact(selfId,nHumanId)
            end
        end
    end
    local ncircle = {"Đen.", "Màu đỏ"}
    self:NotifyFailTips("Xin vào" .. ncircle[nType] .. "trong khu vực, né sát khí của Phạn Vô Cứu")
    return 1
end
function ai_fanwu:DelaySkillAImpact(selfId,ObjId)
    self:LuaFnSendSpecificImpactToUnit(selfId,selfId,ObjId,50009,0)
end

function ai_fanwu:NotifyFailTips(Tip)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:BeginEvent(self.script_id)
        self:AddText(Tip)
        self:EndEvent()
        self:DispatchMissionTips(nHumanId)
    end
end


function ai_fanwu:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function ai_fanwu:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI( selfId )
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetMonsterDataID(nMonsterId) == 48511
        or self:GetMonsterDataID(nMonsterId) == 48512
        or self:GetMonsterDataID(nMonsterId) == 48513
        or self:GetMonsterDataID(nMonsterId) == 48514
        or self:GetMonsterDataID(nMonsterId) == 48515  then
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
	--创建对话NPC....
    self:LuaFnDeleteMonster(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "DisableDynamicRegions", "FanWuJiu_BOSS")
	local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "FanWuJiu_NPC", -1, -1 )
	self:SetUnitReputationID( MstId, MstId, 0 )
end

function ai_fanwu:OnKillCharacter(selfId, targetId)
end

function ai_fanwu:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(892328, "OnDie", selfId, killerId)
end

function ai_fanwu:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
end

return ai_fanwu
