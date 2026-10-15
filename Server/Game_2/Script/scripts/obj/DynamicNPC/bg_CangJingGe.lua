local skynet = require "skynet"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local bg_CangJingGe = class("bg_CangJingGe", script_base)
bg_CangJingGe.DataValidator = 0
bg_CangJingGe.script_id = 810112
bg_CangJingGe.g_BossData = {
    {
        ["ID"] = 113565,
        ["PosX"] = 266,
        ["PosY"] = 257,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 236,
        ["PosY"] = 226,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 227,
        ["PosY"] = 156,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 245,
        ["PosY"] = 74,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 211,
        ["PosY"] = 192,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 156,
        ["PosY"] = 77,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 83,
        ["PosY"] = 111,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 63,
        ["PosY"] = 142,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 88,
        ["PosY"] = 230,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 195,
        ["PosY"] = 227,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 226,
        ["PosY"] = 126,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 127,
        ["PosY"] = 256,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 95,
        ["PosY"] = 174,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 241,
        ["PosY"] = 162,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 196,
        ["PosY"] = 177,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 203,
        ["PosY"] = 101,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 163,
        ["PosY"] = 192,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 113565,
        ["PosX"] = 138,
        ["PosY"] = 210,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 402111,
        ["NeedCreate"] = 1
    }
}

function bg_CangJingGe:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= bg_CangJingGe.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId, 1900 * 1000, iNoticeType)
    if #(self.g_BossData) < 1 then
        return
    end
    for _, Data in pairs(self.g_BossData) do
        Data["NeedCreate"] = 1
    end
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local MonsterId = self:GetMonsterObjID(i)
        local MosDataID = self:GetMonsterDataID(MonsterId)
        self:CurSceneHaveMonster(MosDataID, self:LuaFnGetNpcIntParameter(MonsterId, 3))
    end
	local sceneId = self:get_scene_id()
    for slot, BossData in ipairs(self.g_BossData) do
        if BossData["NeedCreate"] == 1 then
            local MonsterID =
                self:LuaFnCreateMonster(
                BossData["ID"],
                BossData["PosX"],
                BossData["PosY"],
                BossData["BaseAI"],
                BossData["ExtAIScript"],
                BossData["ScriptID"]
            )
            if not MonsterID or MonsterID <= 0 then
                skynet.loge("CYS Cangjingge: failed to create entry NPC", BossData["ID"], sceneId)
                return
            end
		self:LuaFnSetNpcIntParameter(MonsterID, 1, sceneId)
		self:LuaFnSetNpcIntParameter(MonsterID, 2, actId + 1)
            self:LuaFnSetNpcIntParameter(MonsterID, 3, slot)
            self:SetCharacterTitle(MonsterID, "藏经阁")
            self:SetCharacterDieTime(MonsterID, 1800000)
        end
    end
end

function bg_CangJingGe:GetDataValidator(param1,param2)
	bg_CangJingGe.DataValidator = math.random(1,2100000000)
	return bg_CangJingGe.DataValidator
end

function bg_CangJingGe:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
    end
end

function bg_CangJingGe:CurSceneHaveMonster(DataID, slot)
    -- Persist the spawn slot on the NPC: survivors must not consume another
    -- position's slot when one monk has entered a party's copy scene.
    local Data = slot and self.g_BossData[slot]
    if Data and DataID == Data["ID"] then Data["NeedCreate"] = 0 end
end

return bg_CangJingGe
