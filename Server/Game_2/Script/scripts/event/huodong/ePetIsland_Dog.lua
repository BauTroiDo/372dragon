local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ePetIsland_Dog = class("ePetIsland_Dog", script_base)
ePetIsland_Dog.DataValidator = 0
ePetIsland_Dog.script_id = 808106
ePetIsland_Dog.g_MonsterNumber = 5
ePetIsland_Dog.g_MonsterLifeTime = 3000000
ePetIsland_Dog.g_ActivitySceneId = 158
ePetIsland_Dog.g_BookThiefID = {13402, 13403}
ePetIsland_Dog.g_BookThiefExtAI = {288, 289}
ePetIsland_Dog.g_BookThiefNPCID = 807003
ePetIsland_Dog.g_BookThiefLifeTime = 40 * 60000
ePetIsland_Dog.g_ExistBookThief = 10
function ePetIsland_Dog:BroadcastLocation(level, x, z)
    local noticeMsg = string.format("#{ZSSFC_090211_02}%d#{ZSSFC_090211_03}(%d,%d)#{ZSSFC_090211_04}",level, x, z)
    if nil ~= noticeMsg then self:AddGlobalCountNews(noticeMsg) end
end
function ePetIsland_Dog:GetDataValidator(param1,param2)
	ePetIsland_Dog.DataValidator = math.random(1,2100000000)
	return ePetIsland_Dog.DataValidator
end
function ePetIsland_Dog:BroadcastNotice()
    local Notices = "#{ZSSFC_090211_01}"
    self:AddGlobalCountNews(Notices)
end

function ePetIsland_Dog:CreateMonstersByGroup(sceneId,actId,groupId)
    local Group25 = {
        {
            ["DataId"] = 13404,
            ["x"] = 221.8390,
            ["z"] = 129.7934,
            ["aiType"] = 20,
            ["aiScript"] = 285,
            ["aiLuaExtend"] = 808106,
            ["patrolId"] = 4
        }, {
            ["DataId"] = 13407,
            ["x"] = 222.2473,
            ["z"] = 128.2261,
            ["aiType"] = 20,
            ["aiScript"] = 212,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 5
        }, {
            ["DataId"] = 13410,
            ["x"] = 223.2509,
            ["z"] = 129.5619,
            ["aiType"] = 20,
            ["aiScript"] = -1,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 6
        }, {
            ["DataId"] = 13413,
            ["x"] = 220.3515,
            ["z"] = 129.4081,
            ["aiType"] = 20,
            ["aiScript"] = 214,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 7
        }, {
            ["DataId"] = 13416,
            ["x"] = 221.3242,
            ["z"] = 130.8726,
            ["aiType"] = 20,
            ["aiScript"] = 215,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 8
        }
    }
    local Group45 = {
        {
            ["DataId"] = 13405,
            ["x"] = 158.7148,
            ["z"] = 155.5938,
            ["aiType"] = 20,
            ["aiScript"] = 285,
            ["aiLuaExtend"] = 808106,
            ["patrolId"] = 9
        }, {
            ["DataId"] = 13408,
            ["x"] = 158.9959,
            ["z"] = 154.4017,
            ["aiType"] = 20,
            ["aiScript"] = 212,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 10
        }, {
            ["DataId"] = 13411,
            ["x"] = 159.8189,
            ["z"] = 155.4866,
            ["aiType"] = 20,
            ["aiScript"] = -1,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 11
        }, {
            ["DataId"] = 13414,
            ["x"] = 157.6915,
            ["z"] = 155.4017,
            ["aiType"] = 20,
            ["aiScript"] = 214,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 12
        }, {
            ["DataId"] = 13417,
            ["x"] = 158.4503,
            ["z"] = 156.3715,
            ["aiType"] = 20,
            ["aiScript"] = 215,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 13
        }

    }

    local Group65 = {
        {
            ["DataId"] = 13406,
            ["x"] = 35.6149,
            ["z"] = 151.7296,
            ["aiType"] = 20,
            ["aiScript"] = 285,
            ["aiLuaExtend"] = 808106,
            ["patrolId"] = 14
        }, {
            ["DataId"] = 13409,
            ["x"] = 35.6754,
            ["z"] = 150.6953,
            ["aiType"] = 20,
            ["aiScript"] = 212,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 15
        }, {
            ["DataId"] = 13412,
            ["x"] = 34.6520,
            ["z"] = 151.6869,
            ["aiType"] = 20,
            ["aiScript"] = -1,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 16
        }, {
            ["DataId"] = 13415,
            ["x"] = 36.5562,
            ["z"] = 151.8499,
            ["aiType"] = 20,
            ["aiScript"] = 214,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 17
        }, {
            ["DataId"] = 13418,
            ["x"] = 35.5040,
            ["z"] = 152.6140,
            ["aiType"] = 20,
            ["aiScript"] = 215,
            ["aiLuaExtend"] = -1,
            ["patrolId"] = 18
        }

    }
    local MonsterGroup = {Group25, Group45, Group65}
    local LocationInfo = {
        {["level"] = 25, ["x"] = 221, ["z"] = 129},
        {["level"] = 45, ["x"] = 158, ["z"] = 155},
        {["level"] = 65, ["x"] = 35, ["z"] = 151}

    }
    local group = MonsterGroup[groupId]
    if nil ~= group then
        local locationInfo = LocationInfo[groupId]
        for index = 1, self.g_MonsterNumber do
            local monster = group[index]
            if nil ~= monster then
                local monsterId = self:LuaFnCreateMonster(monster["DataId"],
                                                          monster["x"],
                                                          monster["z"],
                                                          monster["aiType"],
                                                          monster["aiScript"],
                                                          monster["aiLuaExtend"])
				if monster["aiLuaExtend"] and monster["aiLuaExtend"] ~= -1 then
					self:LuaFnSetNpcIntParameter(monsterId, 1, sceneId)
					self:LuaFnSetNpcIntParameter(monsterId, 2, actId + 1)
				end
                self:SetMonsterGroupID(monsterId, groupId)
                self:SetPatrolId(monsterId, monster["patrolId"])
                self:SetCharacterDieTime(monsterId, self.g_MonsterLifeTime)
                if (index == 1) then
                    self:SetCharacterTitle(monsterId, "Đội Trưởng Trinh Sát Thánh Thú Sơn")
                end
            else
                break
            end
        end
        self:BroadcastNotice()
        if nil ~= locationInfo then
            self:BroadcastLocation(locationInfo["level"], locationInfo["x"], locationInfo["z"])
        end
    end
end

function ePetIsland_Dog:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= ePetIsland_Dog.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    local sceneId = self:get_scene_id()
    if self.g_ActivitySceneId == sceneId then
        self:StartOneActivity(actId, math.floor(300000))
    end
end

function ePetIsland_Dog:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    local sceneId = self:get_scene_id()
    if self.g_ActivitySceneId == sceneId then
        local RegenesisTime = {
            {["groupId"] = nil}, {["groupId"] = nil}, {["groupId"] = 1},
            {["groupId"] = nil}, {["groupId"] = nil}, {["groupId"] = nil},
            {["groupId"] = 2}, {["groupId"] = nil}, {["groupId"] = nil},
            {["groupId"] = nil}, {["groupId"] = 3}, {["groupId"] = nil},
            {["groupId"] = nil}, {["groupId"] = nil}, {["groupId"] = 1},
            {["groupId"] = nil}, {["groupId"] = nil}, {["groupId"] = nil},
            {["groupId"] = 2}, {["groupId"] = nil}, {["groupId"] = nil},
            {["groupId"] = nil}, {["groupId"] = 3}, {["groupId"] = nil}
        }
        if 100 > math.floor(self:GetMinute()) then
            local index = math.floor(self:GetHour() + 1)
            local groupId = nil
            local regenesisTime = RegenesisTime[index]
            if nil ~= regenesisTime then
                groupId = regenesisTime["groupId"]
            end
            if nil ~= groupId then
                self:CreateMonstersByGroup(sceneId,actId,groupId)
                self:StopOneActivity(actId)
            end
        end
    end
end

function ePetIsland_Dog:OnDie(objId, selfId)
	if not self:LuaFnIsActivityMonster(selfId,objId,false) then return end
    local sceneId = self:get_scene_id()
    if self.g_ActivitySceneId == sceneId then
		local killerID = selfId
		local objType = self:GetCharacterType(selfId)
		if objType == 3 then killerID = self:GetPetCreator(selfId) end
		local postable = {
			{228, 193}, {227, 125}, {215, 66}, {169, 29}, {155, 83}, {154, 127},
			{159, 167}, {156, 224}, {103, 211}, {95, 121}, {86, 36}, {44, 28},
			{54, 126}, {48, 207}, {62, 159}, {210, 214}, {214, 168}, {203, 139},
			{206, 81}, {161, 64}, {132, 89}, {139, 115}, {133, 122}, {142, 186},
			{161, 190}, {188, 217}, {92, 208}, {34, 141}, {30, 177}, {19, 62}
		}
		local size = #(postable)
		for i = 1, self.g_ExistBookThief do
			local ram = math.random(size)
			local ThisPos = postable[ram]
			for j = ram, size do
				if j + 1 <= size then postable[j] = postable[j + 1] end
			end
			size = size - 1
			local monsterType = math.random(#(self.g_BookThiefID))
			local MonsterId = self:LuaFnCreateMonster(
								  self.g_BookThiefID[monsterType], ThisPos[1],
								  ThisPos[2], 0, self.g_BookThiefExtAI[monsterType],
								  self.g_BookThiefNPCID)
			self:LuaFnSetNpcIntParameter(monsterId, 1, sceneId)
			self:LuaFnSetNpcIntParameter(monsterId, 2, 222 + 1)
			self:SetCharacterDieTime(MonsterId, self.g_BookThiefLifeTime)
			self:SetCharacterTitle(MonsterId, "Bảo Thư Thiết Tặc")
			self:SetUnitReputationID(killerID, MonsterId, 0)
		end
		local strText = "#{ZSSFC_090211_06}"
		self:BroadMsgByChatPipe(killerID, strText, 4)
	end
end

return ePetIsland_Dog
