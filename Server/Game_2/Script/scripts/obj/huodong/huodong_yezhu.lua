local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huodong_yezhu = class("huodong_yezhu", script_base)
huodong_yezhu.DataValidator = 0
huodong_yezhu.g_NpcID = {3730, 3740, 3750, 3760, 3770}

huodong_yezhu.g_NpcPos_1 = {
    {["x"] = 182, ["y"] = 214},
    {["x"] = 150, ["y"] = 227},
    {["x"] = 217, ["y"] = 141},
    {["x"] = 154, ["y"] = 174},
    {["x"] = 202, ["y"] = 104},
    {["x"] = 198, ["y"] = 64},
    {["x"] = 162, ["y"] = 35},
    {["x"] = 75, ["y"] = 18},
    {["x"] = 102, ["y"] = 35},
    {["x"] = 91, ["y"] = 65},
    {["x"] = 114, ["y"] = 119},
    {["x"] = 140, ["y"] = 114},
    {["x"] = 127, ["y"] = 99},
    {["x"] = 157, ["y"] = 100},
    {["x"] = 112, ["y"] = 150},
    {["x"] = 42, ["y"] = 129},
    {["x"] = 23, ["y"] = 162},
    {["x"] = 60, ["y"] = 160},
    {["x"] = 21, ["y"] = 53},
    {["x"] = 36, ["y"] = 38},
    {["x"] = 132, ["y"] = 98},
    {["x"] = 65, ["y"] = 192},
    {["x"] = 102, ["y"] = 207},
    {["x"] = 91, ["y"] = 159},
    {["x"] = 138, ["y"] = 189},
    {["x"] = 154, ["y"] = 172},
    {["x"] = 124, ["y"] = 55},
    {["x"] = 96, ["y"] = 113},
    {["x"] = 127, ["y"] = 94},
    {["x"] = 97, ["y"] = 47}
}

huodong_yezhu.g_NpcPos_2 = {
    {["x"] = 135, ["y"] = 90},
    {["x"] = 62, ["y"] = 47},
    {["x"] = 23, ["y"] = 33},
    {["x"] = 172, ["y"] = 57},
    {["x"] = 175, ["y"] = 137},
    {["x"] = 45, ["y"] = 150}
}

huodong_yezhu.g_NpcPos_3 = {
    {["x"] = 60, ["y"] = 96},
    {["x"] = 213, ["y"] = 35},
    {["x"] = 108, ["y"] = 77},
    {["x"] = 140, ["y"] = 119},
    {["x"] = 154, ["y"] = 22},
    {["x"] = 72, ["y"] = 208}
}

huodong_yezhu.g_TimeTickIndex = 0
function huodong_yezhu:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= huodong_yezhu.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId, math.floor(900000))
    self:SetActivityParam(actId, self.g_TimeTickIndex, 0)
	local sceneId = self:get_scene_id()
    for i, v in pairs(self.g_NpcPos_1) do
        local nIndex = math.random(1, 5)
        local MonsterId = self:LuaFnCreateMonster(self.g_NpcID[nIndex], v["x"], v["y"], 3, -1, 402101)
		self:LuaFnSetNpcIntParameter(MonsterId, 1, sceneId)
		self:LuaFnSetNpcIntParameter(MonsterId, 2, actId + 1)
		self:SetCharacterTitle(MonsterId, "Linh Thú")
        self:SetCharacterDieTime(MonsterId, 5 * 1000 * 60 * 60)
    end
end
function huodong_yezhu:GetDataValidator(param1,param2)
	huodong_yezhu.DataValidator = math.random(1,2100000000)
	return huodong_yezhu.DataValidator
end

function huodong_yezhu:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    local TickTime = self:GetActivityParam(actId, self.g_TimeTickIndex)
    TickTime = TickTime + 1
    self:SetActivityParam(actId, self.g_TimeTickIndex, TickTime)
	local sceneId = self:get_scene_id()
    if TickTime == 1 then
        for i, v in pairs(self.g_NpcPos_2) do
            local nIndex = math.random(1, 5)
            local MonsterId = self:LuaFnCreateMonster(self.g_NpcID[nIndex], v["x"], v["y"], 3, -1, 402101)
			self:LuaFnSetNpcIntParameter(MonsterId, 1, sceneId)
			self:LuaFnSetNpcIntParameter(MonsterId, 2, actId + 1)
			self:SetCharacterTitle(MonsterId, "Linh Thú")
            self:SetCharacterDieTime(MonsterId, 5 * 1000 * 60 * 60)
        end
    end
    if TickTime == 2 then
        for i, v in pairs(self.g_NpcPos_3) do
            local nIndex = math.random(1, 5)
            local MonsterId = self:LuaFnCreateMonster(self.g_NpcID[nIndex], v["x"], v["y"], 3, -1, 402101)
			self:LuaFnSetNpcIntParameter(MonsterId, 1, sceneId)
			self:LuaFnSetNpcIntParameter(MonsterId, 2, actId + 1)
			self:SetCharacterTitle(MonsterId, "Linh Thú")
            self:SetCharacterDieTime(MonsterId, 5 * 1000 * 60 * 60)
        end
    end
end

return huodong_yezhu
