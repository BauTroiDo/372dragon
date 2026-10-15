local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ePetSoulActivity = class("ePetSoulActivity", script_base)
ePetSoulActivity.script_id = 893342
ePetSoulActivity.g_TimeTickIndex = 2
ePetSoulActivity.IDX_CombatFlag 		= 1
ePetSoulActivity.g_BossData = {
    {
        ["ID"] = 50614,
        ["BaseAI"] = 22,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 893342,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50615,
        ["BaseAI"] = 22,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 893342,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50616,
        ["BaseAI"] = 22,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 893342,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50617,
        ["BaseAI"] = 22,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 893342,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50618,
        ["BaseAI"] = 22,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 893342,
        ["NeedCreate"] = 1
    },
}
ePetSoulActivity.BossPos = {
    {
        ["PosX"] = 193,
        ["PosY"] = 65,
    },
    {
        ["PosX"] = 236,
        ["PosY"] = 158,
    },
    {
        ["PosX"] = 68,
        ["PosY"] = 119,
    },
    {
        ["PosX"] = 187,
        ["PosY"] = 226,
    },
    {
        ["PosX"] = 250,
        ["PosY"] = 96,
    }
}
ePetSoulActivity.drop_items = {
    38002497, 38002497, 38002497, 38002741, 38002741, 38002497, 38002497, 38002742, 38002497, 38002497,
    38002497, 38002497, 38002530, 38002531, 38002532, 38002533, 38002497, 38002497, 38002497, 38002497,
    38002515, 38002516, 38002517, 38002518, 38002519, 38002520, 38002521, 38002522, 38002523, 38002524,
    38002525, 38002526, 38002527, 38002528, 38002529
}
ePetSoulActivity.IDX_CombatTime		= 1	--进入战斗的计时器....用于记录已经进入战斗多长时间了....
ePetSoulActivity.IDX_UseSkillIndex	= 2	--接下来该使用技能表中的第几个技能....
ePetSoulActivity.UseSkillList =
{
	{ 20,  "A" },
	{ 25,  "B" },

}
function ePetSoulActivity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5)
    self:StartOneActivity(actId, 30 * 60 * 1000, iNoticeType)
    self:SetActivityParam(actId, 1, 0)
    self:SetActivityParam(actId, self.g_TimeTickIndex, 0)
    self:CreateMonsters(actId, 1)
end

function ePetSoulActivity:CreateMonsters(actId, i)
    for _, Data in pairs(self.g_BossData) do
        Data["NeedCreate"] = 1
    end
    local empty_Poss = table.clone(self.BossPos)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum  do
        local MonsterId = self:GetMonsterObjID(i)
        local MosDataID = self:GetMonsterDataID(MonsterId)
        self:CurSceneHaveMonster(MosDataID)
        self:CurPosHaveMonster(MonsterId, empty_Poss)
    end
    if #empty_Poss > 0 then
        for _, BossData in pairs(self.g_BossData) do
            if #empty_Poss > 0 then
                local pos = table.remove(empty_Poss, math.random(#empty_Poss))
                if BossData["NeedCreate"] == 1 then
                        local MstId = self:LuaFnCreateMonster(
                        BossData["ID"],
                        pos["PosX"],
                        pos["PosY"],
                        BossData["BaseAI"],
                        BossData["ExtAIScript"],
                        BossData["ScriptID"]
                    )
                    self:LuaFnSendSpecificImpactToUnit(MstId, MstId, MstId, 10472, 0)
                end
            end
        end
    end
    self:SetActivityParam(actId, 1, i)
end

function ePetSoulActivity:OnTimer(actId, uTime)
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
        return
    end
    local TickTime = self:GetActivityParam(actId, self.g_TimeTickIndex)
	TickTime = TickTime + uTime
    if TickTime >= 5 * 60 * 1000 then
        TickTime = 0
        local value = self:GetActivityParam(actId, 1)
        self:CreateMonsters(actId, value + 1)
        self:BroadCastMonsterTaps()
    end
    self:SetActivityParam(actId, self.g_TimeTickIndex, TickTime)
end

function ePetSoulActivity:BroadCastMonsterTaps()
    local packet_def = require "game.packet"
    local msg = packet_def.GCShowMonsterTaps.new()
    local monster_count = self:GetMonsterCount()
    for i = 1, monster_count do
        local obj_id = self:GetMonsterObjID(i)
        local data_id = self:GetMonsterDataID(obj_id)
        local x, y = self:GetWorldPos(obj_id)
        msg.taps[i] = { id = data_id, pos = { x = x, y = y} }
    end
    self:get_scene():broadcastall(msg)
end

function ePetSoulActivity:CurSceneHaveMonster(DataID)
    for i, Data in pairs(self.g_BossData) do
        if DataID == Data["ID"] then
            self.g_BossData[i]["NeedCreate"] = 0
            return true
        end
    end
    return false
end

function ePetSoulActivity:CurPosHaveMonster(MonsterId, empty_Poss)
    local x, y = self:GetWorldPos(MonsterId)
    local min
    local ii
    for i, v in ipairs(empty_Poss) do
        local dis = (x - v.PosX)^2 + (y - v.PosY)^2
        if min == nil or dis < min then
            min = dis
            ii = i
        end
    end
    if ii then
        table.remove(empty_Poss, ii)
    end
end

function ePetSoulActivity:OnDie(selfId)
    local num = self:GetNearHumanCount(selfId)
    for j = 1, num do

    end
end

function ePetSoulActivity:OnHeartBeat(selfId, nTick)
	--检测是不是死了....
	if not self:LuaFnIsCharacterLiving(selfId) then
		return
	end

	--检测是否不在战斗状态....
	if 0 == self:MonsterAI_GetBoolParamByIndex( selfId, self.IDX_CombatFlag ) then
		return
	end
	--==================================
	--根据节目单释放技能....
	--==================================

	--获得战斗时间和已经执行到技能表中的第几项....
	local CombatTime = self:MonsterAI_GetIntParamByIndex( selfId, self.IDX_CombatTime )
	local NextSkillIndex = self:MonsterAI_GetIntParamByIndex( selfId, self.IDX_UseSkillIndex )
	--累加进入战斗的时间....
	self:MonsterAI_SetIntParamByIndex( selfId, self.IDX_CombatTime, CombatTime + nTick )

	--如果已经执行完整张技能表则不使用技能....
	if NextSkillIndex < 1 or NextSkillIndex > #(self.UseSkillList) then
		NextSkillIndex = 1
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_CombatTime, 0)
	end

	--如果已经到了用这个技能的时间则使用技能....
	local SkillData = self.UseSkillList[NextSkillIndex]
	if ( CombatTime + nTick ) >= SkillData[1]*1000 then
		self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UseSkillIndex, NextSkillIndex+1 )
		self:UseMySkill( selfId, SkillData[2] )
	end
end

function ePetSoulActivity:UseMySkill( selfId, skill )
	if skill == "A" then
		self:UseSkillA(selfId)
	elseif skill == "B" then
        self:UseSkillB(selfId)
    end
end

function ePetSoulActivity:UseSkillA(selfId)
    local i = math.random(1, 3)
    local num = self:GetNearHumanCount(selfId)
    for j = 1, num do
        if j % i == 0 then
            local humanObjId = self:GetNearHuman(selfId, j)
            local x, z = self:GetWorldPos(humanObjId)
            self:CreateSpecialObjByDataIndex(selfId, 1493, x, z)
        end
    end
end

function ePetSoulActivity:UseSkillB(selfId)
    local x, z = self:GetWorldPos(selfId)
    for i = 1, 5 do
         local MstId = self:LuaFnCreateMonster(
            50619,
            x + math.random(1, 10) - 5,
            z + math.random(1, 10) - 5,
            0,
            -1,
            -1
        )
        self:SetCharacterDieTime(MstId, 30 * 1000)
    end
end

function ePetSoulActivity:OnEnterCombat(selfId)
	self:ResetMyAI( selfId )
	--设置进入战斗状态....
	self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1 )
end

function ePetSoulActivity:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI( selfId )
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
end

function ePetSoulActivity:ResetMyAI( selfId )
	--重置参数....
	self:MonsterAI_SetIntParamByIndex( selfId, self.IDX_CombatTime, 0 )
	self:MonsterAI_SetIntParamByIndex( selfId, self.IDX_UseSkillIndex, 1 )
end

-- [2026-09-11] client PetSoul_XuanWuDao: khi vào Huyền Vũ Đảo (112) / Huyền Vũ Đảo·Kính (579) xin dữ liệu UI 89334201
ePetSoulActivity.g_BossGrade = { [50614] = 1, [50615] = 1, [50616] = 2, [50617] = 2, [50618] = 3 }
ePetSoulActivity.g_DropQuota = { 10, 6, 2 }
function ePetSoulActivity:OnOpenXuanWuDaoUI(selfId, flag)
    local sceneId = self:get_scene_id()
    local sceneType = (sceneId == 112 or sceneId == 579) and 1 or 0
    local counts = { 0, 0, 0 }
    if sceneType == 1 then
        local n = self:GetMonsterCount()
        for i = 1, n do
            local objId = self:GetMonsterObjID(i)
            local g = self.g_BossGrade[self:GetMonsterDataID(objId)]
            if g and self:LuaFnIsCharacterLiving(objId) then counts[g] = counts[g] + 1 end
        end
    end
    self:BeginUICommand()
    self:UICommand_AddInt(sceneType)
    self:UICommand_AddInt(counts[1])
    self:UICommand_AddInt(counts[2])
    self:UICommand_AddInt(counts[3])
    self:UICommand_AddInt(self.g_DropQuota[1]) -- server không đếm rơi đồ theo ngày -> hiển thị 0 đã nhận
    self:UICommand_AddInt(self.g_DropQuota[2])
    self:UICommand_AddInt(self.g_DropQuota[3])
    self:UICommand_AddInt(0) -- stopwatch
    self:UICommand_AddInt(0) -- next time
    self:UICommand_AddInt(0) -- ui type
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89334201)
end

return ePetSoulActivity
