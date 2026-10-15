local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huodong_yezhu_2 = class("huodong_yezhu_2", script_base)
huodong_yezhu_2.g_NpcPos = {["x"] = 137, ["y"] = 107}
huodong_yezhu_2.DataValidator = 0
huodong_yezhu_2.g_NpcId = 163
function huodong_yezhu_2:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= huodong_yezhu_2.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId, 30000)
	local sceneId = self:get_scene_id()
    local MonsterId = self:LuaFnCreateMonster(self.g_NpcId, self.g_NpcPos["x"], self.g_NpcPos["y"], 3, -1, 402104)
		self:LuaFnSetNpcIntParameter(MonsterId, 1, sceneId)
		self:LuaFnSetNpcIntParameter(MonsterId, 2, actId + 1)
	self:SetCharacterName(MonsterId, "云飘飘")
    self:SetCharacterTitle(MonsterId, "虫鸟坊坊主")
    self:SetCharacterDieTime(MonsterId, 2 * 1000 * 60 * 60)
end
function huodong_yezhu_2:GetDataValidator(param1,param2)
	huodong_yezhu_2.DataValidator = math.random(1,2100000000)
	return huodong_yezhu_2.DataValidator
end

function huodong_yezhu_2:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
end

return huodong_yezhu_2
