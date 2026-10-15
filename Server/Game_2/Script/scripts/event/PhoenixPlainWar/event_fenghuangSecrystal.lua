local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_fenghuangSecrystal = class("event_fenghuangSecrystal", script_base)
local gbk = require "wire_charset"
event_fenghuangSecrystal.DataValidator = 0
event_fenghuangSecrystal.script_id = 403009
event_fenghuangSecrystal.TimeTick = 0
event_fenghuangSecrystal.g_BigBox = 
{
    ["Name"] = "Thủy Tinh Sinh Mệnh màu Cam",
    ["MonsterID"] = 14005,
    ["PosX"] = 230,
    ["PosY"] = 230,
    ["ScriptID"] = 403005
}

function event_fenghuangSecrystal:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
	self.TimeTick = self.TimeTick + uTime
	if self.TimeTick < 1000 then
		return
	end
	self.TimeTick = 0
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(52) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(21)
	local opentime = self:LuaFnGetCopySceneData_Param(62)
	local overtime = self:LuaFnGetCopySceneData_Param(51)
	if isopen > 0 and isopen >= opentime and isopen < overtime then
		local nMonsterNum = self:GetMonsterCount()
		for i = 1,nMonsterNum do
			local MonsterId = self:GetMonsterObjID(i)
			local MosDataID = self:GetMonsterDataID(MonsterId)
			if MosDataID == self.g_BigBox["MonsterID"]  then
				return
			end
		end
		if self:LuaFnGetCopySceneData_Param(14) > 0 then
			return
		end
		local MstId = self:LuaFnCreateMonster(self.g_BigBox["MonsterID"] ,self.g_BigBox["PosX"] ,self.g_BigBox["PosY"] ,7,0,self.g_BigBox["ScriptID"] )
		local LeagueName = self:LuaFnGetCopySceneData_Param(18)
		if MstId > 0 then
			if LeagueName ~= 0 then
				self:SetCharacterTitle(MstId,LeagueName.."Thuộc về")
				self:HumanTips(LeagueName.."chiếm thủy tinh cứ điểm Đông Nam")
			end
			if self:LuaFnGetCopySceneData_Param(9) > 0 then
				self:SetUnitCampID(MstId,self:LuaFnGetCopySceneData_Param(9))
				else
				self:SetUnitCampID(MstId,600)
			end
			self:SetCharacterName(MstId,self.g_BigBox["Name"] )
			self:HumanTips("Thủy tinh cứ điểm Đông Nam đã làm mới.")
		end
	end
end
function event_fenghuangSecrystal:GetDataValidator(param1,param2)
	event_fenghuangSecrystal.DataValidator = math.random(1,2100000000)
	return event_fenghuangSecrystal.DataValidator
end



function event_fenghuangSecrystal:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= event_fenghuangSecrystal.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId,100*10,iNoticeType)
end


function event_fenghuangSecrystal:HumanTips(str)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId)
        and self:LuaFnIsCanDoScriptLogic(nHumanId)
        and self:LuaFnIsCharacterLiving(nHumanId) then
            self:BeginEvent(self.script_id)
            self:AddText(str)
            self:EndEvent()
            self:DispatchMissionTips(nHumanId)
        end
    end
end



return event_fenghuangSecrystal