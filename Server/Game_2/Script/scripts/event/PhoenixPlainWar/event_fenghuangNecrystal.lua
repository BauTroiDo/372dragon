local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_fenghuangNecrystal = class("event_fenghuangNecrystal", script_base)
local gbk = require "wire_charset"
event_fenghuangNecrystal.DataValidator = 0
event_fenghuangNecrystal.script_id = 403007
event_fenghuangNecrystal.TimeTick = 0

event_fenghuangNecrystal.g_BigBox = 
{
    ["Name"] = "Thủy Tinh Sinh Mệnh màu Lục",
    ["MonsterID"] = 14009,
    ["PosX"] = 229,
    ["PosY"] = 90,
    ["ScriptID"] = 403005
}
function event_fenghuangNecrystal:GetDataValidator(param1,param2)
	event_fenghuangNecrystal.DataValidator = math.random(1,2100000000)
	return event_fenghuangNecrystal.DataValidator
end

function event_fenghuangNecrystal:OnTimer(actId, uTime, param1)
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
		if self:LuaFnGetCopySceneData_Param(16) > 0 then
			return
		end
		local MstId = self:LuaFnCreateMonster(self.g_BigBox["MonsterID"] ,self.g_BigBox["PosX"] ,self.g_BigBox["PosY"] ,7,0,self.g_BigBox["ScriptID"] )
		local LeagueName = self:LuaFnGetCopySceneData_Param(20)
		if MstId > 0 then
			if LeagueName ~= 0 then
				self:SetCharacterTitle(MstId,LeagueName.."Thuộc về")
				self:HumanTips(LeagueName.."chiếm thủy tinh cứ điểm Đông Bắc")
			end
			if self:LuaFnGetCopySceneData_Param(11) > 0 then
				self:SetUnitCampID(MstId,self:LuaFnGetCopySceneData_Param(11))
				else
				self:SetUnitCampID(MstId,600)
			end
			self:SetCharacterName(MstId,self.g_BigBox["Name"] )
			self:HumanTips("Thủy tinh cứ điểm Đông Bắc đã làm mới.")
		end
	end
end

function event_fenghuangNecrystal:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	-- if param6 ~= event_fenghuangNecrystal.DataValidator then
		-- return
	-- elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		-- return
	-- end
    -- self:StartOneActivity(actId,100*10,iNoticeType)
end

function event_fenghuangNecrystal:HumanTips(str)
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
return event_fenghuangNecrystal