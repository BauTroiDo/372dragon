local class = require "class"
local define = require "define"
local script_base = require "script_base"
local emenpaiboss = class("emenpaiboss", script_base)
-- local IsScriptid = 808002
emenpaiboss.DataValidator = 0
emenpaiboss.script_id = 808001
emenpaiboss.g_BossLayout = {
    ["xiaoyao"] = {144, 876, 141, 43, 119},
    ["tianlong"] = {143, 877, 95, 36, 120},
    ["tianshan"] = {147, 874, 94, 39, 117},
    ["emei"] = {145, 870, 45, 34, 113},
    ["gaibang"] = {140, 869, 48, 36, 112},
    ["shaolin"] = {139, 872, 46, 40, 115},
    ["mingjiao"] = {141, 871, 98, 58, 114},
    ["xingxiu"] = {146, 873, 142, 51, 116},
    ["wudang"] = {142, 875, 89, 51, 118}
}
function emenpaiboss:GetDataValidator(param1,param2)
	emenpaiboss.DataValidator = math.random(1,2100000000)
	return emenpaiboss.DataValidator
end
function emenpaiboss:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5,param6)
	if param6 ~= emenpaiboss.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    local unt = self:CallLayoutUnit()
    if unt == nil then
        return
    end
    local numMon = self:GetMonsterCount()
    local objMon
    for i = 1, numMon do
        objMon = self:GetMonsterObjID(i)
        if self:GetMonsterDataID(objMon) == unt[2] then
            self:LuaFnDeleteMonster(objMon)
        end
    end
    self:LuaFnCreateMonster(unt[2], unt[3], unt[4], 17, unt[5], -1)
end
function emenpaiboss:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
end

function emenpaiboss:CallLayoutUnit()
    local unt = nil
    local sceneId = self:get_scene_id()
    for _, unt in pairs(self.g_BossLayout) do
        if unt[1] == sceneId then
            return unt
        end
    end
    return unt
end

return emenpaiboss
