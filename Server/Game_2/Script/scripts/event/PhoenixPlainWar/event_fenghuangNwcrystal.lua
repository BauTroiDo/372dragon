local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_fenghuangNwcrystal = class("event_fenghuangNwcrystal", script_base)
local gbk = require "wire_charset"
event_fenghuangNwcrystal.script_id = 403008
event_fenghuangNwcrystal.TimeTick = 0
event_fenghuangNwcrystal.DataValidator = 0
event_fenghuangNwcrystal.g_BigBox = 
{
    ["Name"] = "Thủy Tinh Sinh Mệnh màu Vàng",
    ["MonsterID"] = 14007,
    ["PosX"] = 92,
    ["PosY"] = 90,
    ["ScriptID"] = 403005
}



function event_fenghuangNwcrystal:OnTimer(actId, uTime, param1)
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

		if self:LuaFnGetCopySceneData_Param(15) > 0 then
			return
		end

		local MstId = self:LuaFnCreateMonster(self.g_BigBox["MonsterID"] ,self.g_BigBox["PosX"] ,self.g_BigBox["PosY"] ,7,0,self.g_BigBox["ScriptID"] )
		local LeagueName = self:LuaFnGetCopySceneData_Param(19)
		if MstId > 0 then
			if LeagueName ~= 0 then
				self:SetCharacterTitle(MstId,LeagueName.."Thuộc về")
				self:HumanTips(LeagueName.."chiếm thủy tinh cứ điểm Tây Bắc")
			end
			if self:LuaFnGetCopySceneData_Param(10) > 0 then
				self:SetUnitCampID(MstId,self:LuaFnGetCopySceneData_Param(10))
			else
				self:SetUnitCampID(MstId,600)
			end
			self:SetCharacterName(MstId,self.g_BigBox["Name"] )
			self:HumanTips("Thủy tinh cứ điểm Tây Bắc đã làm mới.")
		end
	end
end



function event_fenghuangNwcrystal:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= event_fenghuangNwcrystal.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId,100*10,iNoticeType)
end
function event_fenghuangNwcrystal:GetDataValidator(param1,param2)
	event_fenghuangNwcrystal.DataValidator = math.random(1,2100000000)
	return event_fenghuangNwcrystal.DataValidator
end



function event_fenghuangNwcrystal:HumanTips(str)
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
return event_fenghuangNwcrystal