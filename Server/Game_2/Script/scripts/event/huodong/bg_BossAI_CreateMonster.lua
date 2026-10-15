local class = require "class"
local define = require "define"
local script_base = require "script_base"
local bg_BossAI_CreateMonster = class("bg_BossAI_CreateMonster", script_base)
bg_BossAI_CreateMonster.CreateChildTbl = {
    {
        ["MotherID"] = 9100,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9150,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9101,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9151,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9102,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9152,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9103,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9153,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9104,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9154,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9105,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9155,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9106,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9156,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9107,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9157,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9108,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9158,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9109,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9159,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9120,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9140,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9121,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9141,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9122,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9142,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9123,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9143,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9124,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9144,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9125,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9145,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9126,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9146,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9127,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9147,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9128,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9148,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    },
    {
        ["MotherID"] = 9129,
        ["CreateTime"] = 60000,
        ["CreateNum"] = 6,
        ["AllChildNum"] = 900,
        ["ChildID"] = 9149,
        ["BaseAI"] = 0,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = -1,
        ["LifeTime"] = 45000
    }
}

bg_BossAI_CreateMonster.MonsterPosTbl = {
    {["x"] = 0, ["y"] = 0}
}

bg_BossAI_CreateMonster.IDX_UpdateMonsterTime = 1
bg_BossAI_CreateMonster.IDX_NeedCreateMonsterNum = 2
bg_BossAI_CreateMonster.IDX_EnableCreateMonster = 1
bg_BossAI_CreateMonster.IDX_CombatFlag = 2
function bg_BossAI_CreateMonster:OnDie(selfId, killerId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UpdateMonsterTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_NeedCreateMonsterNum, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_EnableCreateMonster, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
end

function bg_BossAI_CreateMonster:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_EnableCreateMonster) then
        return
    end
    local UpdateTime = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_UpdateMonsterTime)
    if nTick < UpdateTime then
        UpdateTime = UpdateTime - nTick
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UpdateMonsterTime, UpdateTime)
        return
    end
    local BossDataID = self:GetMonsterDataID(selfId)
    local bFind = 0
    local CreateData
    for _, Data in pairs(self.CreateChildTbl) do
        if BossDataID == Data["MotherID"] then
            CreateData = Data
            bFind = 1
            break
        end
    end
    local CreateNum = 0
    local NeedCreateNum = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_NeedCreateMonsterNum, 0)
    if NeedCreateNum <= CreateData["CreateNum"] then
        CreateNum = NeedCreateNum
        self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_EnableCreateMonster, 0)
    else
        CreateNum = CreateData["CreateNum"]
    end
    self:LuaFnNpcChat(selfId, 0, "Kẻ không biết sống chết, thủ hạ của ta cũng đủ giết ngươi!")
    for i = 1, CreateNum do
        self:CreateChildMonster(selfId, CreateData)
    end
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_NeedCreateMonsterNum, NeedCreateNum - CreateNum)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UpdateMonsterTime, CreateData["CreateTime"])
end

function bg_BossAI_CreateMonster:OnInit(selfId)
    local BossDataID = self:GetMonsterDataID(selfId)
    local bFind = 0
    local CreateData
    for _, Data in pairs(self.CreateChildTbl) do
        if BossDataID == Data["MotherID"] then
            CreateData = Data
            bFind = 1
            break
        end
    end
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UpdateMonsterTime, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_NeedCreateMonsterNum, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_EnableCreateMonster, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    if bFind == 1 then
        if CreateData["CreateTime"] > 0 and CreateData["CreateNum"] > 0 and CreateData["AllChildNum"] > 0 then
            self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_UpdateMonsterTime, CreateData["CreateTime"])
            self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_NeedCreateMonsterNum, CreateData["AllChildNum"])
            self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_EnableCreateMonster, 1)
        end
    end
end

function bg_BossAI_CreateMonster:OnKillCharacter(selfId, targetId)
end

function bg_BossAI_CreateMonster:OnEnterCombat(selfId, enmeyId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function bg_BossAI_CreateMonster:OnLeaveCombat(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
end

function bg_BossAI_CreateMonster:CreateChildMonster(selfId, CreateData)
    local PosX, PosY = self:LuaFnGetWorldPos(selfId)
    local PosNum = #(self.MonsterPosTbl)
    local PosIndex = math.random(PosNum)
    PosX = PosX + self.MonsterPosTbl[PosIndex]["x"]
    PosY = PosY + self.MonsterPosTbl[PosIndex]["y"]
    local MonId =
        self:LuaFnCreateMonster(
        CreateData["ChildID"],
        PosX,
        PosY,
        CreateData["BaseAI"],
        CreateData["ExtAIScript"],
        CreateData["ScriptID"]
    )
    if CreateData["LifeTime"] > 0 then
        self:SetCharacterDieTime(MonId, CreateData["LifeTime"])
    end
end

return bg_BossAI_CreateMonster
