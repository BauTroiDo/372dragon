local class = require "class"
local define = require "define"
local script_base = require "script_base"
local bg_JingHu = class("bg_JingHu", script_base)
bg_JingHu.script_id = 810111
bg_JingHu.DataValidator = 0
bg_JingHu.g_BossData = {
    {
        ["ID"] = 51660,
        ["PosX"] = 108,
        ["PosY"] = 140,
        ["BaseAI"] = 22,
        ["ExtAIScript"] = 259,
        ["ScriptID"] = 810111,
        ["NeedCreate"] = 1
    }
}

function bg_JingHu:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= bg_JingHu.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	local nTime = os.date("*t").hour
    local sceneId = self:GetSceneID()
	-- 时间检查已由活动系统(activitycore)控制，脚本内不再重复检查
	-- if nTime ~= 19 then
	-- 	return
	-- end
	if sceneId ~= 5 then  -- 镜湖场景ID
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
            self:SetCharacterTitle(MonsterID, "Boss Thiên Ngoại Kính Hồ")
            self:LuaFnSetLifeTimeAttrRefix_MaxHP(MonsterID, 204779960 * 2)
            self:RestoreHp(MonsterID)
        end
    end
end

function bg_JingHu:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
    end
end

function bg_JingHu:CurSceneHaveMonster(DataID)
    for i, Data in pairs(self.g_BossData) do
        if DataID == Data["ID"] then
            self.g_BossData[i]["NeedCreate"] = 0
            break
        end
    end
end

function bg_JingHu:GetDataValidator(param1,param2)
	bg_JingHu.DataValidator = math.random(1,2100000000)
	return bg_JingHu.DataValidator
end

function bg_JingHu:OnDie(objId, killerId)
	if objId == killerId then
		return
	end
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(objId)
	if not obj or obj:get_obj_type() ~= "monster" then
		return
	end
	local playerid
	local name, human
	if objId ~= killerId then
		human = scene:get_obj_by_id(killerId)
		if human then
			if human:get_obj_type() == "human" then
				playerid = killerId
				name = human:get_name()
			elseif human:get_obj_type() == "pet" then
				playerid = human:get_owner_obj_id()
				human = scene:get_obj_by_id(playerid)
				if human then
					name = human:get_name()
				else
					playerid = nil
				end
			else
				human = nil
			end
		end
	end
	if human and playerid then
		local msg = string.format("%s%s#Bkết liễu [BOSS Thiên Ngoại Kính Hồ], may mắn nhận một nụ hôn gió của GM#P.","@*;SrvMsg;SCA:",name)
		self:AddGlobalCountNews(msg)
	end
end

return bg_JingHu
