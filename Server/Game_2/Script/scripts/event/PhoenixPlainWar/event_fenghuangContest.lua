local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_fenghuangContest = class("event_fenghuangContest", script_base)
local gbk = require "wire_charset"
event_fenghuangContest.DataValidator = 0
event_fenghuangContest.script_id = 403006
event_fenghuangContest.TimeTick = 0

event_fenghuangContest.g_BigBox =
{ 
    ["Name"] = "凤凰战旗",
    ["MonsterID"] = 14012,
    ["PosX"] = 162,
    ["PosY"] = 161,
    ["ScriptID"] = 403006
}
event_fenghuangContest.g_LimitiBuff = {50,112,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1709,1710,1711,1712,1713,1714,1715,1716,1717,1718,1719,1720,7084,7085}
-- local curistime = 0--emmm
function event_fenghuangContest:GetDataValidator(param1,param2)
	event_fenghuangContest.DataValidator = math.random(1,2100000000)
	return event_fenghuangContest.DataValidator
end
function event_fenghuangContest:OnTimer(actId, uTime, param1)
	self.TimeTick = self.TimeTick + uTime
	if self.TimeTick < 1000 then
		return
	end
	self.TimeTick = 0
	-- curistime = curistime + 1
	-- self:HumanTips("curistime:"..tostring(curistime))
	if not uTime or uTime ~= param1 then
		return
	end
    --判断凤凰古城争夺战是否进行中
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(52) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(21)
	local opentime = self:LuaFnGetCopySceneData_Param(62)
	local overtime = self:LuaFnGetCopySceneData_Param(51)
	if isopen > 0 and isopen >= opentime and isopen < overtime then
		--场景内存在战旗不重复刷新
		local nMonsterNum = self:GetMonsterCount()
		for i = 1, nMonsterNum do
			local MonsterId = self:GetMonsterObjID(i)
			local MosDataID = self:GetMonsterDataID(MonsterId)
			if MosDataID == self.g_BigBox["MonsterID"] then
				return
			end
		end
		--记录战旗是否有归属玩家
		if self:LuaFnGetCopySceneData_Param(31) > 0 then
			return
		end
		--记录战旗是否正在刷新中
		if self:LuaFnGetCopySceneData_Param(30) > 0 then
			return
		end
		local MstId = self:LuaFnCreateMonster(self.g_BigBox["MonsterID"], self.g_BigBox["PosX"], self.g_BigBox["PosY"], 3, 0,self.g_BigBox["ScriptID"])
		if MstId > 0 then
			self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên", "#{FHZD_090708_67}")
			self:HumanTips("#{FHZD_090708_67}")
			self:SetCharacterName(MstId, self.g_BigBox["Name"])
		end
	end
end

function event_fenghuangContest:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	-- if param6 ~= event_fenghuangContest.DataValidator then
		-- return
	-- elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		-- return
	-- end
    -- self:StartOneActivity(actId, 100 * 10, iNoticeType)
end

function event_fenghuangContest:OnBigBoxOpen(selfId, activatorId)
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(52) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(21)
	local opentime = self:LuaFnGetCopySceneData_Param(62)
	local overtime = self:LuaFnGetCopySceneData_Param(51)
	if isopen > 0 and isopen >= opentime and isopen < overtime then
		local IsId = self:GetMissionData(activatorId,ScriptGlobal.MD_FH_UNION)
		if IsId >= 1 and IsId <= 8 then
			self:LuaFnSetCopySceneData_Param(31,activatorId)
			-- local LeagueId = self:LuaFnGetHumanGuildLeagueID(activatorId)
			-- local LeagueName = self:LuaFnGetHumanGuildLeagueName(activatorId)
			self:LuaFnSendSpecificImpactToUnit(activatorId, activatorId, activatorId, 3019, 0)
			local Name = self:GetName(activatorId)
			local sMessage = ""
			local lmname = self:LuaFnGetCopySceneData_Param(92 + IsId)
			sMessage = string.format("#{_INFOUSR%s}#Wlực vãn cuồng lan, giữa loạn quân nhổ cờ chiến Phượng Hoàng.",Name)
			self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên",sMessage)
			self:HumanTips(string.format("%s của %s đã nhổ cờ chiến Phượng Hoàng.",lmname,Name))
			sMessage = string.format("@*;SrvMsg;GLL:#YChiến sự Phượng Hoàng Cổ Thành:#{_INFOUSR%s}#Wlực vãn cuồng lan, giữa loạn quân nhổ cờ chiến Phượng Hoàng.",Name)
			self:BroadMsgByChatPipe(activatorId,gbk.fromutf8(sMessage), 12)
			self:LuaFnGmKillObj(selfId,activatorId)
			self:LuaFnDeleteMonster(selfId)
		end
	end
end
function event_fenghuangContest:OnActivateConditionCheck(selfId,activatorId)
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(52) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(21)
	local opentime = self:LuaFnGetCopySceneData_Param(62)
	local overtime = self:LuaFnGetCopySceneData_Param(51)
	if isopen > 0 and isopen >= opentime and isopen < overtime then
		IsId = self:GetMissionData(activatorId,ScriptGlobal.MD_FH_UNION)
		if IsId < 1 or IsId > 8 then
			self:BeginEvent(self.script_id)
			self:AddText("Ngươi không thuộc người tham gia hoạt động")
			self:EndEvent()
			self:DispatchMissionTips(activatorId)
			return 0
		end
		local strText = "Trạng thái hiện tại không thể mở"
		if self:LuaFnIsUnbreakable(activatorId) then
			self:BeginEvent(self.script_id)
			self:AddText(strText)
			self:EndEvent()
			self:DispatchMissionTips(activatorId)
			return 0
		end
		if self:LuaFnIsConceal(activatorId) then
			self:BeginEvent(self.script_id)
			self:AddText(strText)
			self:EndEvent()
			self:DispatchMissionTips(activatorId)
			return 0
		end
		for i,impactId in pairs(self.g_LimitiBuff) do
			if self:LuaFnHaveImpactOfSpecificDataIndex(activatorId,impactId) then
				self:BeginEvent(self.script_id)
				self:AddText(strText)
				self:EndEvent()
				self:DispatchMissionTips(activatorId)
				return 0
			end
		end
		return 1
	end
	self:BeginEvent(self.script_id)
	self:AddText("Hoạt động chưa mở hoặc đã kết thúc")
	self:EndEvent()
	self:DispatchMissionTips(activatorId)
	return 0
end

function event_fenghuangContest:OnActivateDeplete(selfId,activatorId)
    return 1
end

function event_fenghuangContest:OnActivateEffectOnce(selfId,activatorId)
    self:OnBigBoxOpen(selfId,activatorId)
    return 1
end

function event_fenghuangContest:OnActivateEffectEachTick(selfId,activatorId)
    return 1
end

function event_fenghuangContest:OnActivateActionStart(selfId,activatorId)
    return 1
end

function event_fenghuangContest:OnActivateCancel(selfId,activatorId)
    return 0
end

function event_fenghuangContest:OnActivateInterrupt(selfId,activatorId)
    return 0
end
function event_fenghuangContest:HumanTips(str)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
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

return event_fenghuangContest
