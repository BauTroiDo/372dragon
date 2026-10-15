local class = require "class"
local define = require "define"
local script_base = require "script_base"
local bg_WuYi = class("bg_WuYi", script_base)
bg_WuYi.DataValidator = 0
bg_WuYi.script_id = 810002
bg_WuYi.g_BossData = {
    {
        ["ID"] = 9120,
        ["PosX"] = 53,
        ["PosY"] = 242,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9121,
        ["PosX"] = 88,
        ["PosY"] = 260,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9122,
        ["PosX"] = 54,
        ["PosY"] = 212,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9123,
        ["PosX"] = 41,
        ["PosY"] = 159,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9124,
        ["PosX"] = 80,
        ["PosY"] = 147,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9125,
        ["PosX"] = 114,
        ["PosY"] = 43,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9126,
        ["PosX"] = 267,
        ["PosY"] = 136,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9127,
        ["PosX"] = 202,
        ["PosY"] = 242,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9128,
        ["PosX"] = 147,
        ["PosY"] = 265,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9129,
        ["PosX"] = 182,
        ["PosY"] = 127,
        ["BaseAI"] = 30,
        ["ExtAIScript"] = 255,
        ["ScriptID"] = 810100,
        ["NeedCreate"] = 1
    }
}

function bg_WuYi:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= bg_WuYi.DataValidator then
		self:LOGI("bg_WuYi:param6",param6,"bg_WuYi.DataValidator",bg_WuYi.DataValidator)
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		self:LOGI("bg_WuYi:iNoticeType",iNoticeType,"param2",param2,"param3",param3,"param4",param4,"param5",param5)
		return
	end
    -- local nTime = self:GetQuarterTime();
    local sceneId = self:GetSceneID()
	-- if nTime ~= 2 and nTime ~= 42 and nTime ~= 62 and nTime ~= 79 then
		-- return
	-- end
	if sceneId ~= 32 then
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
            if (BossData["ID"] == 9120) then
                self:SetCharacterTitle(MonsterID, "Bạo Phá Tối Thượng")
            else
                self:SetCharacterTitle(MonsterID, "Vai Phụ Xuất Sắc Nhất")
            end
        end
    end
end
function bg_WuYi:GetDataValidator(param1,param2)
	bg_WuYi.DataValidator = math.random(1,2100000000)
	return bg_WuYi.DataValidator
end
function bg_WuYi:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
    end
end

function bg_WuYi:CurSceneHaveMonster(DataID)
    for i, Data in pairs(self.g_BossData) do
        if DataID == Data["ID"] then
            self.g_BossData[i]["NeedCreate"] = 0
            break
        end
    end
end

return bg_WuYi
