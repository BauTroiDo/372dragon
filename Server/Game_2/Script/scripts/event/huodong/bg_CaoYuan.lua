local class = require "class"
local define = require "define"
local script_base = require "script_base"
local bg_CaoYuan = class("bg_CaoYuan", script_base)
bg_CaoYuan.script_id = 810003
bg_CaoYuan.DataValidator = 0
bg_CaoYuan.g_BossData = {
    {
        ["ID"] = 9130,
        ["Title"] = "Diệu Thủ Không Không",
        ["PosX"] = 77,
        ["PosY"] = 124,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9131,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 44,
        ["PosY"] = 72,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9132,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 83,
        ["PosY"] = 66,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9133,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 100,
        ["PosY"] = 90,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9134,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 58,
        ["PosY"] = 121,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9135,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 167,
        ["PosY"] = 63,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9136,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 280,
        ["PosY"] = 284,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9137,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 64,
        ["PosY"] = 253,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9138,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 190,
        ["PosY"] = 49,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 9139,
        ["Title"] = "Diệu Thủ Tẩu Tốt",
        ["PosX"] = 276,
        ["PosY"] = 127,
        ["BaseAI"] = 29,
        ["ExtAIScript"] = 256,
        ["ScriptID"] = -1,
        ["NeedCreate"] = 1
    }
}

function bg_CaoYuan:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= bg_CaoYuan.DataValidator then
		self:LOGI("bg_CaoYuan:param6",param6,"bg_CaoYuan.DataValidator",bg_CaoYuan.DataValidator)
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		self:LOGI("bg_CaoYuan:iNoticeType",iNoticeType,"param2",param2,"param3",param3,"param4",param4,"param5",param5)
		return
	end
    -- local nTime = self:GetQuarterTime();
    local sceneId = self:GetSceneID()
	-- if nTime ~= 6 and nTime ~= 54 and nTime ~= 74 and nTime ~= 90 then
		-- return
	-- end
	if sceneId ~= 20 then
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
            local MstId =
                self:LuaFnCreateMonster(
                BossData["ID"],
                BossData["PosX"],
                BossData["PosY"],
                BossData["BaseAI"],
                BossData["ExtAIScript"],
                BossData["ScriptID"]
            )
            self:SetCharacterTitle(MstId, BossData["Title"])
        end
    end
end

function bg_CaoYuan:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
    end
end

function bg_CaoYuan:CurSceneHaveMonster(DataID)
    for i, Data in pairs(self.g_BossData) do
        if DataID == Data["ID"] then
            self.g_BossData[i]["NeedCreate"] = 0
            break
        end
    end
end
function bg_CaoYuan:GetDataValidator(param1,param2)
	bg_CaoYuan.DataValidator = math.random(1,2100000000)
	return bg_CaoYuan.DataValidator
end
return bg_CaoYuan
