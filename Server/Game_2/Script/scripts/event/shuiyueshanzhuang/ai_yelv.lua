local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_yelv = class("ai_yelv", script_base)
ai_yelv.script_id = 892334
ai_yelv.g_FuBenScriptId = 892328
ai_yelv.Buff_MianYi1 = 10472
ai_yelv.Buff_MianYi2 = 10471
ai_yelv.Skill_A = 1409
ai_yelv.Buff_A = 10230
ai_yelv.IDX_CombatFlag = 1
function ai_yelv:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function ai_yelv:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
    local Per = math.floor(self:GetHp(selfId) / self:GetMaxHp(selfId))
    --[[if Per <= 0.9 then
        if 1 == self:TickSkillA(selfId, nTick) then
            return
        end
    end]]
    --if Per <= 0.8 then
        if 1 == self:TickSkillB(selfId, nTick) then
            return
        end
    --end
    --[[if Per <= 0.7 then
        if 1 == self:TickSkillC(selfId, nTick) then
            return
        end
    end]]
end

function ai_yelv:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 3)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 3, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 3, 145000 - (nTick - cd))
        return self:UseSkillC(selfId)
    end
end

function ai_yelv:UseSkillC(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Vạn nhận tung hoành, xoay chuyển!")
    self:LuaFnUnitUseSkill(selfId, 1424, selfId, x, z, 0, 0)
    local nNpcId = self:LuaFnCreateMonster(48522, 71, 66, 3, -1, -1)
    self:SetUnitReputationID(nNpcId, nNpcId, 18)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        local nPox_x, nPos_z = self:GetWorldPos(nHumanId)
        self:CreateSpecialObjByDataIndex(selfId, 486, nPox_x, nPos_z, 0)
    end
    return 1
end

function ai_yelv:TickSkillA(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 1)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 1, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 1, 45000 - (nTick - cd))
        return self:UseSkillA(selfId)
    end
end

function ai_yelv:TickSkillB(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 2)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 2, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 2, 50000 - (nTick - cd))
        return self:UseSkillB(selfId)
    end
end

function ai_yelv:UseSkillB(selfId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local PlayerInfo = {}
    local nCount = 1
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Đao khí tụ tán, ngàn nhận hóa trận, trận khai!")
    self:LuaFnUnitUseSkill(selfId, 3241, selfId, x, z, 0, 0)
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(PlayerInfo,nHumanId)
        end
    end
    if #PlayerInfo then
            if #PlayerInfo > 2 then
                nCount = 2
            end
        for i = 1,nCount do
            local RandomID = PlayerInfo[math.random(#PlayerInfo)]
            local PlayerX,PlayerZ = self:GetWorldPos(RandomID)
            self:CreateSpecialObjByDataIndex(selfId, 1106, PlayerX, PlayerZ,3000)
        end
    end
    return 1
end
function ai_yelv:UseSkillA(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Lấy khí hóa nhận, trảm!")
    self:LuaFnUnitUseSkill(selfId,3240,selfId,x,z,0,0)
    local PlayerInfo = {}
    local RandomID = -1
    local PlayerX,PlayerZ = -1,-1
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(PlayerInfo,nHumanId)
        end
    end
    if #PlayerInfo >= 1 then
        RandomID = PlayerInfo[math.random(#PlayerInfo)]
        PlayerX,PlayerZ = self:GetWorldPos(RandomID)
    end
    self:CreateSpecialObjByDataIndex(selfId,1106,PlayerX,PlayerZ,2000)
    return 1
end

function ai_yelv:DelaySkillAImpact(selfId,x,z)
    self:LuaFnUnitUseSkill(selfId,3240,selfId,x,z,0,0)
    local PlayerInfo = {}
    local RandomID = -1
    local PlayerX,PlayerZ = -1,-1
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(PlayerInfo,nHumanId)
        end
    end
    if #PlayerInfo >= 1 then
        RandomID = PlayerInfo[math.random(#PlayerInfo)]
        PlayerX,PlayerZ = self:GetWorldPos(RandomID)
    end
    self:CreateSpecialObjByDataIndex(selfId,1106,PlayerX,PlayerZ,2000)
end

function ai_yelv:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function ai_yelv:OnLeaveCombat(selfId)
    --重置AI....
	self:ResetMyAI( selfId )
	--创建对话NPC....
    self:LuaFnDeleteMonster(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "DisableDynamicRegions", "YeLvHongYou_BOSS")
	local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "YeLvHongYou_NPC", -1, -1 )
	self:SetUnitReputationID( MstId, MstId, 0 )
end

function ai_yelv:OnKillCharacter(selfId, targetId)
end

function ai_yelv:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(892328, "OnDie", selfId, killerId)
end

function ai_yelv:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
end

return ai_yelv
