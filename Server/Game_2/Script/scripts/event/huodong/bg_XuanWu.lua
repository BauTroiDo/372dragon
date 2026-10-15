local class = require "class"
local define = require "define"
local script_base = require "script_base"
local bg_XuanWu = class("bg_XuanWu", script_base)
bg_XuanWu.DataValidator = 0
bg_XuanWu.script_id = 810000
bg_XuanWu.g_BossData = {
    {
        ["ID"] = 9100,
        ["PosX"] = 181,
        ["PosY"] = 38,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9101,
        ["PosX"] = 182,
        ["PosY"] = 66,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9102,
        ["PosX"] = 233,
        ["PosY"] = 37,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9103,
        ["PosX"] = 135,
        ["PosY"] = 75,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9104,
        ["PosX"] = 132,
        ["PosY"] = 278,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9105,
        ["PosX"] = 42,
        ["PosY"] = 218,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9106,
        ["PosX"] = 74,
        ["PosY"] = 141,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9107,
        ["PosX"] = 268,
        ["PosY"] = 45,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9108,
        ["PosX"] = 238,
        ["PosY"] = 261,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9109,
        ["PosX"] = 271,
        ["PosY"] = 184,
        ["BaseAI"] = 20,
        ["ExtAIScript"] = 253,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    }
}
function bg_XuanWu:GetDataValidator(param1,param2)
	bg_XuanWu.DataValidator = math.random(1,2100000000)
	return bg_XuanWu.DataValidator
end
function bg_XuanWu:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= bg_XuanWu.DataValidator then
		self:LOGI("bg_XuanWu:param6",param6,"bg_XuanWu.DataValidator",bg_XuanWu.DataValidator)
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		self:LOGI("bg_XuanWu:iNoticeType",iNoticeType,"param2",param2,"param3",param3,"param4",param4,"param5",param5)
		return
	end
    -- local nTime = self:GetQuarterTime();
    local sceneId = self:GetSceneID()
	-- if nTime ~= 14 and nTime ~= 50 and nTime ~= 78 and nTime ~= 86 then
		-- return
	-- end
	if sceneId ~= 39 then
		return
	end
    self:StartOneActivity(actId, 180 * 1000, iNoticeType)
    if #(self.g_BossData) < 1 then
        return
    end
    for _, Data in pairs(self.g_BossData) do
        Data["NeedCreate"] = 1
    end
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum  do
        local MonsterId = self:GetMonsterObjID(i)
        local MosDataID = self:GetMonsterDataID(MonsterId)
        self:CurSceneHaveMonster(MosDataID)
    end
    for _, BossData in pairs(self.g_BossData) do
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
            self:SetCharacterTitle(MonsterID, "玄武岛守护兽")
        end
    end
end

function bg_XuanWu:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
    end
end

function bg_XuanWu:CurSceneHaveMonster(DataID)
    for i, Data in pairs(self.g_BossData) do
        if DataID == Data["ID"] then
            self.g_BossData[i]["NeedCreate"] = 0
            break
        end
    end
end

return bg_XuanWu
