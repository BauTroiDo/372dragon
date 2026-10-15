--烹饪技能升级
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local elevelup_pengren = class("elevelup_pengren", script_base)
elevelup_pengren.script_id = 713561
elevelup_pengren.g_nMaxLevel = 5
elevelup_pengren.g_AbilityID = define.ABILITY_PENGREN
elevelup_pengren.g_AbilityName = "Nấu nướng"

--**********************************
--任务入口函数
--**********************************
function elevelup_pengren:OnDefaultEvent(selfId, targetId, nNum, npcScriptId, bid )
	--玩家技能的等级
	local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
	--玩家加工技能的熟练度
	--任务判断
	--如果是在城市中升级
	if bid then
		local ret = self:CallScriptFunction( define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, self.g_AbilityID, bid, 2)
		if ret then
			self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityAction", selfId, targetId, self.g_AbilityID, bid, 2)
		end
		return
	end
	--如果还没有学会该生活技能
	if AbilityLevel < 1	then
		self:BeginEvent(self.scirpt_id)
		local strText = "Ngươi còn chưa học được"..self.g_AbilityName.."Kỹ năng!"
		self:AddText(strText)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end

	--如果生活技能等级已经超出该npc所能教的范围
	if AbilityLevel >= self.g_MaxLevel then
		self:BeginEvent()
		local strText = "Ta chỉ có thể dạy ngươi cấp 1-5 của"..elevelup_pengren.g_AbilityName.."Kỹ năng, thỉnh đến bang phái học tập Kỹ năng Cao cấp của"..elevelup_pengren.g_AbilityName.."."
	    self:AddText(strText)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
	else
		local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel = self:LuaFnGetAbilityLevelUpConfig(self.g_AbilityID, AbilityLevel + 1)
		if ret then
			self:DispatchAbilityInfo(selfId, targetId,self.script_id, elevelup_pengren.g_AbilityID, demandMoney, demandExp, limitAbilityExpShow, limitLevel)
		end
	end
end

--**********************************
--列举事件
--**********************************
function elevelup_pengren:OnEnumerate(caller, selfId, targetId, bid )
	if bid then
		local ret = self:CallScriptFunction( define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, elevelup_pengren.g_AbilityID, bid, 6)
		if ret then 
            caller:AddNumTextWithTarget(self.script_id,"Thăng cấp"..elevelup_pengren.g_AbilityName.."Kỹ Năng", 12, 1) end
		return
	end
	local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel = self:LuaFnGetAbilityLevelUpConfig(self.g_AbilityID, 1);
	if ret then
		caller:AddNumTextWithTarget(self.script_id,"Thăng cấp"..elevelup_pengren.g_AbilityName.."Kỹ Năng", 12, 1)
	end
	return
end

--**********************************
--检测接受条件
--**********************************
function elevelup_pengren:CheckAccept(selfId )
end

return elevelup_pengren